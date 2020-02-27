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
# Wed Nov 7 2012
version=0.1
# A wrapper for oft-imad.py to faclilitate autmated change detection

args=$#


tmpdir=/tmp/$$
mkdir $tmpdir


if [ $args -lt 4 ] ; then

    echo "Usage: oft-chdet.bash <input1> <input2> <output> <nodata_value> [threshold]"
    echo "V. "$version
    exit
else

    echo "oft-chdet.bash - Automatic change detection with imad algorithm"
    echo "V. "$version

    if [  $args -eq 5 ] ; then
	threshold=$5;
    else
	threshold=0.99 ;
    fi

    input1=$1
    input2=$2
    output=$3
    idir=`dirname $output`
    iname=`basename $output`
    nodata=$4

    #extract number of input bands

    bands1=`gdalinfo $input1 |grep -c ^Band`
    bands2=`gdalinfo $input2 |grep -c ^Band`
    
    echo $bands1 input bands in image 1
    echo $bands2 input bands in image 2

   

    if [ $bands1 -ne $bands2 ] ; then 
	
	echo "Different number of bands in input images";
	exit 
    else
	
	imad_band=`expr $bands1 + 1`
	ib=$imad_band
	imad_band="#"$imad_band
	
    fi

    # pre-process to get rid of nodata areas

    equation="";

    for (( i = 1 ; i <= $bands1 ; i++)) ; do

	if [ $i -eq 1 ] ; then
	   equation+="#$i $nodata !"
	else
	    equation+=`echo -e " #$i $nodata ! *"`
	fi

    done

   
oft-calc -ot Byte $input1 $tmpdir/mask1.tif<<EOF
1
${equation}
EOF

oft-calc -ot Byte $input2 $tmpdir/mask2.tif<<EOF
1
${equation}
EOF

# now let us produce a combined mask

oft-stack -ot Byte -o $tmpdir/mask.tif $tmpdir/mask1.tif $tmpdir/mask2.tif
rm $tmpdir/mask2.tif $tmpdir/mask1.tif

oft-calc -ot Byte $tmpdir/mask.tif $tmpdir/tmp.tif<<EOF
1
#1 $nodata ! #2 $nodata ! *
EOF

mv $tmpdir/tmp.tif $tmpdir/mask.tif


# run the imad algorithm 

oft-imad.py $input1 $input2 $tmpdir/tmp.tif $nodata
    
    # compute cumulative histogram
    
    # step 1: take the last channel of the imad output and convert to integer


oft-calc -ot Int32 -um $tmpdir/mask.tif $tmpdir/tmp.tif $tmpdir/tmp2.tif<<EOF
1
$imad_band 10 * 0.5 +
EOF

rm $tmpdir/tmp.tif
mv $tmpdir/tmp2.tif $tmpdir/mad.tif 

# now we need to compute the histogram
# as the chi-square values may be very high
# the oft-his may crash. Therefore, we use a 
# workaround

oft-clump -um $tmpdir/mask.tif $tmpdir/mad.tif $tmpdir/clump.tif
oft-stat  $tmpdir/clump.tif $tmpdir/mad.tif $tmpdir/clumpstat.txt

# now produce a histogram

awk '{his[int($3)]+=$2; sum=sum+$2}END{for(val in his) print val,his[val]/sum}' $tmpdir/clumpstat.txt|sort -n -k1,1| awk '{sum=sum+$2; print $1,sum}' >  $tmpdir/cumhis.txt

# look for the threshold

threshold=`awk -v th=$threshold 'BEGIN{found=0}{if($2 > th && found == 0) { min=$1 ; found = 1 }}END{print min}' $tmpdir/cumhis.txt`

# and produce the output

oft-calc -ot Byte   $tmpdir/mad.tif $output<<EOF
1
#1 $threshold >
EOF

mv $tmpdir/mad.tif $idir/"imad-"$iname

rm -r $tmpdir

fi

