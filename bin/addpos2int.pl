#!/usr/bin/env perl

##############################################################################################
### Jose A Espinosa. CB-CRG Group.                                       Jan 2011          ###
##############################################################################################
###  addpos2int.pl                                                                         ###
##############################################################################################
### Script to gather positions coming from pos files (result from processing ACTI-TRACK    ###
### output with act2pos.pl The output of this script will be a new int file containing for ###
### each interval the mean X and Y position                                                ###
###                                                                                        ###
###OPTIONS                                                                                 ###
### -add pos mean -> add to each interval from int file the mean position X and Y          ###
###      pos all -> add to data coming from pos file the position given the (X,Y)          ###  
###	     channel pos -> Using mean position to set the channel                             ###
### -filter                                                                                ### 
### -out outdata filename-> print intervals, if outdata is used results will be given in   ###
###                         a file called "filename", if only -out is used results will    ###
###                         be shown in standard output                                    ###   		
###      data pos -> print only pos resulting file (by default int file is printed)        ###
### 			                                                                           ### 
##############################################################################################

#use warnings;
use strict;

###Modules used
use FileHandle;
use HTTP::Date; #CPAN str2time()=> time conversion function different time format --> machine time (seconds since EPOCH)
use Data::Dumper;
use File::stat; #Dealing with file metadata

my $A={};
my ($d_int, $d_pos) = {};
my %WEIGHT;
my $HEADER;
my $cl=join(" ", @ARGV);
my @commands=split (/\-+/,$cl);
shift @commands;
#my @files = split (" ", shift @commands);

######IDEAS SCHEME
#1-USE A SYSTEM AS T_COFFEE "addpos2int.pl -int file.int -pos file.pos"
#2-READ HEADERS OF BOTH FILES
#3-COMPARE THAT THE FILES USED FOR THE GENERATION OF BOTH FILES (int and pos) ARE THE SAME
#  WHEN PANLAB SOFTWARE MAKE THE ADQUISITION IT NAMES THE SAME BOTH FILES WITH DIFFERENT EXTENSION
 
foreach my $c (@commands)
  {    
    #&run_instruction (\@files, $A, $c);
    &run_instruction ($A, $c);    
  }

die;

###################
#FUNCTIONS
##########

sub run_instruction
  	{
    	#my $ary_files=shift;
	    my $A=shift;#now is empty
	    my $c=shift;    
	    
	    $A=string2hash ($c,$A);
	              
	    #reading int file
	    if ($c =~ /^int/)
	      	{	
	      		#print STDERR "$A->{int}\n";#del
				$d_int = &int2data ($A->{int});
	      	}
	     
	     #reading pos file
	     elsif ($c =~ /^pos/)
	     	{
	     		#print STDERR "$A->{pos}\n";#del
	     		$d_pos = &pos2data ($A->{pos});
	     	}	     		   
	    
	    #adding positions
	    elsif ($c =~ /^add/)
	    	{	
	    		($d_int, $d_pos) = &add ($d_int, $d_pos, $A);	    		
	    	}
	    
	    elsif ($c =~ /^filter/)
	    	{
	    		$d_int = &filterChannelZone ($d_int, $A);
	    	}
	   	
	   	elsif ($c =~ /^out/)
	   		{
	   			#&display_data ($d_int, $A);
	   			&display_data ($d_pos, $A);
	   			#print Dumper ($d_int);#del
	    		#print Dumper ($d_pos);#del
			}
    
	}
  
  sub string2hash #modified respect to the generic one 
  	{
      my $s=shift;
      my $h=shift;
      my @l=split (/\s+/, $s);
      
      if ($l[0] eq "int" | $l[0] eq "pos")
        {
    	   return array2hash (\@l, $h);
        }
      
      else
      	{
      		shift @l;	
      	} 
      #shift @l;
      return array2hash (\@l, $h);
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
  
#################################################################
#int2data
#################################################################
#USAGE: int2data ($file)
#FUNCTION: This function gets information from int file in a Hash
#POSSIBLE PARAMETERS: NA
#ARGS: $file => *.int file
#RETURNS: $d_int => Hash containing the info of the file 

sub int2data
	{
 		my $f = shift;
 		#my $d = {};
 		
 		return (&parse_data ($f)); 		 	
	}

sub pos2data
	{
		my $f = shift;
 		my $data = {};
 		
 		my $file_mod_date = time2str(stat($f)->mtime); #test file del
 		
 		
 		print STDERR "file: $f last modification time is $file_mod_date\n"; die;#test file del
 		my $F=new FileHandle;
    	my $linen;
    	
    	open($F, $f);
    
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
							
#					    $L->{linen}=$linen;
#					    $L->{period}="1";
#			    	    
#			    		if ($L->{Duration}!=0)
#			      			{
#			    				$L->{Velocity}=$L->{Value}/$L->{Duration};
#			      			}
#			    		else
#			      			{
#			    				$L->{Velocity}=0; 
#			      			}	   

	    				if ($L->{Type})
	      					{
								my $c=$L->{CAGE};
#								my $ch=$L->{Channel};#This info is not present
								my $t=$L->{Time};#Review if it doesn't work #del
		
								foreach my $k (keys(%$L))
								  	{
								    	$data->{$c}{$t}{$k}=$L->{$k};
								  	}
	      					}
	  				}
				else
	  		    	{
#	    				if ( $line=~/Weight/ && $line=~/ANIMALS DATA/)
#							{
#								$line=~/.*;(\d+);Weight;([.\d]+)/;
#								my $c=$1;
#								my $w=$2;
#								
#								if (!$WEIGHT{$c}{start})
#							  		{
#							  			$WEIGHT{$c}{start}=$w;
#							  		}
#								
#								else 
#									{
#										$WEIGHT{$c}{end}=$w;
#									}
#								
#								$WEIGHT{$c}{max}=($WEIGHT{$c}{max}<$w)?$w:$WEIGHT{$c}{max};
#		      				}
		      
	    				$HEADER.=$line;
	  				}
      		}
    
#    foreach my $c (keys (%WEIGHT))
#      {
#	if ($WEIGHT{$c}{start}){	$WEIGHT{$c}{delta}=(($WEIGHT{$c}{end}-$WEIGHT{$c}{start})*100)/$WEIGHT{$c}{start};}
#      }
#    
#    #reformat/annotate fields fields
#    $data=&channel2correct_channel ($data);
#           
#    $data=&channel2Nature($data);
         
    return $data;
 		
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
				
				$WEIGHT{$c}{max}=($WEIGHT{$c}{max}<$w)? $w : $WEIGHT{$c}{max};
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
		
		if ($Caption=~/Food/){$Nature="food";}
		else {$Nature="drink";}
		
		$Name=lc ($Name);
		$Name=~s/\s//g;
		
		
		
		if ($Nature eq "food")
		  {
		    # print "--$Name--\n";
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

	     
sub add 
	{
		my $d_int = shift;
     	my $d_pos = shift;
     	my $A = shift;
     	my $pos = $A->{pos};
     	my $channel = $A->{channel};
     	
     	if (!$pos || $pos eq "mean")
     		{
     			$d_int = &mean_pos2int ($d_int, $d_pos);     			
     		}
     		
     	elsif ($pos eq "all")
     		{
     			print STDERR "IWH -- pos eq all";
     			$d_pos = &all_pos2pos ($d_pos);
     		}
     	
     	if (!$channel || $channel eq "pos")
     		{
     			print STDERR "IWH2 -- channel eq pos";
     			$d_int = &ChannelFromPos2int ($d_int, $d_pos);     			
     		}
     		
     	return ($d_int, $d_pos);
	}
	
sub mean_pos2int
	
	{
		my $d_int = shift;
     	my $d_pos = shift;
     	my ($t, $j, $x, $y) = "";     	
     	
     	foreach my $cage (sort(keys (%$d_int)))
       		{
	 			foreach my $time (sort(keys (%{$d_int->{$cage}})))
	   				{
	   					my $StartT = $d_int->{$cage}{$time}{'StartT'};
	   					my $EndT = $d_int->{$cage}{$time}{'EndT'};
	   					
	   					$j= 0;
	   					($x, $y) = 0;
	   					
	   					for ($t = $StartT; $t <= $EndT  ;$t++)
	   						{
	   							$x += $d_pos->{$cage}{$t}{'XPos'};
	   							$y += $d_pos->{$cage}{$t}{'YPos'};
	   								   								   							
	   							#print STDERR "$d_pos->{$cage}{$t}{'XPos'}\n"; #del
	   							$j++;
	   						}
	   					#print STDERR "============= TOTALS =====================\n"; #IMPORTANT SHOW RESULTS TO CEDRIC
	   					#print STDERR "$cage\t$StartT\t$EndT\t";#del
	   					#print STDERR "$x\t"; #del
	   					
	   					$d_int->{$cage}{$time}{'MeanX'} = $x / $j;
	   					$d_int->{$cage}{$time}{'MeanY'} =  $y / $j;
	   					
	   					#print STDERR "$j\t$d_int->{$cage}{$time}{'MeanX'}$j\n";#del
	   					
	   					#my $mean = get_mean ($d_pos, $StartT, $EndT);#del
	   					
	   				}
       		}
     	
     	return ($d_int);    
	}

#sub get_mean  #del
#	
#	{
#		my $d_pos = shift;
#		my $StartT = shift;
#		my $EndT = shift;
#		
#		
#	}

sub display_data #As in int2combo!!!
  	{
    	my $d=shift;
    	#my $file=shift;
    	my $file=$A->{outdata};
    	my $F= new FileHandle;

    	if (!$file)
    		{
    			open ($F, ">-");
    		}
    	
    	else 
    		{
    			open ($F, ">$file");
    		}

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
	
sub ChannelFromPos2int

	{
		my $d_int = shift;
		my $d_pos = shift;
		my ($x, $y, $x_max, $y_max, $z) = "";
		my $zones = {};		
		#die;
		
			       	
		$zones = &setCageBoundaries ($d_pos);
					
		#&setCageBoundaries ($zones);#del
		print STDERR Dumper ($zones);#del
						
		foreach my $cage (sort(keys (%$d_int)))
       		{	       			
       			 			
	 			foreach my $time (sort(keys (%{$d_int->{$cage}})))
	   				{
	   					
	   					$x = $d_int->{$cage}{$time}{'MeanX'};
	   					$y = $d_int->{$cage}{$time}{'MeanY'};
	   					###if exist the time important correction !!!!!!!!!!!!
						
						$z = &ChannelFromPos ($x, $y, $cage, $zones);
	   						   					
	   					$d_int->{$cage}{$time}{'Zone'} = $z; 
	   				}
       		}
		
		return ($d_int);
	} 

sub ChannelFromPos
	{
		my $x = shift;
		my $y = shift;
		my $c = shift;
		my $z = shift;		
 		my ($channel, $xm, $x1, $x2, $x3, $ym, $y1) = "";
		
		print STDERR "CAGE ----> $c \n";
		
		$xm = $z->{$c}{'Xm'}; print STDERR "xm $xm\n"; 
		$x1 = $z->{$c}{'X1'}; print STDERR "x1 $x1\n";				
		$x2 = $z->{$c}{'X2'}; print STDERR "x2 $x2\n";		
		$ym = $z->{$c}{'Ym'}; print STDERR "ym $ym\n";
		$y1 = $z->{$c}{'Y1'}; print STDERR "y1 $y1\n";
		
		SWITCH: 
	    	{
	      		($x<0 || $y<0  ) && do 
					{
		  				$channel = "Negative"; 
		 	 			last SWITCH;
					};
					
				($x>$xm || $y>$ym) && do
					{
		  				$channel = "Out"; 
		 	 			last SWITCH;
					};
				 
				($x<=$x1 && $y>$y1) && do 
					{
		  				#$channel = "Zone 1";
		  				$channel = "Intake 1"; 
		 	 			last SWITCH;
					};
					
				($x<=$x1 && $y<=$y1) && do 
					{
		  				#$channel = "Zone 2";
		  				$channel = "Intake 2"; 
		 	 			last SWITCH;
					};
								
				(($x>$x1 && $x<$x2))  && do 
					{
		  				$channel = "Center"; 
		 	 			last SWITCH;
					};
					
				($x =>$x2 && $y>$y1) && do 
					{
		  				#$channel = "Zone 3";
		  				$channel = "Intake 3"; 
		 	 			last SWITCH;
					};
				
				($x =>$x2 && $y<=$y1) && do 
					{
		  				#$channel = "Zone 4";
		  				$channel = "Intake 4"; 
		 	 			last SWITCH;
					};
	    	}
	    	
	    return ($channel);
	}	    	

#		if ($x <0 || $y <0)
#			{
#				$channel = "Negative";
#				return ($channel);
#			}	
#		
#		elsif ($x>16.4 || $y>9.8)	
#			{
#				$channel = "Out";
#				return ($channel);
#			}
#		
#		elsif ()	
				
sub data2R_header#AS in int2combo!!!
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

sub data2R_records#AS in int2combo!!!
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
	
sub max
	{
		my $n = shift;
		my $max = shift;
		
		return (($n>$max)? $n:$max);	
	}

#Description of cage coordinates
#
# 									        Y
# X     0        X1           X2       Xm   0   
#       --------------------------------
#		- zone2	 -   center	  - zone4  -    
#		-	     -			  -        -
#		--------------------------------   Y1
#		- zone1  -	 center	  - zone3  -
#		-	     -			  -        -
#		--------------------------------   Ym

sub setCageBoundaries 
	{
		my $d_pos = shift;
		#my ($max_x, $max_y) = "";
		my $z = {};
		
		foreach my $cage (sort(keys (%$d_pos)))
       		{	
       			my($x_max, $y_max) = "";
       						
	 			foreach my $time (sort(keys (%{$d_pos->{$cage}})))
	   				{	
	   					#print STDERR "$d_pos->{$cage}{$time}{'XPos'}\n";
						$x_max = &max($d_pos->{$cage}{$time}{'XPos'}, $x_max);
						$y_max = &max($d_pos->{$cage}{$time}{'YPos'}, $y_max);
	   				}
	   				   				   			
	   			#print STDERR "In cage $cage\t";
	   			#print STDERR "maxim x is $x_max\t";
	   			#print STDERR "maxim y is $y_max\n";
	   			
	   			$z->{$cage}{'Xm'} = $x_max;
	   			$z->{$cage}{'Ym'} = $y_max;
	   			$z->{$cage}{'X1'} = 0.25 * $x_max;
				$z->{$cage}{'X2'} = 0.75 * $x_max;				
				$z->{$cage}{'Y1'} = 0.5 * $y_max;
	   				   				   				   				
       		}
#		foreach my $cage (sort(keys (%$z)))
#			{
#				#print STDERR "$cage-----$z->{$cage}{'Xm'}\n";#del
#				#print STDERR "$cage-----$z->{$cage}{'Ym'}\n";#del
#				$max_x = $z->{$cage}{'Xm'};
#				$max_y = $z->{$cage}{'Ym'};
#				
#			}	
		
		return ($z)
	}
	
sub filterChannelZone
	{
		my $h = shift;		
		my ($ctr, $n) = 0;
		
		foreach my $c (sort(keys (%$h)))
       		{	       			       			 		
	 			foreach my $t (sort(keys (%{$h->{$c}})))
					{	
						$n++;
						
						if    (exists ($h->{$c}{$t}{'Zone'}) && $h->{$c}{$t}{'Zone'} ne $h->{$c}{$t}{'Channel'} )
							{
								delete($h->{$c}{$t}); 
								$ctr++;
							}   
					}
       		}
       	
       	print STDERR "\nFiltering: Removed $ctr values out of $n ---- Position in pos file different to channel in int file!!!\n";
        return ($h);
	}
	
sub all_pos2pos
	{
		my $d_pos = shift;
		my $z = {};
		my $zone = "";
		
		$z = &setCageBoundaries ($d_pos);
		
		foreach my $cage (sort(keys (%$d_pos)))
       		{	
       			      						
	 			foreach my $t (sort(keys (%{$d_pos->{$cage}})))
	   				{
	 					$zone = &ChannelFromPos ($d_pos->{$cage}{$t}{'XPos'}, $d_pos->{$cage}{$t}{'YPos'}, $cage, $z);
	 					$d_pos->{$cage}{$t}{'Zone'} = $zone;   						
	   				}
       		}
		
		return ($d_pos);
		
	}