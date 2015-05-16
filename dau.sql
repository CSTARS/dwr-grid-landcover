drop schema dauco cascade;
create schema dauco;
set search_path=dauco,nlcd,public;

create table dwr_grid_info (
dau_co_id varchar(7),
grid_id varchar(7),
DAU_CoGrdArea float,
aggrdarea float,
urgrdarea float,
nvgrdarea float,
wsgrdarea float,
ag boolean,
urban boolean,
nv boolean,
water boolean);

-- import data
\set foo `cd /home/quinn/dwr-grid-landcover/dwr_grid_info; for i in DAUCo*.csv; do echo $i; grep -v '#' $i | psql -d quinn -c 'copy dauco.dwr_grid_info from stdin with csv header'; done`

update dwr_grid_info set dau_co_id=trim(both from dau_co_id);
update dwr_grid_info set grid_id=trim(both from grid_id);
update dwr_grid_info set dau_co_id='00'||dau_co_id where length(dau_co_id)=3;
update dwr_grid_info set dau_co_id='0'||dau_co_id where length(dau_co_id)=4;


create table dwr_class (
 major text primary key,
 dwr text
);
insert into dwr_class (major,dwr) values 
('Water','Water'),
('Developed','Urban'),
('Barren','NV'),
('Forest','NV'),
('Shrubland','NV'),
('Herbaceous','NV'),
('Planted/Cultivated','Ag'),
('Wetlands','Wetlands');

create or replace view nlcd_2006_dwr as
select 
dwr_id,dau,county,dwr,sum(count) as count 
from nlcd_2006_major 
join dwr_class using (major)
group  by dwr_id,dau,county,dwr 
order by county,dau,dwr_id;

create table nlcd_2006_dwr_ct as 
select * from crosstab(
'select county||'':''||'':''||dau||'':''||dwr_id,dwr_id,dau,county,dwr,count from nlcd_2006_dwr where dwr_id != ''no data'' and dau != '''' and dau != ''no data'' and county != ''no data'' order by 1',
'select distinct dwr from nlcd_2006_dwr order by 1'
) as 
ct(
dd text,
dwr_id varchar(7),
dau varchar(8),
county varchar(3),
Ag float,
NV float,
Urban float,
Water float,
Wetlands float
);

update nlcd_2006_dwr_ct set ag=0 where ag is null;
update nlcd_2006_dwr_ct set nv=0 where nv is null;
update nlcd_2006_dwr_ct set urban=0 where urban is null;
update nlcd_2006_dwr_ct set water=0 where water is null;
update nlcd_2006_dwr_ct set wetlands=0 where wetlands is null;

create table nlcd_grid_info as 
select 
dau||lpad(((county::integer/2)+1)::text,2,'0') as Dau_Co_ID,
dwr_id as Grid_id,
sum*30*30 as DAU_CoGrdArea,
ag*30*30 as AgGrdArea,
urban*30*30 as UrGrdArea,
nv*30*30 as NVGrdArea,
water*30*30 as WSGrdArea,
wetlands*30*30 as WetGrdArea,
CASE WHEN (ag !=0 ) THEN 1 ELSE 0 END as Ag, 
CASE WHEN (urban != 0 ) THEN 1 ELSE 0 END as Urban, 
CASE WHEN (nv != 0) THEN 1 ELSE 0 END as NV, 
CASE WHEN (water != 0) THEN 1 ELSE 0 END as Water, 
CASE WHEN (wetlands != 0) THEN 1 ELSE 0 END as Wetlands 
from nlcd_2006_dwr_ct 
join nlcd.grid_count 
using (dau,county,dwr_id);

create or replace view dau_co_id_tots as 
with d as (select 'dwr' as source,
dau_co_id,
sum(dau_cogrdarea) as total,
sum(aggrdarea) as ag,
sum(urgrdarea) as urban,
sum(nvgrdarea) as nv,
sum(wsgrdarea) as ws 
from dwr_grid_info 
group by dau_co_id),
n as (
select 'nlcd' as source,
dau_co_id,
sum(dau_cogrdarea) as total,
sum(aggrdarea) as ag,
sum(urgrdarea) as urban,
sum(nvgrdarea) as nv,
sum(wetgrdarea) as wet,
sum(wsgrdarea) as ws
from nlcd_grid_info 
group by dau_co_id)
select coalesce(d.dau_co_id,n.dau_co_id) as dau_co_id,
coalesce((d.total/4046.86),0)::decimal(8,1) as dwr_total,
coalesce((d.ag/4046.86),0)::decimal(8,1) as dwr_ag,
coalesce((d.urban/4046.86),0)::decimal(8,1) as dwr_urban,
coalesce((d.nv/4046.86),0)::decimal(8,1) as dwr_nv,
coalesce((d.ws/4046.86),0)::decimal(8,1) as dwr_ws,
coalesce((n.total/4046.86),0)::decimal(8,1) as nlcd_total,
coalesce((n.ag/4046.86),0)::decimal(8,1) as nlcd_ag,
coalesce((n.nv/4046.86),0)::decimal(8,1) as nlcd_nv,
coalesce((n.urban/4046.86),0)::decimal(8,1) as nlcd_urban,
coalesce((n.wet/4046.86),0)::decimal(8,1) as nlcd_wet,
coalesce((n.ws/4046.86),0)::decimal(8,1) as nlcd_ws
from d full outer join n using (dau_co_id) order by 1;

create view totals as 
select 'dwr' as source,
to_char(sum(dau_cogrdarea),'9.99EEEE') as total,
to_char(sum(aggrdarea),'9.99EEEE') as ag,
to_char(sum(urgrdarea),'9.99EEEE') as urban,
to_char(sum(nvgrdarea),'9.99EEEE') as nv,
to_char(sum(wsgrdarea),'9.99EEEE') as ws 
from dwr_grid_info 
union select 'nlcd' as source,
to_char(sum(dau_cogrdarea),'9.99EEEE') as total,
to_char(sum(aggrdarea),'9.99EEEE') as ag,
to_char(sum(urgrdarea),'9.99EEEE') as urban,
to_char(sum(nvgrdarea),'9.99EEEE') as nv,
to_char(sum(wsgrdarea),'9.99EEEE') as ws 
from nlcd_grid_info ; 


-- To Get the files...
-- for d in `psql -A -t -d quinn -c 'select distinct dau_co_id from dauco.nlcd_grid_info'`; do echo $d; psql -d quinn -c "\COPY (select * from dauco.nlcd_grid_info where dau_co_id='$d') to nlcd_grid_info/DAUCo${d}GA.csv with csv header"; done

-- Compare to vector data
create materialized view dau_co_vect as 
select 
 c.name as county,c.ansi as fips,
 dau_code,dau_name,
 sum(st_area(st_intersection(c.boundary,d.boundary))) as area 
from california_counties c 
join detailed_analysis_units d 
on st_intersects(c.boundary,d.boundary) 
group by 1,2,3,4;

create or replace view dwr_list as 
select 
'California'::text as "State",
dau_code as "DAU_Number",dau_name as "DAU_Name",
lpad(((fips::integer/2)+1)::text,2,'0') as "Co_Number",
county as "Co_Name",
dau_code||lpad(((fips::integer/2)+1)::text,2,'0') as dau_co_id,
dau_code||'_'||county as "DAU_County",
(area*0.000247105381)::integer as acres 
from dau_co_vect where (area*0.000247105381)::integer > 0
and dau_code is not null;

