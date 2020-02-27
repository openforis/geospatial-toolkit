#!/usr/bin/perl

############### Author : 	Rémi d'Annunzio {mailto:remi.dannunzio@fao.org}  ########
############### Last update :	21/09/2013
#
# Count the occurence of a pixel value in a raster image 
# Option1 : specify the value of the pixels you want to count. Default is total number of pixels
# Option2 : output the number of pixels with (-v),  below (-b) or above (-a) the value. Default is -v
# Option3 : specify the band of the image. Default is Band 1
#########################################################################################

$version="1.1";

if ($#ARGV < 0 or $#ARGV > 3 ) {
    
    $nbr_args=$#ARGV;
    
   	print "Version $version\n";
   	print "Count the number of pixels within a reference image specifying value of pixel\n";
	print "Usage:   oft-countpix.pl <image> [value [-b/-v/-a [band]]] \n";
    exit;

}

# Record the arguments
$image="@ARGV[0]";
$value="@ARGV[1]";
$ba="@ARGV[2]";
$b="@ARGV[3]";

chomp($image);
chomp($value);
chomp($ba);
chomp($b);



# Create a temporary directory where to put your files	
$tempdir=`mktemp -d --tmpdir histtempXXX`;
chomp($tempdir);

if($b){$b=$b-1;}
$band=$b+1;

# Generate the histogram of the image. 
@info=`oft-mm $image`;

@maxval=grep /Band $band max /,@info;
$maxval=@maxval[0];
chomp($maxval);
$maxval=~s/Band $band max = //;

@minval=grep /Band $band min /,@info;
$minval=@minval[0];
chomp($minval);
$minval=~s/Band $band min = //;

$maxtemp=$maxval;

while($maxtemp ne ''){
	$maxvalue=$maxtemp;
	$bandtemp ++;
	@maxvalue=grep /Band $bandtemp max /,@info;
	$maxtemp=@maxvalue[0];
	chomp($maxtemp);
	$maxtemp=~s/Band $bandtemp max = //;}

	if(@ARGV[1] eq ''){$value=$minval-1;$ba="-a";}
	elsif($maxval eq ''){die("Error - Check band value\n");}
	elsif($value>$maxval or $value < $minval){
		die("Check range: $minval < value < $maxval\n");
					}
system "oft-his -i $image -o $tempdir/temp_hist.txt -hr -maxval $maxvalue>/dev/null";
@hist=`cat $tempdir/temp_hist.txt`;
chomp(@hist);

$hist=@hist[$b];

# Compute and store the 3 first values of the histogram
	$hist=~s/ /"toto"/;
	($mask,$hist)=split("toto",$hist);
	chomp($hist);

	$hist=~s/ /"toto"/;
	($size,$hist)=split("toto",$hist);
	chomp($hist);
	$size=~s/\"//;
	$size=~s/\"//;
	chomp($size);

	$hist=~s/ /"toto"/;
	($nband,$hist)=split("toto",$hist);
	chomp($hist);

# Pick up the histogram frequence, up to the desired value
$k=4;
$add=0;

while($k <= $value +4){
	$hist=~s/ /"toto"/;
	($val,$hist)=split("toto",$hist);
	chomp($hist);
	$val=~s/\"//;
	$val=~s/\"//;
	chomp($val);
	$add=$val+$add;
	$k ++;
	}

# Print the output
$below=$add-$val;
$above=$size-$add;
	if($ba eq "-b"){
		print "$below\n";
			}
	elsif($ba eq "-a"){
		print "$above\n";
			}
	else{
		print "$val\n";
			}

# Remove temporary files
system "rm -r $tempdir";


