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
CASE WHEN (ag is not null) THEN 1 ELSE 0 END as Ag, 
CASE WHEN (urban is not null) THEN 1 ELSE 0 END as Urban, 
CASE WHEN (nv is not null) THEN 1 ELSE 0 END as NV, 
CASE WHEN (water is not null) THEN 1 ELSE 0 END as Water, 
CASE WHEN (wetlands is not null) THEN 1 ELSE 0 END as Wetlands 
from nlcd_2006_dwr_ct 
join nlcd.grid_count 
using (dau,county,dwr_id);

create or replace view missing as 
select 
coalesce(o.grid_id,n.grid_id),
coalesce(o.dau_co_id,n.dau_co_id) as dau_co_id,
coalesce(o.dau_cogrdarea,n.dau_cogrdarea) as area,
o is not null as dwr,
n is not null as nlcd
from dwr_grid_info o 
full outer join nlcd_grid_info n on (o.dau_co_id::integer=n.dau_co_id::integer and o.grid_id=n.grid_id) 
where o is null or n is null 
order by coalesce(o.dau_cogrdarea,n.dau_cogrdarea) desc,dau_co_id,o.grid_id,n.grid_id; 

create view dwr_high_missing as 
select 'dwr' as source,dau_co_id,
grid_id,dau_cogrdarea,aggrdarea,urgrdarea,nvgrdarea,wsgrdarea,0 as wetgrdarea,
CASE WHEN (ag is not null) THEN 1 ELSE 0 END as Ag, 
CASE WHEN (urban is not null) THEN 1 ELSE 0 END as Urban, 
CASE WHEN (nv is not null) THEN 1 ELSE 0 END as NV, 
CASE WHEN (water is not null) THEN 1 ELSE 0 END as Water, 
0 as Wetlands 
from dwr_grid_info where grid_id in ('143_86','86_70','201_115') 
union
select 'nlcd',* from nlcd_grid_info where grid_id in ('143_86','86_70','201_115') 
order by grid_id,dau_co_id;

create view tots as 
select 'dwr' as source,
sum(dau_cogrdarea) as total,
sum(aggrdarea) as ag,
sum(urgrdarea) as urban,
sum(nvgrdarea) as nv,
sum(wsgrdarea) as ws 
from dwr_grid_info 
union select 'nlcd' as source,
sum(dau_cogrdarea) as total,
sum(aggrdarea) as ag,
sum(urgrdarea) as urban,
sum(nvgrdarea) as nv,
sum(wsgrdarea) as ws 
from nlcd_grid_info ; 

create view dau_co_id_tots as 
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
sum(wsgrdarea) as ws 
from nlcd_grid_info 
group by dau_co_id)
select coalesce(d.dau_co_id,n.dau_co_id) as dau_co_id,
d.total as dwr_total,
d.ag as dwr_ag,
d.urban as dwr_urban,
d.nv as dwr_nv,
d.ws as dwr_ws,
n.total as nlcd_total,
n.ag as nlcd_ag,
n.urban as nlcd_urban,
n.nv as nlcd_nv,
n.ws as nlcd_ws
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
-- 
