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

update dwr_grid_info set dau_co_id=trim(both from dau_co_id);
update dwr_grid_info set grid_id=trim(both from grid_id);

-- import data
\set foo `cd /home/quinn/dwr-grid-landcover/dwr_grid_info; for i in DAUCo*.csv; do echo $i; grep -v '#' $i | psql -d quinn -c 'copy dauco.dwr_grid_info from stdin with csv header'; done`

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
'select county||'':''||'':''||dau||'':''||dwr_id,dwr_id,dau,county,dwr,count from nlcd_2006_dwr 
where dwr_id != ''no data'' and dau != ''no data'' and county != ''no data'' order by 1',
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
dau||lpad((county::integer/2)+1,2,'0') as Dau_Co_ID,
dwr_id as Grid_id,
sum*30*30 as DAU_CoGrdArea,
ag*30*30 as AgGrdArea,
urban*30*30 as UrGrdArea,
nv*30*30 as NVGridArea,
water*30*30 as WSGridArea,
wetlands*30*30 as WetGridArea,
ag is not null as Ag, 
urban is not null as Urban, 
nv is not null as NV, 
water is not null as Water, 
wetlands is not null as Wetlands 
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
select 'dwr' as source,*,0 as wetlands from dwr_grid_info where grid_id in ('143_86','86_70','201_115') 
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
