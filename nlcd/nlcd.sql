-- Create the NLCD designation CSV files
drop schema nlcd cascade;
create schema nlcd;
set search_path=nlcd,public;

create table class (
 nlcd_id integer primary key,
 major text,
 class text,
 description text
);
\copy class from nlcd_2006_class.csv with csv header

create table xwalk (
 dau_id integer,
 dau varchar(8),
 grid_id integer,
 dwr_id varchar(7),
 nlcd_id integer,
 nlcd_name text,
 count integer
);
\copy xwalk from xwalk_hist.csv with csv NULL '*'

create table grid_count as 
select dwr_id,dau,sum(count) from xwalk group by dwr_id,dau;

-- The most simple table gives the fractional amount 
-- of major designations for each grid/dau pair.
create table nlcd_2006_major as 
select 
dwr_id,dau,major,
(sum(count)*1.0/sum)::decimal(6,2) as fraction 
from xwalk 
join class using (nlcd_id) 
join grid_count using (dwr_id,dau) 
group by dwr_id,dau,major,sum order by dwr_id,dau,major;

\copy (select dwr_id,dau,major,fraction from nlcd_2006_major) to ../land_cover/nlcd_2006_major.csv with csv header

create table nlcd_2006_major_ct as 
select * from crosstab(
'select dwr_id||'':''||dau,dwr_id,dau,major,fraction from nlcd_2006_major where dwr_id != ''no data'' and dau != ''no_data'' order by 1',
'select distinct major from nlcd_2006_major order by 1'
) as 
ct(
dd text,
dwr_id varchar(7),
dau varchar(8),
barren decimal(6,2),
developed decimal(6,2),
forest decimal(6,2),
herbaceous decimal(6,2),
"planted/cultivated" decimal(6,2),
shrubland decimal(6,2),
water decimal(6,2),
wetlands decimal(6,2)
);

\copy (select dwr_id,dau,barren,developed,forest,herbaceous,"planted/cultivated",shrubland,water,wetlands from nlcd_2006_major_ct) to ../land_cover/nlcd_2006_major_ct.csv with csv header


-- The most simple table gives the fractional amount 
-- of class designations for each grid/dau pair.
create table nlcd_2006_class as 
select 
dwr_id,dau,class,
(sum(count)*1.0/sum)::decimal(6,2) as fraction 
from xwalk 
join class using (nlcd_id) 
join grid_count using (dwr_id,dau) 
group by dwr_id,dau,class,sum order by dwr_id,dau,class;

\copy (select dwr_id,dau,class,fraction from nlcd_2006_class) to ../land_cover/nlcd_2006_class.csv with csv header

--with c as (select distinct class from nlcd_2006_class order by 1) select '"'||class||'" decimal(6,2),' from c;

create table nlcd_2006_class_ct as 
select * from crosstab(
'select dwr_id||'':''||dau,dwr_id,dau,class,fraction from nlcd_2006_class where dwr_id != ''no data'' and dau != ''no_data'' order by 1',
'select distinct class from nlcd_2006_class order by 1'
) as 
ct(
dd text,
dwr_id varchar(7),
dau varchar(8),
"Barren Land (Rock/Sand/Clay)" decimal(6,2),
"Cultivated Crops" decimal(6,2),
"Deciduous Forest" decimal(6,2),
"Developed High Intensity" decimal(6,2),
"Developed, Low Intensity" decimal(6,2),
"Developed, Medium Intensity" decimal(6,2),
"Developed, Open Space" decimal(6,2),
"Emergent Herbaceous Wetlands" decimal(6,2),
"Evergreen Forest" decimal(6,2),
"Grassland/Herbaceous" decimal(6,2),
"Mixed Forest" decimal(6,2),
"Open Water" decimal(6,2),
"Pasture/Hay" decimal(6,2),
"Perennial Ice/Snow" decimal(6,2),
"Shrub/Scrub" decimal(6,2),
"Woody Wetlands" decimal(6,2)
);

--with c as (select distinct class from nlcd_2006_class order by 1) select string_agg('"'||class||'"',',') from c;

\copy (select dwr_id,dau,"Barren Land (Rock/Sand/Clay)","Cultivated Crops","Deciduous Forest","Developed High Intensity","Developed, Low Intensity","Developed, Medium Intensity","Developed, Open Space","Emergent Herbaceous Wetlands","Evergreen Forest","Grassland/Herbaceous","Mixed Forest","Open Water","Pasture/Hay","Perennial Ice/Snow","Shrub/Scrub","Woody Wetlands" from nlcd_2006_class_ct) to ../land_cover/nlcd_2006_class_ct.csv with csv header

