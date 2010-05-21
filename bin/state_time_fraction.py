# PheCom Data Joining Tool 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>


import sys
from sys import *
import string
import time
import os


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<2):
    # Not enough arguments
    sys.stderr.write("\nCalculates the tiem fraction spent in each state.\n")
    sys.stderr.write("Usage:\t state_time_fraction aligned_file\n" % arg[0])
    sys.stderr.write("where:\n'aligned_file' contains the choc/chow information + decoding data\n")  
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Aligner:
  ''' Aligns files for better decoding analysis '''

  def __init__(self,file_list):
    # Class Constructor
    self.file_list=file_list
    # Store read lines
    self.line1=''
    self.line2=''
    # Open all files in file_list
    try:
      self.OpenFile(file_list)
    except:
      sys.stderr.write("Files alignment aborted.\n")
      raise ValueError()
    
  def OpenFile(self,file_list):
    ''' Open files '''
    self.handles=[]  # Stores file handles of filenames provided
    for filename in file_list:
      # Open .mtx file
      if (filename.endswith('.alg')):
        try: 
          self.handles.append(open(filename,'r'))
        except: 
          sys.stderr.write("Unable to open %s" % filename)
          raise ValueError()
      else :
         sys.stderr.write("Error: .mtx/.pth file expected!\n")
         raise ValueError()

    # Open Aligned Output File
    try:
        self.handle_out=open(file_list[0][:-4]+'.frc', 'w') # Create/Open the file
    except:
        sys.stderr.write("Unable create alignment data file\n")
        raise ValueError()
    
       
  def GetFileInfo(self):
    ''' Get information from one fo the files.'''
    self.FileInfo={}
   
    
    self.line1=self.handles[0].readline()
    self.FileInfo['Header']=self.line1     # Get File Header
    self.line1=self.handles[0].readline()
    self.FileInfo['StartDate']=self.line1  # Get Start Date & time
        
  
  def WriteHeader(self):
    ''' Write header of joined file'''
    # Since Data is same type (already checked), copy header and cages distribution from first file
    self.handle_out.write(self.FileInfo['Header'])   # Main header
    # Write Start times
    self.handle_out.write(self.FileInfo['StartDate']) # Start date 
        
  
  
  def Align(self): 
    ''' Aligns intervals,bins and decoding '''
    # self.handle[0]:increment_file , self.handle[1]:bin_file,self.handle[2]: decoding_file
    # Bin file will be the one to control alignment end
   
    self.time_counter=0
    self.interval_counter_list={}
    self.time_list={}
    self.interval_counter=0
    self.state='None'
    last_cage='None'
    # Write Header in output file
    self.line1=self.handles[0].readline()
    while (self.line1.find("-")==-1):   # Sequence Header Eg. C1-
      self.line1=self.handles[0].readline()
    while (self.line1.find('END')==-1):

      if(self.line1.find("-")!=-1):
        print self.line1
        self.cage=self.line1.split()
        if last_cage !='None':
            self.time_list[last_cage].append(self.time_counter)
            self.interval_counter_list[last_cage].append(self.interval_counter)
        if self.cage[0]!= last_cage:
          '''if last_cage !='None':
            self.time_list[last_cage].append(self.time_counter)'''
          self.time_list[self.cage[0]]=[]
          self.interval_counter_list[self.cage[0]]=[]
          last_cage=self.cage[0]
        
        self.state='None' 
        self.interval_counter=0
        self.time_counter=0
        # Get Sequence
        self.line1=self.handles[0].readline()
        self.line2=self.handles[0].readline()
        
      else:
        self.line2=self.handles[0].readline()

      self.CountFraction()

      self.line1=self.handles[0].readline()
    self.time_list[self.cage[0]].append(self.time_counter)
    self.interval_counter_list[self.cage[0]].append(self.interval_counter)
    print self.time_list
    print self.interval_counter_list

  def CountFraction(self):
    ''' Join Temporal files'''
    self.line1=self.line1.split()
    self.line2=self.line2.split()
    for i in range(len(self.line1)):
      if self.line2[i]==self.state:
        self.time_counter+=int(self.line1[i])
        self.interval_counter+=1
      else:
        self.time_list[self.cage[0]].append(self.time_counter)
        self.time_counter=int(self.line1[i])
        self.interval_counter_list[self.cage[0]].append(self.interval_counter)
        self.interval_counter=1
        self.state=self.line2[i]
      line='state '+ self.state+', timecounter %d' %(self.time_counter)
      print line
    
    
    
  def CalculateFraction(self): 
    ''' Aligns intervals,bins and decoding '''
    # self.handle[0]:increment_file , self.handle[1]:bin_file,self.handle[2]: decoding_file
    # Bin file will be the one to control alignment end
    last_cage='None'
    self.sequence_choc0=''
    self.sequence_chow0=''
    self.sequence_choc1=''
    self.sequence_chow1=''
    # Write Header in output file
    self.WriteHeader()
    for key in self.time_list.keys():
      self.handle_out.write(key+'\n')
      suma=0
      for interval in self.time_list[key]:
        suma+=interval
      #print suma
      for i in range(len(self.time_list[key])):
         #print i
         if self.time_list[key][i]!=0:
           interval=self.time_list[key][i]
           fraction=(float(interval)/suma)*100
           fr='%.2f ' %fraction
           seq=fr*self.interval_counter_list[key][i]
           #print seq
           self.handle_out.write(seq)
      self.handle_out.write('\n')  
    self.handle_out.write('\n')
    for key in self.interval_counter_list:
      self.handle_out.write(key+'\n')
      for interval in self.interval_counter_list[key]:
        if interval!=0:
          fr='%.d ' %interval
          self.handle_out.write(fr)
      self.handle_out.write('\n')
    self.handle_out.write('\n')
    for key in self.time_list:
      self.handle_out.write(key+'\n')
      for interval in self.time_list[key]:
        if interval!=0:
          fraction=(float(interval)/suma)*100
          fr='%.2f ' %fraction
          self.handle_out.write(fr)
      self.handle_out.write('\n')

  
  def CreateSequence(self):
    ''' Join Temporal files'''
  
    
        
    sub_seq_choc='%.2f' %choc
    sub_seq_chow='%.2f' %chow
  
    print choc
    print sub_seq_choc
    if (new_cage==1):
      if state=='0':
        sub_seq_choc0=(sub_seq_choc+' ')*(suma+1)
        sub_seq_chow0=(sub_seq_chow+' ')*(suma+1)
        sub_seq_choc1=('0 ')*(suma+1)
        sub_seq_chow1=('0 ')*(suma+1)
      else:
        sub_seq_choc1=(sub_seq_choc+' ')*(suma+1)
        sub_seq_chow1=(sub_seq_chow+' ')*(suma+1)
        sub_seq_choc0=('0 ')*(suma+1)
        sub_seq_chow0=('0 ')*(suma+1)

    else:
      if state=='0':
        sub_seq_choc0=(sub_seq_choc+' ')*suma
        sub_seq_chow0=(sub_seq_chow+' ')*suma
        sub_seq_choc1=('0 ')*suma
        sub_seq_chow1=('0 ')*suma
      else:
        sub_seq_choc1=(sub_seq_choc+' ')*suma
        sub_seq_chow1=(sub_seq_chow+' ')*suma
        sub_seq_choc0=('0 ')*suma
        sub_seq_chow0=('0 ')*suma
    
    self.sequence_choc0+=sub_seq_choc0
    self.sequence_chow0+=sub_seq_chow0
    self.sequence_choc1+=sub_seq_choc1
    self.sequence_chow1+=sub_seq_chow1  





  
  def AlignFiles(self):
    '''Reads .jnd files and joins data in a single file'''
    
    # GetFileInfo
    self.GetFileInfo ()
    # Align Files
    self.Align()
    self.CalculateFraction()
    
        
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)
  
  # Start Joiner Object
  try:
    ToAlign=Aligner(argv[1:])
  except ValueError:
    sys.stderr.write( "Files Alignment aborted.\n" )
    return
  
  # Join Files
  ToAlign.AlignFiles()

 
if __name__=="__main__":
  main()



