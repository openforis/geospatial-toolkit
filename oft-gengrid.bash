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
# Thu May 12 2011
version=1.1 
# Tue Nov 29 2012
# fixed Usage
# Wed 11 dec 2013, Curitiba, Brazil
# Fixed the extent

args=$#

if [ $args != 4 ] ; then
    echo "Point grid builder"
    echo "Version $version Thu May 12 2011"
    echo "Usage: oft-gengrid.bash  <inputimg> <DX> <DY> <outfile>"
    echo "Where: <inputimg> is a georeferenced input image"
    echo "       <DX> distance between the points in X direction"
    echo "       <DY> distance between the points in Y direction"

elif [ ! -e $1 ] ; then 
    echo "Inputs parameters must be an image"

elif [ -e $4 ] ; then
    echo output file exists. Exiting;
    exit
else

for file in $1  ; do

n=`expr $n + 1`

xmin=`gdalinfo $file |grep "Upper Left"|awk '{gsub("[,()]"," ");print $3}'`
ymax=`gdalinfo $file |grep "Upper Left"|awk '{gsub("[,()]"," ");print $4}'`

xmax=`gdalinfo $file |grep "Lower Right"|awk '{gsub("[,()]"," "); print $3}'` 
ymin=`gdalinfo $file |grep "Lower Right"|awk '{gsub("[,()]"," "); print $4}'` 

xsize=`gdalinfo $file |grep "Size is"|awk '{gsub(","," ")  ; print $3}'`
ysize=`gdalinfo $file |grep "Size is"|awk '{gsub(","," ")  ; print $4}'`

ps=`gdalinfo $file |grep "Pixel Size"|awk '{gsub("[(,)]"," "); print $4}'` 

done

# step = dim / inc
# start = min + inc / 2

awk  -v xinc=$2 -v yinc=$3 -v xmin=$xmin -v xmax=$xmax -v ymin=$ymin -v ymax=$ymax \
'BEGIN{ stepx= xdim/xinc ; stepy = ydim /yinc ; startx=xmin + xinc/2 ;starty= ymin+yinc/2 ; for (x=startx ; x <= xmax  ; x = x + xinc ){\
  for (y=starty ; y <= ymax  ; y = y + yinc){\
    n++; printf("%i %f %f\n",n,x,y);\
    }}}' > $4



fi

