#!/usr/bin/awk -f
BEGIN{
    

    
    version=1.1

    # AP fixed first printf 03Oct2012

    printf(stdout,"Open Foris Geospatial Toolkit\n");
    printf(stdout,"oft-hismatch.awk\nVersion %f\n",version);
    printf(stdout,"param %i %i %i\n",minval,maxval,band);


}
{




    # look for record min val 

    rowmin=$(6 + band)
    rowmax=$(6 + band)

# if band is not given use global min and max

    if(band == 0)
	for(i=6;i<=NF;i++){
	    if($i < rowmin) 
		rowmin = $i;
	    else if( $i > rowmax)
		rowmax=$i
	} else {


	if($(5 + band) < rowmin) 
	    rowmin = $(5+band);
	else if( $(5+band) > rowmax)
	    rowmax=$(5 + band)
	

    }
	

    if(rowmin > minval && rowmax < maxval) { 

	valid++;

	# initialize min and max using first valid record

	if(valid == 1){
	    for(i=6;i<=NF;i++){
		min[i]=$i;
		max[i]=$i;
	    }
	    
	    globmin=min[1];
	    globmax=max[1];
	}

	# if all the observations are valid, compute
	# cumulative histogram for all bands (cols)
	# and update global band (col) min and max vals
    
    
	for(i=6;i<=NF;i++){

	    if($i < min[i])
		min[i] = $i
	    else if($i > max[i])
		max[i] = $i
	    
	    id=i"_"int($i)
	    freq[id]=freq[id]+1;
		
	}
    }

}END{
 
    # not the histogram has been computed and we know the nbr of valid 
    # observations as well as min and max vals for each band
    # for the sake of simlicity, useglobal min and max values for every band
    # when writing the results

    # look for global min and max

    if(valid == 0){
	printf("No valid observations. Please change thresholds and re-run\n");
	exit(1);
    }



    for(i=6 ; i <= NF ; i++){

	if(min[i] < globmin)
	    globmin=min[i];
	else if(max[i] > globmax)
	    globmax=max[i];
	    

    }
    
    for(i=globmin ; i<= globmax ; i++){

	printf("%i %i",i,valid);
	
	for(j=6;j<=NF;j++){
	    id=j"_"i
	    sum[j]=sum[j]+freq[id]/valid
	    printf(" %f",sum[j]);
	}
	
	printf("\n");
    }
 }