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

echo "Open Foris Toolkit info"

if [ -d  ~/.of-toolkit/ ] ; then

echo -n "Version "

grep "Open.*Toolkit" ~/.of-toolkit/log*|awk '{print $4}'

wget --quiet -O /tmp/versioninfo  http://foris.fao.org/static/geospatialtoolkit/releases/versioninfo

lines=`wc -l /tmp/versioninfo|awk '{print $1}'`

if [ $lines -gt 0 ] ; then

newversion=`cat /tmp/versioninfo`

echo "Latest version is $newversion and available from" 
echo "http://foris.fao.org/static/geospatialtoolkit/releases/OpenForisToolkit.run"
echo "You can download and install it with command:"
echo "oft-update.bash" 

fi

else

echo "Open Foris Toolkit has not been installed"

fi


