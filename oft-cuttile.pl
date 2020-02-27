#!/usr/bin/perl
# original by Erik Lindquist @ fao org
# Jan 30 2012
# modified to add command line arguments by anssi pekkarinen @ fao org
# Feb 20 2012
# bugfixed version by anssi pekkarinen @ fao org with
# reija haapanen @ haapanenforestconsulting fi

# functionality
# 1 Read points from file
# 2 Look for images from the input directory
# 3 Look for CRS file and check if the input is provided for both, test and image file
# 4 for every image
# 5   compute the bounding box of the image
# 6    parse image header if the CRS was not provided
# 7    for every point
# 8     re-project the point if needed
# 9     check if point falls in the BB
# 10    cut the tile
# 11    re-rproject the tile to the point CRS
# 12   done
# 13 done

$version="1.1";
$nbr_args=$#ARGV;

open LOGFILE, ">/tmp/errors.log";

if($nbr_args != 3){
    
    print "Version $version\n";
    print "Subsets an image using extension of a reference image\n";
    print "Usage: CutTile.pl <coord_list> <CRS_file> <input_dir> <output_basename>\n";
    print "NOTE: coord list format: id x y\n";
    print "NOTE: input list CRS needs to be given as a Proj4 string in CRS file\n";
    print "NOTE: the same file can contain also another line with image CRS as a Proj4 string\n";
    print "You gave ",$nbr_args+1," arguments\n";
    exit;

}

$coord_list = $ARGV[0];
$proj4_crs = $ARGV[1];
$input_dir= $ARGV[2];
$outname =  $ARGV[3];

if ( -d $outname ) {
print "Writing outputs to dir $outname\n";
} elsif ( $outname =~/\/$/ ) {
    
    print "Folder $outname does not exist\n";
    exit;
}


if (-d "$input_dir"){

    print "Looking for images from " ,$input_dir,"\n" ;

    @images = glob("$input_dir/*.*");


} else {
    
    print "Input folder does not exist" ;
    exit
}



if (-e "$coord_list"){
open(LIST, $coord_list) || die("Could not open file $coord_list !");
} else {
   
    print "Input point list does not exist" ;
exit

}


if (-e "$proj4_crs"){

    print "Using: ",$proj4_crs," as source of input CRSs\n";
    $type=`wc -l $proj4_crs|awk '{print $1}'`;

    if($type == 1){

	print "Reading only input point projection from file\n";
	@PCRS=`cat $proj4_crs`;
	chomp(@PCRS);
    }elsif($type == 2){

	print "Reading both projections from file\n";
	@PCRS=`head -1 $proj4_crs`;
	@ICRS=`tail -1 $proj4_crs`;
	chomp(@PCRS);
	chomp(@ICRS);

	print "Using following definitions:\n";

	print "Point coordinates ",@PCRS,"\n";
        print "Image coordinates ",@ICRS,"\n";
	    

    } else {

	print "Ackward number of input lines in CRS file\n";
	print "Please check $proj4_crs\n";
	exit;

    }



} else {
    print "Input point list does not exist" ;
    exit
	
}



#tile list loop



foreach $image (@images){
    
    $begin=rindex($image,"/");
    $end=rindex($image,".");
    $len=$end-$begin;
    $name=substr($image,$begin+1,$len-1);
    
    print "NAME $name\n";

    system "gdalinfo $image &> /tmp/tilelog";
    $errs=`grep ERROR  /tmp/tilelog|wc -l|awk '{print $1}'`;
    
    if($errs > 0){

	print "$image input file format not recognized\n";
	print LOGFILE "$image input file format not recognized\n"
	
    }
    else{

	print "IMAGE\n",  $image,"\n";


# detect bounding box	

	@finfo = `gdalinfo $image`;

	    
	@bbsearch="Upper Left";
	@topl = grep /@bbsearch/,@finfo;

	@bbsearch="Lower Right";
	@botr = grep /@bbsearch/,@finfo;
	
	print "Looking for bounding box:\n";
	print "@topl\n";
	print "@botr\n";
	
	    

	$start=index("@topl","(");
	$end=index("@topl",",");
	$minx =substr("@topl",$start+1,$end-$start-1);
	$start=index("@topl",",");
	$end=index("@topl",")");
	$maxy=substr("@topl",$start+1,$end-$start-1);
	$start=index("@botr","(");
	$end=index("@botr",",");
	$maxx =substr("@botr",$start+1,$end-$start-1);
	$start=index("@botr",",");
	$end=index("@botr",")");
	$miny=substr("@botr",$start+1,$end-$start-1);
	print "BB minx $minx maxx $maxx miny $miny maxy $maxy\n";


# Get projection info 

	if ($type==1){

	    $utm1 = "@utm";
	    $utmsearch = "UTM";
    
	    @utm = grep /$utmsearch/,@finfo;

	    print "@utm\n";

	    $loc=index("@utm","zone");
	  
	    if($loc == -1){
		$loc=index("@utm","Zone");

		if($loc == -1){
		    $loc=index("@utm","ZONE");
		}
	    }


	    if($loc == -1){

		print "Image UTM zone info not found\n" ;
		print LOGFILE "Image UTM zone info not found\n" ;
		print LOGFILE "$image\n";
		    
	    }


	    $loc=$loc+3;
	    $iutm=substr("@utm",$loc+2,2);

	    $izone = substr("@utm",$loc+5,1);
	
	    if ($izone ne "N" && $izone ne "S"){
		$izone = substr("@utm",$loc+4,1);

		if ($izone ne "N" && $izone ne "S"){
		    print "Could not find hemisphere information\n";
		    print LOGFILE "Could not find hemisphere information\n" ;
		    print LOGFILE "$image\n" ;
		}
	    }
	    
	    print "UTM $iutm,HEMI $izone\n";

	    if ($iutm =~ /^[+-]?\d+$/ ) {
		print "IMAGE UTM Zone = $iutm\n";
		
	    } else {
		# Some strange definitions met...
	
		print "Problems...trying to solve.\n";
		$utmsearch = "UTM";

		@utm = grep /$utmsearch/,@finfo;
    
		$utm1 = "@utm";
    
	
		$iutm = substr($utm1,17,2);
		$izone = substr($utm1,20,1);

	    
	    }
 
	    if ($iutm =~ /^[+-]?\d+$/ ) {

		print "$iutm,$izone\n";	
	    } else {
		
		print "Error parsing UTM zone information\n";
		print LOGFILE "Error parsing UTM zone information\n" ;
		print LOGFILE "$image\n";

	    }


	    if( $izone eq "N" ){
		$izone ="+north"; # 
	    }
	    elsif( $izone eq "S" ){ 
		$izone = "+south" ;
	    }
	    else {

		$izone="none";
		print "Could not detect hemisphere for $image\n";

	    }

	    @ICRS=sprintf("+proj=utm +zone=%s +datum=%s %s",$iutm,"WGS84",$izone);

	}


	seek (LIST,0,0);
	$points=0;
	while (<LIST>) {

	    $points++;
		    
#Create variables from database 

	    $line = $_; chomp($line); 
	    ($tileid,$x,$y)=split(' ',$line);
	    
	    print "POINT COORDINATES = $x,$y\n";


# try to cut the tile from all tif and img images in this directory





	    $in=0;
	    $out=0;
	  

    
# Transform the lat/lon coordinate to proper UTM zone
	
		

	    print "echo $x $y | cs2cs  @PCRS +to @ICRS";
	    $transs = `echo $x $y | cs2cs  @PCRS +to @ICRS`;
	    		

	    @transss = split(/ /,$transs);
	    $utms = @transss[0];
	    @coords = split('\s+',$utms);
		
	    $x1 = @coords[0];
	    $y1 = @coords[1];


	    print "POINT2 $x1 $y1\n";
	    print "\n";

# check if the point falls within the scene
		
	    $inside=0;

	    if ($x1 > $minx && $x1 < $maxx && $y1 > $miny && $y1 < $maxy){
		$inside=1;

	    }
		
	    if ($inside == 1){
    

#calculate block boundaries (10km, 20km and 40km)

		$ulx40km=$x1-20040; $uly40km=$y1+20040; $lrx40km=$x1+20040; $lry40km=$y1-20040;
		$ulx20km=$x1-10020; $uly20km=$y1+10020; $lrx20km=$x1+10020; $lry20km=$y1-10020;
		$ulx10km=$x1-5010; $uly10km=$y1+5010; $lrx10km=$x1+5010; $lry10km=$y1-5010;
	
		print "UPPER LEFT X = $ulx20km\n";
		print "UPPER LEFT Y = $uly20km\n";
		print "LOWER RIGHT X = $lrx20km\n";
		print "LOWER RIGHT Y = $lry20km\n";
			
# original version kept all in the LS projection

    
		print "From $ICRS\n";
		print "To @PCRS\n";
			

		system "gdalwarp -te $ulx20km $lry20km $lrx20km $uly20km -tr 30 30 $image /tmp/tiletmp.tif\n";
		system "gdalwarp -s_srs \"@ICRS\" -t_srs \"@PCRS\" /tmp/tiletmp.tif $outname$name\_$tileid.tif\n";
		system "rm /tmp/tiletmp.tif\n";

			
	    }
	    else{
		print "INFO $x1 is not between $minx - $maxx or\n";
		print "INFO $y1 is not between $miny - $maxy\n";	
		print "point $tiled is outside of the $image\n";
		
	    }
	}

		system "echo $points points analyzed for image $image"
    }
}

system "cat /tmp/errors.log";
