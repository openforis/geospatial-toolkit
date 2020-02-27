#Copyright (C) 2014 
#Food and Agriculture Orgazization of the United Nations
#and the following contributing authors:
#
#Reija Haapanen
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
# changes Oct 4 2012 AP
# generalized version of stack.bash
# the input folder MUST be given
version=1.00 
# RH on Mar 3 2013:
# Removed the Capital L search completely
# because the input folder must be given
# and also added check for args = 1

args=$#
#indirs="L*"
outdir=ledaps_stack
tmpdir=/tmp/$$
mkdir $tmpdir 

echo "Extract reclective and thermal bands from LEDAPS hdf file and"
echo "build a HFA stack with OGC SRS" 

echo "V. "$version
 
OGCDIR=~/ogcwkt 

if [ ! -d $OGCDIR ] ; then

    echo "ogcwkt srs definitions not available"
    echo "using best-guess method"
    echo "please report to anssi.pekkarinen@fao.org"
fi

if [ $args -eq 1 ] ; then  
    
    indirs=$1
    echo "Processing files in folder $indirs"
    echo "and writing outputs to folder $outdir"

elif [ $args -eq 2 ] ; then  
    
    indirs=$1
    outdir=$2
    echo "Processing files in folder $indirs"
    echo "and writing outputs to folder $outdir"

elif [ $args -eq 3 ] ; then  

    indirs=$1
    outdir=$2
        
    echo "Processing files in folder $indirs"
    echo "and writing outputs to folder $outdir"
    echo "using $3 m pixel size"
    
    resolution="-ps $3 $3"

elif [ $args -eq 0 ] ; then

    echo "No command line arguments given"
    echo "Usage: oft-ledapsstack.bash <input_folder> [output_folder] [resolution]"
    exit

 
else

    echo "Usage: oft-ledapsstack.bash <input_folder> [output_folder] [resolution]"

   
fi

# create the output dir if not existing

if [ ! -d $outdir ] ; then
    echo "Creating $outdir"
    mkdir $outdir
else
    echo "$outdir exists"
fi

echo processing $indirs

    name=`basename $indirs`

    if [ -d $indirs ] ; then

	srfile=`find -L $indirs -name 'lndsr*.hdf'`
	
	header=$srfile".hdr"
	
	thfile=`find -L $indirs -name 'lndth*.hdf'`
	
	
# echo $srfile

	trunk=`gdalinfo $srfile|grep band|head -1`
	
	trunk=${trunk:20}
	trunk=${trunk%%band*}
	

# parse projection information from the ENVI header file


	datum=`grep 'map info' $header|awk '{gsub("[,{}=]"," "); gsub("-",""); print $12}'`
	proj=`grep 'map info' $header|awk '{gsub("[,{}=]"," "); print $3}'`
	zone=`grep 'map info' $header|awk '{gsub("[,{}=]"," "); print $10}'`
	hemi=`grep North $header|wc -l`

	bands=`gdalinfo $srfile|grep "Grid:band[1234567]"|wc -l` 


	if [ $hemi -gt 0 ] ; then 
	    hemi=north
	else 
	    hemi=south
	fi


	echo "Input has $bands bands"
	echo "Using following map projection:"
	echo "datum: $datum"
	
	echo "proj: $proj"
	echo "zone: $zone $hemi"


	if [ $hemi = "south" ] ; then
	    shorthemi=S
	else
	    shorthemi=N
	fi


	ogcfile=$OGCDIR/$datum"_"$proj"_"$zone$shorthemi".ogcwkt"

	if [ $bands -eq 7 ] ; then 

	    
	    if [ ! -e $ogcfile ] ; then 

		echo "ALERT! $ogsfile not available. Using best-guess method"

		for band in 1 2 3 4 5 6 7  ; do
		
		    gdal_translate  -a_srs "+proj=$proj +zone=$zone +ellps=$datum +datum=$datum +$hemi" -of HFA $trunk"band"$band $tmpdir/$band.img
		
		done

		echo "Extracting QA"
		gdal_translate  -a_srs "+proj=$proj +zone=$zone +ellps=$datum +datum=$datum +$hemi" -of HFA $trunk"lndsr_QA" $tmpdir/QA.img
		
oft-calc  -ot Byte  $tmpdir/QA.img $outdir/$name"_QA.img"<<EOF
1
1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + < 2 1 ? 1 ?
EOF


	    else

		echo "Using $ogcfile"
		
		for band in 1 2 3 4 5 6 7  ; do
		
		    gdal_translate -a_srs $ogcfile -of HFA $trunk"band"$band $tmpdir/$band.img
		
		done
	    fi

	    echo "Extracting QA"
	    gdal_translate -a_srs $ogcfile -of HFA $trunk"lndsr_QA" $tmpdir/QA.img

oft-calc  -ot Byte  $tmpdir/QA.img $outdir/$name"_QA.img"<<EOF
1
1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + < 2 1 ? 1 ?
EOF

	else

	    if [ ! -e $ogcfile ] ; then 
	    
	
		echo "ALERT! $ogsfile not available. Using best-guess method"

		for band in 1 2 3 4 5 7  ; do
	    
		    gdal_translate  -a_srs "+proj=$proj +zone=$zone +datum=$datum +$hemi" -of HFA $trunk"band"$band $tmpdir/$band.img

		done

		gdal_translate  -a_srs "+proj=$proj +zone=$zone +datum=$datum +$hemi" -of HFA $thfile $tmpdir/6.img

		echo "Extracting QA"
		gdal_translate  -a_srs "+proj=$proj +zone=$zone +ellps=$datum +datum=$datum +$hemi" -of HFA $trunk"lndsr_QA" $tmpdir/QA.img
		
oft-calc -ot Byte  $tmpdir/QA.img $outdir/$name"_QA.img"<<EOF
1
1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + < 2 1 ? 1 ?
EOF
	

	    else
		
		echo "Using $ogcfile"

		for band in 1 2 3 4 5 7  ; do
	    
		    gdal_translate -a_srs $ogcfile -of HFA $trunk"band"$band $tmpdir/$band.img

		done

		gdal_translate -a_srs $ogcfile -of HFA $thfile $tmpdir/6.img
	
		echo "Extracting QA"	
		gdal_translate -a_srs $ogcfile -of HFA $trunk"lndsr_QA" $tmpdir/QA.img

oft-calc -ot Byte $tmpdir/QA.img $outdir/$name"_QA.img"<<EOF
1
1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + < 2 1 ? 1 ?
EOF

	    fi


	fi



	gdal_merge.py $resolution -of HFA -separate -o $tmpdir/stack.img $tmpdir/[1234567].img

	rm $tmpdir/[1234567].img

	csmfile=`find -L $indirs -name 'lndcsm*.hdf'`

	if [ ! -e $ogcfile ] ; then 

	    echo "ALERT! $ogsfile not available. Using best-guess method"

	    gdal_translate -a_srs "+proj=$proj +zone=$zone +ellps=$datum +datum=$datum +$hemi" -of HFA $csmfile $tmpdir/cm.img

	else

	    echo "Using $ogcfile"

	    gdal_translate -a_srs $ogcfile -of HFA $csmfile $tmpdir/cm.img


  
	fi



	mv $tmpdir/stack.img  $outdir/$name"_stack.img"
	
	rm $tmpdir/[1234567].img*

	mv $tmpdir/cm.img $outdir/$name"_cm.img"

	rm -r $tmpdir

    fi

