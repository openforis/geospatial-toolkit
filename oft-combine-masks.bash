#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Reija Haapanen
#Anssi Pekkarinen
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
# $1 = list of images and shapes, starting with an image
# file, ending with nodata value and, optionally after nodata EPSG
# projection code of the first image

# Created by Reija Haapanen on December 1, 2011
# Idea is to allow user to give mask images and shapefiles
# and this script combines them into 1 mask
# The first is the base (let's first assume it is an image, later test with shapefile)
# The next ones will be written on only if there is nodata
# Nodata is given by the user
# Extent comes from the first image
# Projection is given by the user (optinally)
# If not, all files are assumed to be in same projection
# Pixel size is assumed to be 30 m
version=1.00
# RH 3.1.2012
# Added on "if shapefile" loop so that gdal_rasterize is not called in case of shapefiles 
version=1.01
# Cesar Cisneros 27/04/2012  Changed '\.'shp for those lines invoquing grep .shp
version=1.02
# AP has added the -inv options to support new version of ofc-calc
# RH 9.5.2012 removed the -inv options, after checking that the oft-calcs in this script 
# were not affected by the change
version=1.03
# Re-named: added oft and changed _ into -
version=1.04
args=$#

#Checks
if [ $args -lt 1 ] ; then
    echo "Version $version"
    echo "Give at least 2 files and nodata value. First file must be an image, the rest may be images or shapefiles"
    echo "In the shapefiles, the last field is assumed to be the one containing the mask values"
    echo "If there are several projections, give the projection of the first image as EPSG code"
    echo "Usage: oft-combine-masks.bash <input1> <input2> .... <nodata> [EPSG code]"
    echo "Example: oft-combine-masks.bash mask1.img mask2.img clouds.shp badregions.shp -9999 EPSG:32636"
exit
fi

args=("$@")

echo $@ > row

#Check if the last one is EPSG code and what is the nodata value
awk -v last=$# '$last ~ /EPSG:/ {print $last}' "row"

if [ `grep EPSG row|wc -l` -eq 0 ]; then
  echo "EPSG code not given"
  echo "Number images/shapes passed: " $(($#-1))
  amount=$(($#-1))
  eval nodata=\$$#
  echo "Nodata value is " $nodata

else
  echo "EPSG code given: " `awk -v last=$# '$last ~ /EPSG:/ {print $last}' "row"`
  echo "Number images/shapes passed: " $(($#-2))
  amount=$(($#-2))
  eval nodata=\$$(($#-1))
  echo "Nodata value is " $nodata
fi


#Go through files in the command line
for (( i=0; i<$amount; i++ )) ; do
echo $amount
#Check if the input file exists

if [ ! -f ${args[i]} ] ; then
nbr=$(($i+1))
   echo "File" $nbr " does not exist"
exit
fi

#If first file, let's steal the extent info

echo $(($i+1))
if [ $(($i+1)) -eq 1 ] ; then

gdalinfo ${args[i]} > header1

xmin=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymax=`grep 'Upper Left' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
xmax=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
ymin=`grep 'Lower Right' header1|sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
echo "Topleft X coordinate of base image: "$xmin
echo "Topleft Y coordinate of base image: "$ymax
echo "Bottomright X coordinate of base image: "$xmax
echo "Bottomrigh Y coordinate of base image: "$ymin

else

#Else, if EPSG code is given, transform next files into this projection
#and force into same extent
#Also find out if the file is a shapefile
#and burn the shape values into an empty image created from img1
#if [ $(($i+1)) -gt 1 ] ; then
if [ `grep EPSG row|wc -l` -ne 0 ] ; then

if [ `echo ${args[i]}|grep '\.'shp|wc -l` -eq 0 ] ; then

gdalwarp -t_srs `awk -v last=$# '$last ~ /EPSG:/ {print $last}' "row"` -te $xmin $ymin $xmax $ymax -tr 30 30 -of HFA ${args[i]} $i.img

else

#go to shapefile process... bcs `echo ${args[i]}|grep .shp|wc -l` -ne 0

#re-project shape
ogr2ogr -t_srs `awk -v last=$# '$last ~ /EPSG:/ {print $last}' "row"` $i.shp ${args[i]}

#get empty image with extents from image1
oft-calc -ot Int16 ${args[0]} empty$i.img<<EOF
1
#1 40000 = $nodata 0 ?
EOF

#Find out name of the masking field in the shapefile

ogrinfo -al -GEOM=NO $i.shp > shapeheader

fieldname=`awk -F" " '$3 ~ /=/ {print $1}' shapeheader |tail -1`

rm shapeheader
#Burn shapes on the image

gdal_rasterize -a $fieldname -l $i $i'.shp' empty$i.img

rm $i.*

fi

else 

if [ `echo ${args[i]}|grep '\.'shp|wc -l` -ne 0 ] ; then

#No re-projection needed, just rasterize the shapefile
#get empty image with extents from image1
oft-calc -ot Int16 ${args[0]} empty$i.img<<EOF
1
#1 40000 = $nodata 0 ?
EOF

#Find out name of the masking field in the shapefile

ogrinfo -al -GEOM=NO ${args[i]} > shapeheader

fieldname=`awk -F" " '$3 ~ /=/ {print $1}' shapeheader |tail -1`

rm shapeheader

#Burn shapes on the image

gdal_rasterize -a $fieldname -l `basename ${args[i]} .shp` ${args[i]} empty$i.img

fi
fi
fi

done

#Now, we need to start piling the mask layers on top of each other
#Rules: in order of the command line... only nodata is replaced

#We have at least 2 input files, otherwise this exercise would be useless...

#The files were all in same projection...
if [ `grep EPSG row|wc -l` -eq 0 ]; then

#And not shapefile....
if [ `echo ${args[1]}|grep '\.'shp|wc -l` -eq 0 ] ; then

gdal_merge.py -of HFA -separate -o comb1 ${args[0]} ${args[1]}

else

#Shapefile
gdal_merge.py -of HFA -separate -o comb1 ${args[0]} empty1.img

rm empty1.img

fi

else

#Different projection and not shapefile

if [ `echo ${args[1]}|grep '\.'shp|wc -l` -eq 0 ] ; then

gdal_merge.py -of HFA -separate -o comb1 ${args[0]} 1.img

rm 1.img

#Different projection and shapefile
else

gdal_merge.py -of HFA -separate -o comb1 ${args[0]} empty1.img

rm empty1.img

fi

fi

#And now combine these 2 masks

oft-calc -ot Byte comb1 tmpmask1.img<<EOF
1
#1 $nodata = #1 #2 ?
EOF

rm comb1

echo "First combined mask produced"

#But do we have more files?
if [ $amount -gt 2 ] ; then

for (( i=2; i<$amount ; i++ )) ; do

prev=$((i-1))

#The files were all in same projection...
if [ `grep EPSG row|wc -l` -eq 0 ]; then

#And not shapefile....
if [ `echo ${args[i]}|grep '\.'shp|wc -l` -eq 0 ] ; then

gdal_merge.py -of HFA -separate -o comb$i tmpmask$prev.img ${args[i]}

rm tmpmask$prev.img

else

#Shapefile

gdal_merge.py -of HFA -separate -o comb$i tmpmask$prev.img empty$i.img

rm tmpmask$prev.img empty$i.img

fi

else

#Different projection and not shapefile

if [ `echo ${args[i]}|grep '\.'shp|wc -l` -eq 0 ] ; then

gdal_merge.py -of HFA -separate -o comb$i tmpmask$prev.img $i.img

rm tmpmask$prev.img $i.img

#Different projection and shapefile
else

gdal_merge.py -of HFA -separate -o comb$i tmpmask$prev.img empty$i.img

rm empty$i.img tmpmask$prev.img
fi

fi

#And combine the masks
echo "Combining masks..."

oft-calc -ot Byte comb$i tmpmask$i.img<<EOF
1
#1 $nodata = #1 #2 ?
EOF

rm comb$i

done

fi

round=$(($amount-1))
mv tmpmask$round.img combined_mask.img

rm row header1





