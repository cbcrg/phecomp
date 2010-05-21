# Chow  vs Choc fraction x hour
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
    sys.stderr.write("\nCalculates Chow  vs Choc fraction x hour in 'limited access' decoded data.\n")
    sys.stderr.write("Usage:\t choc_chow_fraction aligned_file\n" % arg[0])
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
         sys.stderr.write("Error: .alg file expected!\n")
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
   
    self.counter={}
    self.counter['c']=0
    self.counter['w']=0
    self.state='None'
    self.seconds=0
    self.hour=0
    # Write Header in output file
    self.WriteHeader()
    self.line1=self.handles[0].readline()
    while (self.line1.find("-")==-1):   # Sequence Header Eg. C1-
      self.line1=self.handles[0].readline()
    while (self.line1.find('END')==-1):

      if(self.line1.find("-")!=-1):
        '''choc='%d ' %self.counter['c']
        chow='%d ' %self.counter['w']
        self.handle_out.write('Choc,'+self.state+':'+choc+'\n')
        self.handle_out.write('Chow,'+self.state+':'+chow+'\n') 
        self.state='None'
        self.counter['c']=0
        self.counter['w']=0'''
        self.handle_out.write(self.line1)
        self.hour=0
        # Get Sequence
        self.line1=self.handles[0].readline()
        self.line2=self.handles[0].readline()
        self.line3=self.handles[0].readline()
      else:
        self.line2=self.handles[0].readline()
        self.line3=self.handles[0].readline()
      
      self.CountFraction()

      self.line1=self.handles[0].readline()
   
    choc='%d ' %self.counter['c']
    chow='%d ' %self.counter['w']
    self.handle_out.write('Choc,'+self.state+':'+choc+'\n')
    self.handle_out.write('Chow,'+self.state+':'+chow+'\n')
    self.handle_out.write('END')  

  def CountFraction(self):
    ''' Join Temporal files'''
    
    print self.line1
    self.line1=self.line1.split()
    self.line2=self.line2.split()
    self.line3=self.line3.split() 
    self.state=self.line3[0]
    for i in range(len(self.line1)):
      interval=int(self.line1[i])
      self.seconds+=interval
      print self.seconds
      text='hour: %d' %self.hour
      if self.seconds>=3600:
        choc='%d ' %self.counter['c']
        chow='%d ' %self.counter['w']
        self.handle_out.write('Choc,'+self.state+':'+choc+'\n')
        self.handle_out.write('Chow,'+self.state+':'+chow+'\n')
        self.counter['c']=0
        self.counter['w']=0
        self.seconds-=3600
        print self.seconds
        self.hour+=1
        text='hour: %d' %self.hour
      
        print text
        self.state=self.line3[i]
        while self.seconds>=3600:
          self.handle_out.write('Choc,'+self.state+':0\n')
          self.handle_out.write('Chow,'+self.state+':0\n')
          self.counter['c']=0
          self.counter['w']=0
          self.seconds-=3600
          self.hour+=1
          text='hour: %d' %self.hour
          print text
          
          print self.seconds
        if self.line2[i]!='x':
          self.counter[self.line2[i]]+=1   
          self.seconds+=1  
      else:
        if self.line2[i]!='x':
          self.counter[self.line2[i]]+=1
          self.seconds+=1
    
  def CalculateFraction(self): 
    ''' Aligns intervals,bins and decoding '''
    # self.handle[0]:increment_file , self.handle[1]:bin_file,self.handle[2]: decoding_file
    # Bin file will be the one to control alignment end
    last_cage='None'
    self.sequence_choc0=''
    self.sequence_chow0=''
    self.sequence_choc1=''
    self.sequence_chow1=''
    self.sequence_choc2=''
    self.sequence_chow2=''
    
    # Write Header in output file
    self.WriteHeader()
    self.line1=self.handles[0].readline()
    while (self.line1.find("-")==-1):   # Sequence Header Eg. C1-
      self.line1=self.handles[0].readline()
    while (self.line1.find('END')==-1):

      if(self.line1.find("-")!=-1): # New sequence
        cage=self.line1.split()
        if last_cage!=cage[0]:
          last_cage=cage[0]  
          self.handle_out.write('Choc,0\n')
          self.handle_out.write(self.sequence_choc0+'\n')
          self.handle_out.write('Chow,0\n')
          self.handle_out.write(self.sequence_chow0+'\n')
          self.handle_out.write('Choc,1\n')
          self.handle_out.write(self.sequence_choc1+'\n')
          self.handle_out.write('Chow,1\n')
          self.handle_out.write(self.sequence_chow1+'\n')
          self.handle_out.write('Choc,2\n')
          self.handle_out.write(self.sequence_choc2+'\n')
          self.handle_out.write('Chow,2\n')
          self.handle_out.write(self.sequence_chow2+'\n')

          self.handle_out.write(self.line1)
          self.sequence_choc0=''
          self.sequence_chow0=''
          self.sequence_choc1=''
          self.sequence_chow1=''
          self.sequence_choc2=''
          self.sequence_chow2=''
        # Get Sequence
        self.line1=self.handles[0].readline()
        self.line2=self.handles[0].readline()
        self.CreateSequence(1)
      else:
        self.line2=self.handles[0].readline()
        self.CreateSequence(0)

      self.line1=self.handles[0].readline()
    self.handle_out.write('Choc,0\n')
    self.handle_out.write(self.sequence_choc0+'\n')
    self.handle_out.write('Chow,0\n')
    self.handle_out.write(self.sequence_chow0+'\n')
    self.handle_out.write('Choc,1\n')
    self.handle_out.write(self.sequence_choc1+'\n')
    self.handle_out.write('Chow,1\n')
    self.handle_out.write(self.sequence_chow1+'\n')
    self.handle_out.write('Choc,2\n')
    self.handle_out.write(self.sequence_choc2+'\n')
    self.handle_out.write('Chow,2\n')
    self.handle_out.write(self.sequence_chow2+'\n')  

  def CreateSequence(self, new_cage):
    ''' Join Temporal files'''

    print self.line1
    self.line1=self.line1.split()
    self.line1=self.line1[-1].split(':')
    print self.line2
    self.line2=self.line2.split()
    self.line2=self.line2[-1].split(':')
    print self.line1
    print self.line2
    state=self.line1[0][-1]
    print 'state'
    print state
    suma=int(self.line1[-1])+int(self.line2[-1])
    if(suma==0):
       choc=0.0 
       chow=0.0
    else:
      choc=float(self.line1[-1])/suma*100
      chow=float(self.line2[-1])/suma*100
        
    sub_seq_choc='%.2f' %choc
    sub_seq_chow='%.2f' %chow
  
    print choc
    print sub_seq_choc
    if state=='0':
      sub_seq_choc0=sub_seq_choc+' '
      sub_seq_chow0=sub_seq_chow+' '
      sub_seq_choc1='0 '
      sub_seq_chow1='0 '
      sub_seq_choc2='0 '
      sub_seq_chow2='0 '
    elif state=='1':
      sub_seq_choc1=sub_seq_choc+' '
      sub_seq_chow1=sub_seq_chow+' '
      sub_seq_choc0='0 '
      sub_seq_chow0='0 '
      sub_seq_choc2='0 '
      sub_seq_chow2='0 '
    else:
      sub_seq_choc0='0 '
      sub_seq_chow0='0 '
      sub_seq_choc1='0 '
      sub_seq_chow1='0 '
      sub_seq_choc2=sub_seq_choc+' '
      sub_seq_chow2=sub_seq_chow+' '
    
    self.sequence_choc0+=sub_seq_choc0
    self.sequence_chow0+=sub_seq_chow0
    self.sequence_choc1+=sub_seq_choc1
    self.sequence_chow1+=sub_seq_chow1
    self.sequence_choc2+=sub_seq_choc2
    self.sequence_chow2+=sub_seq_chow2

  def AlignFiles(self):
    '''Reads .jnd files and joins data in a single file'''
    
    # GetFileInfo
    self.GetFileInfo ()
    # Align Files
    self.Align()
    self.handles[0].close() 
    self.handle_out.close()
    try: 
      self.handles[0]=open(self.file_list[0][:-4]+'.frc','r')
    except: 
      sys.stderr.write("Unable to open file")
      raise ValueError()
    try: 
      self.handle_out=open(self.file_list[0][:-4]+'_seq.frc','w')
    except: 
      sys.stderr.write("Unable to open file")
      raise ValueError()
    # GetFileInfo
    self.GetFileInfo ()
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



