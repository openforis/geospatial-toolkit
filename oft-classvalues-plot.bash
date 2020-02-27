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
# Sept 14 2011 RH
# Extracts values from an image into training data polygons (shapefile)
# Creates scatterplots of the data class by class
# Output is png and txt files
version=1.00 
# January 24 2013 RH
# Allowed use of flexible number of bands
# Removed -inv from oft-calc
# Added a check before trying to delete the ouput directory
# Re-named the script
version=1.01 
# Feb 4 2013 RH
# Re-named: changed _ into -
version=1.02

echo "     "
echo "=============================================================="
echo "                    Oft-classvalues_plot.bash                 "
echo "=============================================================="
echo "Extracts values from an image into training data polygons (shapefile)"
echo "Creates scatterplots of the data class by class"
echo "At this point the image and the shapefile need to be in the same projection"

echo "V. "$version

# $1 = imagefile
# $2 = shapefile
# $3 = field name storing numeric class values in shape
# $4 = band to be used for X axis
# $5 = band to be used for Y axis

args=$#

if [ $args != 5 ] ; then
    echo "Version $version"

    echo "Usage: oft-classvalues-plot.bash <image> <shapefile_basename> <shapefile_class_fieldname> <image band for x-axis> <image band y-axis>"
exit
fi

#Create an empty image of the size of the image file in question. This empty image is used for storing
#the training data polygons in raster format in the next steps.

oft-calc -ot Byte $1 empty<<EOF
1
#1 32000 =
EOF

#Burn the training area pixels into the empty image

gdal_rasterize -a $3 -l $2 $2'.shp' empty

#Class means and std's

#extract grey values from input image using the rasterized training areas

oft-stat empty $1 s1

#find maximum and minimum class value

maxclass=`awk 'max=="" || $1 > max {max=$1} END{ print max}' FS=" " s1`
minclass=`awk 'min=="" || $1 < min {min=$1} END{ print min}' FS=" " s1`

#Select only desired columns
#$4 tells use the image band to be used for X-axis
#but bcs oft-stat outputs also id and pixel nbr in each segment, we jump 2 cols ahead
#The sdt is then found usinf number of fields (NF) and the computed band location
let "y = $4+2"

awk -v y=$y 'BEGIN { FS = " " } ;{ print $1, $y, $((NF-2)/2+y) }' $"s1" > tmp1

#Plot

Y=$4
let "high = $maxclass+1"
let "low = $minclass-1"

gnuplot<<EOP
set terminal png
set output "output.png"
set xlabel "Class"
set ylabel "Band${Y}"
set xrange [${low}:${high}]
#set yrange [0:3000]
set key box
set title "Spectral values for classes"
#  set pointsize 2.5
# lt is for color of the points: -1=black 1=red 2=grn 3=blue 4=purple 5=aqua 6=brn 7=orange 8=light-brn
# pt gives a particular point type: 1=diamond 2=+ 3=square 4=X 5=triangle 6=*
#plot 'tmp1' using 1:2 title "Value" lt 1
plot 'tmp1' title "Value" with errorbars lt 1
EOP

mv output.png 'plots_'$1'_band_'$4'.png'

#Select only desired columns
#$4 tells use the image band to be used for X-axis
#but bcs oft-stat outputs also id and pixel nbr in each segment, we jump 2 cols ahead
#The sdt is then found usinf number of fields (NF) and the computed band location
let "y = $5+2"

awk -v y=$y 'BEGIN { FS = " " } ;{ print $1, $y, $((NF-2)/2+y) }' $"s1" > tmp2

#Plot

Y=$5

gnuplot<<EOP
set terminal png
set output "output.png"
set xlabel "Class"
set ylabel "Band${Y}"
set xrange [${low}:${high}]
set key box
set title "Spectral values for classes"
plot 'tmp2' title "Value" with errorbars lt 1
EOP

mv output.png 'plots_'$1'_band_'$5'.png'

#Pixelwise values:

#First, remove the output dir if already exists

if [ -d 'plots_'$1'_bands_'$4'_'$5 ]; then

rm -r 'plots_'$1'_bands_'$4'_'$5

fi

#Extract required x-axis and y-axis bands

#gdal_translate -ot Int16 -b $4 $1 'b'$4

gdal_translate -ot Int16 -b $4 $1 'b'$4
gdal_translate -ot Int16 -b $5 $1 'b'$5

#Merge class id, x-axis band and y-axis band

gdal_merge.py -ot Int16 -separate -o comb empty 'b'$4 'b'$5

echo "          "
echo "================================================================================"
echo "Now starts converting training area pixels into xyz-data, please wait patiently!"
echo "================================================================================"
echo "          "

gdal2xyz.py empty areasxyz

#Select only pixels within training areas, give running id's 

let "n = 0"
awk -v n=$n 'BEGIN { FS = " " } ; { if ($3 > 0) print n += 1, $1, $2 }' $"areasxyz" > ids.txt

#Extract values from x and y bands

oft-extr -nomd -avg -ws 1 -o values.txt ids.txt comb<<EOF
2
3
EOF

#Select useful columns. 1=id, 2=x, 3=y, 6=class, 7=tm-x, 8=tm-y

awk 'BEGIN { FS = " " } ;{ print $1, $2, $3, $6, $7, $8 }' $"values.txt" > tmp4

mkdir 'plots_'$1'_bands_'$4'_'$5

#Start plotting

for (( a=1; a<=$maxclass; a++ ))

do

awk -F" " -v a=$a '$4 == a {print $0}' $"tmp4" > classfile

X=$4
Y=$5

gnuplot<<EOP
set terminal png
set output "output.png"
set xlabel "Band${X}"
set ylabel "Band${Y}"
#set xrange [0:3000]
#set yrange [0:3000]
set key box
set title "Classwise plots"
plot 'classfile' using 5:6 title "Value" lt 1
EOP

mv output.png 'plots_'$1'_bands_'$4'_'$5/'class'$a'.png'
mv classfile 'plots_'$1'_bands_'$4'_'$5/'class'$a'.txt'

done

mv tmp1 'classvalues_'$1'_band_'$4'.txt'
mv tmp2 'classvalues_'$1'_band_'$5'.txt'
mv tmp4 'pixelvalues'$1'_bands_'$4'_'$5'.txt'

rm comb areasxyz empty b$4 b$5 ids.txt values.txt s1

