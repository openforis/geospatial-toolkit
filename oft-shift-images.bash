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
#Reija Haapanen 19.3.2013
version=1.00
#RH 29.3.2013: improved the naming of the output

# $1 = reference image
# $2 = image to be shifted

   echo "The script:"
   echo "-shifts an image into the same gridding than a reference image"
   echo "-the reference image does not need to be of the same size"
   echo "-however, the projections need to be the same"
   echo "-the pixel size is also taken from the reference image"

args=$#
#echo $args

#Checks
if [ $args != 2 ] ; then
    echo "Version $version"
    echo "Give the reference image name and image to be shifted!"
    echo "Usage: oft-shift-images.bash <reference_image> <image_to_be_shifted>"

exit
fi

#Check if the image files exist
if [ -e $1 -a -e $2 ] ; then 

# Yes, then prepare for shifting

dummy=$2
imgname=${dummy%.*}
extension=${dummy#*.}

#Find xmin and ymin and pixel size of the image file

gdalinfo $2 > header2

xmin_image=`grep 'Upper Left' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax_image=`grep 'Upper Left' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax_image=`grep 'Lower Right' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin_image=`grep 'Lower Right' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
ps_image=`grep "Pixel Size" header2|awk '{gsub("[(,)]"," "); print $4}'`
echo "Topleft X coordinate of image: "$xmin_image
echo "Topleft Y coordinate of image: "$ymax_image
echo "Bottomright X coordinate of image: "$xmax_image
echo "Bottomrigh Y coordinate of image: "$ymin_image
echo "Pixel size of image: 	"$ps_image

#Find xmin and ymin ans pixel size of the base file

gdalinfo $1 > header1

xmin_base=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin_base=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
ps=`grep "Pixel Size" header1|awk '{gsub("[(,)]"," "); print $4}'`
echo "Topleft X coordinate of base image: 	"$xmin_base
echo "Bottomrigh Y coordinate of base image: 	"$ymin_base
echo "Pixel size of base image: 	"$ps

else

echo "One or both of the input files is missing!"

exit

fi
 
#Compute the shifted location based on these coordinate sets

#First see what is the difference in locations expressed in base image pixels
diffx=`awk -v basex=$xmin_base -v imagex=$xmin_image -v ps=$ps 'BEGIN {printf ("%4.20f\n", (imagex - basex)/ps)}'`
diffy=`awk -v basey=$ymin_base -v imagey=$ymin_image -v ps=$ps 'BEGIN {printf ("%4.20f\n", (imagey - basey)/ps)}'`

echo x difference in base image pixels is $diffx
echo y difference in base image pixels is $diffy

#Now see how many parts-of-pixel you are shifted

#First, strip off the decimals (no rounding, just cutting them off)

roundx=`echo $diffx | awk -v diffx=$diffx '{printf (int(diffx))}'`
roundy=`echo $diffy | awk -v diffy=$diffy '{printf (int(diffy))}'`

echo $roundx
echo $roundy

partsx=`awk -v rdx=$roundx -v dfx=$diffx 'BEGIN {print (dfx - rdx)}'`
partsy=`awk -v rdy=$roundy -v dfy=$diffy 'BEGIN {print (dfy - rdy)}'`

echo "The image pixel's x-location is shifted $partsx pixels from the base grid"
echo "The image pixel's y-location is shifted $partsy pixels from the base grid"

#Shift not needed:

if (( $(bc <<< "$partsx==0") > 0 )); then 

if (( $(bc <<< "$partsx==0") > 0 )) ; then

echo "No shifting needed"

#But is the pixel size ok?
pixdiff=`awk -v psi=$ps_image -v ps=$ps 'BEGIN {printf ("%4.20f\n", (psi - ps))}'`

echo "Pixels differ "$pixdiff

if (( $(bc <<< "$pixdiff==0") > 0 )); then
echo "Pixel size also equal, exiting now"

rm header1 header2

exit

else

echo "Adjusting only the pixel size"

gdalwarp -tr $ps $ps $2 $imgname"_shift."$extension

rm header1 header2

exit
fi
fi
fi

#if shift is needed and if image x is inside the base

if (( $(bc <<< "$partsx>0") > 0 )); then 

if (( $(bc <<< "$partsx>0.5") > 0 )); then 

echo move eastward

new_xmin=`awk -v xmin=$xmin_base -v rdx=$roundx -v ps=$ps 'BEGIN {print xmin+(ps*rdx)+ps}'`

else

echo move westward

new_xmin=`awk -v xmin=$xmin_base -v rdx=$roundx -v ps=$ps 'BEGIN {print xmin+(ps*rdx)}'`

fi

fi

if (( $(bc <<< "$partsx<0") > 0 )); then 

#Image begins west of the base mask, difference is negative

if (( $(bc <<< "$partsx<-0.5") > 0 )); then 

echo move westward

new_xmin=`awk -v xmin=$xmin_base -v rdx=$roundx -v ps=$ps 'BEGIN {print xmin+(ps*rdx)}'`

else

echo move eastward

new_xmin=`awk -v xmin=$xmin_base -v rdx=$roundx -v ps=$ps 'BEGIN {print xmin+(ps*rdx)+ps}'`

fi

fi

#Same for y-coordinates

#if shift is needed and if image y is inside the base

if (( $(bc <<< "$partsy>0") > 0 )); then 

if (( $(bc <<< "$partsy>0.5") > 0 )); then

echo move to north

new_ymin=`awk -v ymin=$ymin_base -v rdy=$roundy -v ps=$ps 'BEGIN {print ymin+(ps*rdy)+ps}'`

else

echo move south
new_ymin=`awk -v ymin=$ymin_base -v rdy=$roundy -v ps=$ps 'BEGIN {print ymin+(ps*rdy)}'`


fi

fi

if (( $(bc <<< "$partsy<0") > 0 )); then 

#Image begins north of the base mask, difference is negative

if (( $(bc <<< "$partsy<-0.5") > 0 )); then 

echo move south

new_ymin=`awk -v ymin=$ymin_base -v rdy=$roundy -v ps=$ps 'BEGIN {print ymin+(ps*rdy)}'`

else

echo move north
new_ymin=`awk -v ymin=$ymin_base -v rdy=$roundy -v ps=$ps 'BEGIN {print ymin+(ps*rdy)+ps}'`

fi

fi

#Then, compute the maximums
xsize=`awk -v xmax=$xmax_image -v xmin=$xmin_image -v ps=$ps 'BEGIN {printf ("%f\n", (xmax - xmin)/ps)}'`
ysize=`awk -v ymax=$ymax_image -v ymin=$ymin_image -v ps=$ps 'BEGIN {printf ("%f\n", (ymax - ymin)/ps)}'`

echo x size in pixels is $xsize
echo y size in pixels is $ysize

new_xmax=`awk -v xmin=$new_xmin -v xsize=$xsize -v ps=$ps 'BEGIN {print xmin+ps*int(xsize)+ps}'`
new_ymax=`awk -v ymin=$new_ymin -v ysize=$ysize -v ps=$ps 'BEGIN {print ymin+ps*int(ysize)+ps}'`

echo new extents are $new_xmin $new_ymin $new_xmax $new_ymax

#Find out the base name and extension for re-naming of the image:

gdalwarp -te $new_xmin $new_ymin $new_xmax $new_ymax -tr $ps $ps $2 $imgname"_shift."$extension

rm header1 header2



