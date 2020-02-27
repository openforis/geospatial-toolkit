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

#This script uses two LEDAPS processed inputs to compute a mask (.img) for the oft-gapfill.
#The inputs are given as directory names, containing the HDF files. 
#The ouput name is given by the program: mask_input1.img.
#The script also trims the mask so that the image margins (= no image values) are excluded.
#The output values are: 
# 1 = fill these pixels (unusable data in anchor, good data in filler) 
# 2 = collect training data for regression model (good data in both images) 
# 3 = do nothing, i.e., use the original values (2 cases: good in anchor, bad in filler OR non-good in both i$
# 0 = do nothing (image margins)
#Band4 of the LEDAPS corrected images ís used in the trimming phase 
#and the QA_layer (band 8) for extracting the cloud, shadow and gap info.
# $1 = input1 LEDAPS folder
# $2 = input2 LEDAPS folder

version=1.00
version=1.01
# changes
# add coordinate information
# Tue Jun 7 2011
version=1.02
# changes output mask values. In case both input masks indicate clouds
# value 3 will be written in the output. 
# TODO trim with band 4 instead of QA layer
version=1.03
# trimming with band 4
version=1.04
# now you can use symbolic links as inputs
version=1.05
# check that inputs exist
version=2.00
# added possibility to mask only one image
# added info in the beginning
# given a new name, instead the onder trim_mask.bash
# RH 27.3.2012
version=2.01
# added creation of another mask where water areas have been removed from model data
# based on red/swir-relations
# RH 12.4.2012
version=2.02
# Added -inv to oft-calc due to change in the method
# AP May 2012
version=2.03
# added option to NOT trim the image
# RH 10.5.2012, based on idea by Cesar C.
# in this option, only the QA layer is used, not band 4.
# also removed the water-mask based on red/swir as ledaps QA land-mask does pretty much same
# (idea was used by Cesar C). This removes gap pixels from band 6 (those differing from B4) as well,
# which is good.
# also removed the oft-calc -inv options from some locations, some are pending
# also renamed the 2 image output to contain both input image names

OGCDIR=~/ogcwkt 

if [ ! -d $OGCDIR ] ; then

    echo "ogcwkt srs definitions not available"
    echo "using best-guess method"
    echo "you may obtain them by running oft-getprojdef.bash"

fi


#Step 1: look for input hdf's

args=$#

if [ $args != 1 -a $args != 2 -a $args != 3 ] ; then
    echo "Version $version"
    echo "Usage: oft-mask.bash <input1> <input2> [-notrim]"
    echo "or"
    echo "Usage: oft-mask.bash <input1> [-notrim]"
exit
fi

if [ ! -d $1 ] ; then

	echo "Input1 is not a directory"

	exit
else 

	input1=`find -L $1 -name 'lndsr*.hdf'`

	echo Input1 $input1

	band[1]=`gdalinfo $input1| grep "Grid:band4"`

#parse
	band[1]=${band[1]#*NAME=}

# collect coordinate information 

	    header[1]=$input1".hdr"

fi

if [ $args -gt 1 -a `echo $2|grep notrim|wc -l` -eq 0 ]; then

	if [ ! -d $2 ] ; then

	echo "Input2 is not a directory"
	
	exit

	else 

	input2=`find -L $2 -name 'lndsr*.hdf'`

	echo Input2 $input2

	band[2]=`gdalinfo $input2| grep "Grid:band4"`
#parse

	 band[2]=${band[2]#*NAME=}

# collect coordinate information 
	 
	header[2]=$input2".hdr"
fi
fi


if [ `echo $@|grep notrim|wc -l` -ne 0 ]; then

 echo "No trimming to be carried out"

#Start calculations without trimming

#Go only up to args  minus 1 (i.e. < args) bcs we know that the last is -notrim option

for (( i=1; i<$args; i++ )) ; do
	
if [ $i -eq 1 ] ; then

input=`echo $input1`
else 
input=`echo $input2`
fi

band=`gdalinfo $input| grep "Grid:lndsr_QA"`

band=${band#*NAME=}

#Surface reflectance bit packed QA flags are
#          0     unused
#          1     valid data (0=yes, 1=no)
#          2     ACCA cloud bit (1=cloudy, 0=clear)
#          3     unused
#          4     ACCA snow mask
#          5     land mask based on DEM (1=land, 0=water)
#          6     DDV
#          7     unused
#          8     internal cloud mask (1=cloudy, 0=clear)
#          9     cloud shadow
#          10    snow mask
#          11    land/water mask based on spectral test
#          12    adjacent cloud
#          13-15 unused

#Do not know if -inv is needed, to be checked RH 10.5.2012
oft-calc -inv -ot Byte $band tmp$i<<EOF
1
11 #1 B 0 = 1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ? 1 ?
EOF

#Suggestion by CC:
#11 #1 B 0 = 1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ? 1 ?
#Original by AP:
#1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ?

done

if [ $args -eq 3 ] ; then

# Merge the masks and compute the final common mask.

gdal_merge.py -of HFA -separate -o mask.img tmp1 tmp2

rm tmp1 tmp2

#-inv not needed
oft-calc -ot Byte -um mask.img mask.img maskfinal.img<<EOF
1
#1 2 = #2 2 = * #1 1 = 3 #2 1 = 1 3 ? ? 2 ?
EOF

rm mask.img

mv maskfinal.img "mask_"$1"_"$2".img"

else

mv tmp1 "mask_"$1".img"


fi


exit

else

    for (( i=1; i<=$args; i++ )) ; do
	
	echo ${header[$i]}
	
    datum=`grep 'map info' ${header[$i]}|awk '{gsub("[,{}=]"," "); gsub("-",""); print $12}'`
    proj=`grep 'map info' ${header[$i]}|awk '{gsub("[,{}=]"," "); print $3}'`
    zone=`grep 'map info' ${header[$i]}|awk '{gsub("[,{}=]"," "); print $10}'`
    hemi=`grep North ${header[$i]}|wc -l`

    if [ $hemi -gt 0 ] ; then 
	hemi=north
    else 
	hemi=south
    fi

    if [ $hemi = "south" ] ; then
	shorthemi=S
    else
	shorthemi=N
    fi

    ogcfile=$OGCDIR/$datum"_"$proj"_"$zone$shorthemi".ogcwkt"


    echo "Using following map projection for file $i:"
    echo "datum: $datum"
    echo "proj: $proj"
    echo "zone: $zone$shorthemi"

       echo $ogcfile

    if [ ! -e $ogcfile ] ; then 

        echo "ALERT! $ogsfile not available. Using best-guess method"

        gdal_translate -a_srs "+proj=proj +zone=$zone +ellps=$datum +datum=$datum +$hemi" -outsize 10% 10% ${band[$i]} tmp

    else

        echo Using:
        echo $ogcfile

        gdal_translate -a_srs $ogcfile -outsize 10% 10% ${band[$i]} tmp

    fi

#no need for -inv option, RH 9.5.2012
oft-calc -ot Byte tmp mask<<EOF
1
#1 -9999 !
EOF

oft-trim -ot Byte -ws 3 mask tmp
oft-trim -ot Byte -ws 3 tmp mask
oft-shrink -ot Byte -ws 21 mask tmp
mv tmp mask


if [ $i -eq 1 ] ; then
	input=`echo $input1`
else 
	input=`echo $input2`
fi

band=`gdalinfo $input| grep "Grid:lndsr_QA"`

band=${band#*NAME=}

xmin=`gdalinfo $band |grep "Upper Left"|awk '{gsub("[,()]"," ");print $3}'`
ymax=`gdalinfo $band |grep "Upper Left"|awk '{gsub("[,()]"," ");print $4}'`

xmax=`gdalinfo $band |grep "Lower Right"|awk '{gsub("[,()]"," "); print $3}'` 
ymin=`gdalinfo $band |grep "Lower Right"|awk '{gsub("[,()]"," "); print $4}'` 

xsize=`gdalinfo $band |grep "Size is"|awk '{gsub(","," ")  ; print $3}'`
ysize=`gdalinfo $band |grep "Size is"|awk '{gsub(","," ")  ; print $4}'`

ps=`gdalinfo $band |grep "Pixel Size"|awk '{gsub("[(,)]"," "); print $4}'` 

echo outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin

gdal_translate -outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin mask tmp

mv tmp mask


# Output a mask with values 0, 1, 2 and 3
# 1 for filling
# 2 for training data collection
# 3 for other
# 0 for background

#Changed to the version with land-mask by CC, RH 10.5.2012
#Not sure if -inv is needed, to be checked and changed later, RH 9.5.2012
oft-calc -inv -ot Byte -um mask $band tmp$i<<EOF
1
11 #1 B 0 = 1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ? 1 ?
EOF

rm mask

done


if [ $args -eq 2 ] ; then

# Merge the masks and compute the final common mask.

gdal_merge.py -of HFA -separate -o mask.img tmp1 tmp2

#No need for -inv option, Rh 9.5.2012
oft-calc -ot Byte -um mask.img mask.img maskfinal.img<<EOF
1
#1 2 = #2 2 = * #1 1 = 3 #2 1 = 1 3 ? ? 2 ?
EOF

rm tmp1 tmp2 mask.img

mv maskfinal.img "mask_"$1"_"$2".img"

else

mv tmp1 "mask_"$1".img"

fi

fi
