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
# Compares overlapping areas of 2 images
# Meant for evaluation of the brdf correction 
# The second image is projected to the same projection as the first when needed
# In that case, user gives the projection of first image as EPGS code. 
# Then also both images need to have a projection defined (although it differs)
# Similar number of bands must exist
# Masks must be given for both images to exclude cloud/shadow areas
# They must be of same size and in same projection as their corresponding images
# Only areas with value 2 in both images are used in comparison
# User gives the spacing of the sampling points as well (in metres; 1000 = 1 km spacing)
# Reija Haapanen on Nov 3, 2011
version=1.00
#Modified for flexible number of image bands
#Reija Haapanen Nov 11, 2011
version=1.01
# RH Feb 4 2013
# Re-named: added oft and changed _ into -
version=1.02

echo "Compares overlapping areas of 2 images"
echo "Ouput is correlation values for bands"

echo "V. "$version

args=$#

#Checks
if [ $args != 5 -a $args != 6 ] ; then
    echo "Version $version"
    echo "Give the names of 2 (Landsat) images or their paths"
    echo "And their mask files"
    echo "Also give the spacing of the sampling"
    echo "If the image projections differ, give the EPGS code of the first one"
    echo "In that case, both images MUST have a projection defined (although it differs)"
    echo "Usage: oft-compare-overlap.bash <image1.img> <image2.img> <mask1.img> <mask2.img> <grid_spacing> [EPSG:img1]"
    echo "Give the last parameter in format EPSG:32637 (replace number with your own, this is for UTM 37 N)"

exit
fi


#Translate image2 and mask2 into same projection with image1
if [ $args = 6 ] ; then 

	echo "Converting image 2 into same projection with image 1"

	gdalwarp -t_srs $6 -of HFA $2 img2
	gdalwarp -t_srs $6 -of HFA $4 mask2
	gdalinfo img2 > header2

else

gdalinfo $2 > header2

fi

gdalinfo $1 > header1

#Parse bounding coordinates from image1

#Upper Left  (   98685.000, -375885.000) ( 35d23'22.49"E,  3d23'38.15"S)
#Lower Left  (   98685.000, -583515.000) ( 35d22'50.41"E,  5d16'6.79"S)
#Upper Right (  335715.000, -375885.000) ( 37d31'16.29"E,  3d23'58.46"S)
#Lower Right (  335715.000, -583515.000) ( 37d31'3.12"E,  5d16'38.37"S)

xmin1=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax1=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax1=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin1=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`

#Repeat to image2

xmin2=`grep 'Upper Left' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax2=`grep 'Upper Left' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax2=`grep 'Lower Right' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin2=`grep 'Lower Right' header2|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`

rm header1 header2

#how to do the above with awk instead of sed and awk is in script oft-gengrid.bash

echo "Finding minimums and maximums of the overlapping area"

xmin=`echo $xmin1 $xmin2 | awk '{ print ($1 > $2) ? $1 : $2 }'`
xmax=`echo $xmax1 $xmax2 | awk '{ print ($1 < $2) ? $1 : $2 }'`
ymin=`echo $ymin1 $ymin2 | awk '{ print ($1 > $2) ? $1 : $2 }'`
ymax=`echo $ymax1 $ymax2 | awk '{ print ($1 < $2) ? $1 : $2 }'`

echo "Topleft X coordinate of overlapping image area: "$xmin
echo "Topleft Y coordinate of overlapping image area: "$ymax
echo "Bottomright X coordinate of overlapping image area: "$xmax
echo "Bottomrigh Y coordinate of overlapping image area: "$ymin

echo "Generating a grid over the whole area using the desired spacing"

awk -v inc=$5 -v xsize=$xsize -v ysize=$ysize -v xmin=$xmin -v xmax=$xmax -v ymin=$ymin -v ymax=$ymax \
'BEGIN{for (x=xmin ; x<= xmax ; x = x + inc){\
  for (y=ymin ; y<= ymax ; y = y + inc){\
    n++; print n,x,y;\
    }}}' > tmp


echo "Extracting values from mask1 for the generated samplig grid"

oft-extr -nomd -avg -ws 1 -o mask1.txt tmp $3<<EOF
2
3
EOF

echo "Cleaning a bit..."
echo "...Getting rid of extra whitespaces"

sed 's/ \+/ /g' < mask1.txt > mask1_sed.txt

echo "Finding mask1 rows with valid data"

awk -F" " '$6 ~ /2/ {print $0}' $"mask1_sed.txt" > mask1_ed.txt

echo "Extracting values from mask2 for the reduced samplig grid"

if [ $args = 6 ] ; then 
oft-extr -nomd -avg -ws 1 -o mask12.txt mask1_ed.txt mask2<<EOF
2
3
EOF

rm mask2
else

oft-extr -nomd -avg -ws 1 -o mask12.txt mask1_ed.txt $4<<EOF
2
3
EOF

fi

echo "...Getting rid of extra whitespaces"

sed 's/ \+/ /g' < mask12.txt > mask12_sed.txt

echo "Finding mask2 rows with valid data"

awk -F" " '$10 ~ /2/ {print $0}' $"mask12_sed.txt" > mask12_ed.txt

echo "Extracting values from img1 for the further reduced samplig grid"

oft-extr -nomd -avg -ws 1 -o img1mask12.txt mask12_ed.txt $1<<EOF
2
3
EOF

echo "..and finally values from img2"

if [ $args = 6 ] ; then
oft-extr -nomd -avg -ws 1 -o img12mask12.txt img1mask12.txt img2<<EOF
2
3
EOF

rm img2

else

oft-extr -nomd -avg -ws 1 -o img12mask12.txt img1mask12.txt $2<<EOF
2
3
EOF

fi

echo "...Getting rid of extra whitespaces"

sed 's/ \+/ /g' < img12mask12.txt > img12mask12_sed.txt

rm tmp mask1.txt mask1_sed.txt mask1_ed.txt mask12.txt mask12_ed.txt img1mask12.txt img12mask12.txt mask12_sed.txt

echo "Find out number of bands in one image"
wc img12mask12_sed.txt > datasize
sed 's/ \+/ /g' < datasize > ds
nbr=`awk '{print $2/$1}' "ds"`
bands=$((($nbr - 15)/4))
echo "Nbr of bands is:" $bands

rm ds datasize

count=0

while [ $count -lt $bands ]
do

b1=$(($count + 14))
b2=$(($count + 14 + $bands + $bands + 2))


gawk -v b1=$b1 -v b2=$b2 -v count=$count '{xy+=($b1*$b2); x+=$b1; y+=$b2; x2+=($b1*$b1); y2+=($b2*$b2)}
 END { 
	ssx=x2-((x*x)/NR); 
	ssy=y2-((y*y)/NR); 
	ssxy = xy - ((x*y)/NR); 
	r=ssxy/sqrt(ssx*ssy); 
#	print "b1=" b1;
#	print "b2=" b2;
	bandnbr=count+1;
	print "r_band"bandnbr"=" r; 
}' "img12mask12_sed.txt"

count=$((count+1))

done

# rm img12mask12_sed.txt









