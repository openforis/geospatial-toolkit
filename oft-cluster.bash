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
# anssi.pekkarinen@fao.org
# Thu May 12 2011
version=1.0 
# Fri Feb 24 2012 RH
# Modified checking of the presence of mask to be done based on nbr of args
version=1.01
#Fri Mar 2 2012 RH 
#Corrected the calculation of density
version=1.02
# Wed Nov 7 2012
# fixed usage information
version=1.03

# added use of gdallocationinfo cause it's faster in this case
version=1.04
# fixed crask in case of too small sample
version=1.05


args=$#

echo "V. "$version

if [ $args -lt 4 ] ; then


    echo "Automated kmeans clustering"
    
    echo "Usage: oft-cluster.bash <input.img> <output.img> <nbr_clusters> <sampling_density%> [mask]"

    exit
else



    gengrid=`which oft-gengrid.bash|wc -l`

    if [ $gengrid -eq 0 ] ; then
	echo "Reguires oft-gengrid.bash"
	echo "Please contact anssi.pekkarinen@fao.org" 
    else


	input=$1
	output=$2
	clusters=$3
	density=$4
#	mask=0;

	if [ $args -eq 5 ] ; then
	    
	    mask=$5
	    echo Using mask $mask

	fi

	tmpfile=$$.xxx

	# study the dimensions and the pixel size of the input

	xsize=`gdalinfo $input |grep "Size is"|awk '{gsub(","," ")  ; print $3}'`
	ysize=`gdalinfo $input |grep "Size is"|awk '{gsub(","," ")  ; print $4}'`

	ps=`gdalinfo $input |grep "Pixel Size"|awk '{gsub("[(,)]"," "); print $4}'` 

	# compute 10% sample

	echo $density
	
#	dx=`awk -v density=$density -v xsize=$xsize -v ps=$ps 'BEGIN{print int((xsize/(xsize/density)) *ps)}'` 
#	dy=`awk -v density=$density -v ysize=$ysize -v ps=$ps 'BEGIN{print int((ysize/(ysize/density)) *ps)}'` 

       dx=`awk -v density=$density -v xsize=$xsize -v ps=$ps 'BEGIN{print int(1/(sqrt(density/100)) *ps)}'`  
       dy=`awk -v density=$density -v ysize=$ysize -v ps=$ps 'BEGIN{print int(1/(sqrt(density/100)) *ps)}'` 

	echo "Using " $dx "m as X sampling interval"
	echo "Using " $dy "m as Y sampling interval"

	echo  oft-gengrid.bash $input $dx $dy /tmp/$tmpfile 

	oft-gengrid.bash $input $dx $dy /tmp/$tmpfile 
	
	lines=$(wc -l /tmp/$tmpfile|awk '{print $1}')

	if [ $lines -lt $clusters ] ; then
	    
	    echo "Your nbr of clusters is larger than nbr of samples"
	    echo "Please increase sampling density"
	    exit
	fi

	echo "$lines $clusters Done"

	#added for speed 2014

	str="";
	

	command -v gdallocationinfo >/dev/null 2>&1

	if [ $? -eq 0 ] ; then
	    

	    bands=$(gdalinfo $input |grep -c ^Band);
	    
	    i=1;

	    while [ $i -le $bands ] ; do 
		
		str+=" -b $i"; 
		i=`expr $i + 1`
	    done	    

	    awk '{print $2,$3}'  /tmp/$tmpfile > /tmp/$tmpfile".2"
	    mv /tmp/$tmpfile".2" /tmp/$tmpfile 
	    gdallocationinfo -valonly -geoloc $str $input < /tmp/$tmpfile|awk -v bands=$bands '{if(NR % bands == 0 ) {i++; str=sprintf("%s %f",str,$1); printf("%i%s\n",i,str); str="";} else {str=sprintf("%s %f",str,$1)} }' >  "/tmp/spec_"$tmpfile ; 

	else


	oft-extr -o "/tmp/spec_"$tmpfile /tmp/$tmpfile  $input<<- EOF
        2
        3
EOF

	fi



#RH 24.2.2012
#	if [ $mask -eq 0 ] ; then 
	 if [ $args -eq 4 ] ; then
	oft-kmeans -ot Byte -oi $output $input<<- EOF
        /tmp/spec_$tmpfile
        $clusters
EOF
	
	else

	oft-kmeans -um $mask -ot Byte -oi $output $input<<- EOF
        /tmp/spec_$tmpfile
        $clusters
EOF

	fi

	rm "/tmp/spec_"$tmpfile /tmp/$tmpfile 
	
	
    fi
fi

	exit

