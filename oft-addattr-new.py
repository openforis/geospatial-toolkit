#!/usr/bin/env python

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

# Open a Shapefile, and get field names

if len(sys.argv) < 6:
    print 'Usage: oft-addattr.py <shapefile> <JoinAttrName> <NewAttrName> <NewAttrType> <textfile> [NoDataVAlue]'
    print 'Allowed field types are:'
    print 'Int/Str/Float'
    sys.exit(1)

source = ogr.Open(sys.argv[1], 1)
JoinAttrName=sys.argv[2]
NewAttrName=sys.argv[3]
NewAttrType=sys.argv[4]
input=open(sys.argv[5],'r');

if len(sys.argv) == 7:
    NoData=int(sys.argv[6]);
else:
    NoData=-9999


layer = source.GetLayer()      
layer_defn = layer.GetLayerDefn()
field_names = [layer_defn.GetFieldDefn(i).GetName() for i in range(layer_defn.GetFieldCount())]

# read in an indexed ascii file

#RH: numRows was giving one too large a nbr
#numRows=len(input.readlines())+1;
numRows=len(input.readlines());
input.seek(0)
lst={}

numFeatures = layer.GetFeatureCount()

print "Reclass Rows ",numRows;
print "Shape Features ",numFeatures

for word in input.xreadlines():
    cols=word.split(' ')    
    id=int(cols[0])    
    outval=cols[1]
    lst[id]=outval


# Add a new field as an integer

if NewAttrType == 'Int':
    new_field = ogr.FieldDefn(NewAttrName, ogr.OFTInteger)
elif NewAttrType == 'Float':
    new_field = ogr.FieldDefn(NewAttrName, ogr.OFTReal)
elif NewAttrType == 'Str':
    new_field = ogr.FieldDefn(NewAttrName, ogr.OFTString)
else:
    print 'Unknown field type'
    exit

layer.CreateField(new_field)

feature = layer.GetNextFeature()

count=0
progr=0;
print "Processing. Please wait"

while feature:

    segid = int(feature.GetField(JoinAttrName))
        
    if segid in lst:
        feature.SetField(NewAttrName,lst[segid])   
    else:
        feature.SetField(NewAttrName,NoData)   

    layer.SetFeature(feature)

    count = count + 1 
#RH: this crashed with < 10 polygons, changed so that we do not go there
# in such cases
    if(numFeatures >= 100):
        if(count % (numFeatures/10) == 0):
            progr=progr+1        
            sys.stdout.write(str(progr));
            sys.stdout.write(" ");
            sys.stdout.flush()

    feature = layer.GetNextFeature()

sys.stdout.write("Done\n");

# Close the Shapefile
source.Destroy()
source = None
