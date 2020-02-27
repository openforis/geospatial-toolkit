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

#This script uses two LEDAPS processed inputs to compute a 14-band image stack for the oft-gapfill.
#It also creates a mask for the same procedure
#The inputs are given as directory names, containing the HDF files. 
#The image and mask names are is given by the program: 
#stack_input1_input2.img and mask_input1_input2.img
#The script also trims the mask so that the image margins (= no image values) are excluded.
#The output values are: 
# 1 = fill these pixels (unusable data in anchor, good data in filler) 
# 2 = collect training data for regression model (good data in both images) 
# 3 = do nothing, i.e., use the original values (2 cases: good in anchor, bad in filler OR non-good in both images) 
# 0 = do nothing (image margins)
#Band4 of the LEDAPS corrected images ís used in the trimming phase 
#and the QA_layer (band 8) for extracting the cloud, shadow and gap info.
#Script is based on two older scripts: stack2images_hdf.bash and trim_mask.bash

# $1 = input1 LEDAPS folder
# $2 = input2 LEDAPS folder
# RH 27.3.2012
version=1.00
# Added -inv to oft-calc due to change in the method
# AP May 2012
version=1.01
# added option to NOT trim the images
# RH 3.6.2012, based on idea by Cesar C.
# in this option, only the QA layer is used, not band 4.
# also added removal of water pixels based on ledaps QA land-mask
# (idea was used by Cesar C). This removes gap pixels from band 6 (those differing from B4) as well,
# which is good.
# also removed the oft-calc -inv options from some locations, some are pending


OGCDIR=~/ogcwkt 

if [ ! -d $OGCDIR ] ; then

    echo "ogcwkt srs definitions not available"
    echo "using best-guess method"
    echo "you may obtain them using oft-getprojdef.bash"

fi

args=$#

if [ $args != 2 -a $args != 3 ] ; then
    echo "Version $version"
    echo "Usage oft-stack_mask_2images.bash <input1> <input2> [-notrim]"
    echo "Example: oft-stack_mask_2images.bash LE71660632009094ASN00 LE71660632006054ASN00"
    echo "Example: oft-stack_mask_2images.bash LE71660632009094ASN00 LE71660632006054ASN00 -notrim"

elif [ ! -d $1 -o ! -d $2 ] ; then 
    echo "Input parameters must be directory names"
else
#Look for input hdf's
    input1=`find -L $1 -name 'lndsr*.hdf'`
    input2=`find -L $2 -name 'lndsr*.hdf'`
    echo Input1 $input1
    echo Input2 $input2

    trunk1=`gdalinfo $input1|grep band|head -1`
    trunk2=`gdalinfo $input2|grep band|head -1`

    trunk1=${trunk1:20}
    trunk1=${trunk1%%band*}

    trunk2=${trunk2:20}
    trunk2=${trunk2%%band*}

        bands1=`gdalinfo $input1|grep "Grid:band[1234567]"|wc -l` 
        bands2=`gdalinfo $input2|grep "Grid:band[1234567]"|wc -l`

if [ $bands1 != 7 -o $bands2 != 7 ] ; then
	
        echo "Error in recognizing all 7 bands in the hdf files, found $bands1 in image1 and $bands2 bands in image2."
	echo "Exiting now..."
exit
fi


# collect coordinate information 

    header[1]=$input1".hdr"
    header[2]=$input2".hdr"

    for i in  1 2 ; do
	
	echo ${header[$i]}
	
    datum[$i]=`grep 'map info' ${header[$i]}|awk '{gsub("[,{}=]"," "); gsub("-",""); print $12}'`
    proj[$i]=`grep 'map info' ${header[$i]}|awk '{gsub("[,{}=]"," "); print $3}'`
    zone[$i]=`grep 'map info' ${header[$i]}|awk '{gsub("[,{}=]"," "); print $10}'`
    hemi[$i]=`grep North ${header[$i]}|wc -l`

    if [ ${hemi[$i]} -gt 0 ] ; then 
	hemi[$i]=north
    else 
	hemi[$i]=south
    fi

    if [ ${hemi[$i]} = "south" ] ; then
	shorthemi[$i]=S
    else
	shorthemi[$i]=N
    fi

    ogcfile[$i]=$OGCDIR/${datum[$i]}"_"${proj[$i]}"_"${zone[$i]}${shorthemi[$i]}".ogcwkt"


    echo "Using following map projection for file $i:"
    echo "datum: ${datum[$i]}"
    echo "proj: ${proj[$i]}"
    echo "zone: ${zone[$i]}${shorthemi[$i]}"

    done

	echo ${ogcfile[1]}
	echo ${ogcfile[2]}

#Let's do the stacking first

if [ ! -e ${ogcfile[1]} ] ; then 

        echo "ALERT! $ogsfile[1] not available. Using best-guess method"

	for band in 1 2 3 4 5 6 7  ; do

        gdal_translate -a_srs "+proj=${proj[1]} +zone=${zone[1]} +ellps=${datum[1]} +datum=${datum[1]} +${hemi[1]}" -of HFA $trunk1"band"$band a$band.img

        done

else

        echo "Using ${ogcfile[1]}"

	for band in 1 2 3 4 5 6 7  ; do

	gdal_translate -a_srs ${ogcfile[1]} -of HFA $trunk1"band"$band a$band.img

	done

fi

if [ ! -e ${ogcfile[2]} ] ; then 

        echo "ALERT! $ogsfile[2] not available. Using best-guess method"

	for band in 1 2 3 4 5 6 7  ; do

	gdal_translate -a_srs "+proj=${proj[2]} +zone=${zone[2]} +ellps=${datum[2]} +datum=${datum[2]} +${hemi[2]}" -of HFA $trunk2"band"$band b$band.img

	done

    else

        echo "Using ${ogcfile[2]}"

	for band in 1 2 3 4 5 6 7  ; do

	gdal_translate -a_srs ${ogcfile[2]} -of HFA $trunk2"band"$band b$band.img

	done

fi

gdal_merge.py -of HFA -separate -o stack_$1_$2.img a1.img a2.img a3.img a4.img a5.img a6.img a7.img b1.img b2.img b3.img b4.img b5.img b6.img b7.img

#======================
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

# -inv is needed as long as the order of > is not changed RH 3.6.2012
oft-calc -inv -ot Byte $band tmp$i<<EOF
1
11 #1 B 0 = 1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ? 1 ?
EOF

done

# Merge the masks and compute the final common mask.

gdal_merge.py -of HFA -separate -o mask.img tmp1 tmp2

rm tmp1 tmp2

#-inv not needed, 4.6.2012 RH
oft-calc -ot Byte -um mask.img mask.img maskfinal.img<<EOF
1
#1 2 = #2 2 = * #1 1 = 3 #2 1 = 1 3 ? ? 2 ?
EOF

rm mask.img

mv maskfinal.img "mask_"$1"_"$2".img"

for band in 1 2 3 4 5 6 7  ; do

rm a$band.img*
rm b$band.img*

done

else
#============================
gdal_translate -of HFA -outsize 10% 10% a4.img tmp1.img

gdal_translate -of HFA -outsize 10% 10% b4.img tmp2.img

# -inv not needed, removed 4.6.2012 RH, same in the next eq.
oft-calc -ot Byte tmp1.img mask1.img<<EOF
1
#1 -9999 !
EOF

oft-calc -ot Byte tmp2.img mask2.img<<EOF
1
#1 -9999 !
EOF

for band in 1 2 3 4 5 6 7  ; do

rm a$band.img*
rm b$band.img*

done

for file in mask1.img mask2.img ; do 

    oft-trim -ot Byte -ws 3 $file "tmp_"$file
    oft-trim -ot Byte -ws 3 "tmp_"$file $file
    oft-shrink -ot Byte -ws 21 $file "tmp_"$file
    mv "tmp_"$file $file
    
done

n=0;

band[1]=`gdalinfo $input1| grep "Grid:lndsr_QA"`
band[2]=`gdalinfo $input2| grep "Grid:lndsr_QA"`

band[1]=${band[1]#*NAME=}
band[2]=${band[2]#*NAME=}

for file in ${band[1]} ${band[2]}  ; do

n=`expr $n + 1`

xmin=`gdalinfo $file |grep "Upper Left"|awk '{gsub("[,()]"," ");print $3}'`
ymax=`gdalinfo $file |grep "Upper Left"|awk '{gsub("[,()]"," ");print $4}'`

xmax=`gdalinfo $file |grep "Lower Right"|awk '{gsub("[,()]"," "); print $3}'` 
ymin=`gdalinfo $file |grep "Lower Right"|awk '{gsub("[,()]"," "); print $4}'` 

xsize=`gdalinfo $file |grep "Size is"|awk '{gsub(","," ")  ; print $3}'`
ysize=`gdalinfo $file |grep "Size is"|awk '{gsub(","," ")  ; print $4}'`

ps=`gdalinfo $file |grep "Pixel Size"|awk '{gsub("[(,)]"," "); print $4}'` 

echo outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin

#Now, let's force the trimmed band4 masks into the same dimensions as the QA-layer
gdal_translate -of HFA -outsize $xsize $ysize -projwin $xmin $ymax $xmax $ymin "mask"$n".img" tmp"$n".img

mv  "tmp"$n".img" "mask"$n".img"

done

# output a mask with values 0, 1, 2 and 3
# 0 for margins
# 1 for filling
# 2 for training data collection
# 3 for other

#Changed both oft-calcs below to the version with land-mask by CC, RH 3.6.2012
# -inv is needed as far as the order of > has not been changed and tested RH 3.6.2012
oft-calc -inv -ot Byte -um mask1.img ${band[1]} tmp1.img<<EOF
1
11 #1 B 0 = 1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ? 1 ?
EOF

oft-calc -inv -ot Byte -um mask2.img ${band[2]} tmp2.img<<EOF
1
11 #1 B 0 = 1 #1 B 0 2 #1 B 4 #1 B + 8 #1 B + 9 #1 B + 12 #1 B + > 2 1 ? 1 ? 1 ?
EOF


# Merge the masks and compute the final common mask.

gdal_merge.py -of HFA -separate -o mask.img tmp1.img tmp2.img

rm tmp1.img tmp2.img mask1.img mask2.img

oft-calc -inv -ot Byte -um mask.img mask.img maskfinal.img<<EOF
1
#1 2 = #2 2 = * #1 1 = 3 #2 1 = 1 3 ? ? 2 ?
EOF

rm mask.img

mv maskfinal.img "mask_"$1"_"$2".img"

fi

fi

