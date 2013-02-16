#!/usr/bin/env perl
# -filter field <field name> contains|equals|min|max value
# -bin

#######################################################################################################
###OPTIONS                                                                                          ###
### -diffChannel                   -> When this option is set channels with the same type of food   ###
###                                   but in different dispensers are differentiated (eg w1, w2)    ###  
### -period period <mode>          -> Mode: day/ week/ eleven/ month                                ###
###                  phase  <mode> -> Mode: phase / phasePeriod                                     ###
###                                   Annotation of phase only light and dark or phase and period   ###
###                                   (day 1, day 2, ...)                                           ###
###                  iniLight <n>  -> A single digit for the starting time of the light phase, on   ###
###                                   GMT TIME!!! By default is 6 which corresponds to 8:00 AM in   ###
###                                   Spanish summer time                                           ###
### -winLogodd win <n>             -> Sliding window of logodd using length of period n             ###
### -stats mail <mode>             -> Sending mail when a stats value is negative, in combination   ###
###                                   with the real time validation of mtb files                    ###
###       labels <mode>            -> Mode: compulse                                                ###
###                                   Labels of table by default have historical names if compulse  ###
###                                   is set then labels are like in compulse software              ###  
### -annotate interInterval <mode> -> Mode: meals/all Annotating inter-intervals time for only      ###
###                                   meals events or for all events                                ###
#######################################################################################################

use HTTP::Date;
use Data::Dumper;

use strict;
use FileHandle;
srand();
my $TAG=0;
my $BIN=0;

my $index;
my $SHIFT=4;
my $LOG_ZERO=-999999999;
my $LOG_UNDERFLOW=0.0000000000000000000001;
my $HEADER;
my $d={};
my $M={};
my $A={};
my %WEIGHT;
my $file=shift (@ARGV);
my $cl=join(" ", @ARGV);
our $mailTime = time ();
our $natureH = {};
 
#Reanotate command should be read before &run_instruction() that is why
#although not elegant I read this option here.
#This is meant to separate channels with the same type of food or liquid
#with 2 different labels, eg. water_1, water_1
my $diffCh = 0;

if ($cl =~ s/-diffChannel//) 
  {    
    $diffCh = 1;    
  }
  
my @commands=split (/\-+/,$cl); 
#test_bw_trainning();die;

$d=parse_data ($file);

foreach my $c (@commands)
  {
    
    run_instruction ($d, $A, $c);
  }
die;

sub run_instruction
  {
    my $d=shift;
    my $A=shift;
    my $c=shift;
    my $sep = '\s+';
    
    $A=string2hash ($c, $A, $sep);
	
	#Calculate interinterval time
	if ($c=~/^annotate/)
	 {
	   $d = &annotate($d, $A);
	 }
	 
    elsif ($c=~/^tag/) 
      {	
	     $d=tag($d, $A);
      }     
      
#    option to rename cage 6 from 13 to 18          
#    elsif ($c=~/^rename/)
#      {
#	$d=&rename ($d,$A); #print Dumper ($d);#del
#      }

    #bit stands for between intervals time (i.e. the time transcurred after next event occurs)  
    elsif ($c=~/^BIT/)
      {
	   $d = &data2BIT ($d,$A);
      }                           
    elsif ($c=~/^untag/)
      {
	$d=untag ($d,$A);
      }
    elsif ($c=~/^zfilter/)
      {
	$d=zfilter_data ($d,$A);
      }
    elsif ($c=~/^filter/)
      {
	$d=filter_data ($d,$A);
      }
    
    elsif ($c=~/^coll/)
      {
	$d = coll ($d,$A);
      }
    
    elsif ($c=~/^unbin/)
      {
	$d=unbin ($d,$A);
      }
    elsif ($c=~/^bin/)
      {
	$d=data2bin ($d,$A);
      }  
    
    elsif ($c=~/^period/)
      {	
      	 #with this function it is possible to separate in dark and light phases
      	 #or in periods since the beginnig of the recording	
         $d = data2tempDiv ($d,$A);
	     #$d=data2period ($d,$A);
      }
      
    elsif ($c=~/^logodd/)
      {
	   data2log_odd ($d, $A);
      }
      
    elsif ($c=~/^winLogodd/)
      {
	   data2log_oddWindow ($d, $A);
      }
      
    elsif ($c=~/^stat/)
      {
	data2stat($d, $A);
      }
    elsif ($c=~/^seq2model/)
      {
	($d,$A)=seq2model ($d,$A);
      }
    elsif ($c=~/^decode/)
      {
	($d,$A)=decode ($d,$A);
      }
    elsif ($c=~/^out/)
      {	     
	#display_data ($d, $A->{outdata}); 
	#display_data ($d, $A->{outdata}, );
	display_data ($d, $A);
      }
    elsif ($c=~/^outmodel/)
      {
	display_model ($A->{dataR}, $A->{outmodel});
      }
    elsif ($c=~/^test/)
      {
	test_bw_trainning($A);
      }
    return;
  }

  #test_bw_trainning ();

  my $d={};
$d=&parse_data ($ARGV[0], $d,0,0.01);

$d=filter_data ($d, "Nature", "char", "keep", "food");
#%data=filter_data (\%data, "Cage", "int", "keep", 1);
$d=data2index ($d);
$d=data2bin ($d, "Value", 10, 0.02);
my ($P, $M)=multi_baum_welch ($d,5,10,10,10);
display_decode ($d);
display_model ($M, "MODEL");die;




my @int=data2intervals ($d,"full");
for ( $a=1; $a<=12; $a++){data2string ($d, $a);}


for (my $a=0; $a<$#int; $a++)
  {
    my $t=interval2count($d,$int[$a], $int[$a+1]);
    print "$int[$a] $int[$a+1] => $t\n";
  }
data2log_odd($d,"all","sc_", $int[$a], $int[$a+1]);
data2log_odd($d,"all","cd_", $int[$a], $int[$a+1]);

foreach my $diet (("sc_","cd_"))
  {
    for (my $c=1; $c<=12; $c++)
      {
	for (my $a=0; $a<$#int; $a++)
	  {
	    
	    data2log_odd($d, $c,$diet, $int[$a], $int[$a+1]);
	  }
      }
  }
print "\n\n\n";

sub display_data
  {
    my $d=shift;
    #my $file=shift;
    my $file=$A->{outdata};
    my $F= new FileHandle;

    if (!$file){open ($F, ">-");}
    else {open ($F, ">$file");}

    if ($A->{output}!~/R/)
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
		  {$WEIGHT{$c}{start}=$w;}
		else {$WEIGHT{$c}{end}=$w;}
		$WEIGHT{$c}{max}=($WEIGHT{$c}{max}<$w)?$w:$WEIGHT{$c}{max};
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

#This function annotated time between events without taking in consideration the nature of the channel.
#i.e. if an SC event occurs and interInterval is set to meals it will consider as next event any food
#regardless of its nature. If flag is set to all then next event is just the following one (water of food).
#This is not the way is performed in Compulse. 
#
#sub annotate
#  {
#    my $d = shift;
#    my $A = shift;
#    my ($pT, $cStartT, $pEndT, $interMealTime) = -1;
#    my $firstCage = 1;
#    #interInterval between all type of events or only meals (all/meals)   
#    my $field = $A->{interInterval};    
#           
#    foreach my $c (sort ({$a<=>$b}keys (%$d)))
#      {
#        $pEndT = -1;
#         
#        foreach my $t (sort ({$a<=>$b}keys (%{$d->{$c}})))
#          {                                   
#            if ($firstCage == 1)
#              {
#                $firstCage = 0;
#                $pEndT = $d->{$c}{$t}{EndT};
#                $pT = $t;                           
#                next;
#              }
#              
#            elsif ($pEndT == -1)
#              {                 
#                my $pC = $c-1;               
#                $d->{$pC}{$pT}{InterTime}= "NA";                        
#                $pT = $t;
#                $pEndT = $d->{$c}{$t}{EndT};                                    
#                next;
#              }	
#                          
#            elsif ($d->{$c}{$t}{Channel} =~ m/Intake(\s)+[3-4]/)
#              {                                       
#                $cStartT = $d->{$c}{$t}{StartT};
#                $interMealTime = $cStartT - $pEndT;
#                
#                #Overlaps are annotated as NA
#                if ($interMealTime <= 0) 
#                  {
#                    #print "currentStart $cStartT\tprevious End$pEndT\t$interMealTime\n";
#                    $d->{$c}{$pT}{InterTime} = "NA";                       
#                  }
#                else
#                  {  
#                    $d->{$c}{$pT}{InterTime} = $interMealTime;
#                  }
#                  
#                $pT = $t;
#                $pEndT = $d->{$c}{$t}{EndT};  
#              }
#              
#            elsif ($d->{$c}{$t}{Channel} =~ m/Intake(\s)+[1-2]/)
#              {                 
#                if ($field eq "meals")
#                  {                                                         
#                    $d->{$c}{$pT}{InterTime} = "NA";
#                    
#                    #Not consider water intervals thus time should not be modified, commented for this reason                    
#                    #$pEndT = $d->{$c}{$t}{EndT};
#                    $pT = $t; #I need this to annotate the correct interval
#                  }
#                elsif ($field eq "all")
#                  {
#                    $cStartT = $d->{$c}{$t}{StartT};
#                    $interMealTime =  $cStartT - $pEndT;
#                    
#                    #Overlaps are annotated as NA
#                    if ($interMealTime <= 0) 
#                      {                        
#                        $d->{$c}{$pT}{InterTime} = "NA"; 
#                      }
#                    else
#                      {                         
#                        $d->{$c}{$pT}{InterTime} = $interMealTime;
#                      }
#                      
#                    $pT = $t;
#                    $pEndT = $d->{$c}{$t}{EndT};
#                  }
#                else
#                  {
#                    print STDERR "FATAL ERROR: Option for field annotation not known\n"; 
#                    die;  
#                  }
#              }
#            else
#              {                
#                print STDERR "FATAL ERROR: Cage $c\t$t\t$d->{$c}{$t}{Channel} not recognized by annotate option\n";
#                die;
#              }    
#          }
#      } 
#      
#    return ($d); 
#  }

sub annotate
  {
    my $d = shift;
    my $A = shift;
    my ($pT, $cStartT, $pEndT, $interMealTime, $nature) = -1;
    my $HpEndT = {};
    my $HpT = {};
    my $HfirstCage = {};
    
    foreach my $nat (keys (%$natureH))
   	  {
        $HfirstCage->{$nat} = 1;
      }
       
    my $firstCage = 1;
    
    #interInterval between all type of events or only meals (all/meals)   
    my $field = $A->{interInterval};    
           
    foreach my $c (sort ({$a<=>$b}keys (%$d)))
      {        
        
        foreach my $nat (keys (%$natureH))
        	{
        		$HpEndT->{$nat} = -1;
        	} 
        
        foreach my $t (sort ({$a<=>$b}keys (%{$d->{$c}})))
          {                    
          	$nature = $d->{$c}{$t}{Nature};
          	               
            if ($HfirstCage->{$nature} == 1)
              {
                $HfirstCage->{$nature} = 0;                            
                $HpEndT->{$nature} = $d->{$c}{$t}{EndT}; 
                $HpT->{$nature} = $t;                                           
                next;
              }
              
            elsif ($HpEndT->{$nature} == -1)
              {                 
                my $pC = $c-1;
                $pT = $HpT->{$nature};               
                $d->{$pC}{$pT}{InterTime}= "LAST";                                        
                $HpT->{$nature} = $t;
                $HpEndT->{$nature} = $d->{$c}{$t}{EndT};                               
                next;
              }	
                          
            elsif ($d->{$c}{$t}{Channel} =~ m/Intake(\s)+[3-4]/)
              {                                       
                $cStartT = $d->{$c}{$t}{StartT};
                $pEndT = $HpEndT->{$nature};
                $pT = $HpT->{$nature};
                
                $interMealTime = $cStartT - $pEndT;
                
                #Overlaps are annotated as NA
                if ($interMealTime <= 0) 
                  {
                    #print "currentStart $cStartT\tprevious End$pEndT\t$interMealTime\n";
                    $d->{$c}{$pT}{InterTime} = "COLL";                       
                  }
                else
                  {  
                    $d->{$c}{$pT}{InterTime} = $interMealTime;
                  }
                  
                $HpT->{$nature} = $t;
                $HpEndT->{$nature} = $d->{$c}{$t}{EndT};  
              }
              
            elsif ($d->{$c}{$t}{Channel} =~ m/Intake(\s)+[1-2]/)
              {                 
                if ($field eq "meals")
                  { 
                  	$pT = $HpT->{$nature};                                                        
                    $d->{$c}{$pT}{InterTime} = "NA";
                    
                    #Not consider water intervals thus time should not be modified, commented for this reason                    
                    #$pEndT = $d->{$c}{$t}{EndT};
                    #$pT = $t; #I need this to annotate the correct interval
                    $HpT->{$nature} = $t;
                  }
                elsif ($field eq "all")
                  {
                    $cStartT = $d->{$c}{$t}{StartT};
                    $pEndT = $HpEndT->{$nature};
                	$pT = $HpT->{$nature};
                	
                    $interMealTime =  $cStartT - $pEndT;
                    
                    #Overlaps are annotated as NA
                    if ($interMealTime <= 0) 
                      {                        
                        $d->{$c}{$pT}{InterTime} = "COLL"; 
                      }
                    else
                      {                         
                        $d->{$c}{$pT}{InterTime} = $interMealTime;
                      }
                      
                    $HpT->{$nature} = $t;
                	$HpEndT->{$nature} = $d->{$c}{$t}{EndT};                   
                  }
                else
                  {
                    print STDERR "FATAL ERROR: Option for field annotation not known\n"; 
                    die;  
                  }
              }
            else
              {                
                print STDERR "FATAL ERROR: Cage $c\t$t\t$d->{$c}{$t}{Channel} not recognized by annotate option\n";
                die;
              }    
          }
      } 
      
    return ($d); 
  }
  
  #  #Filter data
#    $data=&filter_data ($data,"Value","float","rm",-9999999,$T);
#    $data=&filter_overlap ($data, $dup);
    
    
    
    
#    return $data;
#  }

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
			
			elsif ($Caption=~/Food/ && $diffCh)
			 {
			   my $nat = lc($Caption);			  	
			   #separating old annotated files into food_1 and food_2
			   $nat =~ s/\s/_/g;
			   $Nature = $nat;		   
			 }
			       
			elsif ($Caption=~/Food/)
			 {
			   $Nature="food";
			 }
			   			
			elsif ($Caption=~/Drink/ && $diffCh)
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
			    			     
				#if ($Name eq "sc"){$Nature.="_sc";}#Original before fusedSCforFDF heatMap
			    if ($Name eq "sc"){;}#fusedSCforFDF heatMap
			    
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
			
			#if    ($Name =~/sc/ && $Nature eq "food"){$Nature="sc_".$Nature;}#fusedSCforFDF heatMap
			if    ($Name =~/sc/ && $Nature eq "food"){;}#fusedSCforFDF heatMap
			#elsif ($Name =~/cd/){$Nature="cd_".$Nature;}
			elsif (($Name =~/cd/ || $Name =~ /choc/) && $Nature eq "food"){$Nature="cd_".$Nature;}
			#########end modification 31/08/2010
			
			$d->{$c}{$t}{Nature}=$Nature;
			$natureH->{$Nature} = 1;
		
	      }
	  }
	  
	return $d;
  }

sub unbin
  {
    my $d=shift;
    foreach my $c (keys (%$d))
      {
	foreach my $t (keys (%{$d->{$c}}))
	  {
	    delete ($d->{$c}{$t}{bin});
	  }
      }
    $BIN=0;
    return $d;
  }
  
sub untag
  {
    my $d=shift;
    foreach my $c (keys (%$d))
      {
	foreach my $t (keys (%{$d->{$c}}))
	  {
	    delete ($d->{$c}{$t}{tag});
	  }
      }
    $TAG=0;
    return $d;
  }

sub tag
  {
    my $d=shift;
    my $A=shift;
    
    my $field=$A->{field};
    my $min=$A->{min}; 
        
    if ($min =~ /^m(\d+)/) 
      {
          $min = -$1;
      }
    
    my $max=$A->{max};
    my $contains=$A->{contains};
    my $equals=$A->{equals};
    my $tot=0;
    my $n=0;
    my $defined;
    
    my $fl=data2field_list ($d);
    foreach my $c (sort(keys (%$d)))
      {
	foreach my $t (sort(keys (%{$d->{$c}})))
	  {
	    my $mark=0;
	    my $v=$d->{$c}{$t}{$field};
	    
	    if (defined ($d->{$c}{$t}{$field})){$defined++;}
	    
	    if (defined ($A->{contains}) && $v=~$contains){$mark=1;}
	    elsif (defined ($A->{equals}) && $v eq $equals){$mark=1;}
	    elsif (defined ($A->{min}) && defined ($A->{max})   && $v>$min && $v<$max){$mark=1;}
	    elsif (defined ($A->{min}) && $v>$min){$mark=1;}
	    elsif (defined ($A->{max}) && $v<$max){$mark=1;}
	     
	     if (!$TAG){$d->{$c}{$t}{tag}=$mark;}
	     elsif ($TAG)
	       {
		 $d->{$c}{$t}{tag}=($d->{$c}{$t}{tag} && $mark)?1:0;
	       }
	   }
       }
    
    delete ($A->{field});
    delete ($A->{min});
    delete ($A->{max});
    delete ($A->{contains});
    delete ($A->{equals});
    
    $TAG=1;
    return $d;
  }


sub zfilter_data
    {
      my $d=shift;
      my $A=shift;
      my $zf=$A->{filter};
      my ($removed, $n);
      my $stat={};
      
      if (!$zf){$zf=3;}
      
      my $nl=data2nature_list ($d);
      foreach my $nature (keys(%$nl))
	{
	  ($stat->{$nature}{Duration}{avg}, $stat->{$nature}{Duration}{sd})=data2avg_sd($d,$nature,"Duration");
	  ($stat->{$nature}{Value}{avg}, $stat->{$nature}{Value}{sd})=data2avg_sd($d,$nature,"Value");
	
	  #print "$nature D: $stat->{$nature}{Duration}{avg}, $stat->{$nature}{Duration}{sd} V: $stat->{$nature}{Value}{avg}, $stat->{$nature}{Value}{sd}\n";
	}
      
      foreach my $c (keys (%$d))
       {
	 foreach my $t (keys (%{$d->{$c}}))
	   {
	     
	     my $nature=$d->{$c}{$t}{Nature};
	     my $value=$d->{$c}{$t}{Value};
	     my $duration=$d->{$c}{$t}{Duration};
	     
	     my $z1=abs (($value-$stat->{$nature}{Value}{avg})/$stat->{$nature}{Value}{sd});
	     my $z2=abs (($duration-$stat->{$nature}{Duration}{avg})/$stat->{$nature}{Duration}{sd});
	     
	     if ( $z1>$zf || $z2>$zf)
	       {
		 $removed++;
		 delete($d->{$c}{$t});
	       }
	     $n++;
	   }
       }
      print STDERR "\nZ-Score Filtering: removed $removed values out of $n (Filter Z=$zf)\n";
      
    }
sub data2avg_sd 
    {
      my $d=shift;
      my $nature=shift;
      my $field=shift;
      my ($Sx, $Sx2,$avg,$sd, $n);
            
      foreach my $c (keys (%$d))
	{
	  
	  foreach my $t (keys (%{$d->{$c}}))
	    {		      
	      if ($d->{$c}{$t}{Nature} eq $nature)
		{		  
		  my $v=$d->{$c}{$t}{$field};		  
		  $Sx+=$v;
		  $Sx2+=$v*$v;
		  $n++;
		}
	    }
	}
      
      $avg=$Sx/$n;
      $sd=sqrt(($Sx2/$n)-($avg*$avg));
      
      return ($avg, $sd);
    }

sub filter_data
   {
     my $d=shift;
     my $A=shift;
     my $action=$A->{action};
    
     my $tot=0;
     my $n=0;
     my $defined;
     
     if (!$action){$action="keep";}
     foreach my $c (sort(keys (%$d)))
       {
	 foreach my $t (sort(keys (%{$d->{$c}})))
	   {
	     $n++;
	     my $mark=$d->{$c}{$t}{tag};
	     if    ($mark==1 && $action eq "rm"){delete($d->{$c}{$t}); $tot++;}
	     elsif ($mark==0 && $action eq "keep"){delete($d->{$c}{$t}); $tot++;}
	   }
       }
     print STDERR "\nFiltering: Removed $tot values out of $n\n";
     delete ($A->{action});#it should always be specified, if not problems with action option of BIT 
     return untag ($d);
   }

sub data2nature_list
  {
    my $d=shift;
    my $pl={};
    
    foreach my $c (sort(keys (%$d)))
      {
	foreach my $t (sort(keys (%{$d->{$c}})))
	  {
	    if( exists ( $d->{$c}{$t}{Nature}))
	      {
		$pl->{$d->{$c}{$t}{Nature}}=1;
	      }
	  }
      }
    return $pl;
  }

sub data2period_list
  {
    my $d=shift;
    my $pl={};
    
    foreach my $c (sort(keys (%$d)))
      {
	     foreach my $t (sort(keys (%{$d->{$c}})))
	       {
    	     if( exists ( $d->{$c}{$t}{period}))
    	       {
    		    $pl->{$d->{$c}{$t}{period}}=1;
    	       }	    
	       }
      }
    
    return $pl;
  }

#This function will consider both possible modes of -period option:
# mode period divides the data from the initial period until into the given amount of time 1 day, 1 week, 11 days.
# mode phase divides the data between dark and light phase, from 8:00 to 20:00 by default if any other info no provided
# or by natural days 00:00 to 24:00
sub data2tempDiv
  {
    my $d = shift;
    my $A = shift;
       
    if (exists ($A->{period}))
      {        
        $d = data2period ($d,$A);       
      }    
    
    elsif (exists ($A->{phase}) && ($A->{phase} eq "phase" || $A->{phase} eq "phasePeriod"))
      {
        $d = data2phase ($d,$A);
      }
    
#    elsif (exists ($A->{'join'}))
#      {
#        $d = joinPeriodPhase ($d,$A);
#      }
      
    else
      {
        print STDERR "FATAL ERROR: Mode-->$A->{period} not recognize in -period option\n"; 
	    die; 
      }
      
    return ($d);   
  }

sub joinPeriodPhase
  {
    my $d = shift;
    my $A = shift;
    my ($period, $phase);
    
    foreach my $c (sort(keys (%$d)))
      {
    	foreach my $t (sort(keys (%{$d->{$c}})))
    	  {
    	    exists ($d->{$c}{$t}{period}) && exists ($d->{$c}{$t}{phase})? last : die print STDERR "FATAL ERROR \"join\" option needs period and phase to be defined\n";
    	  }
      }

    #The periods given in such way where separated into periods from the beginnig of the file and not taking into account natural days     
    foreach my $c (sort(keys (%$d)))
      {
    	foreach my $t (sort(keys (%{$d->{$c}})))
    	  {     	    
    	    $period = $d->{$c}{$t}{period};
    	    $phase = $d->{$c}{$t}{phase};
    	    $d->{$c}{$t}{period} = $period.$phase;
    	  }
      }
     
    return ($d);      
    
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
            $time->{$a}="1_dark";  print "$a\t 1 light\n";       
          }
        
        for ($a=$firstPhLightChange -(24 * 3600); $a < $firstPhLightChange -($deltaPh * 3600); $a++)
          {
            $time->{$a}="1_light";         
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
  
sub data2period
  {    
    my $d=shift;
    my $A=shift;

    my $n=$A->{period};
    my ($a,$b, $start, $end, @list, $delta);
    my $time={};
    
    $start=$end=-1;
    
    foreach my $c (sort(keys (%$d)))
      {
	foreach my $t (sort(keys (%{$d->{$c}})))
	  {
	    
	    my $cstart=$d->{$c}{$t}{StartT};
	    my $cend=$d->{$c}{$t}{EndT};
	    
	    if ($start==-1 || $start>$cstart){$start=$cstart;}
	    if ($end==-1    || $end<$cend){$end=$cend;}
	  }
      }
    if (!$n){$n="week";}
    if ($n eq "hour"){$delta=3600;}
    elsif ($n eq "day"){$delta=3600*24;}
    elsif ($n eq "five"){$delta=3600*24*5;}   
    elsif ($n eq "week"){$delta=3600*24*7;}
    elsif ($n eq "ten"){$delta=3600*24*10;}
    elsif ($n eq "eleven"){$delta=3600*24*11;}
    elsif ($n eq "twoweek"){$delta=3600*24*7*2;}
    elsif ($n eq "month"){$delta=3600*24*31;}
    elsif ($n eq "year"){$delta=3600*24*365;}
    elsif ($n eq "full"){$delta=$end-$start;}
    else {$delta=($end-$start)/$n;}
    
    #while second has not reach delta we are in the same period then it goes out of nested for and change period->$b
    #$time will have annotated all seconds between start and end
    for ($b=1,$a=$start; $a<$end; $b++)
      {
	for (my $c=0; $c<$delta; $c++, $a++)
	  {

	    $time->{$a}=$b;
	  }
      }
   
    #Then it looks where does the interval time correspond
    foreach my $c (sort(keys (%$d)))
      {
	foreach my $t (sort(keys (%{$d->{$c}})))
	  {
	    $d->{$c}{$t}{period}=$time->{$t};
	  }
      }
    delete($A->{period});
    return $d;
  }

#This function performs the binning of a given data field.
#It is possible to do multiple binning like binX_1::binY_1, binX_1::binY_2 ...
sub data2bin
  {
    my $S=shift;
    my $A=shift;
    
    my $field=$A->{field};
    my $nbin=$A->{nbin};
    my $delta=$A->{delta};
    my $name=$A->{name};
    my $action=$A->{action};
    if ($delta eq "auto")
      {
    	my($min,$max)=datafield2minmax($S,$field);
    	my $delta=($max-$min)/$nbin;
    	print STDERR "$max - $min\n";
      }
      
    if (!$field){$field="Value";}
    if (!$nbin){$nbin=1;}
    if (!$delta){$delta=0.02;}
    if (!$name) 
      {
    	$BIN++;
    	$name="BIN$BIN";
      }
      
    foreach my $c (keys(%$S))
      {
    	foreach my $i (keys (%{$S->{$c}}))
    	  {
    	    if (!defined ($S->{$c}{$i}{tag}) ||(defined ($S->{$c}{$i}{tag} && $S->{$c}{$i}{tag}==1)))
    	      {
    		    if    ($action eq "food")
    		      {
        		    if ( $S->{$c}{$i}{Nature}=~/food/){$S->{$c}{$i}{bin}="food";}
        		    elsif ( $S->{$c}{$i}{Nature}=~/drink/){$S->{$c}{$i}{bin}="drink";}
    		      }
        		elsif ($nbin==1)
        		  {        		    
        		    if ($S->{$c}{$i}{bin}) 
        		      {
        		        $S->{$c}{$i}{bin}="$S->{$c}{$i}{bin}"."::"."$S->{$c}{$i}{Nature}";
        		      }
        		    else
        		    {
        		      $S->{$c}{$i}{bin}=$S->{$c}{$i}{Nature};
        		    }
        		    
        		  }
        		else
        		  { 
        		    #if (($S->{$c}{$i}{$field}/$delta < 0) && ($S->{$c}{$i}{$field}/$delta))
        		    if ($S->{$c}{$i}{$field}/$delta < 0)
        		      {
        		        my $bin = 0;
        		        
        		        if ($S->{$c}{$i}{bin}) 
        		          {
        		            $S->{$c}{$i}{bin}="$S->{$c}{$i}{bin}"."::"."$name"."_"."$bin";
        		          }
        		        else
        		          {
        		            $S->{$c}{$i}{bin}="$name"."_"."$bin";
        		          }
        		      }
        		    
        		    else
        		      {
        		        my $bin=int($S->{$c}{$i}{$field}/$delta);
        		        
        		        if ( $bin<0){$bin=0;}
        		        else
        		          {
        			       $bin=($bin>=$nbin)?$nbin:$bin+1;
        		          }
        		        
        		        if ($S->{$c}{$i}{bin}) 
        		          {
        		            $S->{$c}{$i}{bin}="$S->{$c}{$i}{bin}"."::"."$name"."_"."$bin";
        		          }
        		        else
        		          {
        		            $S->{$c}{$i}{bin}="$name"."_"."$bin";
        		          }
        		      }         
        		  }
    	      }
    	  }
      }
      
    delete ($A->{field});
    delete ($A->{nbin});
    delete ($A->{delta});
    delete ($A->{name});
    delete ($A->{action});
    
    return untag($S);
  }

 
sub data2multipleBin
  {
    my $S=shift;
    my $A=shift;
    
    my $field=$A->{field};
    my $nbin=$A->{nbin};
    my $delta=$A->{delta};
    my $name=$A->{name};
    my $action=$A->{action};
    if ($delta eq "auto")
      {
    	my($min,$max)=datafield2minmax($S,$field);
    	my $delta=($max-$min)/$nbin;
    	print STDERR "$max - $min\n";
      }
      
    if (!$field){$field="Value";}
    if (!$nbin){$nbin=1;}
    if (!$delta){$delta=0.02;}
    if (!$name) 
      {
    	$BIN++;
    	$name="BIN$BIN";
      }
      
    foreach my $c (keys(%$S))
      {
    	foreach my $i (keys (%{$S->{$c}}))
    	  {
    	    if (!defined ($S->{$c}{$i}{tag}) ||(defined ($S->{$c}{$i}{tag} && $S->{$c}{$i}{tag}==1)))
    	      {
    		    if    ($action eq "food")
    		      {
        		    if ( $S->{$c}{$i}{Nature}=~/food/){$S->{$c}{$i}{bin}="food";}
        		    elsif ( $S->{$c}{$i}{Nature}=~/drink/){$S->{$c}{$i}{bin}="drink";}
    		      }
        		elsif ($nbin==1)
        		  {        		    
        		    if ($S->{$c}{$i}{bin}) 
        		      {
        		        $S->{$c}{$i}{bin}="$S->{$c}{$i}{bin}"."::"."$S->{$c}{$i}{Nature}";
        		      }
        		    else
        		    {
        		      $S->{$c}{$i}{bin}=$S->{$c}{$i}{Nature};
        		    }
        		    
        		  }
        		else
        		  { 
        		    #if (($S->{$c}{$i}{$field}/$delta < 0) && ($S->{$c}{$i}{$field}/$delta))
        		    if ($S->{$c}{$i}{$field}/$delta < 0)
        		      {
        		        my $bin = 0;
        		        
        		        if ($S->{$c}{$i}{bin}) 
        		          {
        		            $S->{$c}{$i}{bin}="$S->{$c}{$i}{bin}"."::"."$name"."_"."$bin";
        		          }
        		        else
        		          {
        		            $S->{$c}{$i}{bin}="$name"."_"."$bin";
        		          }
        		      }
        		    
        		    else
        		      {
        		        my $bin=int($S->{$c}{$i}{$field}/$delta);
        		        
        		        if ( $bin<0){$bin=0;}
        		        else
        		          {
        			       $bin=($bin>=$nbin)?$nbin:$bin+1;
        		          }
        		        
        		        if ($S->{$c}{$i}{bin}) 
        		          {
        		            $S->{$c}{$i}{bin}="$S->{$c}{$i}{bin}"."::"."$name"."_"."$bin";
        		          }
        		        else
        		          {
        		            $S->{$c}{$i}{bin}="$name"."_"."$bin";
        		          }
        		      }         
        		  }
    	      }
    	  }
      }
      
    delete ($A->{field});
    delete ($A->{nbin});
    delete ($A->{delta});
    delete ($A->{name});
    delete ($A->{action});
    
    return untag($S);
  }

sub data2field_list
  {
    my $d=shift;
    my $list={};
    foreach my $c (sort(keys (%$d)))
       {
	 
	 foreach my $t (keys (%{$d->{$c}}))
	   { 
	     foreach my $f (keys(%{$d->{$c}{$t}}))
	       {
		 if (!exists($list->{$f}))
		   {
		     $list->{$f}=1;
		   }
	       }
	   }
       }
    return $list;
  }

####################
#filter_overlap
####################
#All records with collisions bigger than a threshold are taken out by default 1 ($T) (i.e.
#the interval it is all inside the previous interval)

sub filter_overlap
    {
      
      my $d=shift;
      my $T=shift;
      my $tot=0;
      my $n=0;
      if ($T eq "no"){return $d;}
      foreach my $c (sort(keys (%$d)))
	{	  
	  foreach my $t (sort(keys (%{$d->{$c}})))
	    {
	      $n++;
	      if ( $d->{$c}{$t}{Collision} && $d->{$c}{$t}{Collision}>$T){delete ($d->{$c}{$t});$tot++;}
	    }
	}
      print STDERR "\nCollisions: Removed $tot values out of $n (T: $T)\n";
      return $d;
    }
        
sub parse_header
  {
    my $file=shift;
    my $data=shift;
    my $F=new FileHandle;
    
    open($F, $file);
    
    while (<$F>) 
      {
	my $line=$_;
	if ( $line=~/#h/)
	  {
	    chomp $line;
	    my @k=split ($line, /;/);
	    
	    $data->{$k[1]}{$k[2]}{$k[3]}{$k[4]}=$k[5];
	  }
	elsif ($line=~/#d/)
	  {
	    last;
	  }
      }
    close ($F);
    return $data;
  }

  sub data2overlap
    {
      my $d=shift;
      my $print=shift;
      my  $nc;
      my ($n,$tot,$double_coll);

      if ($print)
	{
	  print "cage\tdelta\tperiod\tpStartT\tpEndT\tStartT\tEndT\tpStartL\tpEndL\tStartL\tEndL\tpPerc\tPerc\tpChannel\tChannel\tpValue\tValue\tfile\n";
	}

      foreach my $c (sort(keys (%$d)))
	{
	  my $pStartT=-1;
	  my $pEndT=-1;
	  my $pChannel=-1;
	  my $pStartL;
	  my $pEndL;
	  my $pFile;
	  my $pValue;
	  my $pc;
	  my $pt;
	  my $pPeriod;
	  
	  if ($print)
	    {
	      #print "\nCHECK CAGE $c\n";
	    }
	  foreach my $t (sort(keys (%{$d->{$c}})))
	    {
	      $n++;
	      my $StartT=$d->{$c}{$t}{StartT};
	      my $EndT=$d->{$c}{$t}{EndT};
	      my $Channel=$d->{$c}{$t}{Channel};
	      my $StartL=$d->{$c}{$t}{StartL};
	      my $EndL=$d->{$c}{$t}{EndL};
	      my $File=$d->{$c}{$t}{File};
	      my $Value=$d->{$c}{$t}{Value};
	      my $Period=$d->{$c}{$t}{period};	      	     	      
	      
	      if ($pStartT!=-1)
		{
		  if (($StartT<$pEndT) && ($EndT >= $pEndT))
		    {		      
		      my $delta=$pEndT-$StartT;
		      my $v1=$delta/($EndT-$StartT);
		      my $v2=$delta/($pEndT-$pStartT);
		      my $v=($v1<$v2)?$v2:$v1;
		      
		      #if ($d->{$pc}{$pt}{Collision} != 0 && $Value > 0 ) {$double_coll++;} #delete (here we only take into account Value)
		      
		      $d->{$c}{$t}{Collision}=$v1;
		      $d->{$pc}{$pt}{Collision}=$v2;
		      $d->{$c}{$t}{Delta}=$delta;			      
                      $d->{$pc}{$pt}{Delta}=$delta;

		      if ($print)
			{
			  #print "***** ERROR: OVERLAP: CAGE $c --- $delta :\n";
			  #print "\t\tC: $pChannel [$pStartT -- $pEndT] [$pStartL -- $pEndL] VALUE: $pValue File: $pFile\n";
			  #print "\t\tC: $Channel [$StartT -- $EndT] [$StartL -- $EndL] File: VALUE: $Value $File\n";
			  #print "\t\tperc prev:$v2 -- perc after:$v1\n";
			  #print "\t\tvalue prev:$pValue -- value after:$Value\n";
			  #ORDER=>cage delta period pStartT    pEndT StartT    EndT    pStartL   pEndL   StartL EndL  pPerc Perc pChannel Channel pValue          Value file
			  print "$c\t$delta\t$Period\t$pStartT\t$pEndT\t$StartT\t$EndT\t$pStartL\t$pEndL\t$StartL\t$EndL\t$v2\t$v1\t$pChannel\t$Channel\t$pValue\t$Value\t$File\n";
			  
			  }
		      $tot++;
		    }
		  
		  elsif (($StartT < $pEndT) && ($EndT < $pEndT))
		    {
                      my $delta=$EndT-$StartT;
		      my $v1=$delta/($EndT-$StartT);
		      my $v2=$delta/($pEndT-$pStartT);
		      my $v=($v1<$v2)?$v2:$v1;

		      $d->{$c}{$t}{Collision}=$v1;
		      $d->{$pc}{$pt}{Collision}=$v2;
		      $d->{$c}{$t}{Delta}=$delta;			      
                      $d->{$pc}{$pt}{Delta}=$delta;
		      
		      if ($print)
			{
			  #print "***** ERROR: OVERLAP: CAGE $c --- $delta :\n";
			  #print "\t\tC: $pChannel [$pStartT -- $pEndT] [$pStartL -- $pEndL] VALUE: $pValue File: $pFile\n";
			  #print "\t\tC: $Channel [$StartT -- $EndT] [$StartL -- $EndL] File: VALUE: $Value $File\n";
			  #print "\t\tperc prev:$v2 -- perc after:$v1\n";
			  #print "\t\tvalue prev:$pValue -- value after:$Value\n";
			  #ORDER=>cage delta period pStartT    pEndT StartT    EndT    pStartL   pEndL   StartL EndL  pPerc Perc pChannel Channel pValue          Value file
			  print "$c\t$delta\t$Period\t$pStartT\t$pEndT\t$StartT\t$EndT\t$pStartL\t$pEndL\t$StartL\t$EndL\t$v2\t$v1\t$pChannel\t$Channel\t$pValue\t$Value\t$File\n";
			  
			  }
		      $tot++;

		    }

		  else
		    {
		      $d->{$c}{$t}{Collision} = 0;
		      $d->{$c}{$t}{Delta} = 0;		      
		    }		    
		}
	      else 
		{
		  $d->{$c}{$t}{Collision} = 0;
	          $d->{$c}{$t}{Delta} = 0;
		}

	      $pc=$c;
	      $pt=$t;
	      $pStartT=$StartT;
	      $pEndT=$EndT;
	      $pStartL=$StartL;
	      $pEndL=$EndL;
	      $pFile=$File;
	      $pChannel=$Channel;
	      $pValue=$Value;	      
	    }
	}
      print STDERR "\nOverlap: $tot values out of $n\n";
      #print STDERR "\nDouble overlap: $double_coll values out of $tot\n"; #delete
      return $d;
    }

sub data2string 
    {
      my $d=shift;
      my $Cage=shift;
      my  $nc;
      
      foreach my $c (sort(keys (%$d)))
	{
	  if ($Cage!=$c){next;}
	  foreach my $t (sort(keys (%{$d->{$c}})))
	    {
	      printf "$c:   %12s => %5.2f\n",$d->{$c}{$t}{Nature}, $d->{$c}{$t}{Value};
	    }
	}
    }

sub data2stat 
  {
    my $d=shift;
    my $A=shift;
    my $period=data2period_list ($d);

    #modification stat R output 23/09/10
    if ($A->{output}=~/R/)
      {
	     if (exists ($A->{interInterval}))
	       {
	         if ($A->{labels} eq "compulse")
	           {
	             print "period\tcage\tchannel\tduration_period\trec_period\tN_meals\tN_inter_Meals\tDuration\tAvg_Duration\tTotal_Intermeal_Duration\tAvg_Intermeal_Duration\tTotal_Intake\tAvg_Intake\tRate\n";
	           }
	         else
	           {
	             print "period\tcage\tchannel\tduration_period\trec_period\tcount\tcountInterMeal\tduration_T\tmean_duration\tInterTime_T\tInterTime\tvalue_T\tmean_value\tvelocity\n";	             
	           }    
	      
	       }
	     else
	       {
	         print "period\tcage\tchannel\tduration_period\trec_period\tcount\tduration_T\tmean_duration\tvalue_T\tmean_value\tvelocity\n";
	       }
      }
       	
    #foreach my $p (sort (keys (%$period)))#If period is not a number
    foreach my $p (sort ({$a<=>$b}keys (%$period)))
      {	
	     if ($A->{output}!~/R/) 
	       {
	         print "-- $p--\n";
	       }
    #end modification - 23/09/10

      	$A->{period}=$p;
      	$A->{name}="$p";

      	data2display_period_stat ($d, $A);
      }
      
    die;
  } 

sub data2display_period_stat
  {
    my $d=shift;
    my $A=shift;
    my $S={};
    my $mintime=-1;
    my $maxtime=-1;
    my $duration;
    my $tot=0;
    my $mailData = "";
    my $mailBody = "";
    
    #This hash will keep the stats results, so that it could be validated for each value whether it is "strange" (value far from the mean in terms of Zscore...)
    my $statsH = {};
    #my $dP = {};

    foreach my $c (sort(keys (%$d)))
      {
	     my ($ch, $pendt);
	     foreach my $t (sort(keys (%{$d->{$c}})))
	       {
      	     my $period=$d->{$c}{$t}{period};
      	     if ($period ne $A->{period}){next;}
      	     my $ch=$d->{$c}{$t}{bin};
      	     if ($mintime==-1){$mintime=$t;}
      	     if ($maxtime==-1){$maxtime=$t;}
      	     $mintime=($t<$mintime)?$t:$mintime;
      	     $maxtime=($t>$maxtime)?$t:$maxtime;
      	     $tot++;
      	     $S->{$c}{$ch}{Count}++;
      	     
      	     #Calculation of inter-time stats if annotated      	     
      	     if (exists ($d->{$c}{$t}{InterTime})) 
      	       {
      	         #For inter-intervals time some events are not considered (overlaps or water when only intermeal time is calculated)
      	         if ($d->{$c}{$t}{InterTime} ne "NA" & $d->{$c}{$t}{InterTime} ne "LAST" & $d->{$c}{$t}{InterTime} ne "COLL")
      	           {
      	             $S->{$c}{$ch}{InterTime}+=$d->{$c}{$t}{InterTime};
      	             $S->{$c}{$ch}{CountInterTime}++;
      	           }
      	         elsif ($d->{$c}{$t}{InterTime} eq "NA")
      	           {
      	             $S->{$c}{$ch}{InterTime}=0;
      	             $S->{$c}{$ch}{CountInterTime}++;
      	           }
      	       }
      	     
      	     $S->{$c}{$ch}{Duration}+=$d->{$c}{$t}{Duration};      	     
      	     #$dP->{$c}{$t}{Duration} = $d->{$c}{$t}{Duration};      	    
      	     $S->{$c}{$ch}{Value}+=$d->{$c}{$t}{Value};
      	     #$dP->{$c}{$t}{Value} = $d->{$c}{$t}{Value};
      	     #$dP->{$c}{$t}{Nature} = $d->{$c}{$t}{Nature};      	     
      	     #printf "%10s --> %6.2f  %6.2f\n", $ch,$d->{$c}{$t}{Duration},$d->{$c}{$t}{Value}; 
	       }
      }
           
     $duration=$maxtime-$mintime;
     my $tt=sec2time($duration);
     
     foreach my $c (keys (%$S))
       {
	     foreach my $ch (keys(%{$S->{$c}}))
	       {
	         $S->{$c}{$ch}{velocity}=$S->{$c}{$ch}{Value}/$S->{$c}{$ch}{Duration};
	       }
       }
     
     #modification stat R output 23/09/10
     if ($A->{output}!~/R/) 
       {         
	     print "--- Period -- $A->{period} : "; 
	     print "Duration: $duration sec. ($tt). N Records: $tot\n";
	     
	     foreach my $c (sort ({$a<=>$b}keys (%$S)))
	       {
	         printf "Cage: $c\n";
	         
	         foreach my $ch (sort (keys(%{$S->{$c}})))
	           {
		          my $count=$S->{$c}{$ch}{Count};
		          my $countInterTime=$S->{$c}{$ch}{CountInterTime};
		         		         
		          printf "\tChannel: %8s", $ch;
                  
		          foreach my $f (sort ({$a cmp $b}keys(%{$S->{$c}{$ch}})))
		            {		              		                  		    
		              if ($f ne "Count" & $f ne "velocity" & $f ne "InterTime" & $f ne "CountInterTime")
		                { 			                    		                    
			               printf "- %8s: %6.2f ",$f."T",$S->{$c}{$ch}{$f};
			               
			               #Before calculating the mean is assessed whether total channel value is negative			             
			               if ($f eq "Value" && $S->{$c}{$ch}{$f} < 0)
		              	   	{		     		              		         	
		              			$mailData.="############################################CAGE: $c\tPERIOD: $A->{period}\tCHANNEL:$ch\tVALUE:$S->{$c}{$ch}{$f}\n";		              					              					              				             
		              		}
		              		
			               $S->{$c}{$ch}{$f}/=$count;
		                }
		              elsif ($f eq "Count")
		                {
			               printf "- %8s: %6d ",$f,$S->{$c}{$ch}{$f};
			               next;
		                }
          		      elsif ($f eq "velocity")
          		        {
          			       printf "- %8s: %6.5f ",$f,$S->{$c}{$ch}{$f};
          			       next;
          		        }
          		      elsif ($f eq "InterTime")
          		        {
          			       printf "- %8s: %6.2f ",$f."T",$S->{$c}{$ch}{$f};
          			       $S->{$c}{$ch}{$f}/=$countInterTime;          			       
          		        }

		              printf "- %8s: %6.2f ",$f,$S->{$c}{$ch}{$f};
		            }
		          print "\n";
	           }
	       }	 
       }
     else
       {	  	 	 
	     foreach my $c (sort ({$a<=>$b}keys (%$S)))
	       {	     	    
	         foreach my $ch (sort (keys(%{$S->{$c}})))
	           {
		          my $count=$S->{$c}{$ch}{Count};
		          my $countInterTime=$S->{$c}{$ch}{CountInterTime};		 
		          print "$A->{period}\t$c\t$ch\t$duration\t$tot\t";
		          
		          #foreach field
		          foreach my $f (sort ({$a cmp $b} keys(%{$S->{$c}{$ch}})))
		            { 		            
		              if ($f ne "Count" & $f ne "velocity" & $f ne "CountInterTime")		       
		                { 		                   		                   		   			                
			               printf "%6.2f\t",$S->{$c}{$ch}{$f};
			               
			               #Before calculating the mean is assessed whether total channel value is negative			             
			               if ($f eq "value" && $S->{$c}{$ch}{$f} < 0)
		              	   	{		     		              		         	
		              			$mailData.="############################################CAGE: $c\tPERIOD: $A->{period}\tCHANNEL:$ch\tVALUE:$S->{$c}{$ch}{$f}\n";		              					              					              				             
		              		}
		              	   
		              	   if ($f eq "InterTime")
			                 {
			                   $S->{$c}{$ch}{$f}/=$countInterTime;
			                 }
			               else
			                 {  	
			                   $S->{$c}{$ch}{$f}/=$count;
			                 }
		                }
		              if ($f ne "velocity")
		                {
			               printf "%6.2f\t",$S->{$c}{$ch}{$f};
		                }  
		              else 
		                {
			               printf "%6.5f\n",$S->{$c}{$ch}{$f};
		                }		                		             
		            }		 
	             }
	         }
	         
	         if (exists ($A->{mail}) && $mailData ne "")
	         	{
	         			         		
	         		my $mailBody = "Channels intake values are negative, cages involved might be experimenting problems:\n\n".$mailData;
	         		my $mailScript = "callSesMail.sh";
	         		my $mailSubj = "negativeIntakeValues".$mailTime;	         		
	         		my $mailSender = 'phecompubio@gmail.com';
	         		my $mailRecip = 'kadomu@gmail.com';
	         		
	         		print STDERR "INFO: Sending mail negative values\n";
	         		my @args = ($mailScript, $mailBody, $mailSubj, $mailSender, $mailRecip);
	         		system (@args) == 0 || print STDERR "system @args failed\n";
	         		$mailData="";	         		
	         	}
             
             if (exists ($A->{zscoreS}))
              {
                foreach my $c (sort ({$a<=>$b}keys (%$S)))
	             {	 
	                 print "-----------$c\n";    	    
        	         foreach my $ch (sort (keys(%{$S->{$c}})))
        	           {
        		          my $count=$S->{$c}{$ch}{Count};		         		          
        		          
        		          foreach my $f (sort ({$a cmp $b} keys(%{$S->{$c}{$ch}})))
        		            { 
        		              if ($f ne "Count" & $f ne "velocity")		       
        		                { 
        		                   #Mean value and SD among cages for all channels and field stored in statsH
        		                   ($statsH->{$ch}{$f}{avg}, $statsH->{$ch}{$f}{sd}) = data2avg_sd ($d, $ch, $f);
        		                   my $z1 = abs (($S->{$c}{$ch}{$f} - $statsH->{$ch}{$f}{avg}) / $statsH->{$ch}{$f}{sd});
        		                   #I CALCULATE EACH TIME THE MEAN VALUE AND SD FOR ALL CAGES TO IMPROVE #del
        		                   #print "cage mean $S->{$c}{$ch}{$f} overall mean $statsH->{$ch}{$f}{avg}\n";#del
#        		                   if ( $z1 > 3)
#                              	       {
                              		     $mailData.="############################################CAGE: $c\tPERIOD: $A->{period}\tCHANNEL:$ch\tVALUE:$S->{$c}{$ch}{$f}\n"; 
#                              	       }      
#		                           ($statsH->{$c}{$ch}{$f}{avg}, $statsH->{$c}{$ch}{$f}{sd}) = data2avg_sd($dPCage, $ch, $f);
                                }
        		            }
        	           }        	          
	             }              
              }
              
              if (exists ($A->{mail}) && $mailData ne "")
	         	{
	         			         		
	         		my $mailBody = "Some channels present a mean value more than 3 Z scores above/below the SD of the whole sample:\n\n".$mailData;
	         		my $mailScript = "callSesMail.sh";
	         		my $mailSubj = "channels with abnormal behavior Zscore".$mailTime;	         		
	         		my $mailSender = 'phecompubio@gmail.com';
	         		my $mailRecip = 'kadomu@gmail.com';
	         		
	         		print STDERR "INFO: Sending mail zscores\n";
	         		my @args = ($mailScript, $mailBody, $mailSubj, $mailSender, $mailRecip);
	         		system (@args) == 0 || print STDERR "system @args failed\n";	         		
	         	}	         		         			 
	         
           }
     #end modification - 23/09/10
     
     #print Dumper ($statsH);die; #del 

     return;
   }

sub data2log_odd 
  {
    my $d=shift;
    my $A=shift;
    my $period=data2period_list ($d);
    my $mode = $A->{mode};
    my $bitThreshold = $A->{fieldT};
    
    if (!$mode) {$mode = "logodd";}
    
    if (!$bitThreshold) {$bitThreshold = "default";}    
    
    #modification logodd R output 23/09/10
    if ($A->{output}=~/R/ && ($A->{mode} eq "logodd" || $A->{mode} eq "logoddCumulative")) 
      {
        print "period\tcage\todd_ratio\todd_ratio_value\tdelta_w\n";
      }
    #end modification-23/09/10
    elsif ($A->{output}=~/R/ && $A->{mode} eq "logoddBIT")
      {
        print "period\tcage\ttransition\tbin_BIT\todd_ratio_value\tdelta_w\n";                	
      }
      
    foreach my $p (sort ({$a<=>$b}keys (%$period)))
      {        
        #modification logodd R output 23/09/10
    	if ($A->{output}!~/R/) 
          {
            print "-- $p--\n";
	      }   	     
	    #end modification 23/09/10
        
        $A->{period}=$p;
	    $A->{name}="$p";
	      
	    if ($mode eq "logodd" | $mode eq "logodd_CA_global" | $mode eq "logodd_CA_cage")
	     {
	    
	       if ($bitThreshold eq "default")
	         {
	           &data2log_odd_period ($d, $A);#the function is called for each period	           
	         }
	       
	       elsif ($bitThreshold =~ /\d+/)
	         {
	           &data2log_odd_period_bitThreshold ($d, $A);
	         }
	     }
	     
	    elsif ($mode eq "logoddBIT")
	     {
	       &data2log_odd_period_BIT ($d, $A);
	     }
	    
	    elsif ($mode eq "logoddCumulative")
	     {
	       &data2log_odd_period_cumulative ($d, $A);
	     }
	      
	    else 
	     {
	       print "FATAL ERROR: Mode-->$mode not recognize in -logodd option\n"; 
	       die; 
	     }
      }
    
    die;
  }

sub data2log_odd_period
  {    
    my $d=shift;
    my $A=shift;
    my $tot={};
    my $chc={};
    my $M={};
    
    ##INFO
    #c-> cage
    #ch -> previous channel
    #cch -> current channel
    #t -> time
    #pendt -> previous end time        
    foreach my $c (sort(keys (%$d)))
      {
        #my ($ch,$pendt);
        my ($ch) ;
        my $pendt = 0;

    	foreach my $t (sort(keys (%{$d->{$c}})))
          {
            my $period=$d->{$c}{$t}{period};
    	    if ($period ne $A->{period}){next;}
    	    
    	    #if ($d->{$c}{$t}{StartT} > $pendt)  {$pendt=$d->{$c}{$t}{EndT}; next;} else {}
    	    #I take the bin (e.g. sc_food_sc) 
    	    my $cch=$d->{$c}{$t}{bin};
    	    
    	    $M->{$c}{$cch}{$cch }{count}{tot}++;
    	    if ($ch)
              {
                $M->{$c}{$ch}{$cch}{count}{transition}++;
        		$M->{$c}{$ch}{$cch}{count}{interval}+=$d->{$c}{$t}{StartT}-$pendt;
        		#$M->{"total"}{$ch}{$cch}{count}{transitions}++;
        		#$M->{"total"}{$ch}{$cch}{count}{interval}+=$d->{$c}{$t}{StartT}-$pendt;
    	      }
    	    
    	    $tot->{$c}++;
    	    $ch=$cch;
    	    $pendt=$d->{$c}{$t}{EndT};#print "aqui que es $pendt";
    	  }
      }
    
   # foreach my $c ( sort({$a<=>$b}keys (%$chc)))
#      {
#	print "\n-- CAGE: $c\n";
#	foreach my $ch (keys (%{$chc->{$c}}))
#	  {
#	    print "CHANNEL: $ch : $chc->{$c}{$ch}{count}{tot}\n";
#	  }
#      }
    

    foreach my $c (keys (%$M))
      {
        foreach my $b1 (keys (%{$M->{$c}}))
          {
            foreach my $b2 (keys (%{$M->{$c}{$b1}}))
              {
                my ($count0,$count1, $count2);
          		if ( $tot->{$c}==0){next;}
          		$count0=$M->{$c}{$b1}{$b2}{count}{transition};
          		$count0/=$tot->{$c};
          		
          		$count1=$M->{$c}{$b1}{$b1}{count}{tot};
          		$count1/=$tot->{$c};
          		$count2=$M->{$c}{$b2}{$b2}{count}{tot};
          		$count2/=$tot->{$c};
          		$M->{$c}{$b1}{$b2}{logodd}{value}=(($count1*$count2)==0 || $count0==0)?0:log (($count0)/($count1*$count2));
          		$M->{$c}{$b1}{$b2}{count}{fulltot}=$tot->{$c};
          	  }
	      }
      }
    #modification logodd R output 23/09/10
    if ($A->{output}!~/R/) 
      {
	     print "Period:$A->{period}\n";
      } 
    #end modification-23/09/10
    
    if ($A->{mode} eq "logodd")
      { 
        display_log_odd($M);
      }
    
    elsif ($A->{mode} eq "logodd_CA_cage")
      { 
        display_log_odd_CA_Cage($M);
      }
      
    elsif ($A->{mode} eq "logodd_CA_global")
      { 
        display_log_odd_CA_global($M);
      }
        
    return $M;
  }

#The function perform calculates the logodd ratio of a dataset using a sliding window provided in win
#To this end the execution goes in the following way:
# The data is divided in periods of the given window size
# The first logodd ratio is calculated using the above temporal division and ploting just the first period of length window
# The a loop is started where the data is divided into day periods
# In each round the first day is eliminated
# Then remaining data is divided into periods of window size
# The logodd the new first period of length window is calculated
sub data2log_oddWindow
  {    
    my $d=shift;
    my $A=shift;
    
    if ($A->{win} =~ m/\d+/)
    	{
    		print STDERR "FATAL ERROR: Window should not be a numeric value";
    		die;
    	}
   	
    my $window = $A->{win};
    my $p;
        
    my $tot={};
    my $chc={};
    my $M={};
    my $lengthDays = 0;        
    
    print STDERR "MSG: Window used for log odd sliding window is: $window\n";
    
    #Using the input window the data is divided into periods of window size
    $A->{period} = $window;#period used to divide data in periods of same size
    $d = data2tempDiv ($d,$A);
    
    my $period = data2period_list ($d);
     
    
    $A->{period} = $p = 1;#Which of the periods of size window will be printed on screen
    
    #If I want to use more modes probably is better to pass them through command line and not like here with a hardcode
    $A->{mode}="logodd";
    $A->{output}="R";
    $A->{periodWin} = 0; #This will be used to see to which window iteration belongs the printed table
     
    print "period\tcage\todd_ratio\todd_ratio_value\tdelta_w\titeration\n";
    &data2log_odd_period ($d, $A);
        
    #Number of days --> iterations ($lengthDays)
    $A->{period} = "day";
   	$d = data2tempDiv ($d,$A);#tagging by day
   	$period = data2period_list ($d);#getting the periods by day
   	$lengthDays = scalar (keys (%$period));
    
    #print STDERR "Length days-------------->$lengthDays\n";#del
  		
    for (my $i=1; $i < $lengthDays; $i++)
      {
        #Spliting the data in day periods for the elimination of first day (period)
        $A->{period} = "day";
   	    $d = data2tempDiv ($d,$A);
        
        #deleting all records corresponding to day 1
        foreach my $c (sort(keys (%$d)))
          {
    	     foreach my $t (sort(keys (%{$d->{$c}})))
              {
                my $period = $d->{$c}{$t}{period};
                
                $d->{$c}{$t}{period} += -1;
                my $newPeriod = $d->{$c}{$t}{period};
                
                if ($newPeriod == 0) 
                  {
                    delete ($d-> {$c}{$t}); 
                  }                                
              }
          }
        
        #The data is divided again into periods of window length
        $A->{period} = $window;
        $d = data2tempDiv ($d,$A);        
        
        $A->{period} = $p;#we just plot first period of window length        
        $A->{mode}="logodd";
        $A->{periodWin} = $i;#this parameter is passed to data2log_odd_period to tag the position of the sliding window 
        &data2log_odd_period ($d, $A);         
      }
  }

#This function calculates logodd ration but instead of considering
#each period separated if will calculate in a cumulative way
#this way for example logodd of period 2 will be calculated using data of period 1, and 2

sub data2log_odd_period_cumulative
  {    
    my $d=shift;
    my $A=shift;
    my $tot={};
    my $chc={};
    my $M={};
    
    ##INFO
    #c-> cage
    #ch -> previous channel
    #cch -> current channel
    #t -> time
    #pendt -> previous end time    
    
    foreach my $c (sort(keys (%$d)))
      {
        #my ($ch,$pendt);
        my ($ch) ;
        my $pendt = 0;

    	foreach my $t (sort(keys (%{$d->{$c}})))
          {
            my $period=$d->{$c}{$t}{period};
    	    if ($period > $A->{period}){next;}
    	    #print "he passat per aqui --> $pendt\n";
    	    #if ($d->{$c}{$t}{StartT} > $pendt)  {$pendt=$d->{$c}{$t}{EndT}; next;} else {}
    	    #I take the bin (e.g. sc_food_sc) 
    	    my $cch=$d->{$c}{$t}{bin};
    	    
    	    $M->{$c}{$cch}{$cch }{count}{tot}++;
    	    if ($ch)
              {
                $M->{$c}{$ch}{$cch}{count}{transition}++;
        		$M->{$c}{$ch}{$cch}{count}{interval}+=$d->{$c}{$t}{StartT}-$pendt;
        		#$M->{"total"}{$ch}{$cch}{count}{transitions}++;
        		#$M->{"total"}{$ch}{$cch}{count}{interval}+=$d->{$c}{$t}{StartT}-$pendt;
    	      }
    	    
    	    $tot->{$c}++;
    	    $ch=$cch;
    	    $pendt=$d->{$c}{$t}{EndT};#print "aqui que es $pendt";
    	  }
      }
   
    foreach my $c (keys (%$M))
      {
        foreach my $b1 (keys (%{$M->{$c}}))
          {
            foreach my $b2 (keys (%{$M->{$c}{$b1}}))
              {
                my ($count0,$count1, $count2);
          		if ( $tot->{$c}==0){next;}
          		$count0=$M->{$c}{$b1}{$b2}{count}{transition};
          		$count0/=$tot->{$c};
          		
          		$count1=$M->{$c}{$b1}{$b1}{count}{tot};
          		$count1/=$tot->{$c};
          		$count2=$M->{$c}{$b2}{$b2}{count}{tot};
          		$count2/=$tot->{$c};
          		$M->{$c}{$b1}{$b2}{logodd}{value}=(($count1*$count2)==0 || $count0==0)?0:log (($count0)/($count1*$count2));
          		$M->{$c}{$b1}{$b2}{count}{fulltot}=$tot->{$c};
          	  }
	      }
      }
    #modification logodd R output 23/09/10
    if ($A->{output}!~/R/) 
      {
	     print "Period:$A->{period}\n";
      } 
    #end modification-23/09/10

    display_log_odd($M);
                
    return $M;
  }
  
#This function will show the transitions matrices by cage
#in a way that Correspondance analysis could be performed
#        CAGE 1
#                 SC   CD   W
#            SC
#            CD
#             W
#        CAGE 2 ...

sub display_log_odd_CA_Cage
  {
    my $M=shift;
    
    foreach my $c (sort ({$a<=>$b}keys (%$M)))
      {
        print "Cage: $c Delta: $WEIGHT{$c}{delta}\n";
        
        foreach my $b1 (sort ({$a cmp $b}keys (%{$M->{$c}}))) 
	     {
	       print "\t$b1";
	     }
	     
	     print "\n";
	     
	    foreach my $b1 (sort ({$a cmp $b}keys (%{$M->{$c}})))   #(sort(keys (%{$d->{$c}})))
	     {	       
	       print "$b1";
	       
	       foreach my $b2 (sort ({$a cmp $b} keys (%{$M->{$c}{$b1}})))
	         {
              printf "\t%5d", $M->{$c}{$b1}{$b2}{count}{transition};		        
		     }
		      
		      print "\n";
	       }
      }
    return $M;
  }
 
#This function will show the global transition matrix
#in a way that Correspondance analysis could be performed
#          CAGE 1 CAGE2 CAGE3 CAGE4
#        
# SC-SC
# SC-CD
# SC-W
# CD-SC
# CD-CD
# CD-W
# W-SC
# ....       

sub display_log_odd_CA_global
  {
    my $M=shift;
    
    foreach my $c (sort ({$a<=>$b}keys (%$M)))
      {
        print "\t$c";
      }
    
    print "\n";
    
    foreach my $b1 (sort ({$a cmp $b}keys (%{$M->{2}}))) 
	     {	       
	       
	       foreach my $b2 (sort ({$a cmp $b} keys (%{$M->{2}{$b1}})))
	         {
              print  "$b1 -- $b2";
                            
              foreach my $c (sort ({$a<=>$b}keys (%$M)))
                {
                  printf "\t%5d", $M->{$c}{$b1}{$b2}{count}{transition};
                }
               print "\n";		        
		     }
	     }
      
    return $M;
  }
   
sub display_log_odd
  {
    my $M=shift;
    
    foreach my $c (sort ({$a<=>$b}keys (%$M)))
      {
	#modification logodd R output 23/09/10
	if ($A->{output}!~/R/) 
	  {
	    print "Cage: $c Delta: $WEIGHT{$c}{delta}\n";
	  }
	#end modification-23/09/10

	foreach my $b1 (keys (%{$M->{$c}}))
	  {
	    #printf "\t%10s: %d\n", $b1, $M->{$c}{$b1}{$b1}{count}{tot};
	  }
	foreach my $b1 (keys (%{$M->{$c}}))
	  {
	    my $b1C=$M->{$c}{$b1}{$b1}{count}{tot};
	    foreach my $b2 (keys (%{$M->{$c}{$b1}}))
	      {
		my $b2C=$M->{$c}{$b2}{$b2}{count}{tot};
		
		#modification logodd R output 23/09/10
		if ($A->{output}!~/R/) 
		  {
		    printf "\tCAGE: %2d Delta: %6.2f %10s -- %10s : %6.3f (Count: %5d)(FC: %5d)($b1: $b1C, $b2: $b2C)\n",$c,$WEIGHT{$c}{delta}, $b1,$b2,$M->{$c}{$b1}{$b2}{logodd}{value},$M->{$c}{$b1}{$b2}{count}{transition},$M->{$c}{$b1}{$b2}{count}{fulltot};
		  }
		else 
		  {
		    printf "%2d\t%2d\t%10s -- %10s\t%6.3f\t%6.2f", $A->{period}, $c, $b1, $b2, $M->{$c}{$b1}{$b2}{logodd}{value}, $WEIGHT{$c}{delta};
		    
		    if (exists ($A->{periodWin}))
              {
                print "\t$A->{periodWin}\n";                 
              }		       
            else
              {
                print "\n";
              }
		  }
		#end modification - 23/09/10
	      }
	  }
      }
    return $M;
  }

#log odd ratios with BIT information
#f(a I b) / f(a) f(I) f(b)
sub data2log_odd_period_BIT
  {    
    my $d=shift;
    my $A=shift;
    my $tot={};
    my $chc={};
    my $M={};
    my $T={}; #hash only for transitions
  
    ##INFO
    #c-> cage
    #ch -> previous channel
    #cch -> current channel
    #t -> time    
    
    foreach my $c (sort(keys (%$d)))
      {
        my ($ch, $cch, $ch_BIT);
        my $pendt = 0;

    	foreach my $t (sort(keys (%{$d->{$c}})))
          {
            my $period=$d->{$c}{$t}{period};
    	    
    	    if ($period ne $A->{period}){next;}
    	    
    	    #Channel (e.g. sc_food) 
    	    my $cch = $d->{$c}{$t}{Nature};
    	    
    	    #BIT (e.g. BIT_1)
    	    my $BIT = $d->{$c}{$t}{bin};
    	        	        	   
    	    $M->{$c}{$cch}{$cch}{count}{tot}++;
    	    $M->{$c}{$BIT}{$BIT}{count}{tot}++;
    	    
    	    if ($ch)
              {                
                $T->{$c}{$ch}{$BIT}{$cch}{count}{transition}++;                
        		$M->{$c}{$ch}{$cch}{count}{interval}+=$d->{$c}{$t}{StartT}-$pendt;
    	      }
    	    
    	    $tot->{$c}++;
    	    $ch=$cch;    	   
    	    
    	    $pendt=$d->{$c}{$t}{EndT};
    	  }
      }
    
    foreach my $c (keys (%$M))
      {
        
        foreach my $b1 (keys (%{$T->{$c}}))
          {
            foreach my $bitKey (keys (%{$T->{$c}{$b1}}))
              {
                foreach my $b2 (keys (%{$T->{$c}{$b1}{$bitKey}}))
                  {                                       
                    my ($count0,$count1, $count2, $count3);
            		
            		if ( $tot->{$c}==0){next;}
            		            		
            		$count0 = $T->{$c}{$b1}{$bitKey}{$b2}{count}{transition};
            		$count0 /= $tot->{$c};
            		
            		$count1 = $M->{$c}{$b1}{$b1}{count}{tot};
            		$count1/=$tot->{$c};
            		$count2=$M->{$c}{$b2}{$b2}{count}{tot};
            		$count2/= $tot->{$c};
            		$count3 = $M->{$c}{$bitKey}{$bitKey}{count}{tot};
            		$count3/=$tot->{$c};
            		
            		$T->{$c}{$b1}{$bitKey}{$b2}{logodd}{value}=(($count1*$count2*$count3)==0 || $count0==0)?0:log (($count0)/($count1*$count2*$count3));
            		$T->{$c}{$b1}{$bitKey}{$b2}{count}{fulltot}=$tot->{$c};
                  }
          	  }
	      }
      }
    
    if ($A->{output}!~/R/) 
      {
	     print "Period:$A->{period}\n";
      } 
    

    &display_log_oddBIT ($T, $M);
    
    return $M;
  }

sub display_log_oddBIT
  {
    my $T = shift;
    my $M = shift;
    
    foreach my $c (sort ({$a<=>$b}keys (%$T)))
      {
        
        if ($A->{output}!~/R/) 
          {
            print "Cage: $c Delta: $WEIGHT{$c}{delta}\n";
          }
	   
	     foreach my $b1 (keys (%{$T->{$c}}))
	       {
	         my $b1C = $M->{$c}{$b1}{$b1}{count}{tot};
	         
	           foreach my $bitKey (keys (%{$T->{$c}{$b1}}))
	             {
	               
	               my $bitC = $M->{$c}{$bitKey}{$bitKey}{count}{tot};
	               
	               foreach my $b2 (keys (%{$T->{$c}{$b1}{$bitKey}}))
	                 {
	                   my $b2C = $M->{$c}{$b2}{$b2}{count}{tot};
	                   
    	               if ($A->{output}!~/R/)
    	                 {
    	                   printf "\tCAGE: %2d Delta: %6.2f %10s::%5s -- %10s : %6.3f (Count: %5d)(FC: %5d)($b1: $b1C, $bitKey: $bitC, $b2: $b2C)\n",$c,$WEIGHT{$c}{delta}, $b1,$bitKey,$b2,$T->{$c}{$b1}{$bitKey}{$b2}{logodd}{value}, $T->{$c}{$b1}{$bitKey}{$b2}{count}{transition}, $T->{$c}{$b1}{$bitKey}{$b2}{count}{fulltot};
    	                 }
    	                 
    	               else
    	                 {
    	                   #printf "%2d\t%2d\t%10s -- %10s\t%6.3f\t%6.2f\n", $A->{period}, $c, $b1, $b2, $M->{$c}{$b1}{$b2}{logodd}{value}, $WEIGHT{$c}{delta};#del
    	                   printf "%2d\t%2d\t%10s -- %10s\t%10s\t%6.3f\t%6.2f\n", $A->{period}, $c, $b1, $b2, $bitKey, $T->{$c}{$b1}{$bitKey}{$b2}{logodd}{value}, $WEIGHT{$c}{delta};
    	                 }
	                 }
	             }
	       }
      }
    
    return $M;
  }
  
sub data2log_odd_period_bitThreshold
  {    
    my $d=shift;
    my $A=shift;
    my $tot={};
    my $chc={};
    my $M={};
    
    ##INFO
    #c-> cage
    #ch -> previous channel
    #cch -> current channel
    #t -> time
    #pendt -> previous end time    
    
    foreach my $c (sort(keys (%$d)))
      {
        my ($ch) ;
        my $pendt = 0;

    	foreach my $t (sort(keys (%{$d->{$c}})))
          {
            my $period=$d->{$c}{$t}{period};
    	    
    	    if ($period ne $A->{period}){next;}
    	    
    	    #I take the bin (e.g. sc_food_sc) 
    	    my $cch=$d->{$c}{$t}{bin};
    	    my $BIT=$d->{$c}{$t}{BIT};
    	    #print "bit is $BIT\n";die;#del
    	    
    	    $M->{$c}{$cch}{$cch }{count}{tot}++;
    	    
    	    if ($ch)
              {
                
                if ($BIT < $A->{fieldT})
                  {  
                    $M->{$c}{$ch}{$cch}{count}{transition}++;
                  }
        		
        		$M->{$c}{$ch}{$cch}{count}{interval}+=$d->{$c}{$t}{StartT}-$pendt;
    	      }
    	    
    	    $tot->{$c}++;
    	    $ch=$cch;
    	    $pendt=$d->{$c}{$t}{EndT};#print "aqui que es $pendt";
    	  }
      }

    foreach my $c (keys (%$M))
      {
        foreach my $b1 (keys (%{$M->{$c}}))
          {
            foreach my $b2 (keys (%{$M->{$c}{$b1}}))
              {
                my ($count0,$count1, $count2);
          		if ( $tot->{$c}==0){next;}
          		$count0=$M->{$c}{$b1}{$b2}{count}{transition};
          		$count0/=$tot->{$c};
          		
          		$count1=$M->{$c}{$b1}{$b1}{count}{tot};
          		$count1/=$tot->{$c};
          		$count2=$M->{$c}{$b2}{$b2}{count}{tot};
          		$count2/=$tot->{$c};
          		$M->{$c}{$b1}{$b2}{logodd}{value}=(($count1*$count2)==0 || $count0==0)?0:log (($count0)/($count1*$count2));
          		$M->{$c}{$b1}{$b2}{count}{fulltot}=$tot->{$c};
          	  }
	      }
      }
    #modification logodd R output 23/09/10
    if ($A->{output}!~/R/) 
      {
	     print "Period:$A->{period}\n";
      } 
    #end modification-23/09/10

    display_log_odd($M);
    
    return $M;
  }
   
sub data2log_odd_old
    {
      my $d=shift;
      my $Cage=shift;
      my $Nature=shift;
      my $start=shift;
      my $end=shift;
      
      my  $nc;
      my $M={};
      my $chc={};
      
            
      foreach my $c (sort(keys (%$d)))
	{
	  if (!($Cage eq "all" || $Cage==$c)){next;}
	  my ($ch,$pEndT);
	  foreach my $t (sort(keys (%{$d->{$c}})))
	    {
	      if ($start && ($t<$start || $t>$end)){;}
	      else
		{
		  my $cch=$d->{$c}{$t}{Nature};
		  if ($cch=~/$Nature/)
		    {
		      if ($ch)
			{
			  $M->{$ch}{$cch}{Count}{tot}++;
			  $M->{$ch}{$cch}{Interval}{tot}+=$d->{$c}{$t}{StartT}-$pEndT;
			}
		      if (1==2 && $pEndT>$d->{$c}{$t}{StartT})
			{
			  print "\n****** ERROR: $c => Start= $d->{$c}{$t}{StartT} pEnd: $pEndT\n";
			}

		      $chc->{$cch}{Count}{tot}++;
		      $chc->{$cch}{Value}{tot}+=$d->{$c}{$t}{Value};
		      $chc->{$cch}{Duration}{tot}+=$d->{$c}{$t}{Duration};
		      if ($pEndT){$chc->{$cch}{Interval}{tot}+=$d->{$c}{$t}{StartT}-$pEndT;}
		      $ch=$cch;
		      $pEndT=$d->{$c}{$t}{EndT};
		      $nc++;
		    }
		}
	    }
	}
      if (!$nc){return;}
	  
      for my $c(keys(%$chc))
	{
	  for my $x (keys (%{$chc->{$c}}))
	   {
	     $chc->{$c}{$x}{avg}=$chc->{$c}{$x}{tot}/$nc;
	   }
       }

      print "CAGE: $Cage DIET: $Nature START: $start END: $end Nitervals: $nc\n";
      foreach my $c(sort(keys(%$chc)))
	    {
	      printf "\t%12s Freq: %6.2f Dur: %6d Value: %6.2f Int: %6d N: %6d\n", $c,$chc->{$c}{Count}{avg},$chc->{$c}{Duration}{avg}, $chc->{$c}{Value}{avg},$chc->{$c}{Interval}{avg},$chc->{$c}{Count}{tot} ;
	    }
      
      foreach my $c1 (sort(keys (%$chc)))
	{
	  foreach my $c2 (sort(keys (%$chc)))
	    {
	      my $avgInt=$M->{$c1}{$c2}{Interval}{tot}/$M->{$c1}{$c2}{Count}{tot};
	      my $v1=$M->{$c1}{$c2}{Count}{tot}/($nc-1);
	      my $v2=$chc->{$c1}{Count}{avg}*$chc->{$c2}{Count}{avg};
	      my $logv=($v2>0 && $v1>0)?mylog($v1/$v2):0;
	      printf "\t\t%12s ---> %12s  %6.2f Interval: %6d Count: %6d\n", $c1, $c2 ,$logv, $avgInt,$M->{$c1}{$c2}{Count}{tot};
	    }
	}
    }


sub interval2count
    {
      my $d=shift;
      my $s=shift;
      my $e=shift;
      my ($tot);
      
      foreach my $c (sort(keys (%$d)))
	{
	  foreach my $t (sort(keys (%{$d->{$c}})))
	    {
	      if ($t>$s && $t<$e){$tot++;}
	    }
	}
      return $tot;
    }


sub data2index
  {
    my $d=shift;
    my $nd={};
    
    #indexes data so that it can be dealt with by viterbi trainning

    foreach my $c (keys(%$d))
      {
	my $i;
	foreach my $t (sort (keys(%{$d->{$c}})))
	  {
	    ++$i;
	    foreach my $k(keys(%{$d->{$c}{$t}}))
	      {
		$nd->{$c}{$i}{$k}=$d->{$c}{$t}{$k};
	      }
	    delete ($d->{$c}{$t});
	  }
      }
    return $nd;
  }
	    


sub datafield2minmax
  {
    my $d=shift;
    my $field=shift;
    my $set;
    my ($max, $min);
    
    print "Field=$field";
    
    foreach my $c (keys(%$d))
      {
	
	foreach my $i (keys %{$d->{$c}})
	  {
	    my $v=$d->{$c}{$i}{$field};
	    print "$c -- $i -- $field -- $v\n";
	    if (!$set)
	      {
		$max=$min=$v;
		$set=1;
	      }
	    else
	      {
		$max=($max<$v)?$v:$max;
		$min=($min>$v)?$v:$min;
	      }
	  }
      }
    return ($min,$max);
  }
	
	

				  
#####################################################
#emits the model for the occasionally dishonnest casino
sub get_file 
  {
    my $A=shift;
    my $t=shift;
    my $r={};
    my $test;
    my $ref=$t."R";
    
    if (!$A->{$t} && ! $A->{$ref} )
      {
	die;
      }
    elsif ($A->{$ref})
      {
	my $b=$A->{$ref};
	$r=$b;
      }
    else
      {
	if ($t =~/model/){$r=parse_model ($A->{$t});}
	else {$r=parse_data ($A->{$t});}
	$A->{$ref}=$r;
      }
    return $r;
  }
    
sub seq2model 
  {
    my $A=shift;
    my $M={};
    
    my $d=get_file($A, "data");
    
    if (!$A->{ntries}){$A->{ntries}=5;}
    if (!$A->{nit}){$A->{nit}=1000;}
    if (!$A->{nbin}){$A->{nbin}=10;}
    if (!$A->{delta}){$A->{delta}=0.02;}
    if (!$A->{field}){$A->{field}="Value";}
    
    if (!$A->{nstate}){$A->{nstates}=2;}
    if (!$A->{nemit}){$A->{nemit}=$A->{nbin};}
    
    $d=data2bin ($d, $A->{"Value"}, $A->{nbin},$A->{delta});
    my @topo;
    for (my $a=0; $a<$A->{nstate}; $a++){push (@topo, $A->{nemit});}
				       
    my ($P, $M)=multi_baum_welch($d,$A->{ntries}, $A->{nit}, @topo);
    $A->{modelP}=$P;
    $A->{modelR}=$M;
  }
sub decode
  {
    my $A=shift;
    
    my $M=get_file($A, "model");
    my $d=get_file($A, "data");
    
    ($d,$A->{modelP})=viterbiL ($M, $d);
    
    $d=posteriorL($M, $d);
  }
  
#####################################################################
#TEST_BW_TRAINNING
#####################################################################
#Usage: &test_bw_trainning($A)
#Function: This function test the correct operation of the Baum-Welch 
#algorithm with the Occasionally Dishonest Casino Model (ODHC)
#Returns: returns nothing, display 
#Args: No

sub test_bw_trainning()
  {
    my $A=shift;
    my $file=$A->{inmodel}; 
    my ($RP, $P);
    my $M={};
    my $score;
    my ($RM, $RM2);
    my $nseeds=1;
    my $nseq=1;
    my $len=200;
    
    if ($file) 
      {
	$RM = &read_model ($file);       
      }
    else
      {
	$RM = &ODHC2model();
      }
    
    #print STDERR Dumper($RM);

    my $S=model2sequence ($RM,1,1000);
       
    $RM=model2modelL($RM);
    $RM2=sequence2model ($S);
    my $RP=seq2probaL($RM, $S);
    
    ($P,$M)=multi_baum_welch ($S,5,10, 6, 6);
        
    ($S,$score)=viterbiL ($M, $S);
    $S=posteriorL($M, $S); #more probable state using the posterior probability 
    
    display_decode ($S);
    $M  =modelL2model($M);
    $RM =modelL2model($RM);
    $RM2=modelL2model($RM2);
        
    
    display_decode ($S);
    
    display_model ($RM);
    display_model ($RM2);
    
    display_model ($M);
    die;
  }

#####################################################################
#ODHC2MODEL
#####################################################################
#Usage: $ODHC = &ODHC2model()
#Function: Creates a Hash with the probabilities of the ODHC model 
#Returns: returns a ref Hash with transition and emission probabilities
#Args: No

sub ODHC2model
  {
    my $M={};

    $M->{'ST::START'}{'ST::fair'  }=0.5;
    $M->{'ST::START'}{'ST::unfair'}=0.5;

    $M->{'ST::fair'} {'ST::fair'  }=0.95;
    $M->{'ST::fair'} {'ST::unfair'}=0.05;
    
    $M->{'ST::unfair'} {'ST::fair'  }=0.1;
    $M->{'ST::unfair'} {'ST::unfair'}=0.9;
    
    $M->{'ST::fair'} {'ST::END'  }=0.5;
    $M->{'ST::unfair'} {'ST::END'}=0.5;
    
    $M->{'ST::fair'} {'1'}=1/6;
    $M->{'ST::fair'} {'2'}=1/6;
    $M->{'ST::fair'} {'3'}=1/6;
    $M->{'ST::fair'} {'4'}=1/6;
    $M->{'ST::fair'} {'5'}=1/6;
    $M->{'ST::fair'} {'6'}=1/6;
    
    $M->{'ST::unfair'} {'1'}=1/10;
    $M->{'ST::unfair'} {'2'}=1/10;
    $M->{'ST::unfair'} {'3'}=1/10;
    $M->{'ST::unfair'} {'4'}=1/10;
    $M->{'ST::unfair'} {'5'}=1/10;
    $M->{'ST::unfair'} {'6'}=5/10;
    
    return $M;
  }

#####################################################################
#MODEL2SEQUENCE
#####################################################################
#Usage: $Seqs = model2sequence ($hash_model, n, l)
#Function: Creates n sequences of length l given a probalistic model 
#$hash_model, for each step in the sequence it calls &model2emit to 
#set following state and symbol emited given the probabilistic Model  
#Args: $M => A referenced hash with probabilistic model of state 
#            transitions and emissions in format
#             $M -> {'ST::A'} {'ST::B'} = prob (for state transitions)
#             $M -> {'ST::A'} {'SYMBOL X'} = prob (for emission probability of a symbol given a state)   
#      $n => Number of sequences to be created
#      $l => Length of each sequence    
#Returns:returns a ref Hash $H->{$j}{$l}{bin} (symbol)
#                           $H->{$j}{$l}{RST} (state)
#where each position has the state and the symbol emited in this state

sub model2sequence
  {
    my $M=shift;
    my $n=shift; #number of sequences
    my $l=shift; #sequence length
    my $S={};
        
    my $state="ST::START";
    my $symbol;
    for (my $j=0; $j<$n; $j++)
      {
	for (my $i=1; $i<=$l; $i++)
	  {
	    ($state, $symbol)=model2emit($M, $state);
	    
	    $S->{$j}{$i}{bin}=$symbol;
	    $S->{$j}{$i}{RST}=$state;
	    
	  }
      }
    return $S;
  }
  
#####################################################################
#MODEL2EMIT
#####################################################################
#USAGE: ($state, $symbol) = &model2emit ($hash_model, $pState)
#FUNCTION: return a state and a symbol given a probabilistic model and
#the previous state ($start)
#For setting new state and symbol it generates a random number, if this
#number has a lower value than probability for state/symbol X it returns X
#if not it continues until reaching a value, probabilities are added.
#First it generates state as symbol prob will depend on it
#ARGS: $M => A referenced hash with probabilistic model of state 
#            transitions and emissions in format
#             $M->{'ST::A'}{'ST::B'}=prob (for state transitions)
#             $M->{'ST::A'}{'SYMBOL X'}=prob (for emission probability of a symbol given a state)   
#      $pStaten => Previous state in the sequence of states
#RETURNS:returns two strings $state new stateX given the model an previous state
#                            $bin symbol emited on stateX

sub model2emit
  {
    my $M=shift;
    my $start=shift;
    my ($state, $bin);
    my $r_state=rand(1);
    my $r_bin=rand(1);
    my $p=0;
    
    #Getting state
    foreach my $k (keys(%$M))
      {
	$p+=$M->{$start}{$k};
	if ( $r_state<=$p){$state=$k;last;}
      }
    
    #If state is END or eventually START we return to restart the function as &model2seq has the sequence length control
    if ($state eq "ST::END" || $state eq "ST::START"){return model2emit ($M, $start);}
    $p=0;
    
    #Getting symbol
    foreach my $bin (keys (%{$M->{$state}}))
      {
	if ( $bin =~/ST::/){;}#If second element is a state we avoid it as Emission and Transitions aren't separated, we just skip Transition prob
	else
	  {
	    $p+=$M->{$state}{$bin};
	    if ($r_bin<=$p)
	      {
		return ($state, $bin);
	      }
	  }
      }
    
    return ($state, $bin);
  }

sub modelL2model
  {
     my $M=shift;
     my $tag=shift;
         
     
     foreach my $k(keys(%$M))
       {
	 foreach my $l (keys(%$M))
	   {
	     $M->{$k}{$l}=(!$M->{$k}{$l} ||$M->{$k}{$l}==$LOG_ZERO)?0:exp($M->{$k}{$l});
	   }
	}
     
      foreach my $k(keys(%$M))
	{
	  foreach my $l (keys(%{$M->{$k}}))
	    {
	      if (!($l=~/ST::/))
		{
		  $M->{$k}{$l}=(!$M->{$k}{$l} ||$M->{$k}{$l}==$LOG_ZERO)?0:exp($M->{$k}{$l});
		}
	    }
	}
      return $M;
    }

##################################################################
#MODEL2MODELL   #Model to model log  
##################################################################
#USAGE: $M_LOG = &model2modelL ($M) 
#FUNCTION: Converts probabilities into natural log ln(prob), going
#through all values of the Hash. If transition/emission doesn't exist
#or has value 0 it returns a global constant $LOG_ZEROm, 
#else call &mylog () 
#ARGS: $M => A referenced hash with probabilistic model of state 
#            transitions and emissions in format 
#             $M->{'ST::A'}{'ST::B'}=prob (for state transitions)
#             $M->{'ST::A'}{'SYMBOL X'}=prob (for emission probability of a symbol given a state)  
#RETURNS: Same referenced hash but with ln(prob)

sub model2modelL
  {
     my $M=shift;
     my $tag=shift;
     
     #For states transitions state A -> state B
     foreach my $k(keys(%$M))
       {
	 foreach my $l (keys(%$M))
	   {
	     $M->{$k}{$l}=(!$M->{$k}{$l} || $M->{$k}{$l}<0.00000001)? $LOG_ZERO:mylog($M->{$k}{$l});
	   }
	}
     
     #For symbol emission state A -> simbol X
     foreach my $k(keys(%$M))
       {
	 foreach my $l (keys(%{$M->{$k}}))
	   {
	     
	     if (!($l=~/ST::/))
	       {
		 $M->{$k}{$l}=(!$M->{$k}{$l} ||$M->{$k}{$l}<0.00000001)?$LOG_ZERO:mylog($M->{$k}{$l});
	       }
	   }
       }
     return $M;
   }

sub display_hash
    {
      my $dp=shift;
      my $h=shift;
      my @kl=@_;
      
      
      foreach my $k (keys(%$h))
	{
	  print "**** $k\n";
	  if ($dp==1)
	    {
	      foreach my $l (@kl)
		{
		  print "-- $l";
		}
	      print "-- $k -- $h->{$k}\n";
	    }
	  else
	    {
	      @kl=push (@kl, $k);
	      display_hash ($dp-1, $h, @kl);
	    }
	}
    }

sub display_decode 
    {
      my $S=shift;
      my $tag=shift;
      my $T={};
      
      foreach my $j (sort {$a<=>$b}keys (%$S))
	{
	  my $L=keys(%{$S->{$j}});
	  for (my $i=1; $i<=$L; $i++)
	    {
	      my $bin   =$S->{$j}{$i}{bin};
	      my $state =$S->{$j}{$i}{viterbi};
	      my $rstate=$S->{$j}{$i}{RST};
	      $T->{$rstate}{$state}++;
	      print "$tag :: $j :: $i :: $bin == VITERBI: $state";
	      if ($rstate){print "== REAL: $rstate";}
	      if ( exists ($S->{$j}{$i}{bpost}))
		   {
		     printf "== POSTERIOR: $S->{$j}{$i}{bpost}{k}";
		     
		   }
	      print "\n";
	    }
	}
      
      foreach my $k (keys(%$T))
	{
	  foreach my $l (keys (%{$T->{$k}}))
	    {
	      print "TOT: $k -- $l => $T->{$k}{$l}\n";
	    }
	}
    }

#################################################
sub viterbi_trainningL
  {
    my $M=shift;
    my $S=shift;
    
    my $A={};
    my $E={};
    my $ns;
    my $score;
    
    ($S,$score)=viterbiL($M,$S);
    
    foreach my $j (keys(%$S))
      {
	my $L=keys(%{$S->{$j}});
	for (my $i=1; $i<=$L; $i++)
	  {

	    my $l=$S->{$j}{$i}{viterbi};
	    if ($i>1)
	      {
		my $k=$S->{$j}{$i-1}{viterbi};
		$A->{$k}{$l}++;
	      }
	    $E->{$l}{$S->{$j}{$i}{bin}}++;
	  }
      }
    
    foreach my $k (keys (%$M))
      {
	foreach my $l (keys(%{$M->{$k}}))
	  {
	    if (($l=~/ST::/)){$A->{$k}{$l}+=1;}
	    else {$E->{$k}{$l}+=1;}
	  }
      }
    #update A/Model
    foreach my $k (keys (%$M))
      {
	my $num;
	foreach my $lp (keys(%$M)){$num+=$A->{$k}{$lp};}
	foreach my $l (keys(%$M)){$M->{$k}{$l}=$A->{$k}{$l}/$num;}
      }
    
    # update E/model 
    foreach my $k (keys (%$M))
      {
	my $num;
	foreach my $lp (keys(%{$M->{$k}}))
	  {
	    if (!($lp =~/ST::/)){$num+=$E->{$k}{$lp};}
	  }
 	foreach my $l (keys(%{$M->{$k}}))
	  {
	    if (!($l =~/ST::/)){$M->{$k}{$l}=$E->{$k}{$l}/$num;}
	  }
      }
    
    return model2modelL($M);
  }

#################################################################
#multi_baum_welch
#################################################################
#USAGE: multi_baum_welch ($S, $multi, $nit, $n, $m)   
#FUNCTION: Performs Baum-Welch algorithm with set of sequences $S,  
# m times ($multi), with number maximum of iterations ($nit), in each
#iteration it checks if the probability of the sequences with the new
#set model it is better to keep going, if the probability it is not
#improving the loop breaks. This probability is calculateld by 
#&baum_welchL()->seq2probaL() and its the overall probability for all
#sequences given the model and the set of sequences. As this will be
#done multiple times to compare the different executions of baum-welch
#we also compare the probabilities using seq2probaL() and only keeping
#the model if the probability it is greater. 
#ARGS: $S => A referenced hash with the serie of sequences of symbols
#            and its corresponding state. Sequences are indexed by $j
#            and each position of a sequence by $i 
#             $S -> {$j} {$i} {bin} = symbol
#             $S -> {$j} {$i} {RST} = state
#     $multi => number of times the Baum-Welch alg is executed
#     $nit => number maximum of iterations of Baum-Welch if we don't 
#             converge to a stable point 
#     $n, $m = @topology => Topology of the model to generate random
#                           probabilities (transition, emission), for
#                           starting Baum-Welch, (n symbols state 1,
#                           m symbols state 2...)
#   
#RETURNS:     $M => A referenced hash with probabilistic model (best score) 
#                   of state transitions and emissions in format   
#             $M->{'ST::A'}{'ST::B'}=prob (for state transitions)
#             $M->{'ST::A'}{'SYMBOL X'}=prob (for emission probability of a symbol given a state) 
#             $best_score => Best score of different executions of Baum-Welch

sub multi_baum_welch
  {
    my $S=shift;
    my $multi=shift;
    my $nit=shift;
   
    my @topology=@_;
    
    my $best_score;
    my $BM;
    my $maxidle=5;
    my $score;
    
    for (my $i=0; $i<$multi; $i++)
      {
	my ($idle, $PP);
	print "---- $i -----\n";
	my $P;
	my $M=topology2modelL ("rand",@topology);
	#my $M=topology2modelL (0,@topology);#no random model for starting baum-welch
	my $M=model2modelL($M);
	my $cont=1;
	for (my $it=0; $it<$nit && $idle<$maxidle && $cont; $it++)
	  {
	    ($P,$M)=baum_welchL ($S,$M);
	    
	    if ($PP)
	      {
		my $delta=$P-$PP;
		if ($delta<-1){$cont=0;}
		elsif ($delta<0.001){$idle++;}
		else {$idle=0;}
	      }
	    int($P);
	    print "\t$it ==> $P [$best_score --] [$idle]\n";
	    $PP=$P;
	  }

	my $score=seq2probaL($M, $S);#applies forward algorithm for each sequence and add the overall probability(score)
	if (!$BM || $score>$best_score)
	  {
	    $BM=$M;
	    $best_score=$score;
	  }
      }
        
    ($S, $score)=viterbiL($BM, $S);
    $S=posteriorL($BM, $S);
    
    return ($best_score, $BM);
  }

#####################################################################################
#POSTERIORL
#####################################################################################
#USAGE: posteriorL ($M, $S)
#FUNCTION: Calculates posterior probabilities of states for each position of sequence
#          using the forward and backward calculation. It does it for each sequence  
#          of referenced hash $S.
#ARGS: $M => A referenced hash with probabilistic model of state transitions and 
#            emissions in format   
#             $M->{'ST::A'}{'ST::B'}=prob (for state transitions)
#             $M->{'ST::A'}{'SYMBOL X'}=prob (for emission probability of a symbol given a state)
#      $S => A referenced hash with the serie of sequences of symbols
#            and its corresponding state. Sequences are indexed by $j
#            and each position of a sequence by $i 
#             $S -> {$j} {$i} {bin} = symbol
#             $S -> {$j} {$i} {RST} = state 
#RETURNS: Same referenced hash $S updated for each position with the posterior probability
#         for each state, the most probable state and its probability          
#             $M->{$j}{$i}{post}{$k} 
#             $M->{$j}{$i}{bpost}{k}
#             $M->{$j}{$i}{bpost}{score}

sub posteriorL
    {
      my $M=shift;
      my $S=shift;
   
   foreach my $j (keys (%$S))
      {
	
	my $L=keys (%{$S->{$j}});
	my $F={};
	my $B={};

	my ($P,$B)=backwardL($M,$S->{$j});#log_space
	my ($P,$F)=forwardL ($M, $S->{$j});
	
	for (my $i=1; $i<=$L; $i++)
	  {
	    my $symbol=$S->{$j}{$i}{'bin'};
	    my $bpost_score;
	    my $bpost_k;
	    foreach my $k (keys (%$M))
	      {
		if (!(exists ($M->{$k}{$symbol}))){next;}
		my $p=log_divide (log_multiply($F->{$i}{$k},$B->{$i}{$k}),$P);
		$S->{$j}{$i}{post}{$k}=$p;
		if (!$bpost_score || $p>$bpost_score)
		  {
		    $bpost_score=$p;
		    $bpost_k=$k;
		  }
	      }
	    $S->{$j}{$i}{bpost}{k}=$bpost_k;
	    $S->{$j}{$i}{bpost}{score}=$bpost_score;
	  }
      }
   return $S;
 }

sub baum_welchL
  {

    my $S=shift;
    my $M=shift;
    my $A={};
    my $E={};
    my $P;

    
    foreach my $j (keys (%$S))
      {	
	my $L=keys (%{$S->{$j}});
	my $F={};
	my $B={};
	
	my ($P,$B)=backwardL($M, $S->{$j});#log_space
	my ($P,$F)=forwardL ($M, $S->{$j});
	       	
	#Update A
	foreach my $k (keys (%$M))
	  {
	    foreach my $l(keys(%$M))
	      {
		$A->{$j}{$k}{$l}=$LOG_ZERO;
		if (!$A->{$k}{$l}){$A->{$k}{$l}=$LOG_ZERO;}
		
		for (my $i=1; $i<$L; $i++)
		  {
		    my $symbol=$S->{$j}{$i+1}{'bin'};
		    if (!(exists ($M->{$l}{$symbol}))){next;}
		    
		    my $fo=$F->{$i}{$k};#log space
		    my $ba=$B->{$i+1}{$l};#log_space
		    my $tr=$M->{$k}{$l}; #log_space
		    my $em=$M->{$l}{$symbol};;#log_space
		    $A->{$j}{$k}{$l}=log_add ($A->{$j}{$k}{$l},log_multiply($fo,$tr,$em,$ba));
		  }
		$A->{$j}{$k}{$l}=log_divide($A->{$j}{$k}{$l},$P);
		$A->{$k}{$l}=log_add ($A->{$k}{$l},$A->{$j}{$k}{$l});
	      }
	  }
	
	#update Emissions
	foreach my $k (keys (%$M))
	  {
	    foreach my $b (keys (%{$M->{$k}}))
	      {
		if ($b=~/ST::/){next;}
		$E->{$j}{$k}{$b}=$LOG_ZERO;
		if ( ! exists ($E->{$k}{$b})){$E->{$k}{$b}=$LOG_ZERO;}
		
		for (my $i=1; $i<=$L; $i++)
		  {
		    if ($S->{$j}{$i}{bin} eq $b)
		      {
			my $p=$E->{$j}{$k}{$b};
			my $q=log_multiply ($F->{$i}{$k},$B->{$i}{$k});
			$E->{$j}{$k}{$b}=log_add($p,$q);
		      }
		  }
		
		$E->{$j}{$k}{$b}=log_divide($E->{$j}{$k}{$b},$P);
		$E->{$k}{$b}=log_add($E->{$k}{$b},$E->{$j}{$k}{$b});
	      }
	  }
      }
    
    
    foreach my $k (keys(%$M))
      {
	foreach my $l (keys (%{$M->{$k}}))
	  {
	    if (($l=~/ST::/ )){$A->{$k}{$l}=exp($A->{$k}{$l});}
	    else {$E->{$k}{$l}=exp($E->{$k}{$l});}
	  }
      }
    
     #add pseudo-counts
    foreach my $k (keys (%$M))
      {
	foreach my $l (keys(%{$M->{$k}}))
	  {
	    if (($l=~/ST::/)){$A->{$k}{$l}+=1;}
	    else {$E->{$k}{$l}+=1;}
	  }
      }
    #update A/Model
    foreach my $k (keys (%$M))
      {
	my $num;
	foreach my $lp (keys(%$M)){$num+=$A->{$k}{$lp};}
	foreach my $l (keys(%$M)){$M->{$k}{$l}=$A->{$k}{$l}/$num;}
      }
    
    # update E/model 
    foreach my $k (keys (%$M))
      {
	my $num;
	foreach my $lp (keys(%{$M->{$k}}))
	  {
	    if (!($lp =~/ST::/)){$num+=$E->{$k}{$lp};}
	  }
 	foreach my $l (keys(%{$M->{$k}}))
	  {
	    if (!($l =~/ST::/)){$M->{$k}{$l}=$E->{$k}{$l}/$num;}
	  }
      }
    $M=model2modelL($M);
    $P=seq2probaL($M,$S);
    return ($P,$M);
  }
    
sub seq2probaL
  {
    my $M=shift;
    my $S=shift;
    
    my $TP;

    for my $j (keys(%$S))
      {
	my ($P, $f)=forwardL($M, $S->{$j});
	$TP+=$P;
      }
    return $TP;
  }

sub forwardL 
    {
      my $M=shift;
      my $S=shift;
      my $f={};
      my $P;
      my $L=keys(%$S);

      foreach my $k (keys(%$M)){$f->{0}{$k}=$LOG_ZERO;}
      $f->{0}{'ST::START'}=0;
     
      for (my $i=1; $i<=$L; $i++)
	{
	  foreach my $l (keys(%$M))
	    {

	      $f->{$i}{$l}=$LOG_ZERO;
	      my $emit=(!exists($M->{$l}{$S->{$i}{bin}}))?$LOG_ZERO:$M->{$l}{$S->{$i}{bin}};
	      
	      foreach my $k (keys(%$M))
		{
		  $f->{$i}{$l}=log_add($f->{$i}{$l}, log_multiply ($f->{$i-1}{$k},$M->{$k}{$l}));
		  my $v1=myexp($f->{$i}{$l});
		  my $v2=myexp($f->{$i-1}{$k});
		  my $v3=myexp($M->{$k}{$l});
		  #print "\t----L: V1: $v1 V2: $v2 V3: $v3\n";
		}
	      my $v1=myexp($f->{$i}{$l});
	      my $v2=myexp($emit);
	      
	      $f->{$i}{$l}=log_multiply($f->{$i}{$l},$emit);
	      my $v3=myexp($f->{$i}{$l});
	      #print "----L: $i V1: $v1 V2: $v2 V3: $v3\n";
	      
	    }
	}

      
      $P=$LOG_ZERO;
      foreach my $k (keys (%$M))
	{
	  $P=log_add ($P, log_multiply ($f->{$L}{$k},$M->{$k}{'ST::END'}));
	}
      
      return ($P,$f);
    }

sub backwardL 
    {
      my $M=shift;
      my $S=shift; 
      
      my $B={};
     
      my $P;
      my $L=keys (%$S);
      

      foreach my $k (keys(%$M)){$B->{$L}{$k}=$M->{$k}{'ST::END'};}

      for (my $i=$L-1; $i>=1; $i--)
	{
	  foreach my $k (keys(%$M))
	    {
	      $B->{$i}{$k}=$LOG_ZERO;
	      
	      foreach my $l (keys(%$M))
		{
		  if (!exists($M->{$l}{$S->{$i+1}{bin}})){next;}
		  my $x=$M->{$k}{$l};
		  my $y=$M->{$l}{$S->{$i+1}{bin}};
		  my $z=$B->{$i+1}{$l};
		  my $p=$B->{$i}{$k};
		  my $q=$x+$y+$z;
		  
		  $B->{$i}{$k}=log_add ( $B->{$i}{$k}, log_multiply($x,$y,$z));
		  
		}
	    }
	}
      return (0,$B);
    }

sub viterbiL 
  {
    my $M=shift;
    my $S= shift;
    my ($max_k, $ptr_k);
    
    foreach my $j (keys(%$S))
      {
	my $L=keys(%{$S->{$j}});
	my $PTR={};
	my $V={};
	my ($path, $ppath);
	
	#Initialisation
	foreach my $k (keys(%$M)){$V->{0}{$k}=$LOG_ZERO;}
	$V->{0}{'ST::START'}=0;
	
	#Recursion
	for (my $i=1; $i<=$L; $i++)
	  {
	    my $symbol=$S->{$j}{$i}{bin};
	    
	    foreach my $l (keys (%$M))
	      {
		if ( !exists ($M->{$l}{$symbol}))
		  {
		    $V->{$i}{$l}=$LOG_ZERO;
		    $PTR->{$i}{$l}=$LOG_ZERO;
		  }
		else
		  {
		    $max_k=$LOG_ZERO;
		    $ptr_k="";
		    foreach my $k (keys (%$M))
		      {
			my $v=log_multiply($V->{$i-1}{$k},$M->{$k}{$l});
			my $v1=myexp($V->{$i-1}{$k});
			my $v2=myexp($M->{$k}{$l});
			my $v3=myexp($v);
			#print "\t$k $l---> V1: $v1 * V2: $v2 = V3: $v3\n";
			if ($v>$max_k || $max_k==$LOG_ZERO)
			  {
			    $max_k=$v;
			    $ptr_k=$k;
			  }
		      }
		    $V->{$i}{$l}=log_multiply($M->{$l}{$S->{$j}{$i}{bin}},$max_k);
		    $PTR->{$i}{$l}=$ptr_k;
		    my $v=exp($max_k);
		  }
	      }
	  }
	
	#Termination
	$max_k=$LOG_ZERO;
	$ptr_k="";
	foreach my $k (keys (%$M))
	  {

	    my $vv=log_multiply($V->{$L}{$k},$M->{$k}{'ST::END'});
	    if ($vv>$max_k  || $max_k==$LOG_ZERO)
	      {
		$max_k=$vv;
		$ptr_k=$k;
	      }
	  }
	
	#Traceback
	for (my $i=$L; $i>=1; $i--)
	  {
	    $S->{$j}{$i}{viterbi}=$ptr_k;
	    $ptr_k=$PTR->{$i}{$ptr_k};
	  }
	
      }
    return ($S,$max_k);
  }

sub topology2modelL
  {
    my ($model,@topo)=@_;
    my $M=topology2model ($model,@topo);
    return model2modelL($M);
  }

sub topology2model
  {
    my ($model,@states)=@_; 
    my $SL={};
    my $M={};
   
    for (my $a=1; $a<=($#states+1); $a++)
      {
	$SL->{"ST::$a"}=$states[$a-1];
      }
    $SL->{"ST::START"}=0;
    $SL->{"ST::END"}=0;
    
    foreach my $st1 (keys (%$SL))
      {
	my $tot;

	#set emmissions
	for (my $a=1; $a<=$SL->{$st1}; $a++)
	  {
	    $tot+=$M->{$st1}{$a}=($model eq "rand")?rand (1000):100;
	  }
	for (my $a=1; $a<=$SL->{$st1}; $a++)
	  {
	    $M->{$st1}{$a}/=$tot;
	  }


	#Set Transitions
	$tot=0;
	foreach my $st2 (keys (%$SL))
	  {
	    $tot+=$M->{$st1}{$st2}=($model eq "rand")?rand (1000):100;
	  }
	foreach my $st2 (keys (%$SL))
	  {
	    $M->{$st1}{$st2}/=$tot;
	  }
      }
    display_model ($M);
    return $M;
  }

sub display_path 
    {
      my $M=shift;
      my $T=shift;
      my $tag=shift;
      
      my $L=keys (%$T);
      print "L=$L $tag\n";
      for ( my $i=1; $i<=$L; $i++)
	{
	  my $v;
	  foreach my $k (keys (%$M))
	    {
	      if ($tag eq "exp"){$v=exp($T->{$i}{$k});}
	      else {$v=$T->{$i}{$k};}
	      print "-- $i $k ==> $v ($tag)\n";
	    }
	}
    }

sub display_model
  {
    my $M=shift;
    my $fname=shift;
    my $F= new FileHandle;
    
    if ($fname){open ($F,">$fname");}
    else {$F=0;}
    print "#### MODEL: $fname\n";
    print "#### STATES\n";
    foreach my $k(keys(%$M))
      {
	foreach my $l (keys(%$M))
	  {
	    if ($fname){printf "$k;$l;%7.5f\n",$M->{$k}{$l};}
	    else {printf "$k;$l;%7.5f\n",$M->{$k}{$l};}
	    
	  }
      }
    print "#### EMISSIONS\n";
    foreach my $k(keys(%$M))
      {
	foreach my $l (keys(%{$M->{$k}}))
	  {
	    if (!($l=~/ST::/))
	      {
		
		if ($fname){printf $F "$k;$l;%7.5f\n",$M->{$k}{$l};}
		else {printf "$k;$l;%7.5f\n",$M->{$k}{$l};}
	      }
	    
	  }
      }
    print "#### END\n";
    if ($fname) 
      {
	print STDERR "---- Dumped Model in file $fname\n";
	close ($F);
      }
    
    return;
  }

###################################################################
#SEQUENCE2MODEL
###################################################################
#USAGE: $M = &sequence2model ($S) 
#FUNCTION: Calculates the model given the set of sequences, it is 
#used because sequences are generated by a probabilistic model, so 
#at the end the fact that the sequences correspond to the model is
#a matter of luck. NO pseudo-accounts used
#ARGS: $S => A referenced hash with the serie of sequences of symbols
#            and its corresponding state. Sequences are indexed by $j
#            and each position of a sequence by $i 
#             $S -> {$j} {$i} {bin} = symbol
#             $S -> {$j} {$i} {RST} = state
#RETURNS: => A referenced hash with transition and emission probabilities
#             $M -> {'ST::A'} {'ST::B'} = prob (for state transitions)
#             $M -> {'ST::A'} {'SYMBOL X'} = prob (for emission probability of a symbol given a state)

sub sequence2model
      {
	my $S=shift;
	my $A={};
	my $E={};
	my $M={};
	
	#Counts number of transition between states $A -> {state A} {state B}
	#       times a symbol is emited in a given state $E -> {state A} {symbol X}
	foreach my $j (keys(%$S))
	  {
	    my $L=keys (%{$S->{$j}});
	    for (my $i=2; $i<=$L; $i++)
	      {
		my $s=$S->{$j}{$i}{bin};
		my $cstate=0; 
		my $pstate=0;
		my $cstate=$S->{$j}{$i}{viterbi};   
		my $pstate=$S->{$j}{$i-1}{viterbi};  
		$A->{$pstate}{$cstate}++;
		$E->{$cstate}{$s}++;
	      }
	  }

	foreach my $k (keys (%$A))
	  {
	    my $tot;
	    	  
	    $tot=0;
	    
	    #Total number of transitions (by adding counts of each transition)
	    foreach my $l (keys(%{$A->{$k}}))
	      {
		$tot+=$A->{$k}{$l};
	      }
	    
	    #Calculating transition probabilities
	    foreach my $l  (keys(%{$A->{$k}}))
	      {
		$M->{$k}{$l}=$A->{$k}{$l}/$tot;
	      }
	    
	    $tot=0;

	    #Total number of symbols emited (by adding counts of each symbol in each state)
	    foreach my $l (keys(%{$E->{$k}}))
	      {
		$tot+=$E->{$k}{$l};
	      }
	    
	    #Calculating emission probabilities
	    foreach my $l (keys(%{$E->{$k}}))
	      {
		$M->{$k}{$l}=$E->{$k}{$l}/$tot;
	      }
	  }

	#CORRECT THIS
	foreach my $k (keys(%$M))
	  {
	    $M->{$k}{"ST::END"}=1;
	    $M->{"ST::START"}{$k}=1;
	  }
	
	display_model($M);
	return model2modelL($M);
      }
	
sub log_divide 
  {
    my $x=shift;
    my $y=shift;
    
    if ($x==$LOG_ZERO || $y==$LOG_ZERO || $y==0){return $LOG_ZERO;}
    return $x-$y;
  }
sub log_multiply
  {
    my @l=@_;
    my $r;
    
    foreach my $v (@l)
      {
	if ($v==$LOG_ZERO){return $LOG_ZERO;}
	$r+=$v;
      }
    return $r;
  }
sub log_add 
  {
    my ($x,$y)=@_;
    
    
    if ($x==$LOG_ZERO){return $y;}
    elsif ($y==$LOG_ZERO){return $x;}
    elsif ($x>=$y)
      {
	return $x+log(1+exp($y-$x));
	$x=(($x==$LOG_ZERO) || ($y-$x)>=$LOG_UNDERFLOW)?$y:mylog($y-$x)+$x;
      }
    else{return log_add ($y,$x);}
  }

sub mylog
  {
   my $x=shift;
   if ( $x<$LOG_UNDERFLOW){return $LOG_ZERO;}
   else
     {
       return log($x);
       
      }
   if ($x <= 1.00) 
     {return ((-0.009350833524763 * $x + 0.130659527668286) * $x + 0.498799810682272) * $x + 0.693203116424741;}
   if ($x <= 2.50)
     {return ((-0.014532321752540 * $x + 0.139942324101744) * $x + 0.495635523139337) * $x + 0.692140569840976;}
   if ($x <= 4.50) 
     {return ((-0.004605031767994 * $x + 0.063427417320019) * $x + 0.695956496475118) * $x + 0.514272634594009;}
  
  return ((-0.000458661602210 * $x + 0.009695946122598) * $x + 0.930734667215156) * $x + 0.168037164329057;
} 
sub expLookup
  {
    my $x=shift;
    
   if ($x > -2)
     {
       if ($x > -0.5)
	 {
	   if ($x > 0){return exp($x);}
	   return (((0.03254409303190190000*$x + 0.16280432765779600000)*$x + 0.49929760485974900000)*$x + 0.99995149601363700000)*$x + 0.99999925508501600000;
	 }
       if ($x > -1){return (((0.01973899026052090000*$x + 0.13822379685007000000)*$x + 0.48056651562365000000)*$x + 0.99326940370383500000)*$x + 0.99906756856399500000;}
       return (((0.00940528203591384000*$x + 0.09414963667859410000)*$x + 0.40825793595877300000)*$x + 0.93933625499130400000)*$x + 0.98369508190545300000;
     }
   if ($x > -8)
     {
       if ($x > -4){return (((0.00217245711583303000*$x + 0.03484829428350620000)*$x + 0.22118199801337800000)*$x + 0.67049462206469500000)*$x + 0.83556950223398500000;}
       return (((0.00012398771025456900*$x + 0.00349155785951272000)*$x + 0.03727721426017900000)*$x + 0.17974997741536900000)*$x + 0.33249299994217400000;
     }
   if ($x > -16){return (((0.00000051741713416603*$x + 0.00002721456879608080)*$x + 0.00053418601865636800)*$x + 0.00464101989351936000)*$x + 0.01507447981459420000;}
   return 0;
 }
sub myexp
    {
      my $x=shift;
      if ( $x==$LOG_ZERO){return 0;}
      return exp($x);
    }
sub myexp2
  {
    return shift;
  }
sub array2hash

  {
    my $arrayR=shift;
    my $A=shift;
    my ($v, $k);
    my @array=@$arrayR;
    
    while (($k=shift(@array)))
      {
	my $v=shift (@array);
	$k=~s/-//g;
	$A->{$k}=$v;
      }
    return $A;
  }

sub string2hash 
  {
    my $s=shift;
    my $h=shift;
    my $sep = shift;
    
    #my @l=split (/\s+/, $s); 
    my @l = split (/$sep/, $s);
             
    shift @l;
    return array2hash (\@l, $h);
  }

sub sec2time
    {
      my $t=shift;
      my $minute=60;
      my $hour=60*$minute;
      my $day=24*$hour;
      my $week=7*$day;
      my $month=24*$day;
      my $year=12*$month;
      
      my ($y, $m, $w, $d, $h, $min, $l,$date, $min);
      
      $y=int($t/$year);
      $l=$t%$year;
      $t=$l;

      $m=int($t/$month);
      $l=$t%$month;
      $t=$l;

      $w=int($t/$week);
      $l=$t%$week;
      $t=$l;
      
      $d=int($t/$day);
      $l=$t%$day;
      $t=$l;

      $h=int($t/$hour);
      $l=$t%$hour;
      $t=$l;

      $min=int($t/$minute);
      $l=$t%$minute;
      $t=$l;

      if ($y){$date="$y year(s) ";}
      if ($m){$date.="$m month(s) ";}
      if ($w){$date.="$w week(s) ";}
      if ($d){$date.="$d days(s) ";}
      if ($h){$date.="$h hour(s) ";}
      if ($min){$date.="$min minute(s) ";}
      if ($t){$date.="$t second(s)";}
      return $date;
    }


sub data2R_header
      {
	my $d = shift;
	foreach my $c (sort ({$a<=>$b}keys(%$d)))
	  { 
	    foreach my $i (sort {$a<=>$b}keys (%{$d->{$c}}))
	      {
		my $first=0;
		
		foreach my $k (sort (keys (%{$d->{$c}{$i}})))
		  {
		    if ($first == 0) {print "$k"; $first=1;}
		    else {print "\t$k";}		     
		  }		
		print "\n";
		last;
	      }last;	    
	  }	
      }

sub data2R_records
	{
	  my $d = shift;
	  foreach my $c (sort ({$a<=>$b}keys(%$d)))
	  { 
	    foreach my $i (sort {$a<=>$b}keys (%{$d->{$c}}))
	      {
		my $first=0;
				foreach my $k (sort (keys (%{$d->{$c}{$i}})))
		  {
		    if ($first == 0) 
		      {
			print "$d->{$c}{$i}{$k}"; 
			$first=1;
		      }
		    else 
		      {
			print "\t$d->{$c}{$i}{$k}";
		      }		     
		  }		
		print "\n";
	      }	    
	  }
	}

#################################################################
#READ_MODEL
#################################################################
#USAGE: read_model ($file)
#FUNCTION: This function reads a HMM into a referenced hash $M
#ARGS: $file => Text plain file containning the model
#RETURNS: $M A referenced hash with transition and emission prob

sub read_model
	  {
	    my $file = shift;
	    my $M = {};
	    my $F=new FileHandle;
	    my $linen;
	    
	    open($F, $file) or die "Can't open $file\n";
	    
	     while (<$F>)
	       {
		 my $line = $_;
		 $linen++;

		 if ($line =~ /#a/)
		   {
		     my $A = {};
		     my $sep = ';';
		     chomp $line;
		     
		     $A = string2hash ($line, $A, $sep);
			
		     my $ST_1 = "ST::".$A->{State1};
		     my $ST_2 = "ST::".$A->{State2};
		     my $prob = $A->{Probability};
		    
		     $M->{$ST_1}{$ST_2} = $prob;		     		     		    		    
		   }

		 elsif ($line=~/#e/)
		   {
		     my $E = {};
		     my $sep = ';';
		     chomp $line;
		     
		     $E = string2hash ($line, $E, $sep);
			
		     my $ST_1 = "ST::".$E->{State};
		     my $bin = $E->{Bin};
		     my $prob = $E->{Probability};
		    
		     $M->{$ST_1}{$bin} = $prob; 		     	     		     		    		    
		   }
		     		   
		 else
		   {
		     print STDERR "Input model file:$file might be corrupted == line: $linen\n";
		     die;
		   }
	       }
	    close ($F);
	   
	    return($M);	    
	  }

#################################################################
#COLL
#################################################################
#USAGE: coll ($d, $A)
#FUNCTION: This function deals with collisions (ie time intervals
#of same cage that overlaps). Before data2overlap() which tags
#collisions and &filter_overlap() which filters given a threshold
#where always called
#POSSIBLE PARAMETERS:
# -coll -> it will add to hash with data 2 news keys: collision and 
#          delta, this way when we print the interval both of them 
#          will be printed.
# -coll out ->  data2overlap prints collisions
# -coll filter -> filter_overlap filter collisions (deprecated) they
#                 were filtered if the whole second interval its inside
#                 the first one
#ARGS: $d => Ref hash with intervals data
#RETURNS: $d => Same hash modified  	  

sub coll
	    {
	      my $d = shift;
	      my $A = shift;
	      #my $period = &data2period_list($d);
	      my ($out, $T);	      

	      if (exists($A->{out}))
		{
		  $out = 1;
		}
	      	      	      	       					       	       
	      $d = &data2overlap($d, $out);
	      
	      if (exists($A->{filter}))
		{	
	
		  if ($A->{filter} !=0)  
		    {
		      $T = $A->{filter};
		    }

		  else
		    {
		      $T = 1; #default value		    
		    }

		  $d = &filter_overlap ($d, $T);
		}
	      
	      return ($d);
	    }

#I have to test for each interval the file to know if its comming from 6 cage file or 12 cage file, very time consuming
#sub rename 
#	
#	{
#			my $d=shift;
#    		my $A=shift; 
#			my $renamed_H = {};
#			my $ncages;
#			
#			#$ncages= $d{$f}{'HEADER'}{'EHEADER'}{'Ncages'}; 
#			print STDERR "$ncages\n";die;
#			
#			#print Dumper ($A); #del
#	    	if ((exists ($A->{cages}) && $A->{cages} ne 0 && $A->{cages} ne "N" ))
#	    		{
#	    			#print STDERR "IWH\n";#del
#	    			
#	    			foreach my $c (sort(keys (%$d)))
#       					{
#	 						
#	 						foreach my $t (sort(keys (%{$d->{$c}})))
#	   							{
#	   								($d{$f}{'HEADER'}{'EHEADER'}{'Ncages'} == 6) && next;
#	   								$renamed_H->{$c+12}{$t} = $d->{$c}{$t};
#	   								$renamed_H->{$c+12}{$t}{'CAGE'} = $c+12;	     							
#	    						}
#       					}	    				    		
#	    		}
#	    	
#	    	return ($renamed_H);
#	    	#print STDERR "$switch_rename\n";die; #del 
#	}

sub data2BIT 
  {
    my $d=shift;
    my $A=shift;
    my $action = $A->{'action'};
    my $format = $A->{'format'};
    
    if (!$format) {$format="R";}
    
    if (!$action) {$action="annotate";}
        
    my $period = data2period_list ($d);
             
    foreach my $p (sort ({$a<=>$b}keys (%$period)))
      {	
#	     if ($A->{output} !~ /R/) 
#	       {
#	         print "-- $p--\n";
#	       }   	     
	
	     $A->{period}=$p;
	     $A->{name}="$p";
	     
	     $d = annotateBIT ($d, $A);#the function is called for each period
      }
    
    if ($action eq "annotate" )
      {
        return ($d);
      }
      
    elsif ($action eq "output")
      { 
        #Headers in R Format
        if ($A->{format}=~/R/) 
          {
	         print "period\tstartTime\tpEndTime\tcage\tchannel\tBIT\ttransition\n";
	         &BIT2print ($d);
	         die;	         
          }
    
        else
          {
            print STDERR "WARNING: Format \"$A->{format}\" is unknown, thus R table format used!\n";
          }
          
        die;
      }
      
    else 
      {
        print STDERR "FATAL ERROR: BIT (Between Interval Time) action --> $action unknown!!!";
        die; 
      }
  }
  
sub annotateBIT
  {
    my $d = shift;
    my $A = shift;
    my $action = $A->{'action'};    
    my $BIT = -1;
    my $transition = ""; 
             
    if (!$action) {$action="annotate";}
                  
    foreach my $c (sort ({$a<=>$b} keys (%$d)))
      { 
        
        my $pEndT = -1;
	    my $pKeyTime = -1;#We have to keep time to annotate the transition in the previous interval
	    my $pNature = "";
	    
	    foreach my $t (sort ({$a<=>$b} keys (%{$d->{$c}})))
	     {
    	    my $period = $d->{$c}{$t}{period};
    	    
    	    if ($period ne $A->{period}){next;}	    
	         
  	        my $StartT = $d->{$c}{$t}{'StartT'};
  	        my $EndT = $d->{$c}{$t}{'EndT'};
  	        my $channel = $d->{$c}{$t}{'Channel'};
  	        #my $nature = $d->{$c}{$t}{'Nature'}; 
  	        
  	        if (!exists ($d->{$c}{$t}{'bin'})) 
  	         {
  	           print STDERR "FATAL ERROR: bin not set transitions can not been annotated!!!\n";
  	           die;
  	         }   	       
  	        
  	        my $nature = $d->{$c}{$t}{'bin'};
  	         
  	        $d->{$c}{$t}{'BIT'} = 0;#by default we put something, if not last record remains unannotated
  	        $d->{$c}{$t}{'Transition'} = $nature."::lastRec";
  	        
  	        if ($pEndT != -1 || $pKeyTime != -1)
  		      {
  		        $BIT = $StartT - $pEndT;
  		        $transition = $pNature."::".$nature;
  		        #print "Period $period \t Cage --> $c \t Channel --> $channel \t Current end time--> $EndT \t Previous end time --> $pEndT \t BIT --> $BIT \t Transition --> $transition\n";    		      
  		        $d->{$c}{$pKeyTime}{'BIT'} = $BIT;
  		        $d->{$c}{$pKeyTime}{'Transition'} = $transition;            
  		      }
  		    
  		    else 
  		      {
  		        $BIT = 0;
  		      
  		        #print "Cage --> $c \t Channel --> $channel \t Current end time--> $EndT \t Previous end time --> $pEndT \t BIT --> $BIT\n";    		          		     
  		        $d->{$c}{$t}{'BIT'} = $BIT;    		      
  		      }
  		    
  		   $pEndT = $EndT;
  		   $pKeyTime = $t;
  		   $pNature = $nature;    		       		   		   		    
	     }
      }
   
    return ($d);  
         
  }

sub BIT2print
  {
   my $d = shift;
    
   foreach my $c (sort ({$a<=>$b} keys (%$d)))
      {
        my $pEndT = -1;
        	    
	    foreach my $t (sort ({$a<=>$b} keys (%{$d->{$c}})))
	     {
	       my $period = $d->{$c}{$t}{'period'};
	       my $StartT = $d->{$c}{$t}{'StartT'};
  	       my $EndT = $d->{$c}{$t}{'EndT'};
  	       my $channel = $d->{$c}{$t}{'Channel'};
  	       #my $nature = $d->{$c}{$t}{'Nature'};
  	       my $BIT = $d->{$c}{$t}{'BIT'};
  	       my $transition = $d->{$c}{$t}{'Transition'};
  	       
  	       if (!defined ($BIT)) {$BIT = "0"};
  	       if (!defined ($transition)) {$transition = "LastRec"};
  	       
	       print "$period\t$StartT\t$pEndT\t$c\t$channel\t$BIT\t$transition\n";
	       $pEndT = $EndT;
	     }
	     
      }
    
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
                      return ("food_sc");#Original before fusedSCforFDF heatMap
                      #return ("food"); #fusedSCforFDF heatMap
                                                
                      last SWITCH;
                    };
                      
                  ($annot eq "f") && do 
                    { 
                      return ("food_fat");
                      #return ("food");                                              
                      last SWITCH;
                    };
                    
                  ($annot eq "c") && do 
                    { 
                      return ("food_cd");#Original before fusedSCforFDF heatMap
                      #return ("food");#fusedSCforFDF heatMap                           
                      last SWITCH;
                    };  
                }
         
         print STDERR "FATAL ERROR: ANNOTATION PROVIDED $annot DOES NOT CORRESPOND WITH ANY OF THE VALID ANNOTATIONS\n";
         print STDERR "             ASK FOR THE INCLUSSION OF THIS ANNOTATION\n";
         die;
		
	}