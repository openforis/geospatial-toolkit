#!/usr/bin/perl

# original by Erik Lindquist @ fao org
# Dec 6 2011
# modified to add command line arguments by anssi pekkarinen @ fao org

$version="1.1";
$version="1.2";
$version="1.3";
$version="1.4";
$version="1.5";

# Sep 7 2012
# AP Fixed usage message
# May 29 2012
# AP added pixel size extracxtion

# June 4 2014
# AP added removal of existing output file


# switched to PROJ.4 format because of problems with GDAL 1.9.2


if ($#ARGV != 2 ) {
    
    $nbr_args=$#ARGV;
    
    print "Version $version\n";
    print "Subsets an image using extension of a reference image\n";
    print "Usage: oft-clip.pl <input_reference> <input_image> <output_image>  \n";

    exit;

} else {

    $homedir=`pwd`;

    print $homedir;

    
    $extent = $ARGV[0];
    $input =  $ARGV[1];
    $output = $ARGV[2];

    if (-e $output) {
     print "Output file exists! Removing\n";
     unlink $output;
    }



    print "Input:  $input\n";
    print "Output: $output\n";


    chomp($extent);
    chomp($input);
    chomp($output);

# delete output if it exists


# extract extent	

    @finfo = `gdalinfo $extent`;
	
    delete @finfo[0..3];
    

	#delete @finfo[35..500];
	
	$ulstring = "Upper Left";
	$lrstring = "Lower Right";
        $pxsz = "Pixel Size";
	@ul = grep /$ulstring/,@finfo;
	@lr = grep /$lrstring/,@finfo;
        @px = grep /$pxsz/,@finfo;

	$ult = "@ul";
	$lrt = "@lr";		
	$pxt = "@px";	

	$xmin = substr($ult,13,12);
	$xmax = substr($lrt,13,12);
	$ymin = substr($lrt,26,12);
	$ymax = substr($ult,26,12);
	$pxsz = substr($pxt,14,15);

	print "$xmin\n";
	print "$xmax\n";
	print "$ymin\n";
	print "$ymax\n";
        print "$pxsz\n";
# extract SRS info
    
    $ssed="sed s/\\'//g";
    
    system("gdalsrsinfo -o proj4 $extent |grep PROJ.4 |awk -F ':' '{print \$2}' |$ssed >/tmp/proj.prf");

    print "gdalwarp -t_srs /tmp/proj.prf -te $xmin $ymin $xmax $ymax -tr $pxsz $pxsz $input $output" ; 
    system("gdalwarp -t_srs /tmp/proj.prf -te $xmin $ymin $xmax $ymax -tr $pxsz $pxsz $input $output");

    chdir $homedir;

}	


		
