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
# $1 = input image
# $2 = output image
# $3 = R band
# $4 = NIR band
# $5 = mask

version=1.00
# by Reija Haapanen, based on script trim_mask.bash by Anssi Pekkarinen
# Creates a NDVI image (NIR-R) / (NIR + R), where output values have been multiplied by 100
# Input data are image stacs, where bands 3 and 4 are supposed to be at these locations (third and fourth)
# Input may be Landsat or Modis 
version=1.01
# Added user-defined R and NIR bands so that also large image stacks can be used
version=1.02
# Simplified the computation, added a check for the band parameters and
# change output data type to 8bits
version=1.03
# fixed previous fix... change output data type to 16bits 
version=1.04
# fixed usage
version=1.05
# AP changed to produce unscaled ndvi and float32 output
version=1.06
# RH corrected the mask in oft-calc to refer to $5 instead of $3

args=$#

if [ $args != 4 -a $args != 5 ] ; then
    echo "Version $version"
    echo "Creates a NDVI image (NIR-R) / (NIR+R)"
    echo "Usage oft-ndvi.bash <input> <output> <R_band> <NIR_band> [mask]"
    exit
elif [ ! -f $1 ] ; then 
    echo "Input image does not exist"
    exit
else
    echo "Creates a NDVI image (NIR-R) / (NIR + R)"
    
    bands=`gdalinfo $1|grep Band|wc -l`

    if [ $args -eq 4 ] ; then
    
	if [ $3 -gt $bands -o $4 -gt $bands ] ; then
	    echo $3,$4,$bands
	    echo "Error in input band parameter";
	    exit;
	else

oft-calc -ot Float32 $1 $2<<EOF
1
#$4 #$3 - #$4 #$3 + /
EOF

	fi

    elif [ $args -eq 5 ] ; then

oft-calc -ot Float32 -um $5 $1 $2<<EOF
1
#$4 #$3 - #$4 #$3 + /
EOF
    fi
fi

echo  "Computed NDVI image"





