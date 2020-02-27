#!/usr/bin/env python3
#******************************************************************************
#  Name:     oft-addpct
#  Purpose:  Application for adding PCT color table in an image
#  Author:   Anssi Pekkarinen modified from pct2rgb.py
#  Email: anssisamuli@gmail.com
#  changes
# AP improved error message July 18 2013

from osgeo import gdal
from array import array
import sys
import os
import os.path
version=0.1
def Usage():
    
    print('Add pseudo color table to an image')
    print('Version',version)
    print('Usage: oft-addpct.py <input.img> <output.img>')
    sys.exit(1)

# =============================================================================
# 	Mainline
# =============================================================================

create_options = []
color_count = 256
format = 'GTiff'
src_filename = 'None'
dst_filename = 'None'

gdal.AllRegister()
argv = gdal.GeneralCmdLineProcessor( sys.argv )

if len(sys.argv) != 3:
    Usage()
    sys.exit( 0 )

# Parse command line arguments.

i = 1


while i < len(argv) :


    arg = argv[i]
    
    
    if arg == '-co':
        i = i + 1
        create_options.append( argv[i] )
        
    elif src_filename  == 'None' :
        src_filename = arg
        
    elif dst_filename == 'None':
        dst_filename = arg
        
    i = i + 1
        
    
            # Open source file
            
src_ds = gdal.Open( src_filename)

if src_ds is None:
    print('Unable to open ', src_filename)
    sys.exit(1)

if src_ds.RasterCount != 1:
    print('Input has %d bands. Only 1 band input supported.' \
          % src_ds.RasterCount)
    sys.exit(1)



# Ensure we recognise the driver.

dst_driver = gdal.GetDriverByName(format)
if dst_driver is None:
    print('"%s" driver not registered.' % format)
    sys.exit(1)

in_band =src_ds.GetRasterBand(1)

# ask for input file name and open it

try:

    filename=input("Give LUT file name: ")
    print(filename)
    file=open(filename,'r')

except IOError:
    print("Error opening input file")
    sys.exit(1)

# Generate the median cut PCT

ct = gdal.ColorTable()

# read in the color table values from ascii file
# if there are only three columns use 255 as alpha

stub=array('i',[0,0,0,0,0])
nbrline=0
for line in file:
    nbrline+=1
    cols=line.split();
    for i in range(len(cols)):
        stub[i]=int(cols[i])

    if len(cols)<4:
        print('Input line ',nbrline,'has wrong number of cols')
        print('Only 4/5 (RGB[A]) input cols supported. Line ',nbrline,'had ',cols,'cols') 
        sys.exit(1);
    elif len(cols)<5:
        stub[4]=255 

    ct.SetColorEntry(stub[0],(stub[1],stub[2],stub[3],stub[4]))

# Create the TIFF output 

tif_filename = dst_filename

gtiff_driver = gdal.GetDriverByName( 'GTiff' )

tif_ds = gtiff_driver.Create( tif_filename, src_ds.RasterXSize, src_ds.RasterYSize, 1,in_band.DataType,create_options)
tif_ds.GetRasterBand(1).SetRasterColorTable( ct )
tif_ds.SetProjection( src_ds.GetProjection() )
tif_ds.SetGeoTransform( src_ds.GetGeoTransform() )




# copy the data by lines


out_band=tif_ds.GetRasterBand(1)


line=0


while line < src_ds.RasterYSize :

    buff=in_band.ReadRaster(0,line,src_ds.RasterXSize,1,src_ds.RasterXSize,1,in_band.DataType)
    out_band.WriteRaster(0,line,src_ds.RasterXSize,1,buff,src_ds.RasterXSize,1,in_band.DataType)

    line = line + 1
    
    







