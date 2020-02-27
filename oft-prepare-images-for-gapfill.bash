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
#Reija Haapanen 8.4.2013
version=1.00 
#Improvements 28.4.2013 by RH:
#Strip off path names so that processing from other directories is possible
version=1.01

echo "     "
echo "=============================================================="
echo "              oft-prepare-images-for-gapfill.bash             "
echo "=============================================================="
echo "Prepares images and masks for oft-gapfill"
echo "Takes the anchor and filler images as input"
echo "Also their 0/1 masks indicating clouds and gaps are needed"
echo "NDVI can be used to threshold areas with low vegetation off from the models"
echo "At this point, bands 3 and 4 are used for NDVI computation"
echo "Otherwise, nbr of bands is not fixed, but must be equal in the input images"
echo "All material needs to be in same projection"

echo "V. "$version

args=$#

if [ $args -lt 4 ] ; then
    echo "Version $version"

    echo "Usage: oft-prepare-images-for-gapfill.bash <-a anchor> <-f filler> <-m anchor mask> <-s second mask (filler)> [-n ndvi threshold]"
    echo "Anchor = Better image, whose gaps are to be filled"
    echo "Filler = Filler images"
    echo "Anchor mask = 0/1 mask indicating bad areas on anchor image with 0"
    echo "Second mask = 0/1 mask indicating bad areas on filler image with 0"
    echo "Ndvi threshold = If images differ a lot, ndvi can be used to select only vegetated areas for mask"
    echo "Values like 0.4 or 0.5 are useful at some location on the world, check your situation self!"
exit

fi

#Assign the parameters to corresponding ones in the scrips

while getopts a:f:m:s:n: option
do
        case "${option}"
        in
                a) anchor=${OPTARG}
		anchorfound=TRUE;;
                f) filler=${OPTARG}
		fillerfound=TRUE;;
                m) amask=${OPTARG}
		amaskfound=TRUE;;
                s) fmask=${OPTARG}
		fmaskfound=TRUE;;
                n) ndvithr=${OPTARG}
                usendvi=TRUE;;

        esac
done

if [ $anchorfound ] ; then 
if [ $fillerfound ] ; then 
if [ $amaskfound ] ; then
if [ $fmaskfound ] ; then

if [ -e $anchor ] ; then

#Clean possible paths from image base name

aimageb=`basename $anchor`

echo "Using "$aimageb" as anchor"

else

echo "Given anchor file not found"

exit

fi

if [ -e $filler ] ; then

fimageb=`basename $filler`

echo "Using "$fimageb" as filler" 

else

echo "Given filler file not found"

exit

fi

if [ -e $amask ] ; then

amaskb=`basename $amask`

echo "Using "$amaskb" as anchor mask" 

else

echo "Given anchor mask file not found"

exit

fi

if [ -e $fmask ] ; then

fmaskb=`basename $fmask`

echo "Using "$fmaskb" as filler mask" 

else

echo "Given filler mask file not found"

exit

fi

else

echo "Filler mask must be indicated with option -s, exiting now!"

exit 

fi

else

echo "Anchor mask must be indicated with option -m, exiting now!"

exit 

fi

else

echo "Filler image must be indicated with option -f, exiting now!"

exit 

fi

else

echo "Anchor image must be indicated with option -a, exiting now!"

exit

fi

#Extract file names and exensions for later use
adummy=$aimageb
aname=${adummy%.*}
aextension=${adummy#*.}

fdummy=$fimageb
fname=${fdummy%.*}
fextension=${fdummy#*.}

#Check that band nbr equals

abands=`gdalinfo $anchor|grep Band|wc -l`
fbands=`gdalinfo $filler|grep Band|wc -l`

if [ $abands != $fbands ] ; then

echo "Number of bands differs on the images: anchor = "$abands", filler = "$fbands", exiting"

exit

fi

#Combine images, assume that version of gdal_merge.py can swallow multiband images

gdal_merge.py -o "stack_"$aname"_"$fname"."$aextension -separate $anchor $filler

#Combine masks

gdal_merge.py -o gapmask0 -separate $amask $fmask

#Compute mask for gapfill

oft-calc gapmask0 gapmask1<<EOF
2
#1 1 = #2 1 = * 1 2 ?
#2
EOF

oft-calc gapmask1 gapmask2<<EOF
1
#2 0 = #1 1 = * #1 3 ?
EOF

if [ $usendvi ] ; then

echo "Creates NDVI images (NIR-R) / (NIR + R)"

        if [ 4 -gt $abands -o 4 -gt $fbands ] ; then
            echo "Anchor or filler or both images have less than 4 bands";
            exit;
        else

oft-calc -ot Float32 -um $amask $anchor andvi<<EOF
1
#4 #3 - #4 #3 + /
EOF

oft-calc -ot Float32 -um $fmask $filler fndvi<<EOF
1
#4 #3 - #4 #3 + /
EOF

#Combine ndvi images and base mask

gdal_merge.py -o gapmask3 -ot Float32 -separate gapmask2 andvi fndvi

mv andvi "ndvi_"$aname"."$aextension
mv fndvi "ndvi_"$fname"."$fextension

#Allow only areas above given ndvi threshold to remain on the base mask as 2, do nothing on 
#the rest of good areas

oft-calc gapmask3 "ndvi_gapmask_"$aname"_"$fname"."$aextension<<EOF
1
#2 $ndvithr < #3 $ndvithr < * #1 2 = * #1 3 ?
EOF

fi
fi

#Compute another mask that can guide stacking of several filled images

oft-calc gapmask0 "goodarea_mask_"$aname"_"$fname"."$aextension<<EOF
1
#1 0 = #2 0 = * 1 0 ?
EOF

#Re-name the plain gapfill mask 
mv gapmask2 "gapmask_"$aname"_"$fname"."$aextension

rm gapmask0 gapmask1 gapmask3



