-- Keep only intersting column and add constraints
drop table if exists aisdk cascade;

create table aisdk (
    imo integer
    , mmsi integer not null
    , timestamp timestamp not null
    , latitude numeric not null
    , longitude numeric not null
    , rot numeric
    , sog numeric
    , cog numeric
    , heading int
    , navigational_status text
    , ship_type text
    , geom geometry(point)
);

-- create timescaledb hypertable
select
    create_hypertable ('aisdk' , 'timestamp');

insert into aisdk (imo , mmsi , timestamp , latitude , longitude , rot , sog , cog , heading , navigational_status , ship_type , geom)
select
    case when imo = 'Unknown' then
        null
    else
        imo::int
    end as imo
    , mmsi::int
    , timestamp::timestamp
    , latitude::numeric
    , longitude::numeric
    , rot::numeric
    , sog::numeric
    , cog::numeric
    , heading::int
    , navigational_status
    , ship_type
    , st_setsrid (st_point (longitude::numeric , latitude::numeric) , 4326)
from
    aisdk_raw;

create index on aisdk (imo);

create index on aisdk (ship_type);

create index on aisdk using gist (geom);

-- Remove position with incorrect coordinates
-- Keep one position every thirty minutes using timescaledb
-- Calculate a fishing score based on [Global Fish Watch heuristic model](https://github.com/GlobalFishingWatch/vessel-scoring/blob/master/notebooks/Model-Descriptions.ipynb)
-- Calculate a distance from land using land polygon from [pgosmdata](https://github.com/gma2th/pgosmdata) and postgis nearest neighbor algorithm
-- Create fishing zones with dbscan algorithm

with ais as (
    select
        *
        , 1.0 - least (1.0
            , sog / 17.0) as measured_speed
        , cog / 360.0 as measured_course
    from
        aisdk
    where
        - 180 < longitude
        and longitude < 180
        and - 90 < latitude
        and latitude < 90
)
, ais_30min as (
    select
        mmsi
        , ship_type
        , time_bucket (interval '30 minutes'
            , timestamp) as bucket
        , last (latitude
            , timestamp) as latitude
        , last (longitude
            , timestamp) as longitude
        , last (geom
            , timestamp) as geom
        , last (rot
            , timestamp) as rot
        , last (sog
            , timestamp) as sog
        , last (cog
            , timestamp) as cog
        , last (heading
            , timestamp) as heading
        , last (navigational_status
            , timestamp) as navigational_status
        , 2.0 / 3.0 * (stddev(measured_speed) + stddev(measured_course) + avg(measured_speed)) as fishing_score
    from
        ais
    group by
        mmsi
        , ship_type
        , bucket
)
select
    ais_30min.*
    , d.distance as distance_from_land into aisdk_30min
from
    ais_30min
    left join lateral (
        select
            ST_DistanceSphere (ais_30min.geom , land.geom) as distance
        from
            land_polygon land
        order by
            ais_30min.geom <#> land.geom
        limit 1) d on true;

create index on aisdk_30min (imo);

create index on aisdk_30min (ship_type);

create index on aisdk_30min using gist (geom);

-- Create fishing zone with dbscan algorithm
select
    st_convexhull (st_collect (geom)) as geom into fishing_zone
from (
    select
        st_clusterdbscan (geom , eps := 0.3 , minpoints := 10) over () as clusterid
        , geom
    from
        aisdk_30min
    where
        navigational_status = 'Engaged in fishing') zone_cluster
where
    clusterid is not null
group by
    clusterid;
