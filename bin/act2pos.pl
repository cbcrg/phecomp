#!/usr/bin/env perl

##############################################################################################
### Jose A Espinosa. CB-CRG Group.                                       Dec 2010          ###
##############################################################################################
###  act2pos.pl                                                                            ###
##############################################################################################
### Routine to transform positions comming from the ACTI-TRACK analysis (PANLAB) into      ###
### temporal intervals useful to validate feed and drink events resulting from mtb2int and ###
### int2combo.                                                                             ###
### ACTI-TRACK (win application, not automated process) => *.pos file with position info   ###
### for each cage inside the file, separated by a header == "File Track Number : n"        ###
###                                                                                        ### 
##############################################################################################
#use warnings;
use strict;

###Modules used
use FileHandle;
use HTTP::Date; #CPAN str2time()=> time conversion function different time format --> machine time (seconds since EPOCH)
use Data::Dumper;

my $A={};
my $cl=join(" ", @ARGV);
my @commands=split (/\-+/,$cl);
my @files = split (" ", shift @commands);

foreach my $c (@commands)
  {    
    &run_instruction (\@files, $A, $c);
    #&run_instruction ($ary_files, $A, $c); #now first we have checked files
  }

die;

###################
#FUNCTIONS
##########

sub run_instruction
  {
    my $ary_files=shift;
    my $A=shift;#now is empty
    my $c=shift;    
    
    $A=string2hash ($c,$A);
              
    if ($c=~/out/)
      {	
	&act2position ($ary_files);
      }
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
	$k=~s/-//g;
	$A->{$k}=$v;
      }
    return $A;
  }

sub act2position 
    {
      my $files = shift;
      my %data;
      #my @files=@_;
      my @sorted_files;
      my ($stime, $ncages); 
      
      foreach my $f (@$files)
	{	  
	  %data = &act2header($f, \%data);	  
	  &display_header (\%data, $f);
	}
            
      #sort files by time stamp      
      @sorted_files = (sort {$data{$a}{HEADER}{EHEADER}{'StartStamp'} <=> $data{$b}{HEADER}{EHEADER}{'StartStamp'}}(keys (%data)));
           
      foreach my $f (@sorted_files)
	{	  
	  my ($ci);
	  my $F = new FileHandle;
	  my $stime = $data{$f}{"HEADER"}{'EHEADER'}{"StartStamp"}; 
	  
	  $ncages = $data{$f}{'HEADER'}{'EHEADER'}{'Ncages'};
	  
	  my $LineN;
	  
	  ($F,$LineN) = &set_handle ($f, "TRACK INFORMATION"); ###Be AWARE that each time I find 
	  
	  for (my $c=1; $c<=$ncages; $c++)
	    {
	      my $data_H;
	      #($F, $LineN, %data) = &read_track ($F, $f, $LineN, %data);	      
	      ($F, $LineN, %data) = &read_track ($F, $f, $LineN, $c, \%data, $stime);
	      
	    }
	  
	  for (my $c=1; $c<=$ncages; $c++)
	    {	      	 
	      my $ci=$data{'POSITION'}{$c}{0};
	      
	      for (my $i=1; $i<=$ci; $i++)
		{
		  
		  my $time = $data{'POSITION'}{$c}{$i}{Time};
		  my $x = $data{'POSITION'}{$c}{$i}{X};
		  my $y = $data{'POSITION'}{$c}{$i}{Y};
		  my $type = $data{'POSITION'}{$c}{$i}{Type};
		  my $line = $data{'POSITION'}{$c}{$i}{Line};		  
		  my $file = $data{'POSITION'}{$c}{$i}{File};
		  my $f_print = $file;
		  
		  if ($file =~ /^*.\//) #avoiding names as us/cn/file.act -> file.act
  			{  		
  				my @a = split ("/",$file);
  				$f_print = pop( @a);   		
  			} 	
  				  
		  print "#d;CAGE;$c;Index;$i;Time;$time;XPos;$x;YPos;$y;Type;$type;Line;$line;File;$f_print\n";
		}
	    }
	}           
    }

sub act2header
      {
	my $file=shift;
	my $dataR=shift;
	my %header = %$dataR;	
	my $F = new FileHandle;
	my ($id, @id_list);
	my ($time, $Ncages, $cage);

	#print STDERR "--- WORKING WITH FILE: $file ---\n";
	open ($F, "$file");
	
	while (<$F>)
	  {
	    chomp;
	    my $line = $_;
	    
	    if ($line =~ /(^[A-Z]{2,}\s+[A-Z]+)/) #Capital letters at least 2 (eg AA, AAA...); only 2 1st words
		{
		  
		  $id = $1;
		  
		  push (@id_list, $id);		  
		}
	    else
	      {  
		if ($id=~/TRACK INFORMATION/) 
		  {
		    if ($line =~ /(File Track Number)\s+:\s+(\d+)/)
		    #if ($line =~ /Subject Track Number\s+:\s+(\d)/)#-- REVIEW -- WHETHER I USE "File Track Number" AS PROXY FOR THE ANIMAL, CHECK IF
		    #IT ALWAYS HAVE THE SAME INFO NOR I FIRST READ ALL LINES AND THEN AFTER THIS OPERATION I USED THE INFO KEPT IN A DIFF
		    #HASH e.g. %track_info TO ASSOCIATED IT TO THE ANIMAL "Subject Track Number" APPEARS AS 4TH LINE
		    #IT seems that they are always the same (cages1_3_5_test.act at win_unix_folder)
		      {
			$cage = $2;
			
		      }
		    
		      elsif ($line =~ /(([\w|&]+\s*)+):(.*)/ )
			{
			  #print STDERR "lines under TRACK INFO --> $line\n";
			  my $k = $1;
			  my $v = $3;
			  $k =~ s/^\s+|\s+$//g;
			  $v =~ s/^\s+|\s+$//g;
			  $header{$file}{$id}{$cage}{$k}=$v;
			}
			
		      
		  }
		
		elsif ($id =~ /(ZONE FILE|ANALYSIS PARAMETERS|TRACKING FILE)/)
		  {
		    
		    #if ($line =~ /([a-zA-Z&\s]+)/ )
		    #if ($line =~ /(([\w|&]+\s+)+):(.*)/ )
		    if ($line =~ /(([\w|&|\'|-]+\s*)+):(.*)/ )
		      { 
			my $k = $1;
			my $v = $3;
			$k =~ s/^\s+|\s+$//g;
			$v =~ s/^\s+|\s+$//g;
			
			$header{$file}{$id}{$id}{$k}=$v;		       
		      }
		  }
		
		
		elsif ($id =~ /^\d|^Sample/) 
		  {
		    next;
		  }
		
		else 
		  {
		    if (($line=~/(.*):(.*)/))
		      {			
			$header{$file}{$id}{$id}{$1}=$2;
		      }
		  }
		
	      }
	  }
	
	close ($F);
	
	$header{$file}{'HEADER'}{'EHEADER'}{'Ncages'}=$Ncages=&header2value("Number of Trackings", \%header, $file); #Do I need the number of cages #REVIEW
	
	##Modification 07/01/2011
	#It seems that date format depend on the machine and win version you run actitrack, thus I have to incorporate new format dates
	
	%header = &dates_format2change(\%header, $file);#Format of act files is "6/28/2010	2:49:49 PM"        
	
	#Each cage (track) has a "Track Date & Time"
	#It should be the same for all tracks in the same file
	#Checked just in case!	
	$time=$header{$file}{"HEADER"}{'EHEADER'}{'StartStamp'}=str2time(&check_all_dates ("Track Date & Time", \%header, $file)); 
	#$time=$header{$file}{"HEADER"}{'EHEADER'}{'StartStamp'}=str2time(&header2value("File Date & Time ", \%header, $file));
	
	#print STDERR "time -> $time\n";#del
	
	return (%header);
      }

sub display_header#modify respect mtb2int to order keys
{
  my ($hr)=shift;
  my $f= shift;
  my %h = %$hr;
  my $f_print = $f;
  
  if ($f =~ /^*.\//)
  	{  		
  		my @a = split ("/",$f);
  		$f_print = pop( @a);   		
  	} 
 
  foreach my $k1 (keys (%{$h{$f}}))
    {
      if ($k1 eq "POSITION"){next;}
      foreach my $k2 (keys (%{$h{$f}{$k1}} ))
	{
	  foreach my $k3 (keys (%{$h{$f}{$k1}{$k2}}))
	    {
	      print "#h;$f_print;$k1;$k2;$k3;$h{$f}{$k1}{$k2}{$k3}\n";
	    }
	}
    }
}

sub header2value #no modified (modified in comment line)
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
	  #if ($k1 eq "DATAVALUE"){next;}
	  if ($k1 eq "TRACK INFORMATION"){next;}

	  foreach $k2 (keys (%{$h{$f}{$k1}} ))
	    {
	      foreach $k3 (keys (%{$h{$f}{$k1}{$k2}}))
		{   
		  if ($k3=~/$name/)
		    {		      
		      return $h{$f}{$k1}{$k2}{$k3};
		    }
		}
	    }
	}
    }
}

sub dates_format2change
  {
    my ($hr, $f) = @_;
    my %h = %$hr;
    my ($k1,$k2,$k3, @fl);

    if ($f){@fl=($f);}
    else {@fl=keys(%h);}
    
    foreach $k1 (keys (%{$h{$f}}))
      {
	if ($k1 eq "POSITION"){next;} 
	foreach $k2 (keys (%{$h{$f}{$k1}} ))
	  {
	    foreach $k3 (keys (%{$h{$f}{$k1}{$k2}}))
	      {
		if ($k3 =~ /^.*Date.*/)
		  {		    
		    my $old_date = $h{$f}{$k1}{$k2}{$k3};
		    if ($old_date =~ /^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})\s+([0-9]{1,2}):([0-9]{2}):([0-9]{2})\s+([A-Z]{2})/)
		      {
			my ($day, $month, $hour);
			#$day = $2;
			#$month = $2;			
			$day = ($2 =~  tr/[0-9]// < 2)? "0".$2 : $2;
			$month = ($1 =~  tr/[0-9]// < 2)? "0".$1 : $1;
			$hour = ($4 =~  tr/[0-9]// < 2)? "0".$4 : $4;						
			$hour = ($7 eq "PM" && $hour != "12")? $hour + 12 : $hour;
			 			
			my $new_date = $day."/".$month."/".$3." ".$hour.":".$5.":".$6;			
			$h{$f}{$k1}{$k2}{$k3} = $new_date;
		      }
		    #15/12/2010	11:10:11
		    elsif($old_date =~ /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})\s+([0-9]{2}):([0-9]{2}):([0-9]{2})/)
		      {      #Depending on the computer the act files are processed the format of the date is different, that is the good one, no changes
 				}
		    else 
		      {			
			print STDERR "\n\nWARNING: Date and time format in file: $f; field: $k3 NOT RECOGNIZED\n\n";
		      }
		  }
	      }
	  }
      }
    return (%h);
  }

sub check_all_dates 
    {     
      my ($name, $hr, $f) = @_;
      my %h = %$hr;
      my ($k1,$k2,$k3,$Date, $i);
      my $pDate = -1;
      my $H_f_dates = {};
      
      foreach $k1 (keys (%{$h{$f}}))
	{
	  if ($k1 ne "TRACK INFORMATION"){next;}
	  
	  foreach $k2 (keys (%{$h{$f}{$k1}} ))
	    {
	      foreach $k3 (keys (%{$h{$f}{$k1}{$k2}}))
		{  		  
		  if ($k3=~/$name/)
		    {
		      $Date = $h{$f}{$k1}{$k2}{$k3};
		      $i++;
		      
		      if ($pDate != -1) 
			{
			
			  if ($Date eq $pDate) 
			    {
			      $pDate = $Date;
			      #print STDERR "OK!! -- Inside file $f all tracks starting times are equal\n$pDate -- $pDate\n";
			      #next;
			    }
			
			  else 
			    {			      
			      #print STDERR "\nWARNING: Inside file $f all tracks starting times are not equal\n$Date--$pDate\nfile might be corrupted!!!\n;
			      #$pDate = $Date;
			      die "\nPROGRAM ENDS: Inside file $f all tracks starting times are not equal\n$Date--$pDate\nfile might be corrupted!!!\n";
			    }
			}
		      
		      else 
			{
			  $pDate = $Date;			  
			}		      		      		      		      		      
		      if ($i == $h{$f}{'HEADER'}{'EHEADER'}{'Ncages'} ) #when it arrive to the last cage goes out
			{			  
			  return ($h{$f}{$k1}{$k2}{$k3});
			}
		    }
		  
		}
	    }
	}
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

sub read_track
	{
	  my $F = shift;#filehandle
	  my $f = shift;
	  my $LineN = shift;#Review I should print each 1000 lines a stderr msg
	  my $c = shift;
	  my $H_dataR = shift;
	  my $stime = shift;#del
	  my ($count, $count2, $f_print);	  	 
	
	  $f_print = $f;
	  	  
  	  if ($f =~ /^*.\//)
  		{  		
  			my @a = split ("/",$f);
  			$f_print = pop( @a);   		
  		}
  		 
	  my ($line, $track, $ci);
	  
	  while (<$F>)
	    {
	      $LineN++;
	      chomp;
	      $line = $_;
	      
	      if ($count==100000)
	      	{
	      	  print STDERR "------>$f_print -- TRACK $c: $count2\n";
	      	  $count=0;
	      	}
	      $count++; $count2++;
		
	      #next if ($line =~ /^\s*$/);
				      	     	     	     	      
	      if ($line =~ /^\d+/)
		{		
		  #print STDERR "where you are file -> $f       line -> $line    startime -> $stime\n";# -> $f;     line -> $line;      startime -> $stime\n";#del
		  my $H_data_line = &act2parse_line ($f, $line, $stime);
		  #print Dumper ($H_data_line);#del		  
		  if (exists ($H_data_line->{'Time'})) #inside act2parse_line we only keep sec no tenth of sec (1.00, 2.00...)
		    {
		      $ci++;
		      
		      $H_dataR -> {'POSITION'}{$c}{$ci}{File} = $f;
		      $H_dataR -> {'POSITION'}{$c}{$ci}{Time} = $H_data_line->{'Time'};
		      $H_dataR -> {'POSITION'}{$c}{$ci}{X} = $H_data_line->{'X'};
		      $H_dataR -> {'POSITION'}{$c}{$ci}{Y} = $H_data_line->{'Y'};
		      $H_dataR -> {'POSITION'}{$c}{$ci}{Sample} = $H_data_line->{'Sample'};
		      $H_dataR -> {'POSITION'}{$c}{$ci}{Type} = 1;
		      $H_dataR -> {'POSITION'}{$c}{$ci}{Line} = $LineN;
		      $H_dataR -> {'POSITION'}{$c}{0} = $ci; 
		      
		    }
		  
		}
	      
	      elsif ($line =~ /(File Track Number)\s+:\s+(\d+)/)
		{
		  $track = $2;
		  print STDERR "\n-- START TRACK: $track --\n";
		  if ($c != $track) 
		    {
		      print STDERR "\n\nWARNING TRACK $track ON FILE $f DOES NOT CORRESPOND WITH ITS CAGE $c\n\n "
		    }
		}
	      
	      elsif ($line =~ /^TRACK INFORMATION/)
		{
		  print STDERR "\n-- END TRACK: $track --\n";		  
		  return ($F, $LineN, %$H_dataR);
		}
	      
	      elsif ($line =~  /(([\w|&]+\s*)+):(.*)/ | $line =~ /^Sample/ | $line =~ /^Sample/) 
		{
		  next;
		}

	      else 
		{
		  #print STDERR "\n\nWARNING:\nLine ---- $line---- \nin file: $f do not have a recognizable format\n\n";
		}
	    }
	  
	  close ($F);
	  	  
	  return ($F, $LineN, %$H_dataR);
	}

sub act2parse_line
	  {
	    my $file = shift;#print STDERR "file inside function  $file\n";#del
	    my $line = shift;#print STDERR "line inside function  $line\n";#del	    
	    my $sTime = shift;#print STDERR "time inside function  $sTime\n";#del  

	    my @ary_line;
	    my ($time, $lineN);
	    my %dataline;
	    
	    if ($line)
	      {
		#Annotation in act file is 1.000,32, first point changed for nothing, then comma by a point
		#print STDERR "line is $line\n";#del
		$line =~ s/\.//g; 
		#print STDERR "line2 is $line\n";#del
		$line =~ s/\,/./g;
		#print STDERR "line3 is $line\n";#del
			
		@ary_line = split (/\s+/, $line);
		$time = $ary_line[1];
		
		if ($time =~ /(\d+)\.00/) 
		  { 		    
		    $time = $1;
		    $dataline{'Sample'} = $ary_line[0];
		    $dataline{'Time'} = $sTime + $time;
		    $dataline{'X'} = $ary_line[2];
		    $dataline{'Y'} = $ary_line[3];
		  }
					      
		return (\%dataline);
	      }
	  }
