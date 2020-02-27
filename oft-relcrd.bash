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
# $1 = input image
# $2 = output image


version=1.01

# compute relative pixels coordinates within the image
# fixed error in checking the nbr of arguments (Thanks Giuseppe!)


args=$#


if [ $args -ne 2 ] ; then

    echo "Usage oft-relcrd.bash <input> <output>"
    exit

else 

tmpfile=$$

minval=0

tmp=/tmp/$$
gdalinfo $1 > $tmp
sed s/[,\(\)]/" "/g $tmp > $tmp"2"
mv $tmp"2" $tmp

xc=`grep Center $tmp|awk '{print $2}'`
yc=`grep Center $tmp|awk '{print $3}'`
xmin=`grep "Lower Left" $tmp| awk '{print $3}'`
ymin=`grep "Lower Left" $tmp| awk '{print $4}'`
ps=`grep "Pixel" $tmp| awk '{print $4}'`

cenx=`awk -v xc=$xc -v xmin=$xmin -v ps=$ps 'BEGIN{print (xc-xmin)/ps}'`
ceny=`awk -v yc=$yc -v ymin=$ymin -v ps=$ps 'BEGIN{print (yc-ymin)/ps}'`

echo "Cenx "$cenx" Ceny "$ceny
echo "XC "$xc YC ""$yc
echo "xmin "$xmin" ymin "$ymin

oft-calc -ot Int16 $1 $2<<EOF
2
c $cenx -
r $ceny -
EOF

fi