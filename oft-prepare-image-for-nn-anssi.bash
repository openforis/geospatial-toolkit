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
#Reija Haapanen 3.4.2013
version=1.00
#Reija Haapanen 8.5.2013
#Added checks
#Also, after prev. version, several other additions
#like working with 6 bands as well as 7
version=1.01
version=1.02

tmpname="/tmp/"$$".shp"

# AP added replaced -l $shapebase by -l `basename $shapebase` to allow use of shapefile from a different folder
# AP added reprojection of shapefile
# RH added forcing of preserving original pixel size 24.5.2013
echo "     "
echo "=============================================================="
echo "                  oft-prepare-image-for-nn.bash               "
echo "=============================================================="
echo "Re-projects and shifts an image if needed"
echo "Prepares a 0/1 mask of nodata in image, all values <= 0 are considered nodata"

echo "V. "$version

args=$#

if [ $args -lt 1 ] ; then
    echo "Version $version"

    echo "Usage: oft-prepare-image-for-nn.bash <-i image> [-b baseimage] [-p projection] [-s shapefile] [-a attribute]"
    echo "Image = Landsat image with 6 or 7 bands to be prepared for oft-nn"
    echo "Baseimage = Image already in correct grid, meaning pixel size and pixel locations"
    echo "Target projection in EPSG, e.g. EPSG:32736"
    echo "Shapefile = additional mask areas to be added to the base mask, e.g. clouds"
    echo "If target projection is given, also shapefile is re-projected before rasterizing"
    echo "Attribute = name of attribute field to be used in shapefile"
    echo "Field must contain 0 in regions to be masked off"
exit

fi

#Assign the parameters to corresponding ones in the scrips

while getopts i:b:p:s:a: option
do
        case "${option}"
        in
                i) image=${OPTARG}
		imagefound=TRUE;;
                b) base=${OPTARG}
		usebase=TRUE;;
                p) proj=${OPTARG}
		useproj=TRUE;;
                s) shape=${OPTARG}
		useshape=TRUE;;
                a) attr=${OPTARG};;

        esac
done

if [ $imagefound ] ; then

if [ -e $image ] ; then

echo "Using "$image" as image file"

else

echo "Given image file not found, exiting now"

exit

fi

else

echo "You must give the image file with option -i, exiting now"

exit

fi

if [ $usebase ] ; then

if [ -e $base ] ; then

echo "Using "$base" as base file"

else

echo "Given base file not found, exiting now"

exit

fi
fi


#Check nbr of bands 

bands=`gdalinfo $image|grep Band|wc -l`

#Check pixel size

origps=`gdalinfo $image|grep "Pixel Size"|awk '{gsub("[(,)]"," "); print $4}'`

echo $origps

#Clean possible paths from image base name

imagep=`basename $image`
echo $imagep

#Extract name and extension
dummy1=$imagep
imagec=${dummy1%.*}
extension=${dummy1#*.}

if [ $useproj ] ; then

echo "Re-projecting image"

gdalwarp -tr $origps $origps -t_srs $proj $image $imagec"_proj."$extension

# AP add hoc add-on
# re-project and rename shape
# change also the $shape value

if [ -e $shape ] ; then


    echo "Re-projecting shape"

    ogr2ogr  -t_srs $proj $tmpname $shape
    shape=$tmpname

fi

# AP add hoc add-on ends

if [ $usebase ] ; then

echo "Shifting (if needed)"

oft-shift-images.bash $base $imagec"_proj."$extension

if [ -e $imagec"_proj_shift."$extension ] ; then

#Make a mask, this works for all nodata values <= 0

if [ $bands -eq 6 ] ; then

echo "Computing a mask of the re-projected and shifted image"

oft-calc $imagec"_proj_shift."$extension tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * 0 1 ?
EOF

fi

if [ $bands -eq 7 ] ; then

echo "Computing a mask of the re-projected and shifted image"

oft-calc $imagec"_proj_shift."$extension tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * #7 0 > * 0 1 ?
EOF

fi

else 

#Shift was not needed

if [ $bands -eq 6 ] ; then

echo "Computing a mask of the re-projected image"

oft-calc $imagec"_proj."$extension tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * 0 1 ?
EOF

fi

if [ $bands -eq 7 ] ; then

echo "Computing a mask of the re-projected image"

oft-calc $imagec"_proj."$extension tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * #7 0 > * 0 1 ?
EOF

fi

#Ends check for shift output:
fi
#Ends check for use of base image:
fi

else

#Not re-projected

if [ $usebase ] ; then

echo "Shifting (if needed)"

oft-shift-images.bash $base $image

if [ -e $imagec"_shift."$extension ] ; then

if [ $bands -eq 6 ] ; then

echo "Computing a mask of the shifted image"

oft-calc $imagec"_shift."$extension tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * 0 1 ?
EOF

fi

if [ $bands -eq 7 ] ; then

echo "Computing a mask of the shifted image"

oft-calc $imagec"_shift."$extension tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * #7 0 > * 0 1 ?
EOF

fi

else

#Shifting was not needed

if [ $bands -eq 6 ] ; then

echo "Computing a mask of the original image"

oft-calc $image tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * 0 1 ?
EOF

fi

if [ $bands -eq 7 ] ; then

echo "Computing a mask of the original image"

oft-calc $image tmpmask0<<EOF
1
#1 0 > #2 0 > * #3 0 > * #4 0 > * #5 0 > * #6 0 > * #7 0 > * 0 1 ?
EOF

fi

#Ends check for existence of shift output:
fi
#Ends check for using of base image:
fi
#Ends check for use of projection:
fi


#Trim the borders

gdal_translate -outsize 10% 10% tmpmask0 tmpmask1

oft-trim -ot Byte -ws 3 tmpmask1 tmpmask2
oft-trim -ot Byte -ws 3 tmpmask2 tmpmask3
oft-shrink -ot Byte -ws 21 tmpmask3 tmpmask4


xmin=`gdalinfo tmpmask0 |grep "Upper Left"|awk '{gsub("[,()]"," ");print $3}'`
ymax=`gdalinfo tmpmask0 |grep "Upper Left"|awk '{gsub("[,()]"," ");print $4}'`

xmax=`gdalinfo tmpmask0 |grep "Lower Right"|awk '{gsub("[,()]"," "); print $3}'` 
ymin=`gdalinfo tmpmask0 |grep "Lower Right"|awk '{gsub("[,()]"," "); print $4}'` 

xsize=`gdalinfo tmpmask0 |grep "Size is"|awk '{gsub(","," ")  ; print $3}'`
ysize=`gdalinfo tmpmask0 |grep "Size is"|awk '{gsub(","," ")  ; print $4}'`

echo outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin

gdal_translate -outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin tmpmask4 tmpmask5

#Merge the original zeros from gaps in case L7 (in case L5 this does not do any harm)

gdal_merge.py -o tmpmask6 -separate tmpmask0 tmpmask5

oft-calc -ot Byte tmpmask6 $imagec"_mask."$extension<<EOF
1
#1 #2 * 1 = 0 1 ?
EOF

rm tmpmask0 tmpmask1 tmpmask2 tmpmask3 tmpmask4 tmpmask5 tmpmask6

if [ $useshape ] ; then

if [ -e $shape ] ; then

dummy2=$shape
shapebase=${dummy2%.*}

gdal_rasterize -a $attr -l `basename $shapebase` $shape $imagec"_mask."$extension
rm $shape

else

echo "Given shapefile not found, exiting now!"

fi
fi
