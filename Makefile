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

dau.shp:=dwr-dau-1.0.2/shp
${dau.shp}:version:=v1.0.2
${dau.shp}:tgz:=v1.0.2.tar.gz
${dau.shp}:git:=https://github.com/ucd-cws/dwr-dau/archive
${dau.shp}:${tgz}
	[[ -f ${tgz} ]] || wget ${git}/${tgz};\
	tar -xzf ${tgz};

# California Data
${ca.vect}:=${GISDBASE}/california/dwr/vector


${ca.vect}/detailed_analyis_units:${dau.shp}/shp/detailed_analysis_units.shp
	v.in.ogr dsn=${dau.shp} output=detailed_analysis_units layer=detailed_analysis_units type=boundary

${ca.vect}/grid:${dau.shp
	v.in.ogr dsn=${dau.shp} output=detailed_analysis_units layer=detailed_analysis_units type=boundary


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
