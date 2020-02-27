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
#Reija Haapanen 8.5.2013
version=1.00

# $1 = image mask
# $2 = administrative borders image
# $3 = ID for admin area to be processed

   echo "The script:"
   echo "Prepares (clips, re-projects etc) a mask of administrative areas within a satellite image"
   echo "If an ID is given, the admin area with this ID is added to the base mask"
   echo "i.e. other areas are set to 0"
   echo "The input administrative image does not need to be of the same size and projection"

args=$#
#echo $args

#Checks
if [ $args -lt 2 ] ; then
    echo "Version $version"
    echo "Give a mask image and administrative area image"
    echo "Usage: oft-admin-mask.bash <mask for Landsat image> <administrative area image> [ID]"

exit
fi

#Extract name and extension
dummy=$1
imagename=${dummy%.*}
extension=${dummy#*.}

oft-clip.pl $1 $2 adm_tmp

#Case all admin areas to be printed out

if [ $args -eq 2 ] ; then

mv adm_tmp $imagename"_adm."$extension

else

#set 1 in areas within given admin area code

#Merge into same image with mask:

gdal_merge.py -ot Int16 -o adm_and_mask -separate $1 adm_tmp

oft-calc -ot Byte adm_and_mask $imagename"_adm."$extension<<EOF
1
#2 $3 = #1 1 = * 0 1 ?
EOF

rm adm_tmp adm_and_mask

fi

