create extension if not exists postgis;

create extension if not exists timescaledb cascade;

-- Load raw ais data

create table aisdk_raw (
    timestamp text
    , type_of_mobile text
    , mmsi text
    , latitude text
    , longitude text
    , navigational_status text
    , rot text
    , sog text
    , cog text
    , heading text
    , imo text
    , callsign text
    , name text
    , ship_type text
    , cargo_type text
    , width text
    , length text
    , type_of_position_fixing_device text
    , draught text
    , destination text
    , eta text
    , data_source_type text
    , a text
    , b text
    , c text
    , d text
);

\copy aisdk_raw from data/aisdk_20200401.csv delimiter ',' CSV HEADER;
