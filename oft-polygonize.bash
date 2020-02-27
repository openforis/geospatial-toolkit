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
# anssi.pekkarinen@fao.org
# Fri Mar 9 2012 AP 
# wrapper for gdal_polygonize to add prj information to the output
# July 9 2013
# removes output if it exists

version=1.1

args=$#

echo "V. "$version
echo "oft-polygonize.bash"
echo "A wrapper for gdal_polygonize"

if [ $args -lt 2 ] ; then

    

    echo "Usage: oft-polygonize <input.img> <output.shp>"
    exit
else

    infile=$1
    outfile=$2

    if [ -e $outfile ] ; then 
	rm $outfile
    fi

    if [ -e $infile ] ; then 

	gdal_polygonize.py -f "Esri Shapefile" $1 $2 	
	prjfile=${outfile%.*}
	gdalsrsinfo -o esri $infile | grep -v ESRI > $prjfile".prj"
    else
	echo "Input file does not exist"
	exit
    fi


fi