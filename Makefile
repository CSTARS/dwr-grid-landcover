#! /usr/bin/make -f

# Are we currently Running Grass?
ifndef GISRC
  $(error Must be running in GRASS)
endif

GISDBASE:=$(shell g.gisenv get=GISDBASE)
LOCATION_NAME:=$(shell g.gisenv get=LOCATION_NAME)
MAPSET:=$(shell g.gisenv get=MAPSET)

# Shortcut Directories
loc:=$(GISDBASE)/$(LOCATION_NAME)
rast:=$(loc)/$(MAPSET)/cellhd

2013_cdl.csv: 2013_30_m_cdls.img
	gdalinfo $< | grep '<' | xmlstarlet sel -t -m "/GDALRasterAttributeTable/Row" -v "concat(@index,',',F[5])" -n >@

dau.shp:=dwr-dau-2.0.0/shp
${dau.shp}:version:=v2.0.0
${dau.shp}:tgz:=v2.0.0.tar.gz
${dau.shp}:git:=https://github.com/ucd-cws/dwr-dau/archive
${dau.shp}:${tgz}
	[[ -f ${tgz} ]] || wget ${git}/${tgz};\
	tar -xzf ${tgz};

# California Data
${ca.vect}:=${GISDBASE}/california/dwr/vector

${ca.vect}/detailed_analyis_units:${dau.shp}/shp/detailed_analysis_units.shp
	v.in.ogr dsn=${dau.shp} output=detailed_analysis_units layer=detailed_analysis_units type=boundary
# g.mapset quinn; v.in.ogr dsn=. output=detailed_analysis_units layer=detailed_analysis_units type=boundary 

${ca.vect}/dwr-grid:${dwr-grid}/shp/dwr_grid.shp
	v.in.ogr dsn=${dau.shp} output=detailed_analysis_units layer=detailed_analysis_units type=boundary

${ca.vect}/california-counties:
	v.in.ogr dsn=${dau.shp} output=detailed_analysis_units layer=detailed_analysis_units type=boundary
# cd california-counties-1.0.0
# g.mapset quinn; v.in.ogr dsn=. output=counties layer=california_counties type=boundary

# Conterminous Data

2013.cdl.url:=ftp://ftp.nass.usda.gov/download/res/2013_30m_cdls.zip
2013.cult.url:=ftp://ftp.nass.usda.gov/download/res/2013_Cultivated_Layer.zip

mirror::
	wget --mirror ${2013.cdl.url} ${2013.cult.url}

${us.rast}:=${GISDBASE}/conterminous_us/dwr/cellhd

${us.rast}/2013_30m_cdls: 2013_30m_cdls.img
	r.in.gdal input=2013_30m_cdls.img output=2013_30m_cdls -e

${us.vect}/dau:${ca.vect}/dau
	v.proj input=dau 

#${rast}/nlcd@nlcd:

layers:=counties detailed_analysis_units pixels

label.counties:=ansi
label.detailed_analysis_units:=dau_code
label.pixels:=DWR_ID

vects:=$(patsubst, %,${vect}/%,${layers})

${vects}:{$vect}/%:
	v.proj location=calsimetaw input=$*;

${rasts}:${rast}/%:${vect}/%
	g.region vect=$*;\
	eval `g.region -g`;\
	g.region `perl -e "printf \"w=%d s=%d e=%d n=%d res=30\\n\",(int(($$w+15)/30)-1)*30-15,(int(($$s+15)/30)-1)*30-15,(int(($$e-15)/30)-1)*30+15,(int(($$n-15)/30)+1)*30+15"`;\
	v.to.rast input=$* output=$* use=cat labelcolum=${label.$*} type=area

${rast}/dau_mask:
	g.region rast=pixels;\
	r.mapcalc dau_mask='pixels|||dau|||counties'

xwalk.hist: ${rast}/dau_mask
	r.mask -o input=dau_mask
	r.stats -l -c fs=, input=counties,detailed_analysis_units,pixels,nlcd@nlcd output=@<
