#!/usr/bin/env perl

use HTTP::Date; #CPAN str2time()=> time conversion function different time format --> machine time
use File::Compare; #File comparison
use Data::Dumper;
use strict;
use FileHandle;

my $index;
my $SHIFT=4;
my $ary_files = "";

###################################
#Modification 02/09/2010
#Adding the possibility of giving the channel info by a file and not by headings inside mtb files
my $A={};
my $cl=join(" ", @ARGV);
my @commands=split (/\-+/,$cl);
my @files = split (" ", shift @commands);

#ary_files will containg only files we have pass the checking in order to see incosinstencies in files
print STDERR "\n\n---- FILE CHECKING STARTS ----\n\n";
$ary_files = &files2check (\@files);
print STDERR "\n\n---- FILE CHECKING ENDS ----\n\n";
print STDERR "--- FILES REMAINING AFTER THE CHECKING ARE: @$ary_files ---\n\n";

my $H={};
my $switch_f;

#&mtb2intervals ("Intake 1;Intake 2;Intake 3;Intake 4", @ARGV);
	      
#process_mbt (@ARGV);

foreach my $c (@commands)
  {
    #&run_instruction (\@files, $A, $c);
    &run_instruction ($ary_files, $A, $c); #now first we have checked files
  }
die;

sub run_instruction
  {
    my $ary_files=shift;
    my $A=shift;#now is empty
    my $c=shift;    
    
    $A=string2hash ($c,$A);
    
    if ($c=~/info/)
      {
	($H, $switch_f) = &file2channel ($A,$H);
      }
        
    elsif ($c=~/out/)
      {	
	#&mtb2intervals ("Intake 1;Intake 2;Intake 3;Intake 4", $H, $switch_f,  @files);
	&mtb2intervals ("Intake 1;Intake 2;Intake 3;Intake 4", $H, $switch_f,  @$ary_files);
      }
  }

sub file2channel 
    {
      my $A=shift;
      my $H=shift;
      my $file=$A->{file};
      my $switch_f=0;
      my $F=new FileHandle;
      my $c;
      my $seq;
      my $ch;
            
      if (defined ($A->{file})) {$switch_f=1} 
      	  
      open ($F, "$file") or die "Can't open file: $file";
      
      while (<$F>)
	{
	  chomp;
	  my $line=$_;
	  ($c, $seq) = split ("\t",$line);    
	  #print STDERR "c $c => seq $seq \n";
	  #print STDERR "la sequencia es $seq\n";
	  if ($seq!~/C/i) 
	    {
	      $H->{$c}{Name}="SC";
	    } 
	  else {
	    $seq=~m/C/ig;
	    $ch=pos($seq);
	        
	  SWITCH: 
	    {
	      ($ch == 1) && do 
		{
		  $H->{$c}{Name}="CD in A"; 
		  last SWITCH;
		};
		
	      ($ch == 2) && do 
		{
		  $H->{$c}{Name}="CD in B";
		  last SWITCH;
		};
		
	      ($ch == 3) && do 
		{
		  $H->{$c}{Name}="CD in C"; 
		  last SWITCH;
		};
		
	      ($ch == 4) && do 
		{
		  $H->{$c}{Name}="CD in D";  
		  last SWITCH;
		};	     	    
	    }      
	  }
	}
      close ($F);
      return ($H, $switch_f);
    }

sub string2hash 
  {
    my $s=shift;
    my $h=shift;
    my @l=split (/\s+/, $s);
    shift @l;
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
	$k=~s/-//g;#not needed I guess!
	$A->{$k}=$v;
      }
    return $A;
  }

#######end modification - 02/09/2010##############

sub process_mbt
  {
    my $infile=shift;
    
    my ($infile)=@ARGV;
    my %data;


    %data=&mtb2parse ($infile);
    %data=&merge_fields (\%data, "Food", "Intake 3", "Intake 4");
    %data=&intake2intervals (\%data, "Food");
        
    print "START: $data{$infile}{'HEADER'}{'EHEADER'}{'StartTime'} END: $data{'HEADER'}{'EndTime'}";
    die;
  }
  
sub mtb2intervals
    {
      my $channels=shift;
      #modification 02/09/2010
      my $H=shift;
      my $switch_f=shift;      
      #end modification - 02/09/2010
      my @files=@_;
      my @sorted_files;
      my %data;
      my @ch;
      my $ncages;

      foreach my $f (@files)
	{
	  %data=&mtb2header($f, \%data);
	  &display_header  (\%data, $f);
	}
	 
      #sort files by time stamp
      @sorted_files= (sort {$data{$a}{HEADER}{EHEADER}{'StartStamp'}<=>$data{$b}{HEADER}{EHEADER}{'StartStamp'}}(keys (%data)));
      
      
      @ch=split (/;/,$channels);
      foreach my $f (@sorted_files)
	{
	  my (@ci,%pv,%pe,%pt, $count, $count2);
	  my $F = new FileHandle;
	  my @chL=keys (%{$data{$f}{"[Intake Channels]"}});
	  my $stime=$data{$f}{"HEADER"}{'EHEADER'}{"StartStamp"};
	  $ncages=$data{$f}{'HEADER'}{'EHEADER'}{'Ncages'};
	  my $LineN;
	  my %rv;
	  my %in;
	  ($F,$LineN)=set_handle($f,"DATASECTION");

	  while (<$F>)
	    {
	      my $line=$_;
	      $LineN++;
	      
	      my %dataline=mtb2parse_line ($f,$line,\%data,\@chL);
	      if ($count==1000)
		{
		  print STDERR "------>$f: $count2\n";
		  $count=0;
		}
	      $count++; $count2++;
	      for (my $c=1; $c<=$ncages; $c++)
		{
		  foreach my $ch (@ch)
		    {
		      my $v=$dataline{$c}{$ch}{Value};
		      my $ci=$data{'INTERVALS'}{$c}{$ch}{0};
		      if (($v =~/\*/))
			{
			  
			  $v=~s/\*//;
			  if (!$in{$c}{$ch})
			    {
			      
			      $rv{$c}{$ch}=$v;
			      $in{$c}{$ch}=1;
			      $ci=++$data{'INTERVALS'}{$c}{$ch}{0};
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{StartT}=$dataline{$c}{$ch}{Time};
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{StartL}=$LineN;
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{Type}=1;
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{Index}=$ci;
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{Caption}=$data{$f}{"[Intake Channels]"}{$ch}{Caption};
			      
			      ###################################
			      #Modification 02/09/2010
			      #Adding the possibility of giving the channel info by a file and not by headings inside mtb files
			      if (!$switch_f)
				{
				  ########################
				  #Modification 31/08/2010
				  #Files where type of food is not in name but in code (Name2=2/Group2=Obese/Code=Choc in D)			      
				  #$data{'INTERVALS'}{$c}{$ch}{$ci}{Name}=$data{$f}{"[ANIMALS DATA]"}{$c}{Name};
				  if ($data{$f}{"[ANIMALS DATA]"}{$c}{Name}	=~ /\d+/) 
				    { 
				      if ($data{$f}{"[ANIMALS DATA]"}{$c}{Group} =~ /Lean/) 
					{
					  $data{'INTERVALS'}{$c}{$ch}{$ci}{Name}="SC"
					}
				      else 
					{
					  #$data{'INTERVALS'}{$c}{$ch}{$ci}{Name}=$data{$f}{"[ANIMALS DATA]"}{$c}{Code};
					  $data{'INTERVALS'}{$c}{$ch}{$ci}{Name}="CD";
					}				  
				    }
				  else 
				    {
				      $data{'INTERVALS'}{$c}{$ch}{$ci}{Name}=$data{$f}{"[ANIMALS DATA]"}{$c}{Name}; 
				    }
				  ###########end modificiation 31/08/2010##############
				}
			      else
				{				  
				  $data{'INTERVALS'}{$c}{$ch}{$ci}{Name}=$H->{$c}{Name};
				}
			      ###end modification-02/09/2010###############
			      
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{File}=$f;
			      
			    }
			  $data{'INTERVALS'}{$c}{$ch}{$ci}{EndT}=$dataline{$c}{$ch}{Time};
			  $data{'INTERVALS'}{$c}{$ch}{$ci}{EndL}=$LineN;
			  $data{'INTERVALS'}{$c}{$ch}{$ci}{Value}=$v;
			}
		      else
			{
			  if ($in{$c}{$ch})
			    {
			      $data{'INTERVALS'}{$c}{$ch}{$ci}{Value}-=$v;
			    }
			  $in{$c}{$ch}=0;
			}
		    }
		}
	    }
	}
      for (my $c=1; $c<=$ncages; $c++)
	{
	  foreach my $ch (@ch)
	    {
	      
	      my $ci=$data{'INTERVALS'}{$c}{$ch}{0};
	     
	      for (my $i=1; $i<=$ci; $i++)
		{
		  my $StartT=$data{'INTERVALS'}{$c}{$ch}{$i}{StartT};
		  
		  my $EndT=$data{'INTERVALS'}{$c}{$ch}{$i}{EndT};
		  
		  my $StartL=$data{'INTERVALS'}{$c}{$ch}{$i}{StartL};
		  my $EndL=$data{'INTERVALS'}{$c}{$ch}{$i}{EndL};
		  
		  my $Value=$data{'INTERVALS'}{$c}{$ch}{$i}{Value};
		  my $Type=$data{'INTERVALS'}{$c}{$ch}{$i}{Type};
		  
		  my $Caption=$data{'INTERVALS'}{$c}{$ch}{$i}{Caption};
		  my $File=$data{'INTERVALS'}{$c}{$ch}{$i}{File};
		  my $Name=$data{'INTERVALS'}{$c}{$ch}{$i}{Name};
		  
		  my $Duration=$EndT -$StartT;
		 
		  
		  print "#d;CAGE;$c;Channel;$ch;Caption;$Caption;Name;$Name;Index;$i;StartT;$StartT;EndT;$EndT;Duration;$Duration;Value;$Value;Type;$Type;File;$File;StartL;$StartL;EndL;$EndL\n";
		}
	    }
	}
      return %data;
    }
      
sub mtb2parse_line 
    {
      my $file=shift;
      my $line=shift;
      my $dataR=shift;
      my $channelsR=shift;
     
      
      my %data=%$dataR;
      my @channels=@$channelsR;
      my @list;
      my ($Ncages, $stime,$time, $id, %dataline);
      
      $id="[Intake Channels]";
      $stime=$data{$file}{"HEADER"}{'EHEADER'}{"StartStamp"};
      
      $Ncages=$data{$file}{"HEADER"}{'EHEADER'}{"Ncages"};
      

     
      
      if ($line)
	{
	  my ( $i, $cage, $t, $lineN);
	  $line =~ s/[=]/ /g;
	  $line =~ s/,/\./g;
	  
	  @list=split ( /\s+/, $line);
	  $time=$lineN=shift (@list);
	  $time=$lineN+$stime;
	  for (my $a=0; $a<$SHIFT; $a++){shift(@list);} #NODATA out
	  
	  foreach my $ch (@channels)
	    {
	      
	      my $chi=$data{$file}{$id}{$ch}{Index}-1;
	      for (my $cage=1; $cage<=$Ncages;$cage++)
		{
		  my $event;
		  my $i=$chi*$Ncages+($cage-1);
		  my $v=$list[$i];
		  
		  #if (($v=~/\*/)){$event=1;$v=~s/\*//;}
		  #else {$event=0;}
		  
		  $dataline{$cage}{$ch}{'Value'}=$list[$i];
		  #$dataline{$cage}{$ch}{'Event'}=$event;
		  my $t=$dataline{$cage}{$ch}{'Time'}=$time;
		}
	    }
	 
	}
      
      
      return %dataline;
    }

sub mtb2header 
    {
    my $file=shift;
    my $dataR=shift;
    my $F = new FileHandle;
    my %header=%$dataR;
    
    my ($id,@id_list,$index, $v, $time);
    my ($Nintake, $Ncages);
     
    
    #hard code activity as channel 1
    $index=&set_channel (\%header,$file,"[Intake Channels]",$index,"activity",("Type=output", "Captions=activity", "unit=undef"));
    #hard code rearing as channel 2
    $index=&set_channel (\%header,$file,"[Intake Channels]",$index,"rearing" ,("Type=output", "Captions=rearing",  "unit=undef"));
   
    open ($F, "$file");
    while (<$F>)
      {
	my $line=$_;
	if ($line=~/(\[.*\])/)
	  {
	    $id=$1;
	    push (@id_list, $id);
	  }
	else
	  {
	    if ($id=~/ANIMALS DATA/)
	      {
		if (($line=~/(\D+)(\d+)=([\w .\/:]*)/))
		  {
		    $header{$file}{$id}{$2}{$1}=$3;
		  }
	      }
	    elsif ($id=~/Intake/)
	      {

		if (($line=~/(Intake\s+\d+)\s+(.+)=([\w .\/:]*)/))
		  {
		    my $channel=$1;
		    my $name=$2;
		    my $val=$3;
		    
	
		    if (!$header{$file}{$id}{$channel})
		      {
			$index++;
			$header{$file}{$id}{$channel}{Type} ="output";
			$header{$file}{$id}{$channel}{Index}= $index;
			
		      }
		    $header{$file}{$id}{$channel}{$name}=$val;
		  }
	      }
	    elsif ($id=~/DATASECTION/){last;}
	    else 
	      {
		if (($line=~/(.*)=([\w .\/:]*)/))
		  {
		    $header{$file}{$id}{$id}{$1}=$2;
		  }
	      }
	  }
      }
    close ($F);
    $header{$file}{'HEADER'}{'EHEADER'}{'Ncages'}=$Ncages=&header2value("Number of cages", \%header, $file);
    $time=$header{$file}{"HEADER"}{'EHEADER'}{'StartStamp'}=str2time(&header2value("Date and time", \%header, $file));
   
    return %header;
  }
    

sub intake2intervals (\%data, "Food")
{
  my $file=shift;
  my $dataR= shift;
  my $ch =shift;
  my %data =%$dataR;
  my $start_t=$data{$file}{'HEADER'}{'EHEADER'}{'StartTime'};
  my $end_t  =$data{$file}{'HEADER'}{'EHEADER'}{'EndTime'};
  my $ncages =$data{$file}{'HEADER'}{'EHEADER'}{'Ncages'};
  
  for (my $c=1; $c<=$ncages; $c++)
    {
      my ($ci,$pv);
      for (my $t=$start_t; $t<$end_t; $t++)
	{
	  my $v=$data{$file}{"DATASECTION"}{$c}{$ch}{$t};
	  my $lineN=$t-$data{$file}{"HEADER"}{'EHEADER'}{"StartStamp"};
	  
	  if ($v!=$pv || !$ci)
	    {
	      $ci++;
	      my $delta=$pv-$v;
	      
	      if ($delta>=0.02)
		{
		  printf "\n\t---- Big   Delta: Line: %d Cage: %d Delta: %.2f [$pv :: $v]\n",$lineN , $c, $delta;
		}
	      elsif ($delta>0)
		{
		 printf "\n\t---- Small Delta: Line: %d Cage: %d Delta: %.2f [$pv :: $v]\n",$lineN , $c, $delta;
		}
	      
	      $data{'INTERVALS'}{$c}{$ch}{$ci}{'start'}=$t;
	      $data{'INTERVALS'}{$c}{$ch}{$ci}{'delta'}=$delta;
	      $data{'INTERVALS'}{$c}{$ch}{0}++;
	      }
	  $data{'INTERVALS'}{$c}{$ch}{$ci}{'end'}=$t;
	  $pv=$v;
	}
      print STDERR "CAGE: $c N_intervals: $data{'INTERVALS'}{$c}{$ch}{0}\n";
      die;
    }

  for (my $a=1; $a<=$data{'INTERVALS'}{1}{$ch}{0}; $a++)
    {
      my $d= $data{'INTERVALS'}{1}{$ch}{$a}{'end'}-$data{'INTERVALS'}{1}{$ch}{$a}{'start'};
      printf "I:%5d %5d =>%.2f\n", $a, $d, $data{'INTERVALS'}{1}{$ch}{$a}{'delta'};
    }
  return %data;
}

 
sub merge_fields
  {
    #merge the channels in CH list and creat a new channel

    my $dataR=shift;
    my $new_ch=shift;
    my @ch_list=@_;
    my ($c, $t,$ncages, $start_t, $end_t, $ch, $time, $x);
    my %data;

    %data=%$dataR;
    
   
    $start_t=$data{'HEADER'}{'EHEADER'}{'StartTime'};
    $end_t=$data{'HEADER'}{'EHEADER'}{'EndTime'};
    $ncages=$data{'HEADER'}{'EHEADER'}{'Ncages'};
    print STDERR "MERRGE CHANNELS";

   
    
    
    for ($c=1; $c<=$ncages; $c++)
      {
	
	for ($t=$start_t; $t<$end_t; $t++)
	  {
	    my $v;
	    foreach $ch (@ch_list)
	      {

		$v+=$data{"DATASECTION"}{$c}{$ch}{$t};
	      }
	    $x=$data{"DATASECTION"}{$c}{$new_ch}{$t}=$v;
	  }
	print "$c: $x\n";
      }
    return %data;
  }
    

sub mtb2parse
  {
    my $count;
    my $infile= shift;
    my $F = new FileHandle;
    my %header;
    
    my ($id,@id_list,@output, $index, $v, $time);
    my (%header,$Nintake, $Ncages);
    
    open ($F, "$infile");
   
    %header=&set_channel (\%header,$infile,"[Intake Channels]","activity",("Type=output", "Captions=activity", "unit=undef"));
    push (@output, "activity");
    %header=&set_channel (\%header,$infile,"[Intake Channels]","rearing" ,("Type=output", "Captions=rearing",  "unit=undef"));
    push (@output, "rearing");
    
    
    while (<$F>)
      {
	my $line=$_;
	if ($line=~/(\[.*\])/)
	  {
	    $id=$1;
	    
	    push (@id_list, $id);
	    print "$id---";
	    
	  }
	else
	  {
	    if ($id=~/ANIMALS DATA/)
	      {
		if (($line=~/(\D+)(\d+)=([\w .\/:]*)/))
		  {
		    $header{$infile}{$id}{$2}{$1}=$3;
		  }
	      }
	    elsif ($id=~/Intake/)
	      {
		my ($channel, $name, $val);
		if (($line=~/(Intake\s+\d+)\s+(.+)=([\w .\/:]*)/))
		  {
		    $channel=$1;
		    $name=$2;
		    $val=$3;
		    
		    if (!$header{$infile}{$id}{$channel})
		      {
			$index++;
			$header{$infile}{$id}{$channel}{Type} ="output";
			$header{$infile}{$id}{$channel}{Index}= $index;
			push (@output, "$channel");
		      }
		    $header{$infile}{$id}{$channel}{$name}=$val;
		  }
	      }
	    elsif ($id=~/DATASECTION/){last;}
	    else 
	      {
		if (($line=~/(.*)=([\w .\/:]*)/))
		  {
		    $header{$infile}{$id}{$id}{$1}=$2;
		  }
	      }
	  }
	if ($id=~/DATASECTION/){last;}
      }
    
    &display_header(\%header);
    
    $header{$infile}{'HEADER'}{'EHEADER'}{'Ncages'}=$Ncages=&header2value("Number of cages", \%header);
    $header{$infile}{"HEADER"}{'EHEADER'}{"StartStamp"}=str2time(&header2value("Date and time", \%header));
        
    while (<$F>)
      {
	my $line=$_;
	my (@list, $time, $i, $cage, $t, $lineN);
	$line =~ s/[*=]/ /g;
	$line =~ s/,/\./g;
	
	
	
	@list=split ( /\s+/, $line);
	$lineN=$t=$time=shift (@list);
	
	$time+=$header{$infile}{"HEADER"}{"StartStamp"};
	
	if (!$header{$infile}{"HEADER"}{'EHEADER'}{"StartTime"})
	  {$header{$infile}{"HEADER"}{'EHEADER'}{"StartTime"}=$time;}
	
	$header{$infile}{"HEADER"}{"EndTime"}=$time;
	
	for (my $a=0; $a<$SHIFT; $a++){shift(@list);}
	
	if ( $count == 10000){print STDERR "\n\t$time\t";$count=0;}
	for (my $o=0; $o<=$#output;$o++)
	  {
	    for ($cage=1; $cage<=$Ncages; $cage++)
	      {
		$header{$infile}{'DATASECTION'}{$cage}{$output[$o]}{$time}=shift (@list);
		#$header{'DATASECTION'}{$cage}{$output[$o]}{$time}{'line'}=$lineN;
	      }
	  }
      $count++;
      }
    close (F);
    return %header;
  }

sub display_header 
{
  my ($hr)=shift;
  my $f= shift;
  my %h = %$hr;

 
  foreach my $k1 (keys (%{$h{$f}}))
    {
      if ($k1 eq "INTERVALS"){next;}
      foreach my $k2 (keys (%{$h{$f}{$k1}} ))
	{
	  foreach my $k3 (keys (%{$h{$f}{$k1}{$k2}}))
	    {
	      print "#h;$f;$k1;$k2;$k3;$h{$f}{$k1}{$k2}{$k3}\n";
	    }
	}
    }
}
      
sub header2value
{
  my ($name,$hr, $file)=@_;
  my %h = %$hr;
  my ($k1,$k2,$k3, @fl);
  
  if ($file){@fl=($file);}
  else {@fl=keys(%h);}
	
  foreach my $f (@fl)
    {
      foreach $k1 (keys (%{$h{$f}}))
	{
	  if ($k1 eq "DATAVALUE"){next;}
	  foreach $k2 (keys (%{$h{$f}{$k1}} ))
	    {
	      foreach $k3 (keys (%{$h{$f}{$k1}{$k2}}))
		{
		  if ($k3=~/$name/)
		    {return $h{$f}{$k1}{$k2}{$k3};}
		}
	    }
	}
    }
}
sub set_channel 
  {
    
    my $hin=shift;
    my $file=shift;
   
    my $id=shift;
    my $index=shift;
    my $channel=shift;
    my @values=@_;
    my ($v);
    my %h=%$hin;
    $index++;
   
    $h{$file}{$id}{$channel}{Index}=$index;
   
    foreach $v (@values)
      {
	my ($l, $r);
	($l, $r)=split (/=/, $v);
	$h{$file}{$id}{$channel}{$l}=$r;
      }
    return $index;
  }


sub set_handle
    {
      my $f=shift;
      my $exp= shift;
      my $F=new FileHandle;
      my $LineN;
      open($F, $f);
      while (<$F>)
	{
	  $LineN++;
	  if (/$exp/){return ($F,$LineN);}
	}
      close ($F);
      return 0;
    }

#Check input mtb files:
#have date and time
#have date
#have time
#2 files not having the same date
#    2 files having the sama data inside whereas the are named different 
#Concordance between date inside file and name of file

sub files2check 
  {    
    my $ary_files = shift;
    my ($f, $rem_f);
    my ($v, $d, $t);
    my $ary_filter_files;
    my $H = {};

    foreach $f (@$ary_files) 
      {			
	($d, $t) = &timestamp_in_file ($f);
		
	##Date and time presents?
	if (!defined ($d) && !defined ($t)) 
	  {
	    print STDERR "\n\nWARNING FILE $f HAS NO DATE AND TIME!!!\n";
	    print STDERR  "THUS IT WON'T BE USED!!\n\n";	     
	  }
	
	elsif (!defined ($d))
	  {
	    print STDERR "\n\nWARNING FILE $f HAS NO DATE!!!\n\n";
	    print STDERR  "THUS IT WON'T BE USED!!\n\n";
	  }

	elsif (!defined ($t))
	  {
	    print STDERR "\n\nWARNING FILE $f HAS NO TIME!!!\n\n";
	    print STDERR  "THUS IT WON'T BE USED!!\n\n";
	  }
	
	else 
	  {	    
	    $H->{$f}{date} = $d;
	    $H->{$f}{time} = $t; 
	  }
      }
        
    #Checks if the are different files with duplicated dates and removes those where date does not match file name
    $H = &timestamp2repetion ($H);
    
    #We check that remaining files have the same date inside file and in filename 
    foreach $rem_f (keys (%$H)) 
      {
	$H = &date2filename ($rem_f, $H);
      }
    
    $ary_files = &hashkeys2array ($H);
    return ($ary_files);
    
  }

#Gets time and date from file mtb time stamp
sub timestamp_in_file 
    {
      my $f = shift;
      my $F = new FileHandle;
      my $i;
      my ($k, $v, $date, $time);
           
      open ($F, "$f") or die "Can't open file: $f";
      
      while (<$F>)
	{
	  ($i == 3000) && last; #Headers are in the first part of the file, with 12 cages last header line ~1200, to be sure 3000 lines are considered
	  chomp;
	  my $line = $_;
	  
	  if ($line =~ /Date and time=/)
	    {	      
	      ($k, $v) = split ("=", $line);
	      ($date, $time) = split (/\s+/, $v);	      
	    }
	  
	  $i++;
	}
      
      return ($date, $time)
    }

#Check if two files have the same time stamp
#If that happens pass the files to date2filename, that checks which of the files has
#a time stamp different to the file name 
sub timestamp2repetion 
	{
	  my $H = shift;
	  my ($f, $f2) = "";
	  
	  foreach $f (keys (%{$H}))
	    {
	      #print STDERR "file is $f\n";
	      foreach $f2 (keys (%$H))
		{
		  if ($f ne $f2 && $f < $f2 ) 
		    {
		      if ($H->{$f}{time} eq $H->{$f2}{time} && $H->{$f}{date} eq $H->{$f2}{date})
			{
			  if (compare($f, $f2) == 0)
			    {
			      print STDERR "\n\nWARNING: $f and $f2 have the same information (are the same file)!!!\n";
			      $H = &date2filename ($f, $H);
			      $H = &date2filename ($f2, $H);
			    }
			  else
			    {
			      print STDERR "\n\nWARNING: $f and $f2 have the same time stamp!!!\n\n";

			      #If they have thes same time stamp but are not the same file we take file which date matches file name
			      $H = &date2filename ($f, $H);
			      $H = &date2filename ($f2, $H);
			    }	     
			}
		    }
		}
	    }
	  return ($H);
	}

#Check the date inside the file vs the date in file name
sub date2filename 
	  {
	    my $f = shift;
	    my $H = shift;
	    my ($year, $month, $day, $date) = "";
	      
	    		 	       
	    $year = substr ($f, 0, 4);
	    $month = substr ($f, 4, 2);
	    $day = substr ($f, 6, 2);
	    $date = $day."/".$month."/".$year;
		
	    if ($date ne $H->{$f}{date})
	      {
		print STDERR "\n\nWARNING: File $f timestamp --$H->{$f}{date}-- does not match file name!!!\n";
		delete ($H->{$f});
		print STDERR "THUS IT WON'T BE USED!!!\n\n";		    
	      }
 				
	    return ($H);
	  }

#Creates an ordered array with hash keys 
sub hashkeys2array      
	    {
	      my $H = shift;
	      my $k = "";
	      my @a = "";
	      	      
	      foreach $k  (sort ({$a cmp $b} keys (%$H)))
		{
		  push (@a, $k);
		}

	      return (\@a);
	    }
