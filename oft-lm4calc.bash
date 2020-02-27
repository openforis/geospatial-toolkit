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

# Anssi Pekkarinen June 2014 

version=0.01

args=$#


if [ $args -ne 10 ] ; then

    echo "Version $version"
    echo "Linear model builder"
    echo "Usage: oft-lm4calc.bash -vary <ystartcol> -varx <xstartcol> -varcols <varcols> -i <input.csv> -o <output>"
    echo "R linear model builder for oft-calc"
    exit

    elif [ $(R --version > /dev/null; echo $?) -gt 0 ] ; then
    
    echo "Can find R installation"
    echo "Exiting"
    exit
fi


while :
do
    case "$1" in

      -i)  
          input="$2"
	  shift 2
	  ;;
      -o)
          output="$2"
	  shift 2
	  ;;
      -varx)
          ycol="$2"
	  shift 2
	  ;;
      -vary)
          xcol="$2"
	  shift 2
	  ;;
      -varcols)
          ncol="$2"
	  shift 2
	  ;;
      -*)
	  echo "Error: Unknown option: $1" >&2
	  exit 1
	  ;;
      *)  # No more options
	  break
	  ;;
    esac
done



# test for sensible column numbers

test=$(awk -v x=$xcol -v y=$ycol -v cols=$ncols 'BEGIN{if((x+cols-1 > NF) || (y+cols-1 > NF)) print 0 ; else print 1}')



if [ $test == 1 ] ; then

echo "Error in col parameters"
exit
fi
    

#test not comma separated

if [ $(grep -c "," $input) -eq 0 ] ; then
    
    echo "This script requires comma separated input file"
    echo "Please fix your input"
    exit;
fi

echo R  --slave --no-save --args $input $output $xcol $ycol $ncol


R --slave --no-save --args $input $output $xcol $ycol $ncol<<EOF

CommArgs <- commandArgs(TRUE)

input <- CommArgs[1]
output <- CommArgs[2]
xmin<-strtoi(CommArgs[3])
ymin<-strtoi(CommArgs[4])
ncol<-strtoi(CommArgs[5])
ncol=ncol-1;
print(ncol)
sink(output)

data=read.csv(input,sep=",",header=FALSE);

for( i in 0:ncol) { v1=paste("V",xmin+i,sep="") ; v2=paste("V",ymin+i,sep="") ;   print(coefficients(lm(data[,v1] ~ data[,v2])))}

EOF

cat $output
echo "===="
grep -v "(" $output
grep -v "(" $output|awk '{if(NF > 0 ) printf("%f #%i * %f +\n",$1,NR,$2)}'  > /tmp/$$.out

echo $ncol > $output
cat /tmp/$$.out >> $output

exit
