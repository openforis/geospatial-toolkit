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
# Compute segment majority value image
# Requires input and mask to be of Int data type
# Anssi Pekkarinen 20 Apr 2012


version=1.00
version=1.01
# changed gdalinfo -stat to oft-mm because gdalinfo does not take into account nodata val
version=1.02
# added multi-channel functionality
version=1.03
# fixed bug in min calculation and
# added possibility to produce output with negative modes



echo "V. "$version

#$1 mask 
#$2 input 
#$3 output

## create temp file names

tmpfile=/tmp/$$
runme=/tmp/$$.bash

## total nbr of args

args=$#



#Checks

if [ $args != 3 ] ; then
    echo "Usage: oft-segmode.bash <mask> <input> <output>"
    exit
fi

if [ ! -f $1 ] ; then
    echo "Mask $1 image not found"
    exit
fi

if [ ! -f $2 ] ; then
    echo "Input $2 not found"
    exit
else
    bands=`gdalinfo $2|grep Band|wc -l`
fi



# Data type on input has to be int. Make sure that it is
# possible types are
# Int16
# UInt16
# UInt32
# Int32
# CInt16
# CInt32
# Byte

Int=0;
Int=`gdalinfo $1|grep "Int[13]\|Byte"|wc -l`

if [ $Int -eq 0 ] ; then
    
    echo "Input is not of Int data type"
    exit
else

# look for min val and scale if it is < 0. Scaling is done by adding absolute value


    min=`oft-mm $2 | grep Band|awk '{if(NR == 1 ) min = $5 ; else if($5 < min) min=$5}END{if( min < 0 ) print sqrt(min * min) ; else print 0}'`
    
 # if minimum value is positive that means that the original min value was negative
 # let's scale the output

    if [ $min -gt 0 ] ; then

	optfile=$$
	
	# write oft-calc equations to optfile

	echo $bands > /tmp/$optfile

	
	for (( i=1 ; i <= $bands ; i++ )) ; do
	    echo "#$i $min +" >> /tmp/$optfile
	done

	echo "================================="
	cat /tmp/$optfile
	echo "================================="


	infile=/tmp/$optfile".tif"
	oft-calc -ot Int16 $2 $infile < /tmp/$optfile
	
    else
	
	infile=$2

    fi
fi





# Compute segment level majority value

# get the max input val for infile 

max=`oft-mm  $infile |grep "max ="| sort -n -k5,5 |tail -1 |awk '{print int($5) + 1}'`

# check type

type=`gdalinfo $infile |grep Type|head -1|sed s/[=,]/' '/g|awk '{print $6}'`

echo "TYPE *** $type"

# bands

bands=`gdalinfo $2 | grep Band|tail -1|awk '{print $2}'`

echo "Computing modes for $bands bands"

echo "Largest hist val is " $max

echo oft-his $1 $infile $tmpfile $max

oft-his -compact $1 $infile $tmpfile<<EOF
$max
EOF


echo "====================================="
echo  $tmpfile
echo "====================================="

# now max becomes max segment id

max=`tail -1 $tmpfile|awk '{print $1}'`

# compute the mode for every band using the oft-his output

if [ $infile == $2 ] ; then
awk -v max=$max -v bands=$bands '{SegBand=$1"_"$3; mode[SegBand]=0; for(i=4 ; i<=NF ; i=i+2) if($(i+1) > mode[SegBand]) {mode[SegBand]=$(i+1); val[SegBand]=$i}}END{for(obs=1; obs<= max ; obs++) {printf("%i",obs); for(band=1; band<= bands ; band++) {SegBand=obs"_"band; printf(" %f",val[SegBand])}; printf("\n")}}' $tmpfile > $tmpfile"_2"
else
awk -v min=$min -v max=$max -v bands=$bands '{SegBand=$1"_"$3; mode[SegBand]=0; for(i=4 ; i<=NF ; i=i+2) if($(i+1) > mode[SegBand]) {mode[SegBand]=$(i+1); val[SegBand]=$i}}END{for(obs=1; obs<= max ; obs++) {printf("%i",obs); for(band=1; band<= bands ; band++) {SegBand=obs"_"band; printf(" %f",val[SegBand]-min)}; printf("\n")}}' $tmpfile > $tmpfile"_2"
fi


mv $tmpfile"_2" $tmpfile  



awk '{print $1,int($2 + 0.5)}' $tmpfile > $3.txt



# create a temp script for output image creation

echo "oft-reclass -ot $type -oi $tmpfile"_2" $1<<EOF" > $runme
echo $tmpfile >> $runme
echo $bands >> $runme
echo "1" >> $runme
for ((i=1 ; i<= "$bands" ; i++)) ; do
echo `expr $i + 1` >> $runme
done
echo 0 >> $runme
echo EOF >> $runme

# run the script

bash $runme

mv  $tmpfile"_2" $3
rm $runme
rm $tmpfile   
echo "Done" 
