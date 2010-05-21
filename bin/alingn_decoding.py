# Align Decoded Data Tool 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' PheCom Align Decoded Data Tool. Creates a single file appending the content of all increment, bin and decoging to facilitate analysis.
    Usage:
          align_decoding increment_file bin_file decoding_file
    where:
       'increment_file' is the file containig the increments (_int.mtx)
       'bin_file' is the file containing the increments translation into bins (bin.mtx)
       'decoding_file' is the file containing the decoding of the data (.pth)
   
'''   

import sys
from sys import *
import string
import time
import os


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nPheCom Align Decoded Data Tool. Creates a single file appending the content of all increment, bin and decoging to facilitat analysis.\n")
    sys.stderr.write("Usage:\t align_decoding increment_file bin_file decoding_file\n" % arg[0])
    sys.stderr.write("where:\n'increment_file' is the file containig the increments (_int.jnd)\n")  
    sys.stderr.write("'bin_file' is the file containing the increments translation into bins (bin.jnd)\n")
    sys.stderr.write("'decoding_file' is the file containing the decoding of the data (.pth)\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Aligner:
  ''' Aligns files for better decoding analysis '''

  def __init__(self,file_list):
    # Class Constructor
    
    # Store Files Name for further use 
    self.file_list=file_list
    # Store read lines
    self.line=[]
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
      if (filename.endswith('.jnd') or filename.endswith('.pth') ):
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
        self.handle_out=open(file_list[2][:-4]+'.alg', 'w') # Create/Open the file
    except:
        sys.stderr.write("Unable create alignment data file\n")
        raise ValueError()
    
       
  def GetFileInfo(self):
    ''' Get information from one fo the files.'''
    self.FileInfo={}
    # Init line
    for i in range(len(self.handles)):
      self.line.append('')

    self.NewLine()
    self.FileInfo['Header']=self.line[0]     # Get File Header
    self.NewLine()
    self.FileInfo['StartDate']=self.line[0]  # Get Start Date & time
        
  
  def WriteHeader(self):
    ''' Write header of joined file'''
    # Since Data is same type (already checked), copy header and cages distribution from first file
    self.handle_out.write(self.FileInfo['Header'])   # Main header
    # Write Start times
    self.handle_out.write(self.FileInfo['StartDate']) # Start date 
    
    
  def NewLine(self):
    ''' Read lines from the 3 input files '''
    for i in range(len(self.handles)):
      self.line[i]=self.handles[i].readline()

  
  def Align(self): 
    ''' Aligns intervals,bins and decoding '''
    # self.handle[0]:increment_file , self.handle[1]:bin_file,self.handle[2]: decoding_file
    # Bin file will be the one to control alignment end

    # Write Header in output file
    self.WriteHeader()

    self.NewLine()
    while (self.line[0]!=''): # End data reached
      while (self.line[1].find("-")==-1):   # Sequence Header Eg. C1-
        self.NewLine()
      #print line 
      self.handle_out.write(self.line[1]) # Increment 
      # Get Sequence
      self.NewLine()
      # Decoding file has two more lines to be read
      self.line[2]=self.handles[2].readline()
      self.line[2]=self.handles[2].readline()
      # Format data and save it into output file     
      self.FormatData()
      self.NewLine()

  def FormatData(self):
    ''' Join Temporal files'''
    elements=[]
    data_file_sec=[]
    time_gap=[]
    # Split elements in each line
    for i in range(len(self.line)):
      elements.append(self.line[i].split())
   
    day_length=86400 #number of seconds in a day
    acummulated=0

    # seconds in each data file
    data_file_sec.append(602230) #20090302
    data_file_sec.append(344946) #20090309
    data_file_sec.append(455555) #20090313
    data_file_sec.append(402293) #20090317
    data_file_sec.append(167548) #20090323
    data_file_sec.append(421376) #20090325
    data_file_sec.append(691635) #20090330
    # seconds between data files
    time_gap.append(2132)#20090302 to 20090309
    time_gap.append(3988)#20090309 to 20090313
    time_gap.append(2244)#20090313 to 20090317
    time_gap.append(864)#20090317 to 20090323
    time_gap.append(463)#20090323 to 20090325
    time_gap.append(5399)#20090325 to 20090330
    time_gap.append(0)#20090325 to 20090330
   
    seconds=0
    st=0
    
    '''for i in range(len(elements[0])): # increments 
      seconds+=int(elements[0][i])+1 
      acummulated+=int(elements[0][i])+1
      if seconds >= day_length:
        self.line[0]=string.join(elements[0][st:i],' ')
        self.line[1]=string.join(elements[1][st:i],' ')
        self.line[2]=string.join(elements[2][st:i],' ')
        seconds=0
      if acummulated-1 == data_file_sec[i]:
        # add time gap between data files
        seconds+=time_gap[i] '''
    # Format by in 40 columns
    st=0
    sp=40
    while (sp < len(elements[0])):  # All lines must be the same length. Then, just look at one
      self.line[0]=string.join(elements[0][st:sp],' ')
      self.line[1]=string.join(elements[1][st:sp],' ')
      self.line[2]=string.join(elements[2][st:sp],' ')
      st+=40
      sp+=40
      #Save data
      '''self.handle_out.write('Increment:\t'+self.line[0]+'\n') # Increment 
      self.handle_out.write('Bin:\t'+self.line[1]+'\n') # Bin 
      self.handle_out.write('Decoding:\t'+self.line[2]+'\n') # Decoding '''
      self.handle_out.write(self.line[0]+'\n') # Increment 
      self.handle_out.write(self.line[1]+'\n') # Bin 
      self.handle_out.write(self.line[2]+'\n') # Decoding 
    #Save the last samples 
    self.line[0]=string.join(elements[0][st:],' ')
    self.line[1]=string.join(elements[1][st:],' ')
    self.line[2]=string.join(elements[2][st:],' ')
    
    self.handle_out.write(self.line[0]+'\n') # Increment 
    self.handle_out.write(self.line[1]+'\n') # Bin 
    self.handle_out.write(self.line[2]+'\n') # Decoding 


  def AlignFiles(self):
    '''Reads .jnd files and joins data in a single file'''
    
    # GetFileInfo
    self.GetFileInfo ()
    
    # Align Files
    self.Align()

   
        
    
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



