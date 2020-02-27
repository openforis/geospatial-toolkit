#!/usr/bin/python3

#This file is part of Open Foris Geospatial Toolkit which is free software.
#You can redistribute it and/or modify it under the terms of the 
#GNU General Public License as published by the Free Software Foundation, 
#either version 3 of the License, or (at your option) any later version.
# Visit http://www.openforis.org/tools/geospatial-toolkit.html

#Open Foris Geospatial Toolkit is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with the Open Foris Geospatial Toolkit  
#If not, see <http://www.gnu.org/licenses/>.

#####################################################################################
# Script by remi.dannunzio@fao.org
#
# Purpose : Calculate zonal statistics of a raster over defined zones 
# The zones can be defined as a raster product or as a shapefile (less than 255 features)
#####################################################################################

version="1.0"
update ="27/02/2020"
cut_size = 25000

import sys
import subprocess
import os
import tempfile
import re
import pandas
import numpy
import shutil

try:
    from osgeo import gdal
except ImportError:
    import gdal
gdal.AllRegister()

argv = None

if argv is None:
    argv = sys.argv
    argv = gdal.GeneralCmdLineProcessor( argv )
    if argv is None:
        sys.exit( 0 )

###############################################################
##################### Test if all necessary arguments are in
###############################################################
if len(argv) < 7 or len(argv) > 9:
    print("\nVersion %s Last update on %s\nZonal statistics of a raster over a mask\n" % (version,update))
    print("Usage: oft-zonal <-i input.tif> <-um mask.tif OR mask.shp> <-o outfile.txt> [-a attribute]\n")
    print("NB : option \"-a attribute\" is  only used if the mask is in shapefile format \n")
    sys.exit( 0 )


###############################################################
##################### Read the arguments passed to the command
###############################################################

i=1
while i < len(argv):
    arg = argv[i]
    
    if arg == '-a':
        i = i + 1
        attr = argv[i];
    
    elif arg == '-o':
        i = i + 1
        oufile = argv[i];   
               
    elif arg == '-um':
        i = i + 1
        mask = argv[i];

    elif arg == '-i':
        i = i + 1
        infile = argv[i];
        
    elif arg[:1] == '-':
        print('Unrecognized option: %s' % arg)
        sys.exit( 1 )
    i=i+1


###############################################################
##################### Create basenames 
###############################################################
in_base = os.path.basename(infile)
in_path = os.path.split(os.path.abspath(infile))[0]
base = in_base[0:len(in_base)-4]


###############################################################
##################### Create a temp directory
###############################################################
tmpdir = tempfile.mkdtemp(dir=in_path)


###############################################################
##################### Get extension of the mask
###############################################################
mask_ext = os.path.basename(mask)[len(os.path.basename(mask))-3:len(os.path.basename(mask))]
base_msk = os.path.basename(mask)[0:len(os.path.basename(mask))-4]


###############################################################
##################### If the mask is a shapefile -> rasterize
###############################################################
if mask_ext == 'shp':

    ###############################################################
    ##################### If it is a 
    ############################################################### 
    print("-"*40 + "\nRasterize first")
    vc_base = os.path.basename(mask)
    layer   = vc_base[0:len(vc_base)-4]

    ###############################################################
    ##################### Extract extent & pixel size of input tif
    ###############################################################
    ul = subprocess.check_output("gdalinfo %s | grep \"Upper Left\""  % infile, shell=True).decode("utf-8") 
    lr = subprocess.check_output("gdalinfo %s | grep \"Lower Right\"" % infile, shell=True).decode("utf-8") 
    px = subprocess.check_output("gdalinfo %s | grep \"Pixel Size\""  % infile, shell=True).decode("utf-8") 

    im_xmin = float(ul.split("(")[1].split(",")[0])
    im_ymax = float(re.sub(r'\)', '', ul.split("(")[1].split(",")[1]))
    im_xmax = float(lr.split("(")[1].split(",")[0])
    im_ymin = float(re.sub(r'\)', '', lr.split("(")[1].split(",")[1]))
    pxsz    = float(px.split("(")[1].split(",")[0])

    print("Infile:  %s\nxmin : %r \nymax : %r \nxmax : %r \nymin : %r \nsize : %r\n" % (in_base,im_xmin,im_ymax,im_xmax,im_ymin,pxsz))

    ###############################################################
    ##################### Extract extent of vector
    ###############################################################
    vc = subprocess.check_output("ogrinfo -al -so %s | grep \"Extent\"" % mask, shell=True).decode("utf-8") 
    vc=re.sub(r'Extent:\s','',vc)

    vc_xmin = float(re.sub(r'\(', '', vc.split(") - (")[0].split(",")[0]))
    vc_ymin = float(re.sub(r'\)', '', vc.split(") - (")[0].split(",")[1]))
    vc_xmax = float(re.sub(r'\(', '', vc.split(") - (")[1].split(",")[0]))
    vc_ymax = float(re.sub(r'\)', '', vc.split(") - (")[1].split(",")[1]))

    print("-"*40)
    print("Mask:    %s\nvc_xmin : %r \nvc_ymax : %r \nvc_xmax : %r \nvc_ymin : %r\n" % (mask,vc_xmin,vc_ymax,vc_xmax,vc_ymin))

    ################################################################
    ##################### Calculate starting point for rasterization
    ################################################################
    offset_x = int((vc_xmin-im_xmin)/pxsz)-1
    offset_y = int((vc_ymin-im_ymin)/pxsz)-1

    xmin = im_xmin+offset_x*pxsz
    ymin = im_ymin+offset_y*pxsz


    ################################################################
    #################### Calculate size of extent to crop
    ################################################################
    size_x = int((vc_xmax-vc_xmin)/pxsz)+3;
    size_y = int((vc_ymax-vc_ymin)/pxsz)+3;

    xmax = xmin+size_x*pxsz;
    ymax = ymin+size_y*pxsz;


    ###############################################################
    ##################### If no attribute is specified, clump
    ############################################################### 
    try:
        attr
        rasterize = "gdal_rasterize -a %s -l %s -ot UInt32 -te %r %r %r %r -tr %r %r -co \"COMPRESS=LZW\" %s %s/tmp_mask.tif\n" % (attr,layer,im_xmin,im_ymin,im_xmax,im_ymax,pxsz,pxsz,mask,tmpdir)
    except NameError:
        print("-"*40 + "\nNo attribute specified, will clump all features of %s" % base_msk)
        rasterize = "gdal_rasterize -burn 1 -l %s -te %r %r %r %r -tr %r %r -co \"COMPRESS=LZW\" %s %s/tmp_mask.tif\n" %   (layer,im_xmin,im_ymin,im_xmax,im_ymax,pxsz,pxsz,mask,tmpdir)


    ############################################################### 
    ################ Rasterize the vector with at least one pixel encompassing the border
    ############################################################### 
    print("-"*40 + "\n" + rasterize)
    os.system(rasterize)
    mask = tmpdir+"/tmp_mask.tif"

################################################################
#################### Check if the mask is not empty 
################################################################
mmmask = subprocess.check_output("gdalinfo -mm %s | grep \"Computed Min/Max=\""  % mask, shell=True).decode("utf-8") 
maxmsk=int(mmmask.split(",")[1].split(".")[0])

if maxmsk <= 0:
    print("Mask is empty check attributes\n")
    sys.exit(1)

################################################################
#################### Calculate the optimum size to cut the data 
################################################################
size = subprocess.check_output("gdalinfo %s | grep \"Size is\""  % infile, shell=True).decode("utf-8") 

size_x = int(re.sub(r'Size is ', '', size.split(",")[0]))
size_y = int(re.sub(r'Size is ', '', size.split(",")[1]))

nx = 1
ny = 1

if size_x > cut_size:
    nx = int(size_x / cut_size) + 1
if size_y > cut_size:
    ny = int(size_y / cut_size) + 1

################################################################
#################### Compute maxval to be used in calculation
################################################################
mm = subprocess.check_output("gdalinfo -mm %s | grep \"Computed Min/Max=\""  % infile, shell=True).decode("utf-8") 
maxval=int(mm.split(",")[1].split(".")[0])


################################################################
#################### If the tile is small enough, apply oft-his
################################################################
if (size_x * size_y) <= cut_size*cut_size:
    print("Small enough to use oft-his directly\n")
    hist=  "oft-his -i %s -o %s -um %s -maxval %s" % (infile,oufile,mask,maxval)
    print("-"*40 + "\nCompute histogram:\n" + hist)
    os.system(hist)
    show = "cat %s" % oufile
    os.system(show)

    ################################################################
    #################### Clean the temporary directory and exit
    ################################################################
    shutil.rmtree(tmpdir)
    sys.exit(0)


################################################################
#################### If the tile is too big, create tiling 
################################################################
print("-"*40 + "\n")
print("Base is %s and path is %s, file will be cut into %d x %d tiles and put into %s" % (in_base,in_path,nx,ny,tmpdir))

subsize_x=int(size_x/nx)
subsize_y=int(size_y/ny)

print("Original size : %s & %s Subtile size : %s & %s" % (size_x,size_y,subsize_x,subsize_y))


################################################################
#################### Perform the OFGT commands for tiling + hist
################################################################
for i in range(1,nx+1):
    for j in range(1,ny+1):
        print("%s %s\n" % (i,j))

        x_off=subsize_x*(i-1)
        y_off=subsize_y*(j-1)
        x_size=subsize_x
        y_size=subsize_y

        ################# If it is the last tile, the size can be different
        if i == nx:
            x_size=size_x-subsize_x*(nx-1)
        if j == ny:
            y_size=size_y-subsize_y*(ny-1)

        print("%s %s\n" % (x_size,y_size))

	################# Cut original image to tile   
        cut = "gdal_translate -co \"COMPRESS=LZW\" -srcwin %r %r %r %r %s %s/%s_%s_%s.tif" % (x_off,y_off,x_size,y_size,infile,tmpdir,base,i,j)
        print("-"*40 + "\nCut original image to tile:\n" + cut)
        os.system(cut)

	################# Clip the mask to the tile extent
        clip = "gdal_translate -co \"COMPRESS=LZW\" -srcwin %r %r %r %r  %s  %s/%s_mask_%s_%s.tif" % (x_off,y_off,x_size,y_size,mask,tmpdir,base,i,j)
        print("-"*40 + "\nClip the mask to the tile extent:\n" + clip)
        os.system(clip)

	################# Calculate histogram over the tile
        hist=  "oft-his -i %s/%s_%s_%s.tif -o %s/%s_%s_%s.txt -um %s/%s_mask_%s_%s.tif -maxval %s" % (tmpdir,base,i,j,tmpdir,base,i,j,tmpdir,base,i,j,maxval)
        print("-"*40 + "\nCompute histogram:\n" + hist)
        os.system(hist)

	################# Append the result in one text file
        append = "cat %s/%s_%s_%s.txt >> %s/%s_tmp.txt" %  (tmpdir,base,i,j,tmpdir,base)
        print("-"*40 + "\nAppend:\n" + append)
        os.system(append)

txt_file = tmpdir + "/" + base + "_tmp.txt"
my_names = ['class','total','no_data']

################# Create a list of unique names for the table
for i in range(int(maxval)):
    cat = ["cat"+str(i)]
    my_names = my_names + cat

################# Use the pandas functionalities to aggregate data by first column
data = pandas.read_table(txt_file,names=my_names,header=None,sep=" ")
hist = data.groupby('class').sum()

print("-"*40) 
print(hist)

hist.to_csv(oufile,sep=" ",header=False,index=True)

################################################################
#################### Clean the temporary directory
################################################################
shutil.rmtree(tmpdir)
