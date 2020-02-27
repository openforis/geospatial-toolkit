#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
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
# $3 = mask

version=1.00
# by Modified from oft-ndvi.bash (Reija Haapanen, Anssi Pekkarinen)
# Computes normalised burn ratio index (NBR) using LS bands 4 and 7 in the following manner: 
# (LS4-LS7) / (LS4 + LS7).
# outputs a 32 bit float image
# Input data are bands in a stack 
# if input has only 6 channels, band 6 is assumed to be LS band 7.
version=1.01
# fixed usage

args=$#

if [ $args != 2 -a $args != 3 ] ; then
    echo "Version $version"
    echo "Computes Normalised Burn Ratio"
    echo "Usage oft-nbr.bash <input> <output> [mask]"
    exit
elif [$args -eq 3 ] ; then 

    if [ ! -f $3  ] ; then 
    echo "Mask file missing"
    exit
else
    UseMask="-um $3" 
    
    fi
fi

bands=`gdalinfo $1|grep Band|wc -l`

if [ $bands -eq 6 ] ; then
    
oft-calc $UseMask -ot Float32 $1 $2<<EOF
1
#4 #6 - #4 #6 + /
EOF

elif [ $bands -eq 7 ] ; then

oft-calc $UseMask -ot Float32 $1 $2<<EOF
1
#4 #7 - #4 #7 + /
EOF

else

echo "Invalid number of input bands"
exit

fi

echo  "Computed NBR image"





