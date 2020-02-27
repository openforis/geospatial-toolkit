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
# May 30 2012 RH
# Samples pixel values from an image within areas determined by training data polygons (shapefile) 
# Sample size is given by the user
# Divides the sample in relation to class frequencies
# Output is a txt file to be used e.g. in k-nn
version=1.00 
# Added option to pick a new sample with another sample size
version=1.01
# Feb 4 2013 RH
# Added possibility to use flexible nbr of image bands
# Re-named: changed _ into -
#TBD: if one wants to give the sample freqs per class
version=1.02
# Feb 11 RH: Did not run with Wiki test data at gda_rasterize. Currently just removed the -ot byte...
# must check better why it did fail (the values did fit into byte)
version=1.03

echo "     "
echo "=============================================================="
echo "                      oft-sample-within-polys.bash                       "
echo "=============================================================="
echo "Samples pixel values from an image within areas determined by training data polygons (shapefile)"
echo "At this point the image and the shapefile need to be in the same projection"

echo "V. "$version

# $1 = imagefile
# $2 = shapefile
# $3 = field name storing numeric class values in shape

args=$#

if [ $args != 4 -a $args != 5 ] ; then
    echo "Version $version"

    echo "Usage: oft-sample-within-polys.bash <image> <shapefile_basename> <shapefile_class_fieldname> <size_of_sample> [-sample_only]"
    echo "After the first run, a new sample can be picked fast by using option -sample_only"
exit
fi


if [ `echo $@|grep sample_only|wc -l` -eq 0 ]; then

#Create an empty image of the size of the Landsat in question. This empty image is used for storing
#the training data polygons in raster format in the next steps.

oft-calc $1 empty<<EOF
1
1 32000 =
EOF

#Burn the training area pixels into the empty image

gdal_rasterize -a $3 -l $2 $2'.shp' empty

#Merge class id and bands. If crashes, your gdal-version does not contain multiband merging

gdal_merge.py -ot Int16 -separate -o comb empty $1

echo "          "
echo "================================================================================"
echo "Now starts converting training area pixels into xyz-data, please wait patiently!"
echo "================================================================================"
echo "          "

gdal2xyz.py empty areasxyz

#Select only pixels within training areas, give running id's 

let "n = 0"
awk -v n=$n 'BEGIN { FS = " " } ; { if ($3 > 0) print n += 1, $1, $2 }' $"areasxyz" > ids.txt

#Extract values from bands

oft-extr -nomd -ws 1 -o values.txt ids.txt comb<<EOF
2
3
EOF

#Old version with fixed number of bands: Select useful columns. 1=id, 2=x, 3=y, ...=class, ...=tm-x, ...=tm-y
#awk 'BEGIN { FS = " " } ;{ print $1, $2, $3, $6, $7, $8, $9, $10, $11, $12, $13 }' $"values.txt" > greyvals_$2.txt

#Do not print columns 4 and 5 (col and row)
awk '{$4=$5=""; print $0}' $"values.txt" > greyvals_tmp.txt

#Clean extra whitespaces
sed -e 's/  //' $"greyvals_tmp.txt" > greyvals_$2.txt

rm areasxyz empty comb ids.txt values.txt greyvals_tmp.txt

fi

#Compute histograms

awk 'BEGIN { FS = " " } ;{ print $4}' $"greyvals_$2.txt" > class.txt

let "n = 0"
awk -v n=$n 'NF > 0{ counts[$0] = counts[$0] + 1; } END { for (word in counts) print n += 1, word, counts[word]; }' $"class.txt" > histo.txt

#Find out nbr of pixels in training areas

npixels=`wc class.txt|awk 'BEGIN { FS = " " } ;{ print $1}'`
nclasses=`wc histo.txt|awk 'BEGIN { FS = " " } ;{ print $1}'`

#Notify if pixels < required amount of samples... and set nsamples to npixels

if [ $npixels -le $4 ] ; then

echo "Number of pixels $npixels is less or equal to number of required samples $4"
echo "Nsamples will be set to equal npixels"

cp greyvals_$2.txt sample_$2.txt

else

#Go through a loop and select randomly in each class, based on the sample size given by the user and relative size of class

for (( i=1; i<=$nclasses; i++ )) ; do

clsize=`awk -v i=$i 'BEGIN { FS = " " } ;{ if ($1 == i) print $3}' $"histo.txt"`

#echo "classize" $clsize

class=`awk -v i=$i 'BEGIN { FS = " " } ;{ if ($1 == i) print $2}' $"histo.txt"`

#echo "class" $class

samplesize=`awk -v req=$4 -v cs=$clsize -v npix=$npixels 'BEGIN { result = req * cs / npix; print result }'`

#echo "samplesize" $samplesize

awk -v class=$class 'BEGIN { FS = " " } ; { if ($4 == class) print $0 }' $"greyvals_$2.txt" > tmpclass$i.txt
awk -v ss=$samplesize 'BEGIN { FS = " " } ; {srand();} {a[NR]=$0} END{ for(i=1;i<=ss;i++){x=int(rand()*NR);print a[x];}}' $"tmpclass$i.txt" > "ctmp"$i".txt"

rm tmpclass$i.txt

done

cat ctmp*.txt > sample_$2.txt

awk -F" " -v npix=$npixels -v req=$4 '{ print $0, $3/npix*req }' $"histo.txt" > histogram$2.txt

fi

rm class.txt ctmp*.txt histo.txt

