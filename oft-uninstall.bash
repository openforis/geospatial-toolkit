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

LOG=/tmp/$$
echo "log" > $LOG

bCYGWIN=$(uname -a |grep -e CYGWIN -e MINGW32 |wc -l | awk '{print $1}')

if [ $bCYGWIN -eq 0 ] ; then
    if [ $(whoami) == root ] ; then 

        echo "Installing new versions of OpenForis Toolkit tools and removing the old ones"
	
    else
        echo "!!!!!!!!!!!!!!!!!!!"
        echo "Please run as root!"
        echo "!!!!!!!!!!!!!!!!!!!"
        exit
    fi
else
    echo "Installing new versions of OpenForis Toolkit tools and removing the old ones"
fi

if [ -d ~/.of-toolkit  ] ; then 

    echo "Running..."
    cat  ~/.of-toolkit/installed_scripts.txt >> /tmp/remove
    cat  ~/.of-toolkit/installed_bins.txt >> /tmp/remove
    cat ~/.of-toolkit/installed_licenses.txt >> /tmp/remove
    

###########################################################
    if [ -e /tmp/remove ] ; then

        echo "Uninstalling"
	filelist=`cat /tmp/remove`

	for file in $filelist ; do 
	    echo "Removing "$file
	    if [ -e  $file ] ; then 
	        rm -f $file
		echo "removed $file" >> $LOG
	    fi
	    
	done



    fi
###########################################################
    echo "Open Foris Toolkit Uninstalled"


    echo "Removing log dir" 

    echo $LOG
    rm -rf ~/.of-toolkit/
    rm /tmp/remove

fi