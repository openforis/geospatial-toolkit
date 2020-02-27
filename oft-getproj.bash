#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Reija Haapanen
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
# script to fetch projection information from spatialreference.org
# anssi.pekkarinen@fao.org
# 12 May 2011
# Version 1.0  
# Version 1.1
# added shebang in the beginning of the file  
# added version number printing
# 7 Jun 2011
# Version 1.11
# fixed downloading in home dir
# added listing of existing files
version=1.11
# 4 Nov 2011
# Modified to download user-defined UTM zones (and nothing as default)
# Reija Haapanen
version=1.12
# 19 Sep 2012
# Anssi
# Fixed usage function to echo the name of the script
#RH on 16.1.2013: AP has started some -proj modifications in .new version
#These are to be moved here after they work properly
echo "Downloads projection information from spatialreference.org based on user-defined zones"

echo "V. "$version

# $1 = list of zones

args=$#
#Some checks 
if [ $args -lt 1 ] ; then

    echo "Usage: oft-getproj.bash <list of UTM zones separated with space>"
    echo "Example: oft-getproj.bash 21N 22N 23N 24N"
exit
fi

if [ ! -d ~/ogcwkt ] ; then
    echo "Creating ~/ogcwkt directory"
    echo "and fetching projection definition files"
 
    mkdir ~/ogcwkt
else
    echo "updating existing ~/ogcwkt directory"

fi
    trunk=http://spatialreference.org/ref/epsg

args=("$@")

#echo $@

echo Number of zones passed: $#


# UTM North starts with 326

# UTM South starts with 327

for (( i=0; i<$#; i++ )) ; do
zonehemi=${args[i]}

#Separate zone and hemisphere
zone=${zonehemi:0:2}
hemi=${zonehemi:2}

echo $zone
echo $hemi

if [ $hemi = "N" ] ; then 

	wget $trunk"/326"$zone"/ogcwkt/" --output-document=ogcwkt.tmp

	awk '{line=$0; gsub("[\"]"," ",line) ; split(line,words); print $0 > sprintf("%s%s_%s_%s.ogcwkt",words[2],words[3],words[5],words[7])}' ogcwkt.tmp
	rm ogcwkt.tmp
        mv *.ogcwkt ~/ogcwkt
fi

if [ $hemi = "S" ] ; then
	wget $trunk"/327"$zone"/ogcwkt/" --output-document=ogcwkt.tmp

	awk '{line=$0; gsub("[\"]"," ",line) ; split(line,words); print $0 > sprintf("%s%s_%s_%s.ogcwkt",words[2],words[3],words[5],words[7])}' ogcwkt.tmp
	rm ogcwkt.tmp
	mv *.ogcwkt ~/ogcwkt
fi

    done

    echo "Done"
    echo "See ~/ogcwkt for available projections"

