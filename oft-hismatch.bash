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
# $2 = reference miage
# $3 = output image

version=1.00

# Sample based histogram matching

args=$#
tmpfile=$$

minval=0
maxval=100000
band=0


if [ $args != 3 -a  $args != 6 ] ; then
    echo "Version $version"
    echo "Usage oft-hismatch.bash <input> <reference>  <output> [minval] [maxval] [band]"
    exit
else
    
    if [ -e $1 -a -e $2 ] ; then 
	input=$1
	reference=$2
	output=$3
	tmpdir=/tmp/$$
	mkdir $tmpdir
	
	if [ $args -eq 6 ] ; then
	    
	    echo "Using min and max value parameters"
	    minval=$4
	    maxval=$5
	    band=$6
	    
	fi

    else
	echo "One of the input files is missing"
	exit
    fi

fi

# let us generate a sample for both images, input and reference
# lets use ~ 5% sample in x and Y directions
# i.e. we want to sample every xsize/(0.1 x xsize) pixels in x dir
# 

i=0

for image in $input $reference ; do
    
    echo "processing "$image
    
    i=`expr $i + 1`

    gdalinfo $image > $tmpdir/info
    head  $tmpdir/info

    xsize=`grep "Size is" $tmpdir/info|awk '{gsub(","," ")  ; print $3}'`
    ysize=`grep "Size is" $tmpdir/info|awk '{gsub(","," ")  ; print $4}'`
    ps=`grep "Pixel Size" $tmpdir/info|awk '{gsub("[(,)]"," "); print $4}'` 

    bands[$i]=`grep ^Band $tmpdir/info|wc -l`

    echo $xsize,$ysize,$ps

    dx=`awk -v xsize=$xsize -v ps=$ps 'BEGIN{print int(xsize/(0.05 * xsize) * ps)}'` 
    dy=`awk -v ysize=$ysize -v ps=$ps 'BEGIN{print int(ysize/(0.05 * ysize) * ps)}'`

    oft-gengrid.bash $image $dx $dy $tmpdir/$i".txt"

oft-extr -ws 1 -o $tmpdir/$i"out.txt" $tmpdir/$i".txt" $image <<-EOF
2
3
EOF

done    


# now, let us compute cumulative histograms
# we assume that the range is similar in both images
# and that the number of bands is the same ... maybe we should

if [ ${bands[1]} -ne ${bands[2]} ] ; then

    echo "Different number of bands in input and reference"
    exit

else

    # compute cumulative histograms for all bands
    # the data starts from col 6
    
    # clear the data from zeros and compute cumulative histograms lookup
    

    

    oft-cumhis.awk -v minval=$minval -v maxval=$maxval -v band=$band  $tmpdir/1"out.txt" > $tmpdir/1.txt
    oft-cumhis.awk -v minval=$minval -v maxval=$maxval -v band=$band  $tmpdir/2"out.txt" > $tmpdir/2.txt

    # now we have two output files with the cumulative histograms
    # let us use that information to compute a lookup table 
    
    echo  $tmpdir/2.txt  $tmpdir/1.txt

    head  $tmpdir/2.txt  $tmpdir/1.txt
    
    oft-hislookup.awk  $tmpdir/2.txt  $tmpdir/1.txt > $tmpdir/lookup.txt
    
    echo "oft-reclass -oi $output $input<<EOF" > $tmpdir/param.txt
    echo "$tmpdir/lookup.txt" >> $tmpdir/param.txt
    echo "1" >> $tmpdir/param.txt
    echo "1" >> $tmpdir/param.txt
    for((i=1; i<=${bands[1]} ; i++)) ; do
	echo `expr $i + 1` >> $tmpdir/param.txt
    done
    echo "0" >> $tmpdir/param.txt
    echo "EOF">> $tmpdir/param.txt

    bash $tmpdir/param.txt
    cp $tmpdir/lookup.txt "LUT_"$input

    rm -r $tmpdir

    

    
fi

exit
