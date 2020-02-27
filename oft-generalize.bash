#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Reija Haapanen
#
#This file is part of Open Foris Geospatial Toolkit which is free software.
#You can redistribute it and/or modify it under the terms of the 
#GNU General Public License as published by the Free Software Foundation, 
#either version 3 of the License, or (at your option) any later version.
#

#Open Foris Geospatial Toolkit is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with the Open Foris Geospatial Toolkit  
#If not, see <http://www.gnu.org/licenses/>.



#!/bin/bash
# Performs editing tasks for classified image resulting from e.g. Random Forest
# Reija Haapanen on March 29, 2012 based on ideas drafted by Anssi Pekkarinen
version=1.00
# Added covertype attributes to the final shapefile
# RH on April 10, 2012
version=1.01
# Corrected min. spectral distance in the 1st segmentation run
# RH on April 25, 2012
version=1.02
#Changed from oft-seg-fast into oft-seg
#RH on January 22, 2013
echo "V. "$version

#$1 Ledapsed input image
#$2 Classification output
#$3 nodatavalue

args=$#

#Checks
if [ $args != 3 ] ; then
    echo "Give the original ledapsed image and the classification output, as well as nodata"
    echo "Usage: oft-generalize.bash <landsat.tif> <classified.tif> <nodata>"
exit
fi

if [ ! -f $1 ] ; then
    echo "Landsat image not found in present directory"
exit
fi

if [ ! -f $2 ] ; then
    echo "Classification output not found in present directory"
exit
fi

# 1. Run oft-seg using -4n and -automax parameters with a minimum size of, say, 500 pixels

oft-seg -automax -4n $1 prelmask<<EOF
$3
500
0
0
EOF

# 2. Use the previous output as mask and run oft-seg-fast with -4n and minimum size of 12 pixels (or maybe 60 ~ 5 ha)

oft-seg -4n -um prelmask $1 segout<<EOF
$3
12
0
0
0
EOF

# 3. Compute segment level RF majority value for each segment

gdalinfo -stats $2 > imginfo
max=`grep 'Max=' imginfo|awk -F"=" '{print $3}'`

echo "Largest class id is " $max

oft-his segout $2 out.his<<EOF
$max
EOF

awk '{max=0; for(i=4 ; i<=NF ; i++) if($i>max) {max=$i; n=i} print $1,n-3}' $"out.his"  > reclass.txt

oft-reclass -oi filtered segout<<EOF
reclass.txt
1
1
2
0
EOF

# 4. Clump the result

oft-clump filtered clump

# 5. Polygonize

imgname=`basename $2 .tif`

oft-polygonize.bash clump polys$imgname.shp

# 6. Add attributes from the raster to the shapefile
#oft-addattr.py <shapefile> <JoinAttrName> <NewAttrName> <textfile>

oft-addattr.py polys$imgname.shp DN Covertype reclass.txt

rm prelmask segout imginfo out.his reclass.txt filtered clump

