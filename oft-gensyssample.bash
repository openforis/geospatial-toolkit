#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
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
# author anssi.pekkarinen@fao.org
version=0.1

version=0.2
# AP 24 Sep 2012
# fixed bug which prohibited the use of raster layer

# This script creates various systematic point samples for the extent 
# of a given GDAL/OGR compatible raster/vector layer 

# Usage:
# sample <layer> <Dx> <Dy> [scheme] [#plots][dxy] [h]
# where:
# layer = input raster or vector layer the extent of which is used 
# bounding box of the area will be extracted
# Dx between cluster distance in X direction
# Dy between cluster distance in Y direction
# Scheme clustering scheme. The following schemes are implemented: 
# L=L shaped, 
# iL=inverse L shaped, 
# Yline= line in Y direction
# Xline= line in X direction
# Box = a square 
# dxy = distance between the plots
# h = add header

version=0.3

# fixed bounding boxing calculation to allow use of degrees




tmpdir=/tmp/OF.gen$$
mkdir $tmpdir
infofile=$tmpdir/info.txt

function calc () {
   awk "BEGIN { print $* ; }"
}

args=$#

if [ $args -ne 4 -a $args -ne 7 ] ; then

echo "Usage: oft-gensyssample.bash <layer> <Dx> <Dy> <h>"
echo "or:"
echo "       oft-gensyssample.bash <layer> <Dx> <Dy> [scheme] [plots] [dxy] [h]"
echo "where:"
echo "layer  = input raster or vector layer from which the" 
echo "         bounding box of the area will be extracted"
echo "Dx     = between cluster distance in X direction"
echo "Dy     = between cluster distance in Y direction"
echo "scheme = clustering scheme. The following schemes are implemented: "
echo "     1 = line in Y direction"
echo "     2 = line in X direction"
echo "     3 = L shaped" 
echo "     4 = inverse L shaped" 
echo "     6 = a square "
echo "plots  = number of plots" 
echo "dxy    = distance between the plots"
echo "h      = print header (1) or not (0)" 

exit

else 


 # check the layer (raster/vector)



    if [ `ogrinfo $1 | grep FAILURE|wc -l` -gt 0 ] ; then
	
	echo "Not an OGR vector layer" 

	if [ `gdalinfo $1 2>&1 | grep ERROR|wc -l` -gt 0 ] ; then  
	    
	    echo "Not a GDAL raster layer"
	    echo "Input layer type not recognized" ;
	    exit;


	else
	    
	    echo "Using GDAL raster layer"
	    gdalinfo $1 > $infofile


	type=1

	if [ `grep -c "UNIT\[\"D" $infofile` -qt 0 ] ; then
	    unit=degrees;
	else
	    unit=meters
	fi

	xmin=`grep "Lower Left" $infofile | awk '{gsub("[,()]"," ") ; print $3}'`
	ymin=`grep "Lower Left" $infofile | awk '{gsub("[,()]"," ") ; print $4}'`

	xmax=`grep "Upper Right" $infofile | awk '{gsub("[,()]"," ") ; print $3}'`
	ymax=`grep "Upper Right" $infofile | awk '{gsub("[,()]"," ") ; print $4}'`

	fi

    else 

	type=2
 
	layer=`basename $1`
	layer=${layer%.*}
	
	ogrinfo $1 $layer |grep -m 1 Extent|awk '{gsub("[,()]","");print $0}'>   $infofile

	if [ `grep -c "UNIT\[\"D" $infofile` -gt 0 ] ; then
	    unit=degrees;
	else
	    unit=meters
	fi

	xmin=`awk '{print $2}' $infofile`
	xmax=`awk '{print $5}' $infofile`
	ymin=`awk '{print $3}' $infofile`
	ymax=`awk '{print $6}' $infofile`

    fi


    echo xmin=$xmin
    echo ymin=$ymin
    echo xmax=$xmax
    echo ymax=$ymax
    
    # compute bounding box

    if [ $unit == "Meters" ]  ; then 

    xmin=`calc "1000 * int($xmin /1000)" `
    ymin=`calc "1000 * int($ymin /1000)" `
    xmax=`calc "1000 * int($xmax /1000 + 0.5" `
    ymax=`calc "1000 * int($ymax /1000 + 0.5" `

    else

    xmin=`calc "int($xmin) - 0.5" `
    ymin=`calc "int($ymin) - 0.5" `
    xmax=`calc "int($xmax) + 0.5" `
    ymax=`calc "int($ymax) + 0.5" `

    fi

    
      echo  "BB " $xmin,$ymin,$xmax,$ymax
  


    id=0;

    plots=$tmpdir/plots.txt

    outfile=$tmpdir/tmp.plot
    
    xadd=$2
    yadd=$3


    if [ $args -eq 4 ] ; then

	header=$4;
	clustype=0
	nbrplots=0
	delta=0
    else
	clustype=$4
	delta=$6
	header=$7;
	nbrplots=$5;

    fi 


    echo "Calling gensam.awk"

    exec 6>&1

    exec > $outfile

    gensam.awk -v header=$header -v xmin=$xmin -v ymin=$ymin -v xmax=$xmax -v ymax=$ymax -v xadd=$xadd -v yadd=$yadd -v clustype=$clustype -v nbrplots=$nbrplots -v delta=$delta 


    
    exec 1>&6 6>&- 


    
    if [ $# -eq 4 ] ; then
	
	out=$1_"0_0_plots"

    else

	out=$1"_"$4"_"$5"_"$6"_plots"
	
    fi
    
    echo $outfile
    echo  $out".txt"
    mv $outfile $out".txt"



fi

    rm -r $tmpdir


