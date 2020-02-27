#!/usr/bin/awk -f
BEGIN{
    
    version=1.0
    printf(stdout,"Open Foris Geospatial Toolkit\n",version);
    printf(stdout,"oft-hislookup.awk\nVersion %f\n",version);
    

}
 

    

{

    # read in cumulative histogram to which we will match
 
    if(NR==FNR){ 
	for(i=3 ; i <= NF ; i++){
	    val_band=$1"_"i; 
	    to[val_band]=$i;
	}	    
	next;
    } else {
	



	if(NR==1){


	    nextfile	    
	    for(i=3 ; i<= NF ; i++) 
		current_rec[i]=0;



	}

    # now let us read the histogram to be matched and look 
    # for the output values

    # look for matching values for every band
    # as we start from 0 next matching value will 
    # always be larger then the previous one


    # for every band look for teh mathing value in the target histogram
    # id[i] start from 0 and is incerased during the search
    

	printf("%i",$1);

	for( i = 3 ; i <= NF ; i++){
	    tmp_id=sprintf("%i_%i",current_rec[i],i)
	
	    old_id=tmp_id;

	    while( to[tmp_id] < $i  ){	   

		current_rec[i]=current_rec[i]+1;
		tmp_id=sprintf("%i_%i",current_rec[i],i)
	    }


	# now we've found the approximate histogram value
	# and we can choose the nearest value
	

	    

		if(to[tmp_id] - $i > $i - to[old_id])
		    printf(" %i",old_id)
		else
		    printf(" %i",current_rec[i])


	}
	printf("\n");
    }
}

