# Splits data into days 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>
''' Splits data into days (Customized for inital Developmental Phase Phecomp Data ->5 weeks) and calculates the day/night periods. Returns:
     - A daily file for the intervals
     - A daily file for the path
     - A dayly file for the day/night periods
     - A cage file for the intervals
     - A cage file for the path
     - A cage file for the day/night periods
    Usage:
          dayly intervals_file path_file
    where:
       'intervals_file' is a .jnd file having the data conveted to intervals
       'path_file' is a .pth file the corresponding states path for the intervals file

'''   
  

import sys
from sys import *
import string
import time
import os


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<2):
    # Not enough arguments
    sys.stderr.write("\nSplits data into days (Customized for inital Developmental Phase Phecomp Data ->5 weeks) and calculates the day/night periods. Returns:\n")
    sys.stderr.write("- A daily file for the intervals'\n'")
    sys.stderr.write("- A daily file for the path'\n'")
    sys.stderr.write("- A dayly file for the day/night periods'\n'")
    sys.stderr.write("- A cage file for the intervals'\n'")
    sys.stderr.write("- A cage file for the path'\n'")
    sys.stderr.write("- A cage file for the day/night periods'\n'")
    sys.stderr.write("Usage:\t python %s intervals_file path_file\n" % arg[0])
    sys.stderr.write("where:\n'intervals_file' is a .jnd file having the data conveted to intervals'\n")  
    sys.stderr.write("'path_file' is a .pth file the corresponding states path for the intervals file'\n")
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class DayConverter:
  ''' Joins provided data files in a single file '''

  def __init__(self,file_list):
    # Class Constructor
    
    # Store Files Name for further use 
    self.file_list=file_list
        
        
  def OpenFile(self,filenamelist):
    ''' Open files '''
    self.handles=[]
    # Open .mtx file
    if (filenamelist[0].endswith('.jnd')):
      try: 
        self.handles.append(open(filenamelist[0],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    if (filenamelist[1].endswith('.pth')):
      try:
        self.handles.append(open(filenamelist[1], 'r')) # Create/Open the file
      except:
        sys.stderr.write("Unable to open joined paht file\n")
        raise ValueError()
    
  def NewLine(self):
   '''Reads a new line in both input files '''
   lines=[]
   for i in range(len(self.handles)):
     lines.append(self.handles[i].readline())
   return lines

  def NewLine2(self):
   '''Reads a new line in both input files '''
   lines=[]
   lines.append(self.handles[0].readline())
   self.handles[1].readline()
   self.handles[1].readline()
   lines.append(self.handles[1].readline())
   return lines 

  def JoinTempFiles(self):
    ''' Join Temporal files. Only to be used if the files do not include the skipped data and gaps (for training!)'''

    duration=[]
    duration.append(602170)#20090302
    duration.append(344886)#20090309
    duration.append(455495)#20090313
    duration.append(402233)#20090317
    duration.append(167488)#20090323
    duration.append(421316)#20090325
    duration.append(691575)#20090330

    seconds=0
    st_day=1
    sp_day=1
    day=1
    '''daynight=[]
    dayelapsedtime=[]
    for i in range(6):
      daynight.append(1) # day=1, night=0
      dayelapsedtime.append(14795)   # 1st file starts at 12:06:35, day started at 08:00:00 -> 4h 6min 35sec already consumed (Mara's data)'''
    daynight=1
    dayelapsedtime=14795  
    seconds=14795 
    file_index=0
    cage_index=0
    self.handle_out1=[] # intervals x day
    self.handle_out2=[] # path x day
    self.handle_out3=[] # day_night per day
    self.handle_out4=[] # day_night per cage
    self.handle_out5=[] # path per cage
    self.handle_out6=[] # intervals per cage
    # Open Final Joined Data File
    for i in range(36):
      index='%d' %i
      try:
          self.handle_out1.append(open(self.file_list[0][:-4]+'_day'+index+'.jnd', 'w') )# Create/Open the file
      except:
          sys.stderr.write("Unable create joined data file\n")
          raise ValueError()
    
      # Open Final Joined Data File
      try:
          self.handle_out2.append(open(self.file_list[0][:-4]+'_bin_day'+index+'.pth', 'w'))# Create/Open the file
      except:
          sys.stderr.write("Unable create joined data file\n")
          raise ValueError()
      try:
          self.handle_out3.append(open(self.file_list[0][:-4]+'_day_night_Day'+index+'.jnd', 'w'))# Create/Open the file
      except:
          sys.stderr.write("Unable create joined data file\n")
          raise ValueError()

    for i in range(6):
      #SC
      #ndex=['1','3','5','7','9','11']
      #CD
      index=['2','4','6','8','10','12']
      try:
          self.handle_out4.append(open(self.file_list[0][:-4]+'_day_night_c'+index[i]+'.jnd', 'w') )# Create/Open the file
      except:
          sys.stderr.write("Unable create joined data file\n")
          raise ValueError()
      try:
          self.handle_out5.append(open(self.file_list[0][:-4]+'bin_c'+index[i]+'.pth', 'w') )# Create/Open the file
      except:
          sys.stderr.write("Unable create joined data file\n")
          raise ValueError()
      try:
          self.handle_out6.append(open(self.file_list[0][:-4]+'_int_c'+index[i]+'.jnd', 'w') )# Create/Open the file
      except:
          sys.stderr.write("Unable create joined data file\n")
          raise ValueError()

    # Open all files in file_list
    try:
      self.OpenFile(self.file_list)
    except:
      sys.stderr.write("Data Files join aborted.\n")
      raise ValueError()
    # Open all files in file_list
    
    lines=self.NewLine()
    line_w=[] 
    line_w.append('') #intervals
    line_w.append('') #path
    dayvalue=''
    dayline=''
    while lines[0].find('-')==-1:
      lines=self.NewLine()
    cage=lines[0].split()
    cage=cage[0]
    cage_line=[]
    cage_path=[]
    cage_interval=[]
    first=True
    for i in range(36):
      # initialize daily files
      self.handle_out1[i].write(lines[0])
      self.handle_out2[i].write(lines[0])
      self.handle_out3[i].write(lines[0])
    for i in range (6):
       # initialize cage data
       cage_line.append('')
       cage_path.append('')
       cage_interval.append('')

    while lines[0]!='':
      if (lines[0].find('-')!=-1):
        # check cage
        tmp_cage=lines[0].split()
        tmp_cage=tmp_cage[0]
        if tmp_cage==cage: # same cage
          # update time counters
          dayelapsedtime+=60
          seconds+=60
          if first==False:
            file_index+=1
          else:
            first=False
        else: # new cage
          # update cage, day index and store new cage name in daily files
          cage_index+=1
          day=1
          daynight=1
          cage=tmp_cage
          for i in range(36):
            self.handle_out1[i].write('\n'+cage+'\n')
            self.handle_out2[i].write('\n'+cage+'\n')
            self.handle_out3[i].write('\n'+cage+'\n')
          file_index=0
          seconds=60
          dayelapsedtime=60
        # lines=self.NewLine2() # viterbi decoding 
        lines=self.NewLine() # posterior decoding
      else:  
        # classify data into cage/day files
        intervals=lines[0].split()
        path=lines[1].split()
        for i in range(len(intervals)):
          #update time
          seconds+=(int(intervals[i])+1)
          dayelapsedtime+=(int(intervals[i])+1)
          # update data :intervals, path, day/night 
          cage_path[cage_index]+=path[i]+' ' # path values per cage
          cage_interval[cage_index]+=intervals[i]+' ' # intervals values per cage
          dayvalue=self.DayNight(daynight) # day/night value for the current interval
          cage_line[cage_index]+=dayvalue # day/night values per cage
          line_w[0]+=intervals[i]+' ' # intervals in the current day
          line_w[1]+=path[i]+' '      # path in the current day
          dayline+=dayvalue           # day/night in the current day
                  
          if dayelapsedtime >= 43200:  # 12h starting in day
            # Update day/night value
            while dayelapsedtime >=43200:
              daynight=self.DayNightToggle(daynight)
              dayelapsedtime-=43200
             
          if seconds >= 86400: # 24h
            # Save data into the current daily file 
            self.handle_out1[day-1].write(line_w[0]+'\n') # intervals x day# path x day
            self.handle_out2[day-1].write(line_w[1]+'\n') # path x day# day_night per day
            self.handle_out3[day-1].write(dayline+'\n')   # day_night per day
            line_w[0]=''
            line_w[1]=''
            dayline=''
            while seconds >=86400:
              day+=1
              seconds-=86400
        lines=self.NewLine()
   
    for i in range (6):
      # save cage values for path, interval and day/night
      self.handle_out4[i].write(cage_line[i]+'\n')   
      self.handle_out5[i].write(cage_path[i]+'\n')   
      self.handle_out6[i].write(cage_interval[i]+'\n')   

    self.CalculateStateDailyFraction(cage_line,cage_path)


  def CalculateStateDailyFraction(self,cage_line,cage_path):
    ''' Calculates the percentage of intervals in each state per day/night '''
    day_state1_counter=[]# day=1, night=0
    night_state1_counter=[]
    for i in range(6):
      day_state1_counter.append(0)
      night_state1_counter.append(0)  
      daynight=cage_line[i].split()
      state=cage_path[i].split() 
      day=0
      night=0
      print 'test lengths'
      print len(daynight)
      print len(state)
      for j in range(len(daynight)):
        if daynight[j]=='1':
          day+=1
          if state[j]=='2': #day,state=2->1, state=1->0
            day_state1_counter[i]+=1
        else:
          night+=1 
          if state[j]=='2': #night,state=2->1, state=1->0
            night_state1_counter[i]+=1
      value='%d' %day_state1_counter[i]
      self.handle_out4[i].write('State 1 counts during day: '+value+'\n') 
      value='%d'%day
      self.handle_out4[i].write('Total day counts: '+value+'\n') 
      value='%d' %night_state1_counter[i]
      self.handle_out4[i].write('State 1 counts during night: '+value+'\n')
      value='%d'%night
      self.handle_out4[i].write('Total night counts: '+value+'\n') 
      value=float(day_state1_counter[i])/day
      valuep='%.2f' %value
      self.handle_out4[i].write('State fraction during Day\n')   
      self.handle_out4[i].write('State 1: '+valuep+'\n') 
      value=1-value
      valuep='%.2f' %value
      self.handle_out4[i].write('State 0: '+valuep+'\n') 
      value=float(night_state1_counter[i])/night
      valuep='%.2f' %value
      self.handle_out4[i].write('State fraction during Night\n')   
      self.handle_out4[i].write('State 1: '+valuep+'\n') 
      value=1-value
      valuep='%.2f' %value
      self.handle_out4[i].write('State 0: '+valuep+'\n') 
 

  def DayNight(self,daynight):
    ''' Creates Day/Night sequences '''
    daynight='%d ' % daynight
    return daynight
 
  
  def DayNightToggle(self,day):
    '''Toggles from Day/Night'''
    if day==1 : #day
      return 0  # night
    else:   # night
      return 1 #day


  def Convert(self):
    '''Reads .mtx files and joins data in a single file'''
    
    # Join Temporal files
    self.JoinTempFiles()
        
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start DayConverter Object
  try:
    Daily=DayConverter(argv[1:])
  except ValueError:
    sys.stderr.write( "Files Joining aborted.\n" )
    return

  # Join Files
  Daily.Convert()       

 
if __name__=="__main__":
  main()



