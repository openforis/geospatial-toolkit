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
# Mar 5 2013 RH
# Picks field data in a text file based on image extent
# Extracts image values based on field data locations
# If a mask is given, pixels with mask value 0 are dropped
#TBD: option to give the EPSG-codes of image and field data
# for transformation purposes
version=1.00 

echo "     "
echo "=============================================================="
echo "                      oft-nn-training-data.bash               "
echo "=============================================================="
echo "Picks field data in a text file based on the extent of given image"
echo "Extracts image values based on field data locations"
echo "If a mask is given, pixels with mask value 0 are dropped"
echo "At this point the materials must to be in the same projection"

echo "V. "$version

args=$#

if [ $args -lt 4 ] ; then
    echo "Version $version"

    echo "Usage: oft-nn-training-data.bash <-i image.tif> <-f field_data.txt> <-x col> <-y col> [-m mask.tif] [-d dem] [-l lu]"
exit

fi

#echo "Total number of args passed: $#"

#Assign the parameters to corresponding ones in the scrips

while getopts i:f:x:y:m:d:l: option
do
        case "${option}"
        in
                i) image=${OPTARG};;
                f) data=${OPTARG};;
                x) xcol=${OPTARG}
		xfound=true;;
                y) ycol=${OPTARG}
		yfound=true;;
                m) mask=${OPTARG}
		usemask=true;;
                d) dem=${OPTARG}
		usedem=true;;
                l) lu=${OPTARG}
		uselu=true;;

        esac
done

if [ -e $image ] ; then

echo "Picking pixel values from "$image

else

echo "Given image file not found"

exit

fi

if [ -e $data ] ; then

echo "Using "$data" as input data"

else

echo "Given data file not found"

exit

fi

#Checks for existence of x and y options
if [ $xfound -a $yfound ] ; then

echo "Using "$xcol" for x coordinate column and "$ycol" for y"

else

echo "Give both -x and -y options!"

exit

fi

#Checks for mask, dem & lu, if given
if [ $usemask ] ; then

if [ -e $mask ] ; then

echo "Using "$mask" as mask file"

else

echo "Given mask file not found"

exit

fi
fi

if [ $usedem ] ; then

if [ -e $dem ] ; then

echo "Using "$dem" as DEM file"

else

echo "Given DEM file not found"

exit

fi
fi

if [ $uselu ] ; then

if [ -e $lu ] ; then

echo "Using "$lu" as LU file"

else

echo "Given LU file not found"

exit

fi
fi

#Find out extent of the image

gdalinfo $image > header1

xmin=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
echo "Topleft X coordinate of base image: "$xmin
echo "Topleft Y coordinate of base image: "$ymax
echo "Bottomright X coordinate of base image: "$xmax
echo "Bottomrigh Y coordinate of base image: "$ymin

#Select data based on these boundaries

sed 's/[[:space:]]\+/,/g' $data > datamod

awk -v xmax=$xmax -v xmin=$xmin -v ymax=$ymax -v ymin=$ymin -v xcol=$xcol -v ycol=$ycol -F"," '$xcol < xmax && $xcol > xmin && $ycol > ymin && $ycol < ymax {print}' $"datamod" > tmp1

sed 's/,/ /g' tmp1 > tmp2

#Create a coordinate file for extraction

awk -v xcol=$xcol -v ycol=$ycol '{print $1,$xcol,$ycol}' $"tmp2" > crdi

#If we have mask, let's first extract values from it

if [ $usemask ] ; then

oft-extr -nomd -ws 1 -o maskvalues crdi $mask<<EOF
2
3
EOF

#Then drop off the 0-pixels


awk  '$6 > 0 {print $1,$2,$3}' $"maskvalues" > crdi

# ap moved rm maskvalues here

rm maskvalues

fi

#Then, extract only valid values from bands

oft-extr -nomd -ws 1 -o valuestmp crdi $image<<EOF
2
3
EOF

#Do not print columns 4 and 5 (col and row)
awk '{$4=$5=""; print $0}' $"valuestmp" > values

#Clean extra whitespaces
sed -e 's/   / /' $"values" > valuesclean

#Continue to DEM if given

if [ $usedem ] ; then

oft-extr -nomd -ws 1 -o demtmp crdi $dem<<EOF
2
3
EOF

#Now take only id and demvalue
awk '{print $1,$6}' $"demtmp" > demvalues 

#Drop x and y off from the valuesfile to avoid repetition
awk '{$2=$3=""; print $0}' $"valuesclean" > valuestmp

#Clean extra whitespaces
sed -e 's/  / /' $"valuestmp" > valuesclean

#Combine data into one textfile

i=0
j=0

awk 'BEGIN{i=1; while((getline input[i] < "demvalues")){i++}}{for(j=1; j<=i ; j++){split(input[j],row); if(row[1] == $1) print input[j],$0}}' $"valuesclean" > tmp100

#Drop extra id off
awk '{$3=""; print $0}' $"tmp100" > tmp101

#Clean extra whitespaces
sed -e 's/  / /' $"tmp101" > valuesclean

rm demvalues demtmp tmp100 tmp101

fi

#Continue to LU mask if given

if [ $uselu ] ; then

oft-extr -nomd -ws 1 -o lutmp crdi $lu<<EOF
2
3
EOF

#Now take only id and LU col
awk '{print $1,$6}' $"lutmp" > luvalues 

if [ ! $usedem ] ; then

#Drop x and y off from the valuesfile to avoid repetition
awk '{$2=$3=""; print $0}' $"valuesclean" > valuestmp

#Clean extra whitespaces
sed -e 's/  / /' $"valuestmp" > valuesclean

fi

#Combine data into one textfile

i=0
j=0

awk 'BEGIN{i=1; while((getline input[i] < "luvalues")){i++}}{for(j=1; j<=i ; j++){split(input[j],row); if(row[1] == $1) print input[j],$0}}' $"valuesclean" > tmp100

#Drop extra id off 
awk '{$3=""; print $0}' $"tmp100" > tmp101

#Clean extra whitespaces
sed -e 's/  / /' $"tmp101" > valuesclean

rm luvalues lutmp tmp100 tmp101

fi

#combine with field data

i=0
j=0

awk 'BEGIN{i=1; while((getline input[i] < "tmp2")){i++}}{for(j=1; j<=i ; j++){split(input[j],row); if(row[1] == $1) print input[j],$0}}' $"valuesclean" > values_for_nn


rm tmp2 tmp1 header1 datamod crdi valuestmp values valuesclean


