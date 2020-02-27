#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Giuseppe Amatulli
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
# giuseppe.amatulli@gmail.com  18
# calculate the  pearson's coefficient r between two bands
# $1 = input image containing the two bands
# $2 = txt file containing the r coefficent for each class
# $3 = input image containg categories data or mask image.
# 0 considering as no data
# 1 2 3 categories classes
# slightly modified by anssi to check the nbr of input image bands etc

version=1.01

args=$#

if [ $args != 2 -a $args != 3 ] ; then
    echo "Usage $0 <input> <output> [mask]"
    echo "Input has to be an image with 2 band"
    echo "Output is a text file reporting the r for each class"
    exit
elif [ $args -eq 3 ] ; then 
    if [ ! -f $3  ]  ; then 
    echo "Mask file missing"
    exit
else
    UseMask="-um $3"     
   fi
fi

echo "Calculating pearson cofficient for each class using file $1"

if [ -f $3  ]  ; then 
    input=$1
    bands=`gdalinfo $input|grep -c  ^Band" "`
    
    if [ $bands -ne 2 ] ; then

	echo "The input image has to have two bands"
	exit
    fi
else

    echo "File $input does not exist"
fi

	


# force to be Float64 in case of high number. 

oft-calc  -ot Float64 $input  /tmp/tifb1xb2$$.tif  <<EOF
5
#1 #2 *
#1 1 *
#2 1 *
#1 #1 *
#2 #2 *
EOF

oft-stat -i /tmp/tifb1xb2$$.tif   -o /tmp/tifb1xb2$$.txt $UseMask  -nostd &>/dev/null

# formula for the pearson coefficient
# sum obtained usin  average * obs
# print (obs * xysum - xsum * ysum)/((sqrt(obs*x2sum - xsum*xsum)) * (sqrt(obs*y2sum - ysum*ysum)))

#1 = x
#2 = y

#1 #2 *     xysum  $3   no
#1 1 *      xsum   $4   ok 
#2 1 *      ysum   $5   ok 
#1 #1 *     x2sum  $6   no
#2 #2 *     y2sum  $7   no

# in case of using mask as uncillary layers it return the pearson for each class results
# use oft-reclass if you want obtained a map of pearson for each class.

if [ -n "$UseMask"  ] ; then 
    awk '{ print $1 , (($2*$3*$2 - $4*$2*$5*$2))/((sqrt($2*$6*$2 - $4*$2*$4*$2))*(sqrt($2*$7*$2 - $2*$5*$2*$5 )))}' /tmp/tifb1xb2$$.txt > $2
else 
    awk '{ print      (($2*$3*$2 - $4*$2*$5*$2))/((sqrt($2*$6*$2 - $4*$2*$4*$2))*(sqrt($2*$7*$2 - $2*$5*$2*$5 )))}' /tmp/tifb1xb2$$.txt > $2
fi 

rm /tmp/tifb1xb2$$.txt /tmp/tifb1xb2$$.tif




