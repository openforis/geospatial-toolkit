#!/usr/bin/env python
# Conversion of csv / space separated text file
# into a vrt data set
# Author: anssi.pekkarinen@fao.org


import sys
import os
try:
    from osgeo import gdal
except ImportError:
    import gdal

gdal.AllRegister()

argv=None

nr = 0
header=0
   
if argv is None:
    argv = sys.argv
    argv = gdal.GeneralCmdLineProcessor( argv )
    if argv is None:
        sys.exit( 0 )
        
if argv < 14 or argv > 15:
    print "Usage: oft-csv2vrt <-l layer> <-x xcol> <-y ycol> <-v varcol> <-s separator> [-h header] <-i infile> <-o outfile>"
    sys.exit( 0 )

# process arguments 

i=1

xcol=0;
ycol=0;
vcol=0;
hdr=0
   

while i < len(argv):

    print i,argv[i]
    
    arg = argv[i]
    
    if arg == '-o':
        i = i + 1
        outfile = argv[i]
        
    elif arg == '-i':
        i = i + 1
        infile = argv[i]
        
    elif arg == '-x':
        i = i + 1

        xcol=int(argv[i]);
        

    elif arg == '-y':
        i = i+ 1
        ycol=int(argv[i]);


    elif arg == '-l':
        i = i+ 1
        layer=argv[i];

    elif arg == '-v':
        i = i+ 1
        vcol=int(argv[i]);
        
    elif arg == '-s':
        i = i+ 1
        sep=argv[i];
        
    elif arg == '-h':
        hdr=1
        
    elif arg[:1] == '-':
        print('Unrecognised option: %s' % arg)
        Usage()
        sys.exit( 1 )

    i=i+1


try:

    print "Opening files"
    input=open(infile,'r');
    output=open(outfile,'w');

except IOError:
    print 'Can\'t open file.'
    sys.exit(0)
    

print >> output, '<OGRVRTDataSource>'
print >> output, '<OGRVRTLayer name="'+layer+'">'
print >> output, '<SrcDataSource>'+infile+'</SrcDataSource>'
print >> output, '<GeometryType>wkbPoint</GeometryType>'


line=names=input.readline().rstrip()
cols=line.split(sep)



if hdr == 1:
    print "Using header"
    print >> output, '<GeometryField encoding="PointFromColumns" x="'+str(cols[xcol-1])+'" y="'+str(cols[ycol-1])+'" z="'+str(cols[vcol-1])+'"/>'
else:
    print >> output, '<GeometryField encoding="PointFromColumns" x="field_'+str(xcol)+'" y="field_'+str(ycol)+'" z="field_'+str(vcol)+'"/>'
    

print >> output, '</OGRVRTLayer>'
print >> output, '</OGRVRTDataSource>'


input.close()
output.close()

