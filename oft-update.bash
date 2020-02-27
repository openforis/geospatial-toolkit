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

# version 1.1
# changing from Dropbox to fao server

function clean_complete {
    echo "Uninstalling old version"
    oft-uninstall.bash
}



echo "Open Foris Toolkit Download and installation"


bCYGWIN=$(uname -a |grep CYGWIN|wc -l | awk '{print $1}')

if [ $bCYGWIN -eq 0 ] ; then
    if [ $(whoami) == root ] ; then 

        echo "Dowloading and installing new versions of OpenForis Toolkit tools and removing the old ones"
	
    else
        echo "!!!!!!!!!!!!!!!!!!!"
        echo "Please run as root!"
        echo "!!!!!!!!!!!!!!!!!!!"
        exit
    fi

fi

wget --quiet -O /tmp/OF_installer http://foris.fao.org/static/geospatialtoolkit/releases/OpenForisToolkit.run
# http://dl.dropbox.com/u/4143957/OpenForisToolbox/OpenForisToolkit.run
    
if [ -s /tmp/OF_installer  ] ; then 
	
    clean_complete ;

    chmod u+x /tmp/OF_installer
    /tmp/OF_installer
    
    rm /tmp/OF_installer

else

    echo "Problem downloading the installer."

fi


