#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Reija Haapanen
#Anssi Pekkarinen
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
#Reija Haapanen 6.3.2013 based on trim_ledaps.bash by Anssi Pekkarinen
# $1 = input image 
# $2 = image nodata value
version=1.0
# RH 25.3.2013 corrected the basename extraction to a more clever one
version=1.1
# RH 8.5.2013 added possibility to use 6-band image
# RH Removed nodata option, so that the typical values 0 or lower (e.g. -9999) can all be removed at the same time
echo "This script makes a 0/1 mask of a 6 or 7 band (Landsat) image"
echo "It detects the margins and Landsat 7 missing scanlines, and trims the edges"
echo "All values <= 0 are considered nodata"

args=$#

if [ $args != 1 ] ; then
    echo "Version $version"
    echo "Usage oft-trim-mask.bash <image>"
    exit
elif [ ! -f $1 ] ; then 
    echo "Input image not found!"
   exit
fi

dummy=$1
imgname=${dummy%.*}
extension=${dummy#*.}
if [ -f $imgname"_mask."$extension ] ; then

echo "You already have a mask? Check, exiting now"

exit

fi

bands=`gdalinfo $1|grep Band|wc -l`

if [ $bands != 6 -a $bands != 7 ] ; then

echo "Currently only works with 6 or 7 band images, exiting now"

exit

fi

if [ $bands -eq 7 ] ; then

oft-calc -ot Byte $1 tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * #7 0 > * 0 1 ?
EOF

fi

if [ $bands -eq 6 ] ; then

oft-calc -ot Byte $1 tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * 0 1 ?
EOF

fi

gdal_translate -outsize 10% 10% tmpmask0 tmpmask1

oft-trim -ot Byte -ws 3 tmpmask1 tmpmask2
oft-trim -ot Byte -ws 3 tmpmask2 tmpmask3
oft-shrink -ot Byte -ws 21 tmpmask3 tmpmask4

xmin=`gdalinfo $1 |grep "Upper Left"|awk '{gsub("[,()]"," ");print $3}'`
ymax=`gdalinfo $1 |grep "Upper Left"|awk '{gsub("[,()]"," ");print $4}'`

xmax=`gdalinfo $1 |grep "Lower Right"|awk '{gsub("[,()]"," "); print $3}'` 
ymin=`gdalinfo $1 |grep "Lower Right"|awk '{gsub("[,()]"," "); print $4}'` 

xsize=`gdalinfo $1 |grep "Size is"|awk '{gsub(","," ")  ; print $3}'`
ysize=`gdalinfo $1 |grep "Size is"|awk '{gsub(","," ")  ; print $4}'`

echo outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin

gdal_translate -outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin tmpmask4 tmpmask5

#Merge the original zeros from gaps in case L7 (in case L5 this does not do any harm)

gdal_merge.py -o tmpmask6 -separate tmpmask0 tmpmask5

oft-calc -ot Byte tmpmask6 $imgname"_mask."$extension<<EOF
1
#1 #2 * 1 = 0 1 ?
EOF

rm tmpmask0 tmpmask1 tmpmask2 tmpmask3 tmpmask4 tmpmask5 tmpmask6



