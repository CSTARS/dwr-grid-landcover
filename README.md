# DWR Landcover Summaries for Planning Grids

DWR requires estimates of land-cover types for their planning grids,
and detailed analysis units.  This project supplies land-cover
estimates for a number of different national land cover maps.  These
are simple CSV files containing the dwr_id for the grid, the Detailed
Analysis Unit deignation, the classes and the fractional amounts.

* land_cover contains the csv files for determining the fractional
  land-cover for each grid-point / DAU combination.

Data users probably just want to download the data.  Please go to the
[Release Page](https://github.com/CSTARS/dwr-grid-landcover/releases)
for the latest releases.

You can also browse the land_cover directory and download individual
files as well.

## National Land Cover Database (NLCD)

Currently, the [2006 NLCD](http://www.mrlc.gov/nlcd2006.php) is included in the land cover classifications.

## GIS data

The GIS data used to determine the DAUs and DWR grid points are both
found in github.

* [DWR Grid](https://github.com/CSTARS/dwr-grid) - used release
  [v1.0.0](https://github.com/CSTARS/dwr-grid/releases/tag/v1.0.0),
  and the ```calsimetaw``` data as the grid.

* [Detailed Analysis Units](https://github.com/ucd-cws/dwr-dau) used
  release
  [v1.0.2](https://github.com/ucd-cws/dwr-dau/releases/tag/v1.0.2)

