#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Laura Daietti
#Antonia Ortmann
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
# July 1, 2013

version=0.2
#CHANGES

# July 1, 2013
# AP fixed calculation of xsize ysize

# This script crops a raster image to the extent of a certain pixel value (i.e. a district of a country).

tmpdir=/tmp/OF.crop$$
mkdir $tmpdir
statfile=$tmpdir/stat.txt
tmpfile=$tmpdir/img.tif

args=$#



if [ $args -ne 3 -a $args -ne 4 ] ; then

    echo "Usage: oft-crop.bash <input-img> <output-img> [ { value / -all } ] [ nodata-value ] "
    echo "Where: <input-img> is a GDAL raster layer"
    echo "[value] = is the value of the inputfile it should be cropped to"
    echo "-all = if image should be cropped to every unique pixel value; output will be named accordingly"
    echo "[nodata-value]: for this value no cropping will be done; if not provided, it is assumed to be 0 (only applicable for option -all)"
    exit

else

    if [ `gdalinfo $1 2>&1 | grep ERROR|wc -l` -gt 0 ] ; then  
	    
	echo "Not a GDAL raster layer"
	echo "Input layer type not recognized" ;
	exit;


    else
	    
	echo "Using GDAL raster layer"

        if [ $3 = -all ] ; then

        if [ $args -eq 4 ] ; then
            nodata=$4
        else nodata=0
        fi

            echo "Performing cropping for ALL occuring pixel values except nodata value" $nodata

            oft-stat -i $1 -o $statfile -um $1 -noavg -nostd

            list=`awk '{print $1}' $statfile`

        elif [ $args -eq 3 ] ; then

            list=$3

            echo "Cropping raster to value" $3

        fi

        for value in $list ; do

        if [ $3 != -all ] || [ $value != $nodata ] ; then

        # compute the required bounding box values

        coor=`oft-bb $1 $value | grep "Band 1 BB"`

        xmin=`echo $coor | awk '{print $6}'`
        ymin=`echo $coor | awk '{print $7}'`
        xoff=`echo $coor | awk '{print $8-$6 + 1}'`
        yoff=`echo $coor | awk '{print $9-$7 + 1}'`

        # modify the output name

        if [ $3 = -all ] ; then
            output=`basename $2`
            dir=`dirname $2`
	    output=$dir/${output%.*}_${value}.tif
        else output=$2
        fi

        # crop the image

        gdal_translate -srcwin $xmin $ymin $xoff $yoff $1 $tmpfile

        oft-calc $tmpfile $output <<EOF
1
#1 $value = 0 $value ?
EOF

        fi

        done

    fi

fi

rm -r $tmpdir

