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
#Reija Haapanen 16.4.2013

version=1.00 

echo "     "
echo "=============================================================="
echo "                  oft-combine-images.bash                     "
echo "=============================================================="
echo "Combines 2 images into one image"
echo "Can be used to merge same-day Landsat images (adjacent)"
echo "or two gapfill results (stack)"
echo "Takes as input the images and their masks"
echo "Masks for same-day can be prepared with oft-trim-mask.bash"
echo "and for gapfill with oft-prepare-images-for-gapfill.bash.bash"
echo "All ok areas are taken from image 1, and image 2 is used elsewhere"
echo "Also produces a mask that indicates ok areas of the resulting combined image with 1"
echo "All material needs to be in same projection"
echo "Works with 6 or 7 band images"

echo "V. "$version

args=$#

if [ $args -lt 4 ] ; then
    echo "Version $version"

    echo "Usage: oft-combine-images.bash <-a first image> <-b second image> <-m first image mask> <-s second mask)>"
    echo "First image = Better image, whose area is used whenever possible"
    echo "Second image = Image to be used elsewhere"
    echo "First image mask = 0/1 mask indicating bad areas on first image with 0"
    echo "Second mask = 0/1 mask indicating bad areas on second image with 0"
exit

fi

#Assign the parameters to corresponding ones in the scrips

while getopts a:b:m:s: option
do
        case "${option}"
        in
                a) fimage=${OPTARG}
		firstfound=TRUE;;
                b) simage=${OPTARG}
		secondfound=TRUE;;
                m) fmask=${OPTARG}
		fmaskfound=TRUE;;
                s) smask=${OPTARG}
		smaskfound=TRUE;;

        esac
done

if [ $firstfound ] ; then
if [ $secondfound ] ; then 
if [ $fmaskfound ] ; then
if [ $smaskfound ] ; then

if [ -e $fimage ] ; then

echo "Using "$fimage" as first image file"

else

echo "Given first image file not found"

exit

fi

if [ -e $simage ] ; then

echo "Using "$simage" as second image file"

else

echo "Given second image file not found"

exit

fi

if [ -e $fmask ] ; then

echo "Using "$fmask" as mask for first file" 

else

echo "Given first mask file not found"

exit

fi

if [ -e $smask ] ; then

echo "Using "$smask" as mask for second file" 

else

echo "Given second mask file not found"

exit

fi

else

echo "Second mask file must be given with option -s, exiting now!"

exit 

fi

else

echo "First mask file must be given with option -m, exiting now!"

exit

fi

else

echo "Second image must be given with option -b, exiting now!"

exit

fi

else

echo "First image must be given with option -a, exiting now!"

exit

fi



#Extract file names and exensions for later use
fdummy=$fimage
fname=${fdummy%.*}
fextension=${fdummy#*.}

sdummy=$simage
sname=${sdummy%.*}
sextension=${sdummy#*.}

#Check that band nbr equals

fbands=`gdalinfo $fimage|grep Band|wc -l`
sbands=`gdalinfo $simage|grep Band|wc -l`

if [ $fbands != $sbands ] ; then

echo "Number of bands differs on the images: first = "$fbands", second = "$sbands", exiting now"

exit

fi

if [ $fbands != 6 -a $fbands != 7 ] ; then

echo "Currently only works with 6 or 7 band images, exiting now"

exit

fi

#Combine images and masks, assume that version of gdal_merge.py can swallow multiband images

gdal_merge.py -o tmpstack -separate $fimage $simage $fmask $smask

#Compute combined image

if [ $fbands -eq 7 ] ; then

oft-calc tmpstack "stack_"$fname"_"$sname"."$fextension<<EOF
7
#16 1 = #15 0 = * #1 #8 ?
#16 1 = #15 0 = * #2 #9 ?
#16 1 = #15 0 = * #3 #10 ?
#16 1 = #15 0 = * #4 #11 ?
#16 1 = #15 0 = * #5 #12 ?
#16 1 = #15 0 = * #6 #13 ?
#16 1 = #15 0 = * #7 #14 ?
EOF

#Produce a mask that indicated ok areas of the resulting image with 1

oft-calc tmpstack "mask_"$fname"_"$sname"."$fextension<<EOF
1
#16 0 = #15 0 = * 1 0 ?
EOF

fi


if [ $fbands -eq 6 ] ; then

oft-calc tmpstack "stack_"$fname"_"$sname"."$fextension<<EOF
6
#14 1 = #13 0 = * #1 #7 ?
#14 1 = #13 0 = * #2 #8 ?
#14 1 = #13 0 = * #3 #9 ?
#14 1 = #13 0 = * #4 #10 ?
#14 1 = #13 0 = * #5 #11 ?
#14 1 = #13 0 = * #6 #12 ?
EOF

#Produce a mask that indicated ok areas of the resulting image with 1

oft-calc tmpstack "mask_"$fname"_"$sname"."$fextension<<EOF
1
#13 0 = #14 0 = * 1 0 ?
EOF

fi

rm tmpstack
