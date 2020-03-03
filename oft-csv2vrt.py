#!/usr/bin/env python3
# Conversion of csv / space separated text file
# into a vrt data set
# Author: anssi.pekkarinen@fao.org


import sys
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("layer",
                    help="Name of the point layer")
parser.add_argument("x", type=int,
                    help="Number of the x coordinate column")
parser.add_argument("y", type=int,
                    help="Number of the y coordinate column")
parser.add_argument("varcol", type=int,
                    help="Number of the z coordinate column")
parser.add_argument("separator",
                    help="Specify the separator used in the csv file")
parser.add_argument("header", type=int, choices=[0, 1],
                    help="Specify whether the file has or not a header")
parser.add_argument("infile",
                    help="Specify the input file path")
parser.add_argument("outfile",
                    help="Specify the ouput file path ending with .vrt")
args = parser.parse_args()

xcol = args.x
ycol = args.y
vcol = args.varcol
hdr = args.header
sep = args.separator
infile = args.infile
outfile = args.outfile
layer = args.layer

try:
    print("Opening files")
    input=open(infile,'r');
    output=open(outfile,'w');

except IOError:
    print('Can\'t open file.')
    sys.exit(0)


print('<OGRVRTDataSource>', file=output)
print('<OGRVRTLayer name="'+layer+'">', file=output)
print('<SrcDataSource>'+infile+'</SrcDataSource>', file=output)
print('<GeometryType>wkbPoint</GeometryType>', file=output)


line=names=input.readline().rstrip()
cols=line.split(sep)

if hdr == 1:
    print("Using header")
    print('<GeometryField encoding="PointFromColumns" x="'+str(cols[xcol-1])+'" y="'+str(cols[ycol-1])+'" z="'+str(cols[vcol-1])+'"/>', file=output)
else:
    print('<GeometryField encoding="PointFromColumns" x="field_'+str(xcol)+'" y="field_'+str(ycol)+'" z="field_'+str(vcol)+'"/>', file=output)

print('</OGRVRTLayer>', file=output)
print('</OGRVRTDataSource>', file=output)
print('File vrt created.')

input.close()
output.close()
