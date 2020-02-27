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
# Sept 23 2011 RH
# Compares pixelvalues of training data classes
# Script create_plots.bash must first be run in order to extract values for all classes
# This script must be lauched on the directory where the classwise data files are stored (e.g. class22.txt)
# Input parameters: max 5 class id's
version=1.00 
# January 24 2013 RH
# Corrected erroneus capitals from some class files in the plotting commands
version=1.01 
# Feb 4 2013 RH
# Re-named: changed _ into -
version=1.02

echo "==========================================================="
echo "                  Compare_classes.bash                     "
echo "==========================================================="
echo "Compares pixelvalues of training data classes"

echo "V. "$version

# $1 = class1
# $2 = class2
# $3 = class3
# $4 = class4
# $5 = class5

args=$#

if [ $args != 2 -a $args != 3 -a $args != 4 -a $args != 5 ] ; then
    echo "Version $version"
    echo "Script create_plots.bash must first be run in order to extract values for all classes"
    echo "This script must be lauched on the directory where the classwise data files (e.g. class22.txt) are stored"
    echo "        "
    echo "Usage: oft-classvalues_compare.bash <class1> <class2> [class3] [class4] [class5]"
    echo "Give a least 2 classes to be compared. Maximum is 5"
exit
fi

if [ $args -eq 2 ] ; then
gnuplot<<EOP
set terminal png
set output "Comparison${1}_${2}.png"
set xlabel "Band a"
set ylabel "Band b"
#set xrange [0:3000]
#set yrange [0:3000]
set key box
set title "Class comparison plots"
plot 'class${1}.txt' using 5:6 title "Class${1}" lt 1, 'class${2}.txt' using 5:6 title "Class${2}" lt 2
EOP

fi

if [ $args -eq 3 ] ; then
gnuplot<<EOP
set terminal png
set output "Comparison${1}_${2}_${3}.png"
set xlabel "Band a"
set ylabel "Band b"
#set xrange [0:3000]
#set yrange [0:3000]
set key box
set title "Class comparison plots"
plot 'class${1}.txt' using 5:6 title "Class${1}" lt 1, 'class${2}.txt' using 5:6 title "Class${2}" lt 2, 'class${3}.txt' using 5:6 title "Class${3}" lt 3
EOP

fi

if [ $args -eq 4 ] ; then
gnuplot<<EOP
set terminal png
set output "Comparison${1}_${2}_${3}_${4}.png"
set xlabel "Band a"
set ylabel "Band b"
#set xrange [0:3000]
#set yrange [0:3000]
set key box
set title "Class comparison plots"
plot 'class${1}.txt' using 5:6 title "Class${1}" lt 1, 'class${2}.txt' using 5:6 title "Class${2}" lt 2,'class${3}.txt' using 5:6 title "Class${3}" lt 3, 'class${4}.txt' using 5:6 title "Class${4}" lt 4
EOP

fi

if [ $args -eq 5 ] ; then
gnuplot<<EOP
set terminal png
set output "Comparison${1}_${2}_${3}_${4}_${5}.png"
set xlabel "Band a"
set ylabel "Band b"
#set xrange [0:3000]
#set yrange [0:3000]
set key box
set title "Class comparison plots"
plot 'class${1}.txt' using 5:6 title "Class${1}" lt 1, 'class${2}.txt' using 5:6 title "Class${2}" lt 2, 'class${3}.txt' using 5:6 title "Class${3}" lt 3, 'class${4}.txt' using 5:6 title "Class${4}" lt 4, 'class${5}.txt' using 5:6 title "Class${5}" lt 5 
EOP

fi
