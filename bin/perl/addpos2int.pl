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
###Order matters!!!                                                                        ###
### -int <file> -> flag for input intervals file (*.int)                                   ###
### -shift add integer -> shift time of position file, by the integer specified (+ or -)   ### 
###                trying to fit both time stamps                                          ###
### -shift mult decimal ->trying to fit both time stamps                                   ###
### -pos <file> -> flag for input position file (*.pos)                                    ###
### -bigPos <file> -> flag for input position file (*.pos), using this option only         ###
###                   positions which are included in intervals files are read, thus this  ###
###                   has dependency to -int option.                                       ###
### -add pos mean -> add to each interval from int file the mean position X and Y          ###
###      pos vector -> add to each interval from int file the vector with the position     ###
###                    counts positions for each second of this interval                   ###
###      pos all -> add to data coming from pos file the position given the (X,Y)          ###
###                 this way it is possible to visualize each zone for pos file            ###    
### -set channel pos -> set the channel using the mean position                            ###    
###      channel vector -> set the channel using the information carried in vector         ###
### -filter                                                                                ### 
### -out outdata filename-> print intervals, if outdata is used results will be given in   ###
###                         a file called "filename", if only -out is used results will    ###
###                         be shown in standard output                                    ###       
###      print pos -> print only pos resulting file (by default int file is printed)       ###
###                                                                                        ### 
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
my $shift_time = {};
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
          $d_int = &int2data ($A->{int});
          print STDERR "--------------- int file read! ---------------\n\n";
        }
      
      #shifting position timestamp
      elsif ($c =~ /^shift/)
        {  
          $shift_time = &shiftTimestamp ($A); 
        }      
          
      #reading pos file
      #This option remains in case we want to reprint the whole pos file
      elsif ($c =~ /^pos/)
        {
          $d_pos = &pos2data ($A->{pos}, $shift_time, $d_int);
          print STDERR "--------------- pos file read! ---------------\n\n";                                   
        }              
      
      #reading big pos files, only keeping positions which are inside food intervals 
      elsif ($c =~ /^bigPos/)
        {
          $d_pos = &bigPos2data ($A->{bigPos}, $shift_time, $d_int);
          print STDERR "--------------- pos file read! ---------------\n\n";                      
        }              
            
      #adding positions to interval type record
      elsif ($c =~ /^add/)
        {  
          ($d_int, $d_pos) = &add ($d_int, $d_pos, $A);               
        }
        
      elsif ($c =~ /^set/)
        {
          $d_int = &set ($d_int, $d_pos, $A);
        }
      
      elsif ($c =~ /^filter/)
        {
          $d_int = &filterChannelZone ($d_int, $A);
        }
       
       elsif ($c =~ /^out/)
         {
           if ($A->{print} eq "pos")
             { 
               &display_data ($d_pos, $A);
             }
           
           else
             {           
               &display_data ($d_int, $A);               
             }
      }
    
  }
  
  sub string2hash #modified respect to the generic one 
    {
      my $s=shift;
      my $h=shift;
      my @l=split (/\s+/, $s);
      
      if ($l[0] eq "int" | $l[0] eq "pos" | $l[0] eq "bigPos")
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
    my $shift_time = shift;    
    my $data = {};
    my $switch = 0;
    my $start_time = 0;
    my $intFile = "";     
    #geting last modification time
    #@y $file_mod_date = time2str(stat($f)->mtime); #test to see if I get modification time file del
    #print STDERR "file: $f last modification time is $file_mod_date\n"; die;#test file del
     
    my $F=new FileHandle;
    my $linen;        
    
    if (!-e "$f")
      {
        print STDERR "FATAL ERROR: Can't open file: $f! Make sure that file exists!\n\n";
        die;
      }
              
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
            shift @v;           #get rid of the line header(i.e.#d) 
            while (@v) 
              {
                my $key=shift @v;
                my $value= shift @v;
                $L->{$key}=$value;
              }
            
            if (!$switch) 
              {
                $start_time = $L->{Time};                
                $switch=1; 
              }
            
            if ($L->{Type})
              {
                my $c=$L->{CAGE};               
                my $t=$L->{Time};
                my $new_t = 0;
                
                if (exists ($shift_time->{"add"}))                       
                  {                    
                    $new_t = $t + $shift_time->{"add"};                       
                  }  
                
                elsif (exists($shift_time->{"mult"}))
                  {  
                    my $value = $shift_time->{"mult"};
                    my $delta = $t-$start_time;
                    #print STDERR "$value----$delta\n";#del
                    $new_t = int ($t + ($t-$start_time) * $shift_time->{"mult"});
                    #print STDERR "time --> $t\tnew_time --> $new_t\n";#del                              
                  }
                
                else 
                  {
                    $new_t = $t; 
                  } 
                                      
                foreach my $k (keys(%$L))
                  {                                                         
                    #Time in k is changed in index ($data->{$c}{$new_t}), but if we print the pos file it will retrieve time from 
                    #$data->{$c}{$new_t}{$k} = $L->{$k}, meaning that the time use as key and the time keep as value will not be
                    #the same, so we have to change this time too.
                    if ($k eq "Time") 
                      {
                        $data->{$c}{$new_t}{$k} = $new_t;
                      }
                        
                    else
                      {                          
                        $data->{$c}{$new_t}{$k} = $L->{$k};
                      }                      
                  }
              }
          }
        
        else
          {           
            $HEADER.=$line;
          }
      }
    
     return ($data);
         
  }

sub bigPos2data
  {
    my $f = shift;
    my $shift_time = shift;
    my $H_int= shift;    
    my $data = {};
    my $dataOut = {};
    my $switch = 0;
    my $start_time = 0;
    my $intCage = ""; 
    my $firstScan = 1;    
     
    my $F=new FileHandle;
    my $linen;        
    
    if (!-e "$f")
      {
        print STDERR "FATAL ERROR: Can't open file: $f! Make sure that file exists!\n\n";
        die;
      }
      
    if (!keys %$H_int)
      {
        print STDERR ("WARNING: \"-bigPos\" option needs a loaded int file, please load it using \"-int\" option\n");
        die;
      }
      
    foreach $intCage (sort(keys (%$H_int)))#del
      {
        my $cagePat = "CAGE;".$intCage.";";
        
        open($F, $f);
        
        while (<$F>)
          {
            my $line=$_;
            $linen++;
             
            if ($line=~/#d/ && $line=~/$cagePat/)
              {                
                my $L={};
                chomp $line;
                my @v=split (/;/,$line);
                shift @v;#get rid of the line header(i.e.#d) 
                while (@v) 
                  {
                    my $key=shift @v;
                    my $value= shift @v;
                    $L->{$key}=$value;
                  }
                
                if (!$switch) 
                  {
                    $start_time = $L->{Time};                
                    $switch=1; 
                  }
                
                if ($L->{Type})
                  {
                    my $c=$L->{CAGE};               
                    my $t=$L->{Time};
                    my $new_t = 0;
                    
                    if (exists ($shift_time->{"add"}))                       
                      {                    
                        $new_t = $t + $shift_time->{"add"};                       
                      }  
                    
                    elsif (exists($shift_time->{"mult"}))
                      {  
                        my $value = $shift_time->{"mult"};
                        my $delta = $t-$start_time;
                        
                        $new_t = int ($t + ($t-$start_time) * $shift_time->{"mult"});                                              
                      }
                    
                    else 
                      {
                        $new_t = $t; 
                      } 
                                          
                    foreach my $k (keys(%$L))
                      {                                                         
                        #Time in k is changed in index ($data->{$c}{$new_t}), but if we print the pos file it will retrieve time from 
                        #$data->{$c}{$new_t}{$k} = $L->{$k}, meaning that the time use as key and the time keep as value will not be
                        #the same, so we have to change this time too.
                        if ($k eq "Time") 
                          {
                            $data->{$c}{$new_t}{$k} = $new_t;
                          }
                            
                        else
                          {                          
                            $data->{$c}{$new_t}{$k} = $L->{$k};
                          }                      
                      }                      
                  }
                  
              }
            
            elsif ($line=~/#h/ && $firstScan)
              {           
                $HEADER.=$line;
                
              }
            
            else
              {
                next;
              }
          }
          
          #print Dumper ($data);
          
          $dataOut->{$intCage} = &filterPos_by_Int ($H_int->{$intCage}, $data->{$intCage}, $intCage);
          $firstScan = 0;
          close ($F);
        }               
        
     return ($dataOut);
         
  } 

sub filterPos_by_Int
  {
    my $H_int = shift;
    my $H_pos = shift;
    my $c = shift;
    
    my ($t, $startT, $endT, $i, $H_posOut);
    print Dumper ($H_int);
            
    foreach $t (sort({$a<=>$b} keys (%$H_int)))
      {
        $startT = $H_int->{$t}{'StartT'};
        $endT = $H_int->{$t}{'EndT'};        
        
        for ($i=$startT; $i<=$endT; $i++)
          {
            print STDERR "---------->$i\n";#del
            
            if (exists ($H_pos->{$i}))
              {
                $H_posOut->{$i} = $H_pos->{$i};
              }
            
            else 
              {                
                my $f = $H_pos->{$i}{'File'};
                print STDERR "WARNING: Position at time point $i, cage $c is not set inside position file $f or if \"shift option\" used is not available after shifting\n";
              }
          }        
      } 
    
    return ($H_posOut);     
  }

sub parse_data
  {
    my $file=shift;
    my $data={};
    
    my $F=new FileHandle;
    my $linen;
    
    if (!-e "$file")
      {
        print STDERR "FATAL ERROR: Can't open file: $file! Make sure that file exists!\n\n";
        die;
      }
      
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
        if ($WEIGHT{$c}{start}){  $WEIGHT{$c}{delta}=(($WEIGHT{$c}{end}-$WEIGHT{$c}{start})*100)/$WEIGHT{$c}{start};}
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
    
    elsif ($pos eq "vector")
      {
        $d_int = &vector_pos2int ($d_int, $d_pos);
      }
         
    elsif ($pos eq "all")
      {
        #print STDERR "IWH -- pos eq all";del
        $d_pos = &all_pos2pos ($d_pos);
      }
       
#       if (!$channel || $channel eq "pos")
#         {
#           print STDERR "IWH2 -- channel eq pos";#del
#           $d_int = &ChannelFromPos2int ($d_int, $d_pos);           
#         }
         
    return ($d_int, $d_pos);
  }

sub set 
  
  {
    my $d_int = shift;
    my $d_pos = shift;
    
    my $A = shift;
    my $ch = $A->{channel};
    
    if (!$ch || $ch eq "pos")
      {
        $d_int = &setChannelFromPos ($d_int, $d_pos);           
      }
       
    elsif ($ch eq "vector")
      {           
        $d_int = &setChannelFromVector ($d_int);
      }
       
    return ($d_int);
         
  }
  
sub mean_pos2int
  
  {
    my $d_int = shift;
    my $d_pos = shift;
    my ($t, $j, $x, $y, $x_std, $y_std,  $p_zone, $i1, $i2, $i3, $i4, $pEndT, $pCage, $inter_zone, $interTime) = ""; 
    my ($Match, $missMatch, $ratio) = 0;      
    my $z = {};
    
    $z = &setCageBoundaries ($d_pos);  
       
    foreach my $cage (sort(keys (%$d_int)))
      {
        foreach my $time (sort(keys (%{$d_int->{$cage}})))
          {
            my $StartT = $d_int->{$cage}{$time}{'StartT'};
            my $EndT = $d_int->{$cage}{$time}{'EndT'};
            
            #my $StartL = $d_int->{$cage}{$time}{'StartL'}-48;#ojo solo para archivos con una sola jaula
            #my $EndL = $d_int->{$cage}{$time}{'EndL'}-48;#ojo solo para archivos con una sola jaula
               ###############136 for 12 cages
               
            #Printing inter-interval positions                          
            if ($pCage eq $cage)
              {  
                #print STDERR "Inter-Internal POSITIONS:\n";                   
                #&printInterPos ($d_int, $pEndT, $StartT, $cage);                                                                                             
                #print STDERR "Inter-Interval ends at :\n\n";               
              }
                                                                  
            ($j, $x, $y, $p_zone, $x_std, $y_std, $i1, $i2, $i3, $i4) = 0;
               
            my (@X_values, @Y_values);
            
            if ($EndT-$StartT > 10) {$EndT = $EndT-10}###time minus ten, maybe the average then is better, the condition is set to avoid n/0)
            
            ###SHIFT_faster_version commented
            #my $start_min = int($StartL/60);
            #my $start_sec = $StartL%60;  
            #print STDERR "Interval starting at $StartT\tline;$StartL\tnumber;$index\ttime;$start_min:$start_sec\n";  
            ###SHIFT_faster_version commented-end                     
                              
            for ($t = $StartT; $t <= $EndT  ;$t++)
              {
                $x += $d_pos->{$cage}{$t}{'XPos'};
                $y += $d_pos->{$cage}{$t}{'YPos'};
                
                #$p_zone =  &ChannelFromPos_modified($d_pos->{$cage}{$t}{'XPos'}, $d_pos->{$cage}{$t}{'YPos'});       
                $p_zone =  &ChannelFromPos ($d_pos->{$cage}{$t}{'XPos'}, $d_pos->{$cage}{$t}{'YPos'}, $cage, $z);
                
              SWITCH: 
                {
                  ($p_zone eq "Intake 1") && do 
                    { 
                      $i1++;
                      last SWITCH;
                    };
                    
                  ($p_zone eq "Intake 2") && do 
                    { 
                      $i2++;                          
                      last SWITCH;
                    };
                      
                  ($p_zone eq "Intake 3") && do 
                    { 
                      $i3++;                          
                      last SWITCH;
                    };
                    
                  ($p_zone eq "Intake 4") && do 
                    { 
                      $i4++;                          
                      last SWITCH;
                    };  
                }
                                                          
                push (@X_values, $d_pos->{$cage}{$t}{'XPos'});
                push (@Y_values, $d_pos->{$cage}{$t}{'YPos'});
                
                #SHIFT_faster_version commented                               
                #print STDERR "$d_pos->{$cage}{$t}{'XPos'}\t$d_pos->{$cage}{$t}{'YPos'}\t$p_zone\n"; #del
                $j++;
              }
            #SHIFT_faster_version commented
            #print STDERR "Interval ending at $EndT\n\n";
            #SHIFT_faster_version commented end
               
            #print STDERR "============= TOTALS =====================\n"; #IMPORTANT SHOW RESULTS TO CEDRIC
            #print STDERR "$cage\t$StartT\t$EndT\t";#del
            #print STDERR "$x\t"; #del
            
            $d_int->{$cage}{$time}{'MeanX'} = $x / $j;
            $d_int->{$cage}{$time}{'MeanY'} =  $y / $j;
               
            #printf "$c:   %12s => %5.2f\n",$d->{$c}{$t}{Nature}, $d->{$c}{$t}{Value};
            #print STDERR "$j\t$d_int->{$cage}{$time}{'MeanX'}\t$d_int->{$cage}{$time}{'MeanY'}, ($i1, $i2, $i3, $i4)\n";#del
            
               
            #St Deviation X
            #print STDERR Dumper ($d_int->{$cage}{$time}{'MeanX'}, @X_values, $j); 
            $x_std = &data2std ($d_int->{$cage}{$time}{'MeanX'}, \@X_values);
            $y_std = &data2std ($d_int->{$cage}{$time}{'MeanY'}, \@Y_values);
                                         
            #my $zone = &ChannelFromPos_modified($d_int->{$cage}{$time}{'MeanX'}, $d_int->{$cage}{$time}{'MeanY'});
            my $zone = &ChannelFromPos ($d_int->{$cage}{$time}{'MeanX'}, $d_int->{$cage}{$time}{'MeanY'}, $cage, $z);
               
               
            #SHIFT_faster_version commented
            #print STDERR "CAGE;$cage;MTB_assigned_zone;$d_int->{$cage}{$time}{'Channel'};";
            #printf STDERR "n;$j;x;%2.2f;y;%2.2f;std_x;%2.2f;std_y;%2.2f;",
            #SHIFT_faster_version commented-end
            
            #vector;%2d;%2d;%2d;%2d;",
            $d_int->{$cage}{$time}{'MeanX'},$d_int->{$cage}{$time}{'MeanY'},$x_std,$y_std;#$i1,$i2,$i3,$i4;                                           
               
            if ($i1 eq "") {$i1 = 0;}
            if ($i2 eq "") {$i2 = 0;}
            if ($i3 eq "") {$i3 = 0;}
            if ($i4 eq "") {$i4 = 0;}
            
            #SHIFT_faster_version commented
            #print STDERR "VECTOR;$i1;$i2;$i3;$i4;resulting_zone;$zone;File;$d_int->{$cage}{$time}{'File'}\n";                            
               
            if ($d_int->{$cage}{$time}{'Channel'} eq $zone){print STDERR "Match: Y\n\n";}
            else {print STDERR "Match: N\n\n";}
            #SHIFT_faster_version commented-end
            
            #if ($d_int->{$cage}{$time}{'Channel'} eq $zone){$Match++;}
            #else {$missMatch++;}
            
            #my $mean = get_mean ($d_pos, $StartT, $EndT);#del                                           
            
            $pEndT = $EndT;
            $pCage = $cage;
          }
             
      }
       
    #$ratio = $Match/$missMatch;
      
    print "$A->{'int'}\t$Match\t$missMatch\t$ratio\n";  #t$ratio\n";
    
    return ($d_int);    
  }
  
sub vector_pos2int
  {
    my $d_int = shift;
    my $d_pos = shift;
       
    my ($t, $p_zone, $i1, $i2, $i3, $i4) = "";
    my $z = {};
       
    $z = &setCageBoundaries ($d_pos);
    print STDERR "IWH\n\n";
       
    foreach my $cage (sort(keys (%$d_int)))
      {
        foreach my $time (sort(keys (%{$d_int->{$cage}})))
          {
            my $StartT = $d_int->{$cage}{$time}{'StartT'};
            my $EndT = $d_int->{$cage}{$time}{'EndT'};
            
            ($i1, $i2, $i3, $i4) = 0;
               
            for ($t = $StartT; $t <= $EndT  ;$t++)
              {
                #$x += $d_pos->{$cage}{$t}{'XPos'};
                #$y += $d_pos->{$cage}{$t}{'YPos'};                   
                $p_zone = ""; #it might not be information for some time points   
                #$p_zone =  &ChannelFromPos_modified($d_pos->{$cage}{$t}{'XPos'}, $d_pos->{$cage}{$t}{'YPos'});
                
                if (!exists ($d_pos->{$cage}{$t}{'XPos'}) || (!exists($d_pos->{$cage}{$t}{'YPos'}))) 
                  {
                    print STDERR "WARNING: Positions at time point $t, cage $cage is not set inside position file $d_pos->{$cage}{$t}{'File'}  or if \"shift option\" used is not available after shifting\n";                    
                  }
                       
                $p_zone =  &ChannelFromPos ($d_pos->{$cage}{$t}{'XPos'}, $d_pos->{$cage}{$t}{'YPos'}, $cage, $z);
                   
              SWITCH: 
                {
                  ($p_zone eq "Intake 1") && do 
                    { 
                      $i1++;
                      last SWITCH;
                    };
                  
                  ($p_zone eq "Intake 2") && do 
                    { 
                      $i2++;                          
                      last SWITCH;
                    };
                  
                  ($p_zone eq "Intake 3") && do 
                    { 
                      $i3++;                          
                      last SWITCH;
                    };
                  
                  ($p_zone eq "Intake 4") && do 
                    { 
                      $i4++;                          
                      last SWITCH;
                    };
                  
                  ($p_zone eq "Intake 4") && do 
                    { 
                      $i4++;                          
                      last SWITCH;
                    };
                      
                }
              }
            
            if ($i1 eq "") {$i1 = 0;}
            if ($i2 eq "") {$i2 = 0;}
            if ($i3 eq "") {$i3 = 0;}
            if ($i4 eq "") {$i4 = 0;}
            
            $d_int->{$cage}{$time}{'Ctr_1'} = $i1;
            $d_int->{$cage}{$time}{'Ctr_2'} = $i2;
            $d_int->{$cage}{$time}{'Ctr_3'} = $i3;
            $d_int->{$cage}{$time}{'Ctr_4'} = $i4;
            #$d_int->{$cage}{$time}{'Vector'} = ($i1, $i2, $i3, $i4);
            
          }      
      }
         
    return ($d_int);        
  }

#sub get_mean  #del
#  
#  {
#    my $d_pos = shift;
#    my $StartT = shift;
#    my $EndT = shift;
#    
#    
#  }

sub display_data #As in int2combo!!!
  {
    my $d=shift;
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
  
sub setChannelFromPos

  {
    my $d_int = shift;
    my $d_pos = shift;
    my ($x, $y, $x_max, $y_max, $z) = "";
    my $zones = {};    
    #die;
    
               
    $zones = &setCageBoundaries ($d_pos);
          
    #&setCageBoundaries ($zones);#del
    #print STDERR Dumper ($zones);#del
            
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
  
sub setChannelFromVector

  {
    my $d_int = shift;
    #my $d_pos = shift;
    my ($int_1, $int_2, $int_3, $int_4) = 0;
    my @ary = "";
    my $max = 0;    
    my $z = "";
    
    foreach my $cage (sort(keys (%$d_int)))
      {               
                    
        foreach my $time (sort(keys (%{$d_int->{$cage}})))
          {            
                        
            $int_1 = $d_int->{$cage}{$time}{'Ctr_1'}; 
            $int_2 = $d_int->{$cage}{$time}{'Ctr_2'};
            $int_3 = $d_int->{$cage}{$time}{'Ctr_3'};
            $int_4 = $d_int->{$cage}{$time}{'Ctr_4'};
            
            $max = 0;              
            $z = "";
              
            foreach my $ch ($int_1, $int_2, $int_3, $int_4)
              {                  
                print STDERR "$ch\n";#del
                $max = &max ($ch, $max);
                #print STDERR "interval channel number--> $max\n";
                
              }
            
          SWITCH: 
            {
              ($max == 0) && do
                {
                  $z = "No Pos Intake"; 
                  last SWITCH;
                };
                
              ($max == $int_1) && do 
                {
                  $z = "Intake 1"; 
                  last SWITCH;
                };
                  
              ($max == $int_2) && do 
                {
                  $z = "Intake 2"; 
                  last SWITCH;
                };
              
              ($max == $int_3) && do 
                {
                  $z = "Intake 3"; 
                  last SWITCH;
                };
              
              ($max == $int_4) && do 
                {
                  $z = "Intake 4"; 
                  last SWITCH;
                };
            }
              
            print STDERR "cage is $cage an interval is startTime --> $time\n\n";   
            print STDERR "max is $max zone is $z\n\n";
            print STDERR "Interval channel is $d_int->{$cage}{$time}{'Channel'}\n\n";
            
            $d_int->{$cage}{$time}{'Zone'} = $z;
            
            if ($d_int->{$cage}{$time}{'Channel'} eq $z){print STDERR "Match: Y\n\n";}
            else {print STDERR "Match: N\n\n";}                     
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
    
    #print STDERR "CAGE ----> $c \n";
    ##OJO PONER UN EXISTS PORQUE SINO CUANDO NO TENGO VALORES PARA UNA CAGE LOS CONSIDERA 0 O PONER <= 0!!!!!!!!!!!!!!!!
    $xm = $z->{$c}{'Xm'}; #print STDERR "xm $xm\n"; 
    #$x1 = $z->{$c}{'X1'}; print STDERR "x1 $x1\n";        
    $x2 = $z->{$c}{'X2'}; #print STDERR "x2 $x2\n";    
    $ym = $z->{$c}{'Ym'}; #print STDERR "ym $ym\n";
    $y1 = $z->{$c}{'Y1'}; #print STDERR "y1 $y1\n";
    
  SWITCH: 
        {
          ($x<=0 || $y<=0  ) && do 
            {
              $channel = "Negative"; 
              last SWITCH;
            };
          
          ($x>$xm || $y>$ym) && do
            {
              $channel = "Out"; 
              last SWITCH;
            };
         
          ($x<=$x2 && $y>$y1) && do 
            {
              #$channel = "Zone 1";
              $channel = "Intake 1"; 
              last SWITCH;
            };
          
          ($x<=$x2 && $y<=$y1) && do 
            {
              #$channel = "Zone 2";
              $channel = "Intake 2"; 
              last SWITCH;
            };
          
#        (($x>$x1 && $x<$x2))  && do 
#          {
#              $channel = "Center"; 
#              last SWITCH;
#          };
          
          ($x >$x2 && $y>$y1) && do 
            {
              #$channel = "Zone 3";
              $channel = "Intake 3"; 
              last SWITCH;
            };
          
          ($x >$x2 && $y<=$y1) && do 
            {
              #$channel = "Zone 4";
              $channel = "Intake 4"; 
              last SWITCH;
            };
        }
    
    return ($channel);
  }     
  

#Same function as ChannelFromPos but here xm, x2, ym and y1 are hard coded according with the values observed empirically
  
sub ChannelFromPos_modified
  {
    my $x = shift;#print STDERR "-----$x-----\n\n ";
    my $y = shift;#print STDERR "-----$y-----\n\n ";
    #my $c = shift;
    #my $z = shift;    
     my ($channel, $xm, $x1, $x2, $x3, $ym, $y1) = "";
    
    #print STDERR "CAGE ----> $c \n";
    
    $xm = "24.803"; #print STDERR "xm $xm\n"; 
    #$x1 = $z->{$c}{'X1'}; print STDERR "x1 $x1\n";        
    $x2 = "12.4015"; #print STDERR "x2 $x2\n";    
    $ym = "13.602"; #print STDERR "ym $ym\n";
    $y1 = "6.801"; #print STDERR "y1 $y1\n";
    
  SWITCH: 
    {
      ($x<=0 || $y<=0  ) && do 
        {
          $channel = "Negative"; 
          last SWITCH;
        };
      
      ($x>$xm || $y>$ym) && do
        {
          $channel = "Out"; 
          last SWITCH;
        };
      
      ($x<=$x2 && $y>$y1) && do 
        {
          #$channel = "Zone 1";
          $channel = "Intake 1"; 
          last SWITCH;
        };
      
      ($x<=$x2 && $y<=$y1) && do 
        {
          #$channel = "Zone 2";
          $channel = "Intake 2"; 
          last SWITCH;
        };
      
#        (($x>$x1 && $x<$x2))  && do 
#          {
#              $channel = "Center"; 
#              last SWITCH;
#          };
          
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

#    if ($x <0 || $y <0)
#      {
#        $channel = "Negative";
#        return ($channel);
#      }  
#    
#    elsif ($x>16.4 || $y>9.8)  
#      {
#        $channel = "Out";
#        return ($channel);
#      }
#    
#    elsif ()  
        
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
#                           Y
# X     0        X1           X2       Xm   0   
#       --------------------------------
#    - zone2   -   center    - zone4  -    
#    -       -        -        -
#    --------------------------------   Y1
#    - zone1  -   center    - zone3  -
#    -       -        -        -
#    --------------------------------   Ym

sub setCageBoundaries 
  {
    my $d_pos = shift;
    my $z = {};
    
    foreach my $cage (sort(keys (%$d_pos)))
           {  
             my ($x_max, $y_max) = (-1000., -1000);
                   
             foreach my $time (sort(keys (%{$d_pos->{$cage}})))
               {                   
                 $x_max = &max($d_pos->{$cage}{$time}{'XPos'}, $x_max);
                 $y_max = &max($d_pos->{$cage}{$time}{'YPos'}, $y_max);
               }
                                 
             print STDERR "In cage ---------------- $cage\t";
             print STDERR "maxim x is $x_max\t";
             print STDERR "maxim y is $y_max\n";
             
             $z->{$cage}{'Xm'} = $x_max;
             $z->{$cage}{'Ym'} = $y_max;
             #$z->{$cage}{'X1'} = 0.25 * $x_max;
             #$z->{$cage}{'X2'} = 0.75 * $x_max;
             $z->{$cage}{'X2'} = 0.5 * $x_max;        
             $z->{$cage}{'Y1'} = 0.5 * $y_max;
             
           }
#    foreach my $cage (sort(keys (%$z)))
#      {
#        #print STDERR "$cage-----$z->{$cage}{'Xm'}\n";#del
#        #print STDERR "$cage-----$z->{$cage}{'Ym'}\n";#del
#        $max_x = $z->{$cage}{'Xm'};
#        $max_y = $z->{$cage}{'Ym'};
#        
#      }  
    
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
  
sub data2std
  #$x_std = &data2std ($d_int->{$cage}{$time}{'MeanX'}, $j, \@X_values);
  {
    my $mean = shift;    
    my $ary_values = shift;
    my $N = scalar @$ary_values;
    my ($std, $sqtotal) = "";
      
    foreach my $v (@$ary_values) 
      {
        $sqtotal += ($mean-$v) ** 2;
      }
    
    $std = ($sqtotal / $N) ** 0.5;
        
  }
  
sub printInterPos
  {
    my $d_int = shift;
    my $pEndT = shift;
    my $StartT = shift;
    my $cage = shift;
    
    my ($t, $zone) = "";
    
    $pEndT++;
    
    print STDERR "$StartT  $pEndT\n";
    
    if ($StartT < $pEndT) {print STDERR "COLLISION --- NO Inter-Interval\n\n";}
    
    else 
      { 
        print STDERR "Inter-Interval starting at ---$pEndT ---\n"; 
              
        for ($t= $pEndT; $t < $StartT ; $t++)
          {  
            #$zone =  &ChannelFromPos_modified($d_pos->{$cage}{$t}{'XPos'},$d_pos->{$cage}{$t}{'YPos'});
            $zone =  &ChannelFromPos($d_pos->{$cage}{$t}{'XPos'},$d_pos->{$cage}{$t}{'YPos'});                       
            #print STDERR "$d_pos->{$cage}{$ttt}{'XPos'}\t$d_pos->{$cage}{$ttt}{'YPos'}\t$inter_zone\n\n";
            print STDERR "$d_pos->{$cage}{$t}{'XPos'}\t$d_pos->{$cage}{$t}{'YPos'}\t$zone\n";  
          }
        
        $StartT--;
      
        print STDERR "Inter-Interval ends at ---$StartT ---\n\n";
      }
  }
  
sub shiftTimestamp 
  {
    $A = shift;
    my $H = {};
    
    if (exists ($A->{add})) 
      {
        my $shift_time = $A->{add};
        my $operation = "add";  
        
        if ($shift_time =~ /m(\d+)/)
          {
            $shift_time = -$1;            
          }
        
        #$shift_time =~ s/m/-/;
        
        $H->{$operation} = $shift_time;
                
      }
    
    elsif (exists ($A->{mult}))
      {
        my $shift_time = $A->{mult};
        my $operation = "mult";
        print STDERR "I was in multiplication $shift_time\n";
        
        if ($shift_time =~ /m(\d+\.\d+)/)
          {
            $shift_time = -$1;            
          }
        
        #$shift_time =~ s/m/-/;
          
        $H->{$operation} = $shift_time;
        print STDERR "I was in multiplication $shift_time\n";              
      }
    
    else
      {
        #print Dumper ($A);die;
        print STDERR "\n\nOperation set by shift option is not correct!!!\n\n";
        die;
      }
          
    return ($H);           
  }
