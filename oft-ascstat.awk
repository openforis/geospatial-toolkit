#!/usr/bin/awk -f
BEGIN{
    
    # added sample std on 3.Oct.2012

    version=1.1
    
    printf("Open Foris Geospatial Toolkit\n",version);
    printf("oft-ascstat.awk\nVersion %f\n",version);
    


}
{

    if(NR ==1) {

	for(i=1;i<=NF;i++){
	    min[i]=$i;
	    max[i]=$i;
	    sum[i]=0;
	    sum2[i]=0;
	    n[i]=0;
	}
    }

 
    for(i=1;i<=NF;i++){
	if($i < min[i]) 
	    min[i] = $i;

  	if($i > max[i]) 
	    max[i]=$i;



	sum[i]=sum[i]+$i;
	sum2[i]=sum2[i]+$i*$i

	nbr[i]=nbr[i]+1;
    }
}END{
    printf("%15s %15s %15s %15s %15s\n","Col","Min","Max","Avg","Std");
    for(i=1;i<=NF;i++)
	printf("%15i %15f %15f %15f %15f\n",i,min[i],max[i],sum[i]/nbr[i],sqrt(sum2[i] - ((sum[i]*sum[i])/nbr[i]))/(nbr[i]-1));
 }