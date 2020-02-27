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
# 16 April 2013
version=0.1

# This script generates oft-reclassification file.

args=$#
remainder=`expr $args % 3`
argv=($@)

if [ $args -lt 3 -o $remainder -ne 0 ] ; then
echo "oft-genreclass.bash version "$version
echo "Usage: oft-genreclass.bash <start> <end> <value> ..."

else

for (( i=0 ; i < $args ;i = i + 3)) ; do
    start=${argv[$i]}
    end=${argv[$((i+1))]}


 for (( j=$start ; j<= $end ; j++)) ; do
   out=${argv[$((i+2))]}
   echo $j" "$out
   
 done
done  

fi





