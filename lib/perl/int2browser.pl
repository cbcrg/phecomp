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

$param = &process_param (@ARGV);

#Reads the data
$d = &readData ($d, $param);

###RUNNING OPTIONS
if ($param->{convert} eq "cytobandFile")
  {
    &changeDayPhases2cytobandLikeFile ($d);
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
	        print "$line\n\n";
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
#    $rp->{action} = 1;
#    $rp->{output} = 1;
    $rp->{outdata} = 1;
#    $rp->{add} = 1;
#    $rp->{bin} = 1;
#    $rp->{countBin} = 1;
#    $rp->{infile_format} = 1;
#    $rp->{outBins} = 1;
#    $rp->{outLogodd} = 1;
#    $rp->{out} = 1;
    
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
  
changeDayPhases2cytobandLikeFile
  {
    my $d = shift;
    my $param = shift;
    
    my $ph = $param->{phase};
    my $iniLightPh = $param->{iniLight};
    
    #By the moment I set the delta phase to 12 in case the phases are not symetric then I should see how to further implement the code
    my $deltaPh = 12; # = $A->{deltaPh}; my deltaPhTwo = 24 - $deltaPh;  
    
    my ($a,$b, $start, $end, $delta, $secAfterLastMidnight, $firstPhLightChange, $day); 
    
    return (0);
  }
  
sub data2phase
  {
    my $d = shift;
    my $A = shift;
    
    my $ph = $A->{phase};
    my $iniLightPh = $A->{iniLight};
    
    #By the moment I set the delta phase to 12 in case the phases are not symetric then I should see how to further implement the code
    my $deltaPh = 12; # = $A->{deltaPh}; my deltaPhTwo = 24 - $deltaPh;  
    
    my ($a,$b, $start, $end, $delta, $secAfterLastMidnight, $firstPhLightChange, $day); 
    
    my $time={};
    
    $start=$end=-1;
    
    #Traversing all intervals to set initial and end time
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
      
    if (!$ph){$ph="lightDark"; $delta = 3600*12;}    
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
    
    $secAfterLastMidnight = $start % (3600 * 24);                
    
    if ($secAfterLastMidnight > (3600 * $iniLightPh))
      {
        $firstPhLightChange =  $start - $secAfterLastMidnight  + ($iniLightPh * 3600) + (24 * 3600);    
      }
    else 
      {
        $firstPhLightChange =  $start - $secAfterLastMidnight  + ($iniLightPh * 3600);
      }
    
    #print STDERR "start: $start first phase change is $firstPhLightChange\n";  
    
    #Both the days and the phases are annotated    
    if ($A->{'phase'} eq "phasePeriod") 
      {                
        #Time points before first light phase change are annotated here    
        for ($a=$firstPhLightChange -($deltaPh * 3600); $a < $firstPhLightChange; $a++)
          {
            $time->{$a}="1_Light";         
          }
        
        for ($a=$firstPhLightChange -(24 * 3600); $a < $firstPhLightChange -($deltaPh * 3600); $a++)
          {
            $time->{$a}="1_dark";         
          }
                
        $day =2;
    
        for ($b=1, $a=$firstPhLightChange; $a<$end; $b++)
          {
            for (my $c=0; $c<24*3600; $c++, $a++)
              {
                
                if ($c < $deltaPh*3600 )
                  {                                      
                    $time->{$a}=$day."_Light";
                  }
                else
                  {                    
                    $time->{$a}=$day."_dark";                    
                  }                  
              }
            $day++;
          }
      }
    
    #only phase (Light/dark) annotation  
    else 
      {
        #Time points before first light phase change are annotated here    
        for ($a=$firstPhLightChange -($deltaPh * 3600); $a < $firstPhLightChange; $a++)
          {
            $time->{$a}="dark";         
          }
        
        for ($a=$firstPhLightChange -(24 * 3600); $a < $firstPhLightChange -($deltaPh * 3600); $a++)
          {
            $time->{$a}="Light";         
          }
                            
        for ($b=1, $a=$firstPhLightChange; $a<$end; $b++)
          {
            for (my $c=0; $c<24*3600; $c++, $a++)
              {
                
                if ($c < $deltaPh*3600 )
                  {                                   
                    $time->{$a}="Light";
                  }
                else
                  {                    
                    $time->{$a}="dark";                    
                  }                   
              }
          }
      }  
          
    #Now real time points are annotated
    #If an interval belongs to both phases it will be annotated with the phase in which it starts
    
    foreach my $c (sort(keys (%$d)))
      {
	   foreach my $t (sort(keys (%{$d->{$c}})))
	     {
	       my $phase=$time->{$t};
	       $d->{$c}{$t}{period}=$time->{$t};
	     }
      }
    
    delete($A->{period});
    delete($A->{phase});
    
    return $d;
      
  }