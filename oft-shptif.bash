#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Reija Haapanen
#Anssi Pekkarinen
#Cesar Cisneros
#Antonia Ortmann
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

# Reija Haapanen, Anssi Pekkarinen, Cesar Cisneros Oct 3 2012
version=1.00

# Antonia Ortmann added choice of output type and "flags" for the input files Jun 12 2014
# AO added compression to gdal_rasterize Jul 14 2014
version=1.01

args=$#

# check if the old (without flags) or new version (with flags) is supposed to be used
ct=`echo $* | grep -c -e ' -o' -e ' -i' -e '-ref'`

#############################################################################################
#### the new version with flags #############################################################
#############################################################################################

if [ $ct -gt 0 ] ; then


if [ $args -lt 6 -o $args -gt 11 ] ; then

    echo "Version $version"
    echo "Usage: oft-shptif.bash [-ot {Byte/Int16/UInt16/UInt32/Int32/Float32/Float64/CInt16/CInt32/CFloat32/CFloat64}] -i <shapefile> -ref <raster_reference> -o <raster_output> [-fn fieldname] [-nocompress]"
    echo "Shapefile to tif conversion. A wrapper for gdal_rasterize"
    exit

fi


# By keeping options in alphabetical order, it's easy to add more.
# options that will be used: -fn, -i, -o, -ot, -ref
while :
do
    case "$1" in
      -fn)
	  fieldname="$2"   # You may want to check validity of $2
	  shift 2
	  ;;
      -i)  
          shapefile="$2"
	  shift 2
	  ;;
      -o)
          output="$2"
	  shift 2
	  ;;
      -ot)
          datatype="$2"
	  shift 2
	  ;;
      -ref)
          reference="$2"
	  shift 2
	  ;;
      -nocompress)
          compress=1
          shift 1
          ;;
      --) # End of all options
	  shift
	  break;;
      -*)
	  echo "Error: Unknown option: $1" >&2
	  exit 1
	  ;;
      *)  # No more options
	  break
	  ;;
    esac
done


echo "A wrapper for gdal_rasterize"


if [ -z "$shapefile" ] ; then

    echo "Shapefile not given with option -i, exiting now"
    exit

elif [ -e "$shapefile" ] ; then

    echo "Shapefile: "$shapefile

else 

    echo "Given shapefile not found, exiting now"
    exit

fi


if [ -z "$reference" ] ; then

    echo "Reference image not given with option -ref, exiting now"
    exit

elif [ -e "$reference" ] ; then

    echo "Reference: "$reference 

else

    echo "Reference image not found, exiting now"
    exit

fi


if [ -n "$output" ] ; then

    echo "Output: "$output

else

    echo "Output image not given with option -o, exiting now"
    exit

fi


if [ -z "$datatype" ] ; then

    datatype=Float64

else case "$datatype" in
    Byte | Int16 | UInt16 | UInt32 | Int32 | Float32 | Float64 | CInt16 | CInt32 | CFloat32 | CFloat64)
        ;;
    *) 
        echo "Unknown output data type specified, exiting now"
        echo "Please use one of the following output data types {Byte/Int16/UInt16/UInt32/Int32/Float32/Float64/CInt16/CInt32/CFloat32/CFloat64}"
        exit
        ;;
    esac

fi


echo "Output data type: "$datatype


if [ -z "$fieldname" ] ; then

    fieldname=NULL

fi

if [ -z "$compress" ] ; then

    compress=NULL

fi


#############################################################################################
#### the old version without flags ##########################################################
#############################################################################################

else

# the old version does not allow the specification of data type nor the compression 
# therefore set it to Float64 and no compression
datatype="Float64"
compress=1

if [ $args -ne 3 -a $args -ne 4 ] ; then
    echo "Version $version"
    echo "Usage: oft-shptif.bash [-ot {Byte/Int16/UInt16/UInt32/Int32/Float32/Float64/CInt16/CInt32/CFloat32/CFloat64}] -i <shapefile> -ref <raster_reference> -o <raster_output> [-fn fieldname] [-nocompress]"
    echo "Shapefile to tif conversion. A wrapper for gdal_rasterize"
    exit
fi

if [ ! -f $1 -o ! -f $2 ] ; then

   echo "Input or reference file missing";
   exit

else

    echo "A wrapper for gdal_rasterize"

    shapefile=$1
    reference=$2
    output=$3

    if [ $args -eq 4 ] ; then 
	fieldname=$4
    else
	fieldname=NULL
    fi

fi

fi

#############################################################################################
#### this part is the same for both versions ################################################
#############################################################################################


tmpdir=/tmp/$$
mkdir $tmpdir

gdalsrsinfo -o wkt $reference|grep PROJCS > $tmpdir/srs

srs=`wc -l $tmpdir/srs|awk '{print $1}'`

    if [ $srs -gt 0 ] ; then
	srs="-a_srs $tmpdir/srs"
    else
	echo "NOTE: did not manage to extract SRS info from the reference image"
	srs=""
    fi
    
    gdalinfo $reference > $tmpdir/header

    xmin=`grep 'Upper Left'     $tmpdir/header  |sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
    ymax=`grep 'Upper Left'     $tmpdir/header  |sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
    xmax=`grep 'Lower Right'    $tmpdir/header  |sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $3}'`
    ymin=`grep 'Lower Right'    $tmpdir/header  |sed -e 's/(\([^)]*\))/\1/g' -e 's/,/ /g'|awk '{print $4}'`
    pixsize=`grep 'Pixel Size'  $tmpdir/header  |awk '{gsub("[(,)]"," "); print $4}'`

    
    ogrinfo -al -GEOM=NO $shapefile > $tmpdir/shapeheader

    fields=`awk -F" " '$3 ~ /=/ {print $1}'  $tmpdir/shapeheader |grep $fieldname | wc -l`

    if [ $fields -gt 0 -a $compress == 1 ] ; then 

        echo "Field name:" $fieldname 
	gdal_rasterize -ot $datatype $srs -te $xmin $ymin $xmax $ymax -tr $pixsize $pixsize -a $fieldname -l `basename $shapefile .shp` $shapefile $output

    elif [ $fields -gt 0 -a $compress == NULL ] ; then 

        echo "Field name:" $fieldname 
	gdal_rasterize -co "COMPRESS=LZW" -ot $datatype $srs -te $xmin $ymin $xmax $ymax -tr $pixsize $pixsize -a $fieldname -l `basename $shapefile .shp` $shapefile $output

    elif [ $fieldname == NULL -a $compress == 1 ] ; then

        echo "No field name specified"
	gdal_rasterize -ot $datatype $srs -clump -te $xmin $ymin $xmax $ymax -tr $pixsize $pixsize -l `basename $shapefile .shp` $shapefile $output

    elif [ $fieldname == NULL -a $compress == NULL ] ; then

        echo "No field name specified"
	gdal_rasterize -co "COMPRESS=LZW" -ot $datatype $srs -clump -te $xmin $ymin $xmax $ymax -tr $pixsize $pixsize -l `basename $shapefile .shp` $shapefile $output

    else 

	echo "Specified field name" $fieldname "not found, exiting now"
	exit

    fi
    
    rm -r $tmpdir


