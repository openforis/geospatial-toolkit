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
#Reija Haapanen 29.5.2013
version=1.0
#RH on 21.6.2013
#Added possibility to select whether one uses the grey value distribution of the image
#or the training data file
#Added possibility to give only an image file and normalize it
#Corrected output band nbr in oft-calc in case of 7 bands
version=1.1

echo "     "
echo "=============================================================="
echo "                  oft-normalize.bash                          "
echo "=============================================================="
echo "Normalizes image bands and training data file,"
echo "based on the distribution of image or training data file grey values"

echo "V. "$version

args=$#

if [ $args -lt 2 ] ; then
    echo "Version $version"
    echo "Image grey values in both files are converted to mean 0 and std 1"
    echo "based on the distribution of pixels on the image OR the sample in the text file"
    echo "======================================================================"
    echo "Usage: oft-normalize.bash <-i image> [-t training data] [-f] [-m mask]"
    echo "======================================================================"
    echo "-i image = give Landsat image with 6 or 7 bands to be normalized"
    echo "-t training data = give also a text file containing ground truth"
    echo "and image grey values for ground truth locations (in last columns)"
    echo "-f 1/2 = normalization will be based on the distribution present in the image (1)"
    echo "or the training data file (2)"
    echo "-m mask = mask file showing areas to be processed with 1 and other areas with 0"
exit
fi

#Assign the parameters to corresponding ones in the scrips

while getopts i:t:f:m: option
do
        case "${option}"
        in
                i) image=${OPTARG}
		imagefound=TRUE;;
                t) training=${OPTARG}
                usetraining=TRUE;;
                f) distrib_source=${OPTARG};;
		m) mask=${OPTARG}
		usemask=TRUE;;
        esac
done

if [ $imagefound ] ; then

if [ -e $image ] ; then

echo "Using "$image" as image file"

else

echo "Given image file not found, exiting now"

exit

fi

else

echo "You must give the image file with option -i, exiting now"

exit

fi

if [ $usetraining ] ; then

if [ -e $training ] ; then

echo "Using "$training" as training data file"

else

echo "Given training data file not found, exiting now"

exit

fi

fi

if [ $usemask ] ; then

if [ -e $mask ] ; then

echo "Using "$mask" as mask file"

else

echo "Given mask file not found, exiting now"

exit

fi

fi

#Check nbr of bands 

bands=`gdalinfo $image|grep Band|wc -l`

echo "Number of bands is " $bands

#Extract name and extension
dummy=$image
imagebase=${dummy%.*}
extension=${dummy#*.}

if [ $usetraining ] ; then

#Print out some properties so the user can check the sensibility
#First find out nbr columns...
#Then for $cols-$bands

cols=`awk '{print NF;exit}' $training`

echo "Number of columns in training data file is " $cols

let "startcol=$cols+1-$bands"

echo "Image grey values start from column " $startcol

fi

#If training data file was given, and we want to take the grey value distributions from it...

if [ $distrib_source -eq 2 ] ; then

echo " "
echo "Using training data file for grey values distribution!"
echo " "

#Find out average and std of bands in training data file

average1=`awk -v sc=$startcol '{sum+=$sc} END { printf ("%4.10f"), sum/NR }' $training`
std1=`awk -v sc=$startcol '{sum+=$sc; array[NR]=$sc} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`
echo "Band 1 average: " $average1 " and std: " $std1
average2=`awk -v sc=$startcol '{sum+=$(sc+1)} END { printf ("%4.10f"), sum/NR }' $training`
std2=`awk -v sc=$startcol '{sum+=$(sc+1); array[NR]=$(sc+1)} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`
echo "Band 2 average: " $average2 " and std: " $std2
average3=`awk -v sc=$startcol '{sum+=$(sc+2)} END { printf ("%4.10f"), sum/NR }' $training`
std3=`awk -v sc=$startcol '{sum+=$(sc+2); array[NR]=$(sc+2)} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`
echo "Band 3 average: " $average3 " and std: " $std3
average4=`awk -v sc=$startcol '{sum+=$(sc+3)} END { printf ("%4.10f"), sum/NR }' $training`
std4=`awk -v sc=$startcol '{sum+=$(sc+3); array[NR]=$(sc+3)} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`
echo "Band 4 average: " $average4 " and std: " $std4
average5=`awk -v sc=$startcol '{sum+=$(sc+4)} END { printf ("%4.10f"), sum/NR }' $training`
std5=`awk -v sc=$startcol '{sum+=$(sc+4); array[NR]=$(sc+4)} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`
echo "Band 5 average: " $average5 " and std: " $std5
average6=`awk -v sc=$startcol '{sum+=$(sc+5)} END { printf ("%4.10f"), sum/NR }' $training`
std6=`awk -v sc=$startcol '{sum+=$(sc+5); array[NR]=$(sc+5)} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`
echo "Band 6 average: " $average6 " and std: " $std6

if [ $bands -eq 6 ] ; then

#Modify training data file

awk -v sc=$startcol -v a1=$average1 -v a2=$average2 -v a3=$average3 -v a4=$average4 -v a5=$average5 -v a6=$average6\
  -v s1=$std1 -v s2=$std2 -v s3=$std3 -v s4=$std4 -v s5=$std5 -v s6=$std6\
 ' {$sc=($sc-a1)/s1} {$(sc+1)=($(sc+1)-a2)/s2} {$(sc+2)=($(sc+2)-a3)/s3} {$(sc+3)=($(sc+3)-a4)/s4} {$(sc+4)=($(sc+4)-a5)/s5} {$(sc+5)=($(sc+5)-a6)/s6} {print $0} ' $training > $training"_norm"

#Compute new image values

if [ $usemask ] ; then

oft-calc -ot Float32 -um $mask $image $imagebase"_norm."$extension<<EOF
6
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
EOF

else 

oft-calc -ot Float32 $image $imagebase"_norm."$extension<<EOF
6
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
EOF

fi

else 

#$bands -eq 7

average7=`awk -v sc=$startcol '{sum+=$(sc+6)} END { printf ("%4.10f"), sum/NR }' $training`
std7=`awk -v sc=$startcol '{sum+=$(sc+6); array[NR]=$(sc+6)} END {for(x=1;x<=NR;x++){sumsq+=((array[x]-(sum/NR))^2);}printf ("%4.10f"), sqrt(sumsq/NR)}' $training`

echo "Band 7 average: " $average7 " and std: " $std7

#Modify training data file

awk -v sc=$startcol -v a1=$average1 -v a2=$average2 -v a3=$average3 -v a4=$average4 -v a5=$average5 -v a6=$average6 -v a7=$average7\
  -v s1=$std1 -v s2=$std2 -v s3=$std3 -v s4=$std4 -v s5=$std5 -v s6=$std6 -v s7=$std7\
 ' {$sc=($sc-a1)/s1} {$(sc+1)=($(sc+1)-a2)/s2} {$(sc+2)=($(sc+2)-a3)/s3} {$(sc+3)=($(sc+3)-a4)/s4} {$(sc+4)=($(sc+4)-a5)/s5} {$(sc+5)=($(sc+5)-a6)/s6} {$(sc+6)=($(sc+6)-a7)/s7} {print $0} ' $training > $training"_norm"

if [ $usemask ] ; then

oft-calc -ot Float32 -um $mask $image $imagebase"_norm."$extension<<EOF
7
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
#7 $average7 - $std7 /
EOF

else 

oft-calc -ot Float32 $image $imagebase"_norm."$extension<<EOF
7
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
#7 $average7 - $std7 /
EOF

fi

fi

else

echo " "
echo "Using image file for grey values distribution!"
echo " "

if [ $usemask ] ; then

oft-stat -i $image -o "stat_"$imagebase".txt" -um $mask
#Example output: 1 34449377 36.773373 90.440189 127.532760 215.638976 297.622931 232.968856 21.826354 28.884089 36.375665 41.712310 57.741962 53.198461 

else

oft-stat -i $image -o "stat_"$imagebase".txt" 

fi

average1=`awk '{ printf ("%4.10f"), $3 }' "stat_"$imagebase".txt"`
std1=`awk '{ printf ("%4.10f"), $9 }' "stat_"$imagebase".txt"`
echo "Band 1 average: " $average1 " and std: " $std1
average2=`awk '{ printf ("%4.10f"), $4 }' "stat_"$imagebase".txt"`
std2=`awk '{ printf ("%4.10f"), $10 }' "stat_"$imagebase".txt"`
echo "Band 2 average: " $average2 " and std: " $std2
average3=`awk '{ printf ("%4.10f"), $5 }' "stat_"$imagebase".txt"`
std3=`awk '{ printf ("%4.10f"), $11 }' "stat_"$imagebase".txt"`
echo "Band 3 average: " $average3 " and std: " $std3
average4=`awk '{ printf ("%4.10f"), $6 }' "stat_"$imagebase".txt"`
std4=`awk '{ printf ("%4.10f"), $12 }' "stat_"$imagebase".txt"`
echo "Band 4 average: " $average4 " and std: " $std4
average5=`awk '{ printf ("%4.10f"), $7 }' "stat_"$imagebase".txt"`
std5=`awk '{ printf ("%4.10f"), $13 }' "stat_"$imagebase".txt"`
echo "Band 5 average: " $average5 " and std: " $std5
average6=`awk '{ printf ("%4.10f"), $8 }' "stat_"$imagebase".txt"`
std6=`awk '{ printf ("%4.10f"), $14 }' "stat_"$imagebase".txt"`
echo "Band 6 average: " $average6 " and std: " $std6

if [ $bands -eq 6 ] ; then

if [ $usetraining ] ; then

#Modify training data file

awk -v sc=$startcol -v a1=$average1 -v a2=$average2 -v a3=$average3 -v a4=$average4 -v a5=$average5 -v a6=$average6\
  -v s1=$std1 -v s2=$std2 -v s3=$std3 -v s4=$std4 -v s5=$std5 -v s6=$std6\
 ' {$sc=($sc-a1)/s1} {$(sc+1)=($(sc+1)-a2)/s2} {$(sc+2)=($(sc+2)-a3)/s3} {$(sc+3)=($(sc+3)-a4)/s4} {$(sc+4)=($(sc+4)-a5)/s5} {$(sc+5)=($(sc+5)-a6)/s6} {print $0} ' $training > $training"_norm"

fi

#Compute new image values

if [ $usemask ] ; then

oft-calc -ot Float32 -um $mask $image $imagebase"_norm."$extension<<EOF
6
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
EOF

else

oft-calc -ot Float32 $image $imagebase"_norm."$extension<<EOF
6
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
EOF

fi

else

#7 bands

average7=`awk '{ printf ("%4.10f"), $9 }' "stat_"$imagebase".txt"`
std7=`awk '{ printf ("%4.10f"), $16 }' "stat_"$imagebase".txt"`
echo "Band 7 average: " $average7 " and std: " $std7

if [ $usetraining ] ; then

#Modify training data file

awk -v sc=$startcol -v a1=$average1 -v a2=$average2 -v a3=$average3 -v a4=$average4 -v a5=$average5 -v a6=$average6 -v a7=$average7\
  -v s1=$std1 -v s2=$std2 -v s3=$std3 -v s4=$std4 -v s5=$std5 -v s6=$std6 -v s7=$std7\
 ' {$sc=($sc-a1)/s1} {$(sc+1)=($(sc+1)-a2)/s2} {$(sc+2)=($(sc+2)-a3)/s3} {$(sc+3)=($(sc+3)-a4)/s4} {$(sc+4)=($(sc+4)-a5)/s5} {$(sc+5)=($(sc+5)-a6)/s6} {$(sc+6)=($(sc+6)-a7)/s7} {print $0} ' $training > $training"_norm"

fi

if [ $usemask ] ; then

oft-calc -ot Float32 -um $mask $image $imagebase"_norm."$extension<<EOF
7
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
#7 $average7 - $std7 /
EOF

else

oft-calc -ot Float32 $image $imagebase"_norm."$extension<<EOF
7
#1 $average1 - $std1 /
#2 $average2 - $std2 /
#3 $average3 - $std3 /
#4 $average4 - $std4 /
#5 $average5 - $std5 /
#6 $average6 - $std6 /
#7 $average7 - $std7 /
EOF

fi

fi

fi

