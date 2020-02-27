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
#  May 26 2014
version=1.0 

args=$#
argv=($@)





if [ $args -lt 1 -o $args -gt 5 ] ; then

    echo "Extent coordinate parser for images"
    echo "V. "$version
    echo "Usage: oft-crdparse.bash <input.img> [xmin] [ymin] [xmax] [ymax]"

    exit

else

    file=$1

    gdalinfo $file > /dev/null 2>&1;

    if [ $? -eq 0 ] ; then

    xmin=`gdalinfo $file |grep "Upper Left"|awk '{gsub("[,()]"," ");print $3}'`
    ymax=`gdalinfo $file |grep "Upper Left"|awk '{gsub("[,()]"," ");print $4}'`
    
    xmax=`gdalinfo $file |grep "Lower Right"|awk '{gsub("[,()]"," "); print $3}'` 
    ymin=`gdalinfo $file |grep "Lower Right"|awk '{gsub("[,()]"," "); print $4}'` 

    if [ $args -eq 1 ] ; then

	echo $xmin $ymax $xmax $ymin

    else
	
	i=1 
	par="-n"


	while [ $i -lt $args ] ; do

	    
	    if [ $i -eq $(expr $args - 1) ] ; then 
		par="";
	    fi

	    
	    if [ ${argv[$i]} = 'xmin' ] ; then
		echo $par " $xmin" ;
	    elif [ ${argv[$i]} = 'xmax' ] ; then
		echo $par " $xmax" ;
	    elif [ ${argv[$i]} = 'ymin' ] ; then
		echo $par " $ymin" ;
	    elif [ ${argv[$i]} = 'ymax' ] ; then
		echo $par " $ymax" ;
	    fi
	    
	    i=`expr $i + 1` ;
	done
    fi

    else 

	echo "Did not recognize input image format"
	exit 1
    fi
fi
