#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
# Giuseppe Amatulli
# Laura Daietti
# Antonia Ortmann
# Anssi Pekkarinen
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
# Authors:  Giuseppe Amatulli, Laura Daietti, Antonia Ortmann, Anssi Pekkarinen 
# Fri June 28, 2013

version=0.2

# This script gets the coordinates of the corners of a GDAL raster layer or OGR vector layer.
# CHANGES
# AP Sun June 30, 2013
# changed usage following Giuseppe's suggestion

args=$#


if [ $args -ne 2 -a $args -ne 1 ] ; then

    echo "Usage: oft-getcornercoord.bash <inputfile> [ { -ul_lr /-min_max} ]"
    echo "Where: <inputfile> is a GDAL raster layer or OGR vector layer"
    echo "-ul_lr = ulx uly lrx lry (default)"
    echo "-min_max = xmin ymin xmax ymax (ulx lry lrx uly)"
    exit

else

file=$1

# check which order of output should be used

    if [ $args -eq 1 ] ; then

        order=-ul_lr

    elif [ $args -eq 2 ] ; then

        order=$2

    fi

# check the layer (raster/vector)

    if [ `ogrinfo $1 | grep FAILURE|wc -l` -gt 0 ] ; then
	
	echo "Not an OGR vector layer" 

	if [ `gdalinfo $1 2>&1 | grep ERROR|wc -l` -gt 0 ] ; then  
	    
	    echo "Not a GDAL raster layer"
	    echo "Input layer type not recognized" ;
	    exit;


	else
	    
	    echo "Using GDAL raster layer"

            type=1

            ulx=$(gdalinfo $file | grep "Upper Left" | awk '{ gsub ("[(),]"," ") ; print  $3  }')
            uly=$(gdalinfo $file | grep "Upper Left" | awk '{ gsub ("[(),]"," ") ; print  $4  }')
            lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; print $3  }')
            lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; print $4  }')

       fi

    else

        echo "Using OGR vector layer"

	type=2
 
	layer=`basename $1`
	layer=${layer%.*}
	

	ulx=`ogrinfo $1 $layer |grep -m 1 Extent|awk '{gsub("[,()]"," ");print $0}' | awk '{print $2}'`
	lrx=`ogrinfo $1 $layer |grep -m 1 Extent|awk '{gsub("[,()]"," ");print $0}' | awk '{print $5}'`
	lry=`ogrinfo $1 $layer |grep -m 1 Extent|awk '{gsub("[,()]"," ");print $0}' | awk '{print $3}'`
	uly=`ogrinfo $1 $layer |grep -m 1 Extent|awk '{gsub("[,()]"," ");print $0}' | awk '{print $6}'`

    fi



    if [ $order = "-ul_lr" ] ; then

        echo "Output in order ulx uly lrx lry"

        echo $ulx $uly $lrx $lry

    elif [ $order = "-min_max" ] ; then

        echo "Output in order xmin ymin xmax ymax (ulx lry lrx uly)"

        echo $ulx $lry $lrx $uly

    fi

fi




