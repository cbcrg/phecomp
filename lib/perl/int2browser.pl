#!/usr/bin/env perl

use strict;
use FileHandle;
use XML::Simple;
use Data::Dumper;

my $param;
my $d={};
my $HEADER;
my %WEIGHT;
my $diffCh = 0;
our @channel;

our @blackGradient = ("226,226,226", "198,198,198", "170,170,170", "141,141,141", "113,113,113", "85,85,85", "56,56,56", "28,28,28", "0,0,0");
our @blueGradient = ( "229,229,254", "203,203,254", "178,178,254", "152,152,254", "127,127,254", "102,102,254", "76,76,173", "51,51,162", "0,0,128");
our @redGradient = ("254,172,182", "254,153,162", "254,134,142", "254,115,121", "254,96,101", "254,77,81", "254,57,61", "254,38,40", "254,19,20");
our @greenGradient = ("203,254,203", "178,254,178", "152,254,152", "127,254,127", "102,254,102", "76,254,76", "51,254,51", "0,254,0", "25,115,25"); 

our @intervals = ("0.03", "0.04", "0.05", "0.06", "0.07", "0.08", "0.09", "1", "1000");

our $colorsGrad = {};
$colorsGrad ->{"water"} = [@blueGradient];
$colorsGrad -> {"food_sc"} = [@blackGradient];
$colorsGrad -> {"food_cd"} = [@redGradient];
$colorsGrad -> {"food_fat"} = [@greenGradient];

our $colorsSingleTone = {};
$colorsSingleTone -> {"water"} = "0,0,255";
$colorsSingleTone -> {"food_sc"} = "0,0,0";
$colorsSingleTone -> {"food_cd"} = "255,0,0";
$colorsSingleTone -> {"food_fat"} = "0,128,0";

@channel = ("Intake 1", "Intake 2", "Intake 3", "Intake 4");

$param = &process_param (@ARGV);

#Reads the data
$d = &readData ($d, $param);

$param = setOutputName ($param);

###RUNNING OPTIONS
#If this option is set the bed files for each cage and channel, the genome and the cytoband file will be generated at the same time
if ($d && $param->{allFiles} eq "genomeBrowser")
  {
  	$param = &setAllOptions ($param);
  }

if ($d && $param->{generate} eq "cytobandFile")
  {
    &changeDayPhases2cytobandLikeFile ($d, $param);
  }  

if ($d && $param->{generate} eq "phase2bed")
  {
    &changeDayPhases2bedLikeFile ($d, $param);
  } 
  
if ($d && $param->{convert} eq "int2bed")
  {  	
    &int2bed ($d, $param);
  } 
  
if ($param->{create} eq "chr")
  {
    &fromInt2chromosome ($d, $param);
  }  

if ($param->{process} eq "files2bed")
  {
    &fromLengthFiles2bed ($d, $param);
  }  
    
if ($d && $param->{outdata} ne "no")
  {  
    &display_data ($d, $param); 
  }
  
sub readData 
  
  {
    my $d = shift;
    my $p = shift;
    
    if ($p->{data}) 
      {
        my @fl=split (/\s+/, $p->{data});
                
        foreach my $ff (@fl)
          {
            if ( -e $ff) 
              {                                    
                $d = &parse_data ($ff);                
              }
             
            else 
            	{
            		print STDERR "\nERROR: $ff does not exist [FATAL]\n";
            		exit(1);
            	}
          }
        }  
      return ($d);
  }
  
sub parse_data
  {
    my $file=shift;
    my $data={};
    
    my $F=new FileHandle;
    my $linen;
    open($F, $file);
    
    while (<$F>)
      {
	my $line=$_;
	$linen++;
	
	if ( $line=~/#d/)
	  {
	    my $L={};
	    chomp $line;
	    my @v=split (/;/,$line);
	    shift @v; #get rid of the line header(i.e.#d) 
	    while (@v)
	      {
		my $key=shift @v;
		my $value= shift @v;
		$L->{$key}=$value;
		
	      }
	    $L->{linen}=$linen;
	    $L->{period}="1";
	    	    
	    if ($L->{Duration}!=0)
	      {
	    	$L->{Velocity}=$L->{Value}/$L->{Duration};
	      }
	    else
	      {
	    	$L->{Velocity}=0; 
	      }	   
	    
	    if ($L->{Type})
	      {
		my $c=$L->{CAGE};
		my $ch=$L->{Channel};
		my $t=$L->{StartT};
		
		foreach my $k (keys(%$L))
		  {
		    $data->{$c}{$t}{$k}=$L->{$k};
		  }
	      }
	  }
	else
	  {
	    if ( $line=~/Weight/ && $line=~/ANIMALS DATA/)
	      {	   
		    $line=~/.*;(\d+);Weight;([.\d]+)/;
		    my $c=$1;
		    my $w=$2;
		    		   
		    if (!$WEIGHT{$c}{start})
		      {
		        $WEIGHT{$c}{start}=$w;
		      }
		    else 
		      {
		        $WEIGHT{$c}{end}=$w;
  		      }
  		    
  		    $WEIGHT{$c}{max}=($WEIGHT{$c}{max} < $w)?$w:$WEIGHT{$c}{max};
	       }
	     $HEADER.=$line;
	   }
      }
    
    foreach my $c (keys (%WEIGHT))
      {
	if ($WEIGHT{$c}{start}){	$WEIGHT{$c}{delta}=(($WEIGHT{$c}{end}-$WEIGHT{$c}{start})*100)/$WEIGHT{$c}{start};}
      }
    
    #reformat/annotate fields fields
    $data=&channel2correct_channel ($data);
           
    $data=&channel2Nature($data);
         
    return $data;
  }

sub display_data
  {
    my $d=shift;
    #my $file=shift;
    my $file= $param->{outdata};
    my $F= new FileHandle;

    if (!$file){open ($F, ">-");}
    else {open ($F, ">$file");}

    if ($param->{output}!~/R/)
      {	
	    print $F "$HEADER";
	    
      	foreach my $c (sort ({$a<=>$b}keys(%$d)))
      	  {
      	    foreach my $i (sort {$a<=>$b}keys (%{$d->{$c}}))
      	      {
        		print $F "#d;";
        		foreach my $k (sort (keys (%{$d->{$c}{$i}})))
        		  {
        		    print $F "$k;$d->{$c}{$i}{$k};";
        		  }
      		    print $F "\n";
      	      }
      	  }
	    close ($F);
      }
    else
      {
    	&data2R_header($d);
    	&data2R_records($d);
    	
    	close ($F);
      }
  }  
  
sub channel2correct_channel
    {
      #THis function corrects all sorts of labelling errors made by the acquisition equipment
      my $d=shift;
      my ($tot, $n);

      foreach my $c (keys (%$d))
	{
	  foreach my $t (keys (%{$d->{$c}}))
	    {
	      my $Name=$d->{$c}{$t}{Name};
	      my $Channel=$d->{$c}{$t}{Channel};
	      my $Caption=$d->{$c}{$t}{Caption};
	      
	      $Channel=~/.*(\d)/;
	      my $i=$1;
	      
	      #This is meant to correct the wrong labelling of the intakes: 1 and 2 are always drink, 3 and 4 are always food
	      if ($i==1){$d->{$c}{$t}{Caption}="Drink 1";}
	      elsif ($i==2){$d->{$c}{$t}{Caption}="Drink 2";}
	      elsif ($i==3){$d->{$c}{$t}{Caption}="Food 1";}
	      elsif ($i==4){$d->{$c}{$t}{Caption}="Food 2";}
	      else
		{
		  print STDERR "\n*** ERROR: unknown index for the Intake\n";
		}
	      if ($Caption ne $d->{$c}{$t}{Caption}){$tot++;}
	      $n++;
	    }
	}
      print STDERR "\nclean_data: relabled $tot values out of $n\n";
      return $d;
    }

sub channel2Nature
      {
	# This function creates a label describing the precise content of each intake
	my $d=shift;
		
	foreach my $c (sort(keys (%$d)))
	  {
	    foreach my $t (sort(keys (%{$d->{$c}})))
	      {
			my $Name=$d->{$c}{$t}{Name};
			my $Channel=$d->{$c}{$t}{Channel};
			my $Caption=$d->{$c}{$t}{Caption};
			
			$Channel=~/.*(\d)/;
			my $i=$1;
			my $Nature="";
		
			$d->{$c}{$t}{SlotI}=$i;
			
			$Name=lc ($Name);
			$Name=~s/\s//g;
			
			if ((length ($Name)) == 4 && ($Name =~/(w)(w)(s)(s)/ || $Name =~/(w)(w)(c)(s)/ || $Name=~/(w)(w)(s)(c)/ || $Name=~/(w)(w)(c)(s)/ || $Name=~/(w)(w)(f)(f)/))
			  {
			    
		      	if ($i==1) 
		      		{
		      			$Nature.=&anot2nature ($1);		      			
		      			($diffCh)? $Nature.="_$i" : $Nature=$Nature;#many times we have water in both channels, separate them into water_1 and water_2		      			
		      		}
		      		
		      	elsif ($i==2) 
		      		{
		      			$Nature.=&anot2nature ($2);
#		      			$Nature.="_$i";#many times we have water in both channels, separate them into water_1 and water_2		      
                        ($diffCh)? $Nature.="_$i" : $Nature=$Nature;#many times we have water in both channels, separate them into water_1 and water_2	
		      		}
		      		
		      	elsif ($i==3) 
		      		{
		      			$Nature.=&anot2nature ($3);
                        ($3 == $4 && $diffCh)? $Nature.="_$i" : $Nature=$Nature;		      			
		      		}
		      		
	      		elsif ($i==4) 
	      			{
	      				$Nature.=&anot2nature ($4);
                        ($4 == $3 && $diffCh)? $Nature.="_$i" : $Nature=$Nature;	      				
	      			}		
				
				#print STDERR "$Nature\n";
			  }
			      
			elsif ($Caption=~/Food/){$Nature="food";}
			
			elsif ($Caption=~/Drink/)
			  {
			  	my $nat = lc($Caption);
			  	
			  	#separating old annotated files into drink_1 and drink_2
			  	$nat =~ s/\s/_/g;
			  	$Nature = $nat;
			  }
			  
			else {$Nature="drink";}
		
			if ($Nature eq "food")
			  {
			    #print STDERR "--$Name--\n";
			    			     
				if ($Name eq "sc"){$Nature.="_sc";}
			    
			#####################
			#Modification 31/08/2010
			#Female file different codification of CD slots
			    
			    #elsif ($Name =~/cd/ && $Nature eq "food")
		    	elsif (($Name =~/cd/ || $Name=~/choc/) && $Nature eq "food")
			      {
					if    ($i==1 && (($Name =~/slota/) ||($Name =~/ina/) )){$Nature.="_cd";}
					elsif ($i==2 && (($Name =~/slotb/) ||($Name =~/inb/) )){$Nature.="_cd";}
					elsif ($i==3 && (($Name =~/slotc/) ||($Name =~/inc/) )){$Nature.="_cd";}
					elsif ($i==4 && (($Name =~/slotd/) ||($Name =~/ind/) )){$Nature.="_cd";}
					else  {$Nature.="_sc";}
			      }
				          
				    
				else
			      {
				     #print "ERROR: $Name\n";
			      }
			  }
			
			if    ($Name =~/sc/ && $Nature eq "food"){$Nature="sc_".$Nature;}		
			#elsif ($Name =~/cd/){$Nature="cd_".$Nature;}
			elsif (($Name =~/cd/ || $Name =~ /choc/) && $Nature eq "food"){$Nature="cd_".$Nature;}
			#########end modification 31/08/2010
			
			$d->{$c}{$t}{Nature}=$Nature;
		
	      }
	  }
	  
	return $d;
  }

#anot2nature match the given symbol of annotation with the appropiated type of food or liquid, i.e. (s->standard chow, f->fat food)
sub anot2nature
	{
		my $annot = shift;
		
		
		SWITCH: 
                {
                  ($annot eq "w") && do 
                    { 
                      return ("water");
                      last SWITCH;
                    };
                    
                  ($annot eq "s") && do 
                    { 
                      return ("food_sc");                          
                      last SWITCH;
                    };
                      
                  ($annot eq "f") && do 
                    { 
                      return ("food_fat");                             
                      last SWITCH;
                    };
                    
                  ($annot eq "c") && do 
                    { 
                      return ("food_cd");                          
                      last SWITCH;
                    };  
                }
         
         print STDERR "FATAL ERROR: ANNOTATION PROVIDED $annot DOES NOT CORRESPOND WITH ANY OF THE VALID ANNOTATIONS\n";
         print STDERR "             ASK FOR THE INCLUSSION OF THIS ANNOTATION\n";
         die;
		
	}

#############################################
#                                           #
# FUNCTIONS                                 #
#                                           #
#############################################

#####################
# Parameters
#####################
  
sub process_param
  
  {
    my @arg=@_;
    my $cl=join(" ", @arg);
    
    my @commands=split (/\s\-+/,$cl);
    my $param={};
    
    
    foreach my $c (@commands)
      {
        if (!($c =~ /\S/)){next;}
        $c =~ /(\w+)\s*(.*)\s*/;
        my $k = $1;
        if (!$2) {$param->{$k} = 1;}
        else {$param->{$k} = $2;}
        $param->{$k} =~ s/\s*$//;
      }
    
    return check_parameters ($param);
  }

sub check_parameters 
  
  {
    my $p = shift;
    my $rp = {};
    
    $rp->{data} = 1;
    $rp->{out} = 1;
    $rp->{convert} = 1;
    $rp->{convertMode} = 1;
    $rp->{outBed} = 1;
    $rp->{outCytoband} = 1;
    $rp->{outPhaseBed} = 1;
    $rp->{outGenome} = 1;    
    $rp->{create} = 1;
    $rp->{generate} = 1;
    $rp->{process} = 1;
    $rp->{outFileDiv} = 1;
    $rp->{outFilesBed} = 1;
    $rp->{allFiles} = 1;
    $rp->{outdata} = 1;
    
    foreach my $k (keys (%$p))
      {
        if (!$rp->{$k})
          {
            print STDERR "\n****ERROR: $k is an unknown pararmeter[FATAL]***\n";
            die;
          }
          
        else
          {
            print STDERR "PARAM: -$k ---> [$p->{$k}]\n";
          }
      }
    return $p;
  }
  
sub changeDayPhases2cytobandLikeFile
  {
    my $d = shift;
    my $param = shift;
    my $ph = $param->{phase};
    my $iniLightPh = $param->{iniLight};
    my $outCytobandFile = $param->{outCytoband};
    #By the moment I set the delta phase to 12 in case the phases are not symetric then I should see how to further implement the code
    my $deltaPh = 12; # = $A->{deltaPh}; my deltaPhTwo = 24 - $deltaPh;  
    
    my ($a,$b, $start, $end, $delta, $secAfterLastMidnight, $firstPhLightChange, $day, $file); 
    my $time={};
    
    $start=$end=-1;
    
    #Traversing all intervals to set initial and end time
    ($start, $end) = &firstAndLastTime ($d, $param);
      
    if (!$ph) {$ph="lightDark"; $delta = 3600*12;}    
    elsif ($ph eq "lightDark") {$delta = 3600*12;}
    elsif ($ph eq "day") {$delta = 3600*24;}
    
    if (!$iniLightPh)
      {
        $iniLightPh = 6;
        print STDERR "WARNING: Beginning of the light phase has been set to 8:00 AM as you didn't provide any info (iniLight)\n\n";
      }
    elsif ($iniLightPh !~ /^\d+$/) 
      {
        $iniLightPh = 6;
        print STDERR "WARNING: Beginning of the light phase has been set to 6:00 AM GMT (8:00 spanish summer time) as the value provided by iniLight: $iniLightPh is not a number\n\n";
      }
    elsif ($iniLightPh < 1 || $iniLightPh > 24)
      {
        $iniLightPh = 6;
        print STDERR "WARNING: Beginning of the light phase has been set to 6:00 AM GMT (8:00 spanish summer time) as the value provided by iniLight: $iniLightPh is not in the correct range\n\n";
      }
    
    #Searching the first change to light phase taking place in the data
    $secAfterLastMidnight = $start % (3600 * 24);                
   
    #print $start, "\n";die;#del
    if ($secAfterLastMidnight > (3600 * $iniLightPh))
      {
      	#As the start is after the change to light, we calculate unix midnight, add seconds until change to light and we add a whole day
        $firstPhLightChange =  $start - $secAfterLastMidnight  + ($iniLightPh * 3600) + (24 * 3600);    
      }
    else 
      {
        $firstPhLightChange =  $start - $secAfterLastMidnight  + ($iniLightPh * 3600);
      }
    
    #opening the file
    $file = $outCytobandFile."_cytoBand".".txt";
    
    my $F= new FileHandle;
	vfopen ($F, ">$file");
	
    #is start more than 12 hours before first change to light phases? -> then start is occurring during the previous light phase     
    if ($start < ($firstPhLightChange - ($deltaPh * 3600)))
    	{
    		print $F "chr1", "\t", $start - $start, "\t", $firstPhLightChange -($deltaPh * 3600)- $start, "\t", "light", "\t", "gneg\n";
    		print $F "chr1", "\t", $firstPhLightChange -($deltaPh * 3600) - $start, "\t", $firstPhLightChange - $start, "\t", "dark", "\t", "gpos25\n";
    	}
    else 
    	{
    		print $F "chr1", "\t", $start - $start, "\t", $firstPhLightChange - $start, "\t", "dark", "\t", "gpos25\n";
    	}	

    my $lastEnd = $firstPhLightChange;
    my $lastPhase = "dark";
    my $colour = "gpos25";       
    	  
   	for ($a=$firstPhLightChange + 1; $a < $end; $a ++)
   		{	
   			$a = $a + 43199;
   			
   			if ($lastPhase eq "dark") {$lastPhase="light"; $colour = "gneg";}
   			else {$lastPhase = "dark"; $colour = "gpos25";}
   			
   			print $F "chr1", "\t", $lastEnd-$start, "\t", $a-$start, "\t", $lastPhase, "\t", $colour, "\n";
   			
   			$lastEnd = $a;
   		}
   		
   	close ($F);
   		
   	printf "      Cytoband like file in: $file\n";
  }

#This function will create a bed file within which intervals correspond to division into dark/light phases of the time length of the experiment
sub changeDayPhases2bedLikeFile
  {
    my $d = shift;
    my $param = shift;
    my $ph = $param->{phase};
    my $iniLightPh = $param->{iniLight};
    my $outBedPhFile = $param->{outPhaseBed};
    #By the moment I set the delta phase to 12 in case the phases are not symetric then I should see how to further implement the code
    my $deltaPh = 12; # = $A->{deltaPh}; my deltaPhTwo = 24 - $deltaPh;  
    
    my ($a,$b, $start, $end, $delta, $secAfterLastMidnight, $firstPhLightChange, $day, $file); 
    my $time={};
    
    $start=$end=-1;
    
    #Traversing all intervals to set initial and end time
    ($start, $end) = &firstAndLastTime ($d, $param);
      
    if (!$ph) {$ph="lightDark"; $delta = 3600*12;}    
    elsif ($ph eq "lightDark") {$delta = 3600*12;}
    elsif ($ph eq "day") {$delta = 3600*24;}
    
    if (!$iniLightPh)
      {
        $iniLightPh = 6;
        print STDERR "WARNING: Beginning of the light phase has been set to 8:00 AM as you didn't provide any info (iniLight)\n\n";
      }
    elsif ($iniLightPh !~ /^\d+$/) 
      {
        $iniLightPh = 6;
        print STDERR "WARNING: Beginning of the light phase has been set to 6:00 AM GMT (8:00 spanish summer time) as the value provided by iniLight: $iniLightPh is not a number\n\n";
      }
    elsif ($iniLightPh < 1 || $iniLightPh > 24)
      {
        $iniLightPh = 6;
        print STDERR "WARNING: Beginning of the light phase has been set to 6:00 AM GMT (8:00 spanish summer time) as the value provided by iniLight: $iniLightPh is not in the correct range\n\n";
      }
    
    #Searching the first change to light phase taking place in the data
    $secAfterLastMidnight = $start % (3600 * 24);                
   
    #print $start, "\n";die;#del
    if ($secAfterLastMidnight > (3600 * $iniLightPh))
      {
      	#As the start is after the change to light, we calculate unix midnight, add seconds until change to light and we add a whole day
        $firstPhLightChange =  $start - $secAfterLastMidnight  + ($iniLightPh * 3600) + (24 * 3600);    
      }
    else 
      {
        $firstPhLightChange =  $start - $secAfterLastMidnight  + ($iniLightPh * 3600);
      }
    
    #opening the file
    $file = $outBedPhFile."_Phase".".bed";
    
    my $F= new FileHandle;
	vfopen ($F, ">$file");
	
	print $F "track name=\"Day phases\" description=\"Track annotating the dark and light phase of the experiment\" visibility=2 color=0,0,255 useScore=1 priority=user\n";
	
	#print $firstPhLightChange, "\n";
    
    #Printing the first interval
    #print $firstPhLightChange -($deltaPh * 3600), "\t", $start-$start;
    
    #is start more than 12 hours before first change to light phases? -> then start is occurring during the previous light phase     
    if ($start < ($firstPhLightChange - ($deltaPh * 3600)))
    	{
    		print $F "chr1", "\t", $start - $start, "\t", $firstPhLightChange -($deltaPh * 3600)- $start, "\t", "light", "\t", "0\n";
    		print $F "chr1", "\t", $firstPhLightChange -($deltaPh * 3600) - $start, "\t", $firstPhLightChange - $start, "\t", "dark", "\t", "1000\n";
    	}
    else 
    	{
    		print $F "chr1", "\t", $start - $start, "\t", $firstPhLightChange - $start, "\t", "dark", "\t", "1000\n";
    	}	

    my $lastEnd = $firstPhLightChange;
    my $lastPhase = "dark";
    my $scorePhase = 1000;       
    	  
   	for ($a=$firstPhLightChange + 1; $a < $end; $a ++)
   		{	
   			$a = $a + 43199;
   			
   			if ($lastPhase eq "dark") {$lastPhase="light"; $scorePhase = 0;}
   			else {$lastPhase = "dark"; $scorePhase = 1000;}
   			
   			print $F "chr1", "\t", $lastEnd-$start, "\t", $a-$start, "\t", $lastPhase, "\t", $scorePhase, "\n";
   			
   			$lastEnd = $a;
   		}
   		
   	close ($F);
   		
   	printf "      Bed like file with day phases in: $file\n";
  }
    	
sub fromInt2chromosome
	{
		my $d = shift;
	    my $param = shift;
	    my ($a,$b, $start, $end, $outGenomeFile, $file); 
	   	my $outGenomeFile = $param->{outGenome};
	   	    
	    $start=$end=-1;
	    
	    #Traversing all intervals to set initial and end time    	
    	($start, $end) = &firstAndLastTime ($d, $param);    	
    	
    	#opening the file
    	$file = $outGenomeFile."Genome.fa";
    	
    	my $F= new FileHandle;
		vfopen ($F, ">$file");
		
    	print $F ">chr1\n";
    	
    	for ($a=$start - $start; $a < $end - $start; $a ++)
   			{
   				print $F "N";
   			}
   			
   		print $F "\n";
    	close ($F);
    	
		printf "      Chromosome for browser in: $file\n";
	}

sub fromLengthFiles2bed
	{
		my $d = shift;
	    my $param = shift;
	    my $outFileDiv = $param->{outFileDiv};
	    my $switch = 0;
	    
	    my ($intFile, $pIntFile, $intFileName, $endT, $outFile);
	    my @aryFiles;
	    $pIntFile = "";
	    
	    #Traversing all intervals to set initial and end time    	
    	my ($globalStart, $globalEnd) = &firstAndLastTime ($d, $param);
    			
	    foreach my $t (sort {$a<=>$b}keys (%{$d->{"1"}}))
	    	{
				#print "track file information\n";
				$intFile = $d->{"1"}{$t}{File};
				#print "----- $intFile\n";
				if ($intFile ne $pIntFile)
  					{
  						push (@aryFiles, $intFile);
  						print "track file information\n";
						  								
  						$intFileName = &path2fileName ($intFile);
  						$endT = $d->{"1"}{$t}{EndT};
  						print "----- $intFileName\t$endT\n";		  										  					
    					#print  "$k;$d->{$c}{$t}{$k};";		
  					} 
				
				$pIntFile = $intFile;
	    	}	
	    
	    #opening the file
    	$outFile = $outFileDiv."_fileDiv".".bed";
    	   	
    	my $F= new FileHandle;
		vfopen ($F, ">$outFile");
		
		#In this case we use itemRgb this flag is used to use define a precise color for each band inside track file
		print $F "track name=\"Int Files div\" description=\"Track annotating the length of each int file\" visibility=2  useScore=1 priority=user itemRgb=\"On\"\n";
		
		my $score=1000;		
		my $color="255,0,0";#red
		
	    foreach my $f (@aryFiles)
	    	{
	    		print STDERR "$f\n";#del
	    			    		
	    		my ($start, $end);
    			$start=$end=-1;    			
	    		 
	    		foreach my $c (sort ({$a<=>$b}keys(%$d)))
	  				{
	    				foreach my $t (sort {$a<=>$b}keys (%{$d->{$c}}))
	      					{	
	      						if ($f ne $d->{$c}{$t}{File}) {next;}
	      						my $cstart = $d->{$c}{$t}{StartT};
	    	    				my $cend = $d->{$c}{$t}{EndT};	      						
	      						
	      						if ($start==-1 || $start>$cstart){$start=$cstart;}
	      						if ($end==-1 || $end<$cend){$end=$cend;}
	      					}
	  				}
	  				  			
	  			print $F "chr1", "\t", $start-$globalStart, "\t", $end-$globalStart, "\t", $f, "\t", $score, "\t", "+","\t",$start-$globalStart, "\t", $end-$globalStart, ,"\t", $color, "\n";
	  			#$score = ($score == 0)? 1000 : 0;
	  			$color = ($color eq "255,0,0")? "255,215,0" : "255,0,0";
	    	}
	    
    	close ($F);
	    	
	}
	
sub firstAndLastTime
	{
		my $d = shift;
    	my $param = shift;
    	
    	my ($start, $end);
    	
    	$start=$end=-1;
    	
		foreach my $c (sort(keys (%$d)))
	      {
	    	foreach my $t (sort(keys (%{$d->{$c}})))
	    	  {	    	    
	    	    my $cstart = $d->{$c}{$t}{StartT};
	    	    my $cend = $d->{$c}{$t}{EndT};
	    	    
	    	    if ($start==-1 || $start>$cstart){$start=$cstart;}
	    	    if ($end==-1    || $end<$cend){$end=$cend;}
	    	  }
	      }
	      
		return ($start, $end);	  
	}
	     	
sub int2bed
	{
		my $d = shift;
    	my $param = shift;    	
    	
    	if (!exists ($param->{convertMode})) {$param->{convertMode} = "singleCh2track";}#by default each channel into a single track
    	
    	my $convertMode = $param->{convertMode};
    	    	   	
    	my ($start, $end, $startInt, $endInt, $nature, $value); 
    	
    	($start, $end) = &firstAndLastTime ($d, $param);
    	
    	#print $start, "\t", $end, "\n";#del
    	
    	if ($convertMode eq "singleCh2track")
    		{    		
    			int2bedSingleCh2track ($d, $param, $start, $end);
    		}
    	elsif ($convertMode eq "allFoodCh2track")
    		{
    			
    			int2bedAllFoodCh2track ($d, $param, $start, $end);
    		}
    	elsif ($convertMode eq "allCh2track")
    		{
    			print STDERR "kdkdkdkdkkd";
    		}
    	else
    		{
    			print STDERR "FATAL ERROR: problem while processing convertMode option\n";
    		}    	    		      	    	        
	}

sub int2bedSingleCh2track
	{
		my $d = shift;
    	my $param = shift;
    	my $start = shift;
    	my $end = shift;
    	my $bedName = $param->{outBed};
    	my ($startInt, $endInt, $nature, $value, $chN);
    	
    	#Defines the initial display mode of the annotation track. Values for display_mode include: 0 - hide, 1 - dense, 2 - full, 3 - pack, and 4 - squish
    	my $visibility = 2;#by the moment hardcoded in future it might be a parameter
    	my $color = "0,0,0";
    	my $priority = "user"; #from higher to low priority "user", "map", "genes", "rna", "regulation", "compGeno"
    	
		foreach my $c (sort ({$a<=>$b} keys(%$d)))
	  		{
	    		foreach my $ch (@channel)
	    			{
	    				$ch =~ m/(\d)/;
	    				$chN = $1;		  
	    					    					    				
	    				#Getting the label of the channel (food_SC, fat_food, ...)
	    				foreach my $t (sort (keys (%{$d->{$c}})))
      						{      							      								
      							if ($d->{$c}{$t}{Channel} eq $ch)
      								{
      									$nature = $d->{$c}{$t}{Nature};       									
      									$color = &natureValue2color ($nature);      									      												 
      									last;		
      								}
      							else
      								{
      									next;
      								}	
      						}
      							    				
	    				my $file = $bedName."cage".$c."ch".$nature.$chN.".bed";
	    				
	      				my $F= new FileHandle;
	      				
	      				vfopen ($F, ">$file");
	      				
	      				#Add track line specifications for the genome browser
	      				#link to field info http://genome.ucsc.edu/goldenPath/help/customTrack.html#TRACK
	    				print $F "track ";
	    				print $F "name=", "\"cage ", $c, "\;", $nature, "\"", " ";
	    				print $F "description=", "\"cage ", $c, "\;", $nature, "\"", " ";
	    				print $F "visibility=", $visibility, " ";
	    				print $F "color=", $color, " ";
	    				print $F "useScore=", "1", " ";
	    				print $F "priority=", $priority, " ";
	    				print $F "\n";
	    					    					    				
    					foreach my $t (sort (keys (%{$d->{$c}})))
      						{
      							if ($d->{$c}{$t}{Channel} ne $ch)
      								{next;}
      							else
      								{	
	      								$startInt = $d->{$c}{$t}{StartT} - $start;
	    								$endInt = $d->{$c}{$t}{EndT} - $start;	    								
	    								$value = int ($d->{$c}{$t}{Value} * 10000 + 0.5);
	    								#print $F "chr".$c, "\t", $startInt, "\t", $endInt, "\n";	    								 
	    								#print $F "chr1", "\t", $startInt, "\t", $endInt, "\t", $nature, "\t", $value, "\n";#too many nature labels	
	    								print $F "chr1", "\t", $startInt, "\t", $endInt, "\t", "\t", $value, "\n";				
	      							}	      					    				   					
	      					}
	      		
	      				close ($F);
	      				printf "      Intervals cage $c, channel $ch, nature $nature in: $file\n";
	  				}
	  		}
	}

sub int2bedAllFoodCh2track
	{
		my $d = shift;
    	my $param = shift;
    	my $start = shift;
    	my $end = shift;
    	my $bedName = $param->{outBed};
    	my ($startInt, $endInt, $nature, $value, $score, $chN);
    	
    	#Defines the initial display mode of the annotation track. Values for display_mode include: 0 - hide, 1 - dense, 2 - full, 3 - pack, and 4 - squish
    	my $visibility = 2;#by the moment hardcoded in future it might be a parameter
    	my $color = "0,0,0";
    	my $priority = "user"; #from higher to low priority "user", "map", "genes", "rna", "regulation", "compGeno"
    	    		   		   
    	foreach my $c (sort ({$a<=>$b} keys(%$d)))
	  		{
	  			#Two files open one for drink annotations and a second one for food annotations
		    	#Drink file
		    	my $Dfile = $bedName."cage".$c."Drink.bed";
			   	my $FD= new FileHandle;
			   	vfopen ($FD, ">$Dfile");			   	
	      		
	      		#Add track line specifications for the genome browser
      			#link to field info http://genome.ucsc.edu/goldenPath/help/customTrack.html#TRACK
    			print $FD "track ";
    			print $FD "name=", "\"cage ", $c, "\;", "drink", "\"", " ";
    			print $FD "description=", "\"cage ", $c, "\;", "drink", "\"", " ";
    			print $FD "visibility=", $visibility, " ";			    				
    			print $FD "itemRgb=\"On\"";#different natures have different color
    			print $FD "priority=", $priority, " ";
    			print $FD "\n";	
    					
			   	#Food File
			   	my $Ffile = $bedName."cage".$c."Food.bed";
			   	my $FF= new FileHandle;
			   	vfopen ($FF, ">$Ffile");
			   	print $FF "track ";
    			print $FF "name=", "\"cage ", $c, "\;", "food", "\"", " ";
    			print $FF "description=", "\"cage ", $c, "\;", "food", "\"", " ";
    			print $FF "visibility=", $visibility, " ";			    				
    			print $FF "itemRgb=\"On\"";#different natures have different color
    			print $FF "priority=", $priority, " ";
    			print $FF "\n";
			   	      					
      			foreach my $t (sort (keys (%{$d->{$c}})))
      				{
      					if ($d->{$c}{$t}{Channel} eq "Intake 1" ||  $d->{$c}{$t}{Channel} eq "Intake 2")
      						{		      							      							    					    					    	
		    					$startInt = $d->{$c}{$t}{StartT} - $start;
    							$endInt = $d->{$c}{$t}{EndT} - $start;
    							$value = $d->{$c}{$t}{Value};	    								
    							$score = int ($value * 10000 + 0.5);
    							$nature = $d->{$c}{$t}{Nature};
    							#$color = &nature2color ($nature);
    							$color = &natureValue2color ($nature, $value);
    							print STDERR "------------$color\n";
    							print $FD "chr1", "\t", $startInt, "\t", $endInt, "\t", "", "\t", $value, "\t", "+","\t",$startInt, "\t", $endInt, "\t", $color, "\n";							      								      					    				   								      						      		      					
      						}
      					
      					elsif ($d->{$c}{$t}{Channel} eq "Intake 3" ||  $d->{$c}{$t}{Channel} eq "Intake 4")
      						{		      							      							    					    					    	
		    					$startInt = $d->{$c}{$t}{StartT} - $start;
    							$endInt = $d->{$c}{$t}{EndT} - $start;	
    							$value = $d->{$c}{$t}{Value};    								
    							$score = int ($value * 10000 + 0.5);
    							$nature = $d->{$c}{$t}{Nature};
    							#$color = &nature2color ($nature);
    							$color = &natureValue2color ($nature, $value);
    							print STDERR "------------$color\n";
    							    							
    							print $FF "chr1", "\t", $startInt, "\t", $endInt, "\t", "", "\t", $value, "\t", "+","\t",$startInt, "\t", $endInt, "\t", $color, "\n";							      								      					    				   								      						      		      					
      						}      												
	  				}
	  				
  				close ($FD);
				close ($FF);
      				
      			printf "      Intervals cage $c, drink channels are in: $Dfile\n";
      			printf "      Intervals cage $c, foods channels are in: $Ffile\n";
	  		}	
	}

sub natureValue2color
	{
		my $nature = shift;
				
		my ($value, $color, $i);
		
		if (@ARGV) {$value = shift;} 	
		
		if ($value) 
      		{

      			for ($i=0; $i < scalar (@intervals); $i++)
      				{
						if ($value <= $intervals [$i])
      						{
      							$color = $colorsGrad -> {$nature} [$i];
      							#print STDERR "-------$nature -> $value -> $color \n";
      							last;		
      						}
      					else
      						{
      							print STDERR "FATAL ERROR: The color of an interval with value $value and nature $nature couldn't be assigned\n";
      						}
      					}      					
      		}
      	else
      		{
      			$color = $colorsSingleTone->{$nature};
      		}
      	
      	return ($color)
	}
		
sub vfopen 
  {
    my $f=shift;
    my $file=shift;

    if (($file =~/^\>/) && !($file =~/^\>\>/ )){open ($f, $file); return $f;}
    elsif (($file =~/^\>\>(.*)/))
      {
	if (!-e $1){	print STDERR "\nERROR: $file does not exist [FATAL]\n";exit(1);}
      }
    elsif (!-e $file){	print STDERR "\nERROR: $file does not exist [FATAL]\n";exit(1);}
   
    open ($f,$file);
    return $f;
  }	
  
sub setOutputName
  {
    my $param=shift;
    
    if (!$param->{out})
      {
		$param->{out}=$param->{data};
		$param->{out}=~s/\.[^\.]*$//;
	  }
    
    if (!$param->{outBed}) {$param->{outBed} = "$param->{out}";}
    if (!$param->{outCytoband}) {$param->{outCytoband} = "$param->{out}";}
    if (!$param->{outPhaseBed}) {$param->{outPhaseBed} = "$param->{out}";}
    if (!$param->{outGenome}) {$param->{outGenome} = "$param->{out}";}
    
    return $param;
  }  

sub setAllOptions
	{
		my $param=shift;
		
		$param->{generate} = "cytobandFile";
		$param->{convert} = "int2bed";
		$param->{create} = "chr";
		
		return ($param);		
	}

sub path2fileName 
  {
    my $f = shift;
                  
    if ($f =~ /^*.\//) #avoiding names as us/cn/file.act -> file.act  #REVIEW!!!!!
      {      
        my @a = split ("/",$f);        
        $f = pop (@a);      
      } 
    	
    return ($f);
    
  }