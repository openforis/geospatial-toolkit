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
# June 9 2011 RH
# Extracts values from an image into training data polygons (shapefile)
# Output is a text file
version=1.00 
# Improved to take shapefiles with any order of fields, added 1 parameter
# Added shapefile projection definition, 2 cases: 1) exists --> compare with imagefile
# 2) Give datum, projection, zone and hemisphere in command line
# 29.7.2011 RH
version=1.01
# 18.1.2013 RH
# Tracked and corrected problems causing crashing
# 22.1.2013 RH
# Was happy to realize that this works also with verbal attribute field
# ...only the ID field must be numerical
# Added possibility to use flexible nbr of image bands

echo "Extracts values from an image into training data polygons (shapefile)"
   
echo "V. "$version

# $1 = imagefile
# $2 = shapefile
# $3 = field name storing id's in shape
# $4 = field name storing numeric class values in shape
# $5 = ouput signaturefilename
# $6 = projection of image file
# $7 = projection of shapefile

args=$#
#Some checs 
if [ $args != 5 -a $args != 7 ] ; then
    echo "Version $version"
    echo "Either 5 or 7 parameters are needed, latter in the case your image and shapefile projections differ"
    echo "The projections are then given as EPSG codes (e.g. EPSG:32467)"
    echo "Usage: oft-sigshp.bash <image> <shapefile_basename> <shapefile_id_fieldname> <shapefile_coverclass_fieldname> <ouput_sigfile>"
    echo "Usage: oft-sigshp.bash <image> <shapefile_basename> <shapefile_id_fieldname> <shapefile_coverclass_fieldname> <ouput_sigfile> <image_projection_EPSG> <shp_projection_EPSG>"
exit
fi

if [ ! -f $2".shp" ] ; then
    echo "Shapefile missing"
exit
fi
if [ `ogrinfo -al $2".shp"|grep -w $3|wc -l` -eq 0 ] ; then
    echo "No field named "$3" in shapefile 1"
exit
fi
if [ `ogrinfo -al $2".shp"|grep -w $3|wc -l` -eq 0 ] ; then
   echo "No field named "$3" in shapefile 2"
exit
fi

#Compare  projections if no projection info is given

if [ $args -eq 5 ] ; then

gdalinfo $1|grep "PROJCS" > improjrow
awk -F"\"" '{print $2}' "improjrow" > improj
echo "image projection as defined in the PROJCS variable:"
cat improj

ogrinfo -ro -so $2'.shp' $2|grep "PROJCS" > shprojrow
awk -F"\"" '{print $2}' "shprojrow" > shproj
echo "shapefile projection as defined in the PROJCS variable:"
cat shproj

if [ `diff improj shproj|wc -l` -gt 0 ] ; then

echo "PROJCS contents seem to differ, are you absolutely sure that the image and shape are in same projection?"

rm improjrow improj shprojrow shproj

fi

fi

#Create an empty image of the size of the Landsat in question. This empty image is used for storing
#the training data polygons in raster format in the next steps.

oft-calc -inv -X -ot Int16 $1 empty.img<<EOF
1
#1 32000 =
EOF

if [ $args -eq 7 ] ; then
#Re-project shapefile into same projection

ogr2ogr -s_srs $7 -t_srs $6 toberemoved.shp $2'.shp'

#Burn the training areas into the empty image

gdal_rasterize -a $3 -l $'toberemoved' $'toberemoved.shp' $'empty.img'

#extract grey values from input image using the rasterized training areas
oft-stat $'empty.img' $1 s1

ogr2ogr -f "CSV" $2'.csv' $'toberemoved.shp'

rm toberemoved*

fi

if [ $args -eq 5 ] ; then
#Burn the training areas into the empty image

gdal_rasterize -a $3 -l $2 $2'.shp' $'empty.img'

#extract grey values from input image using the rasterized training areas
oft-stat $'empty.img' $1 s1

ogr2ogr -f "CSV" $2'.csv' $2'.shp'

fi

mv $2'.csv' tmp1

rm empty.img

#select columns that store training area id's and cover classes

i=0
j=0

awk -v colname=$3 'BEGIN { FS = "," } ;
{
if(NR==1) for(i=1;i<=NF;i++)
{ if($i~colname) { colnum=i;break}}
else print $colnum 
}' tmp1 > tmp11

awk -v colname2=$4 'BEGIN { FS = "," } ;
{
if(NR==1) for(j=1;j<=NF;j++) 
{ if($j~colname2) { colnum2=j;break}}
else print $colnum2 
}' tmp1 > tmp12


#Combine into one file
awk '{str = $1 ; getline < "tmp12" ; print str " " $1 > "s2"}' tmp11

#combine with greyvalues
i=0
j=0

awk 'BEGIN{i=1; while((getline input[i] < "s1")){i++}}{for(j=1; j<=i ; j++){split(input[j],row); if(row[1] == $1) print $1,$2,input[j]}}' $"s2" > tmp2

#select only desired columns
#old version with fixed 7 bands
#awk 'BEGIN { FS = " " } ;{ print $1, $2, $5, $6, $7, $8, $9, $10, $11 }' $"tmp2" > tmp3

#First, do not print columns 3 and 4 (3 repeats id, 4 tells nbd of pixels)
awk '{$3=$4=""; print $0}' $"tmp2" > tmp3

#Second, print all columns up to the end of averages
awk '{for(i=1;i<=((NF-2)/2)+2;i++){printf "%s ", $i}; printf "\n"}' $"tmp3" > tmp4

#Remove those that are zero in the satellite image (check the first band)
awk -F" " '$3 ~ /1|2|3|4|5|6|7|8|9/ {print $0}' $"tmp4" > $5

rm tmp1 tmp2 tmp3 tmp4 tmp11 tmp12 s1 s2

