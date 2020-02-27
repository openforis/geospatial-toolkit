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
#Reija Haapanen 21.4.2013
version=1.00
echo "This script creates a unique mask for oft-nn analysis"
echo "Unique means here, that same pixel is not classified from several images"
echo "It is needed in 2 cases: 1. take an adjacent image into account or"
echo "2. use the new image to fill a cloud etc. on nn-classified base image"
echo "--As input you need a mask of the main image and a preliminary mask of the new image"
echo "--A preliminary mask for the new image can be run with oft-trim-mask.bash"
echo "--If you need to add clouds or water, do that before or after this unique mask script"
echo "--The new image must be in the same projection and gridding (pixel loxations)"
echo "--In all masks, 0=do not use, 1=use"
echo "--To take several images into account, re-run"
echo "--Script produces also an accumulated mask, showing common ok areas"

# $1 = earlier mask
# $2 = mask of new image

echo "V. "$version

args=$#

#Checks
if [ $args -lt 2 ] ; then
    echo "Version $version"
    echo "Give the earier mask and the new mask to be fitted!"
    echo "Usage: oft-unique-mask-for-nn.bash <-m mask of base image> <-s mask of new image>"

exit
fi

while getopts m:s: option
do
        case "${option}"
        in
                m) fmask=${OPTARG}
                fmaskfound=TRUE;;
                s) smask=${OPTARG}
                smaskfound=TRUE;;

        esac
done

if [ $fmaskfound ] ; then 
if [ $smaskfound ] ; then
if [ -e $fmask ] ; then

echo "Using "$fmask" as base mask"

else

echo "Given base mask file not found"

exit

fi

if [ -e $smask ] ; then

echo "Using "$smask" as new mask file"

else

echo "Given new mask file not found"

exit

fi
fi
fi

#Extract file names and exensions for later use
fdummy=$fmask
fname=${fdummy%.*}
fextension=${fdummy#*.}

sdummy=$smask
sname=${sdummy%.*}
sextension=${sdummy#*.}

#Find xmin and ymin and pixel size of the image file

gdalinfo $smask > header2

xmin_image=`grep 'Upper Left' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax_image=`grep 'Upper Left' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax_image=`grep 'Lower Right' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin_image=`grep 'Lower Right' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
ps_image=`grep "Pixel Size" header2|awk '{gsub("[(,)]"," "); print $4}'`
echo "Topleft X coordinate of image: "$xmin_image
echo "Topleft Y coordinate of image: "$ymax_image
echo "Bottomright X coordinate of image: "$xmax_image
echo "Bottomrigh Y coordinate of image: "$ymin_image
echo "Pixel size of image:      "$ps_image

#Find xmin and ymin ans pixel size of the base file
gdalinfo $fmask > header1

xmin_base=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax_base=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax_base=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin_base=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
ps=`grep "Pixel Size" header1|awk '{gsub("[(,)]"," "); print $4}'`
echo "Topleft X coordinate of base image:       "$xmin_base
echo "Bottomrigh Y coordinate of base image:    "$ymin_base
echo "Bottomright X coordinate of image: "$xmax_base
echo "Bottomrigh Y coordinate of image: "$ymin_base
echo "Pixel size of base image:         "$ps

#merge the masks

gdal_merge.py -o masks_tmp -separate $fmask $smask

oft-calc masks_tmp unique_tmp<<EOF
1
#1 0 = #2 1 = * 0 1 ?
EOF

#Add accumulated mask for potential next additions

oft-calc masks_tmp accumulated_tmp<<EOF
1
#1 1 = #2 1 = * 0 1 ?
EOF

#Retrieve the original extent

gdalwarp -te $xmin_image $ymin_image $xmax_image $ymax_image -tr $ps_image $ps_image unique_tmp $sname"_unique_mask."$sextension
gdalwarp -te $xmin_image $ymin_image $xmax_image $ymax_image -tr $ps_image $ps_image accumulated_tmp $sname"_accumulated_mask."$sextension

rm header1 header2
rm unique_tmp accumulated_tmp masks_tmp
