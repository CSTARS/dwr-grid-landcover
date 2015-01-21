# Land Cover estimates

This directory contains the landcover estimations for the DWR grid and
Detailed Analysis Units.

Each estimate is distributed in two methods. One csv file is a four
column file that contains the dwr_id, the DAU, the class, and the
fractional amount.

The other table (designated with _ct) is a crosstab, with each class
designated as it's own column.  The values are then the fraction for
each class.

For each, values of 0.00 indicate a trace presence.

## NLCD 2006

The [National Land Cover Database](http://www.mrlc.gov/nlcd2006.php),
contains both a major and a minor classification.

* ```nlcd_2006_major(_ct)``` Are the major categories

* ```nlcd_2006_class(_ct)``` Are the individual class categories
