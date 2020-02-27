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
# $2 = output image
# TC weights from 
# http://arsc.arid.arizona.edu/resources/image_processing/vegetation/index.html

version=1.01
# by Anssi Pekkarinen

args=$#


if [ $args -ne 4 ] ; then
    echo "Version $version"
    echo "Tasseled cap transformation"
    echo "Usage oft-tascap.bash <input> <output> <TM4/TM5/TM7> <DN/REF>"
    exit
elif [ ! -f $1 ] ; then 
    echo "Input image does not exist"
    exit
else
    
    bands=`gdalinfo $1|grep Band|wc -l`

    if [ $bands -lt 6 -o $bands -gt 7 ] ; then	
	echo "Only 6/7 band inputs accepted";
	exit;
	
    elif [ $bands -eq 6 ] ; then	
	
	band[1]="#1"
	band[2]="#2"
	band[3]="#3"
	band[4]="#4"
	band[5]="#5"
	band[7]="#6"
	
    else

	band[1]="#1"
	band[2]="#2"
	band[3]="#3"
	band[4]="#4"
	band[5]="#5"
	band[7]="#7"

    fi
    

    if [ $3 != "TM4" -a $3 != "TM5" -a $3 != "TM7" ] ; then

	echo "Unrecognized input image type. Only TM4, TM5 and TM7 inputs accepted'"
	
    else

	if [ $3 = "TM4" -a $4 = "DN" ] ; then

	    echo "TM4 DN input"

	    B[1]=0.3037
	    B[2]=0.2793
	    B[3]=0.4743
	    B[4]=0.5585
	    B[5]=0.5082
	    B[7]=0.1863

	    B[8]=0


	    G[1]=-0.2848 
	    G[2]=-0.2435 
	    G[3]=-0.5436 
	    G[4]=0.7243  
	    G[5]=0.0840  
	    G[7]=-0.1800 

	    G[8]=-0
	    

	    W[1]=0.1509  
	    W[2]=0.1973  
	    W[3]=0.3279  
	    W[4]=0.3406  
	    W[5]=-0.7112 
	    W[7]=-0.4572 

	    W[8]=0

	elif [  $3 = "TM4" -a $4 = "REF" ] ; then

	    echo "TM4 Reflectance input"

	    B[1]=0.2043
	    B[2]=0.4158
	    B[3]=0.5524
	    B[4]=0.5741
	    B[5]=0.3124
	    B[7]=0.2303

	    B[8]=0


	    G[1]=-0.1063 
	    G[2]=-0.2819 
	    G[3]=-0.4934 
	    G[4]=0.7940  
	    G[5]=-0.0002  
	    G[7]=-0.1446 

	    G[8]=0

	    W[1]=0.0315 
	    W[2]=0.2021  
	    W[3]=0.3102  
	    W[4]=0.1594  
	    W[5]=-0.6806 
	    W[7]=-0.6109 

	    W[8]=0

	elif [  $3 = "TM5" -a $4 = "DN" ] ; then


	    B[1]=0.2909
	    B[2]=0.2493
	    B[3]=0.4806
	    B[4]=0.5568
	    B[5]=0.4438
	    B[7]=0.1706

	    B[8]=10.3695

	    G[1]=-0.2728
	    G[2]=-0.2174 
	    G[3]=-0.5508 
	    G[4]=0.7220  
	    G[5]=0.0733  
	    G[7]=-0.1648 

	    G[8]=-0.7310

	    W[1]=0.1446
	    W[2]=0.1761  
	    W[3]=0.3322  
	    W[4]=0.3396  
	    W[5]=-0.6210 
	    W[7]=0.4186 

	    W[8]=-3.3828
	    
	elif [  $3 = "TM7" -a $4 = "REF" ] ; then



	    B[1]=0.3561
	    B[2]=0.3972
	    B[3]=0.3904
	    B[4]=0.6966
	    B[5]=0.2286
	    B[7]=0.1596

	    B[8]=0

	    G[1]=-0.3344 
	    G[2]=-0.3544 
	    G[3]=-0.4556 
	    G[4]=0.6966  
	    G[5]=-0.0242  
	    G[7]=-0.2630 

	    G[8]=0.0

	    W[1]=0.2626 
	    W[2]=0.2141  
	    W[3]=0.0926  
	    W[4]=0.0656  
	    W[5]=-0.7629 
	    W[7]=-0.5388 

	    W[8]=0
  
	else 

	    echo "Wrong combination of parameters" 
	    exit
	    
	fi

echo "${band[1]} ${B[1]} * ${band[2]} ${B[2]} * + ${band[3]} ${B[3]} * + ${band[4]} ${B[4]} * + ${band[5]} ${B[5]} * + ${band[7]} ${B[7]} * + ${B[8]} +"
echo "${band[1]} ${G[1]} * ${band[2]} ${G[2]} * + ${band[3]} ${G[3]} * + ${band[4]} ${G[4]} * + ${band[5]} ${G[5]} * + ${band[7]} ${G[7]} * + ${G[8]} +"
echo "${band[1]} ${W[1]} * ${band[2]} ${W[2]} * + ${band[3]} ${W[3]} * + ${band[4]} ${W[4]} * + ${band[5]} ${W[5]} * + ${band[7]} ${W[7]} * + ${W[8]} +"

oft-calc -inv -ot Float32 $1 $2 <<EOF
3
${band[1]} ${B[1]} * ${band[2]} ${B[2]} * + ${band[3]} ${B[3]} * + ${band[4]} ${B[4]} * + ${band[5]} ${B[5]} * + ${band[7]} ${B[7]} * + 
${band[1]} ${G[1]} * ${band[2]} ${G[2]} * + ${band[3]} ${G[3]} * + ${band[4]} ${G[4]} * + ${band[5]} ${G[5]} * + ${band[7]} ${G[7]} * + 
${band[1]} ${W[1]} * ${band[2]} ${W[2]} * + ${band[3]} ${W[3]} * + ${band[4]} ${W[4]} * + ${band[5]} ${W[5]} * + ${band[7]} ${W[7]} * + 
EOF

echo  "Tasseled Cap tranformation done"
echo  "Output channels are:"
echo  "Band1: Brightness"
echo  "Band2: Greenness"
echo  "Band3: Wetness"
echo "Applied weights were"
for band in 1 2 3 4 5 7 8 ; do
if [ $band -lt 8 ]; then
echo TM$band "B" ${B[$band]},${G[$band]},${W[$band]}
else
echo Additive item "B "${B[$band]}" G "${G[$band]}" W "${W[$band]}
fi
done
    fi




fi

