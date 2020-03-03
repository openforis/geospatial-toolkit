#!/usr/bin/env python3

# Add an attribute field in a shapefile
# read the values from a text file
# Authors: Anssi Pekkarinen & Erik Lindquist
# Edited by Reija Haapanen Mar 3 2012
# version 0.1
# AP 11 Oct 2012
# Changed usage to allow user to select JoinAttrName
# Fixed a bug in assigning new values for fields
# And using dictionary instead of a list to allow
# different number of feature infile records
# RH 30 Jan 2013
# Changed process stage controlling so that it does not
# crash if a small nbr of polys are processed.
# Also: corrected the row count (it gave 1 too much)

from osgeo import ogr
import sys
import argparse

# Open a Shapefile, and get field names

parser = argparse.ArgumentParser()
parser.add_argument("shapefile",
                    help="Path of the shapefile")
parser.add_argument("joinAttrName",
                    help="Name of the column to be used as a join")
parser.add_argument("newAttName",
                    help="Name of the new column to be created")
parser.add_argument("textFile",
                    help="Path of the file to be joined, delimited by spaces")
args = parser.parse_args()

source = ogr.Open(args.shapefile,1)
JoinAttrName = args.joinAttrName
NewAttrName = args.newAttName
input_file = open(args.textFile,'r')
layer = source.GetLayer()

layer_defn = layer.GetLayerDefn()


field_names = [layer_defn.GetFieldDefn(i).GetName() for i in range(layer_defn.GetFieldCount())]


# read in an indexed ascii file

#RH: numRows was giving one too large a nbr
#numRows=len(input.readlines())+1;
numRows=len(input_file.readlines())
input_file.seek(0)
lst={}

numFeatures = layer.GetFeatureCount()

print("Reclass Rows " , numRows)
print("Shape Features " , numFeatures)

for word in input_file:
    cols = word.split(' ')
    key = int(cols[0])
    outval = int(cols[1])
    lst[key] = outval

# Add a new field as an integer
new_field = ogr.FieldDefn(NewAttrName, ogr.OFTInteger)
layer.CreateField(new_field)

feature = layer.GetNextFeature()

count=0
progr=0;
print("Processing. Please wait")

while feature:

    segid = int(feature.GetField(JoinAttrName))

    if segid in lst:
        feature.SetField(NewAttrName,lst[segid])
    else:
        feature.SetField(NewAttrName,-9999)

    layer.SetFeature(feature)

    count = count + 1
#RH: this crashed with < 10 polygons, changed so that we do not go there
# in such cases
    if(numFeatures >= 100):
        if(count % (numFeatures/10) == 0):
            progr=progr+1
            sys.stdout.write(str(progr))
            sys.stdout.write(" ")
            sys.stdout.flush()

    feature = layer.GetNextFeature()

sys.stdout.write("Done\n");

# Close the Shapefile
source.Destroy()
source = None
