# PheCom Calculates interval frequences
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

'''
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
    sys.stderr.write("\nInterval statistics. Calculates interval frequences.\n")
    sys.stderr.write("Usage:\t python %s input_file1 input_file2 ... input_fileN\n" % arg[0])
    sys.stderr.write("where:\n'input_fileX' is an interval .jnd file\n")  
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Calculator:
  ''' Joins provided data files in a single file '''

  def __init__(self,file_list):
    # Class Constructor
    
    # Store Files Name for further use 
    self.file_list=file_list
    self.counter={}
    self.dispenser=[]
    self.min=1000
    self.max=0
    self.disp=''
       
    # Open all files in file_list
    try:
      self.OpenFile(file_list)
    except:
      sys.stderr.write("Data Files join aborted.\n")
      raise ValueError()

        
    
  def OpenFile(self,file_list):
    ''' Open files '''
    self.handles=[]  # Stores file handles of filenames provided
    for filename in file_list:
      # Open .mtx file
      if (filename.endswith('.jnd')):
        try: 
          self.handles.append(open(filename,'r'))
        except: 
          sys.stderr.write("Unable to open %s" % filename)
          raise ValueError()
      else :
         sys.stderr.write("Error: .jnd file expected!\n")
         raise ValueError()
    #print self.handles

  def OpenFileOut(self,filename):
    ''' Open files '''
        
    # Open output data (.hmm) file
    try: 
      self.handle_out=open(filename,'w')
    except: 
      sys.stderr.write("Unable to open ouput statistics file")
      raise ValueError()    
  

  def GetTrainSeq(self,week):
    ''' Obtains new training sequence from file '''
    #print self.handles[week]
    line = self.handles[week].readline()
    print line
    if (line!=''):
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handles[week].readline()
        print line 
      disp=line.split()
      self.disp=disp[0]
      print disp
      if week==0:
        self.dispenser.append(disp[0])
      self.counter[week][disp[0]]={}
      keys=self.counter[week].keys()
      #print keys
      # Get Training Sequence
      line = self.handles[week].readline()  
      print line
      train_seq=line.split()
      #print 'to train seq'
      #print train_seq
      return train_seq
    else:
      return ''


  def CalculateFreq(self,week,dispenser,seq):
   ''' Calculates Frequencies'''
   for interv in seq:
     #print interv
     if self.counter[week][dispenser].has_key(interv):
       self.counter[week][dispenser][interv]+=1
     else:
       self.counter[week][dispenser][interv]=1
     self.GetMin(interv)
     self.GetMax(interv)


  def GetMin(self,interv):
   ''' Finds the minimum interval'''
   interv=int(interv)
   if interv < self.min:
     self.min=interv

  def GetMax(self,interv):
   ''' Finds the minimum interval'''
   interv=int(interv)
   if interv > self.max:
     self.max=interv


  def Statistics(self):
    '''Reads .jnd files and joins data in a single file'''
    #print len(self.handles)
    for i in range(len(self.handles)):
      #print 'week'
      #print i
      self.counter[i]={} 
      #print self.counter
      seq=self.GetTrainSeq(i)
      while (seq!=''):
        #print 'dispenser'
        #print self.disp
        #print seq
        self.CalculateFreq(i,self.disp,seq)
        seq=self.GetTrainSeq(i)
      #print 'outwhile'
    #print self.min
    #print self.max
    self.SaveCounts()



  def SaveCounts(self):
   ''' Save Results in a file '''
  
   # Write values
   for i in range(len(self.handles)):
     week=i+1
     week='%d' % week
     for disp in self.counter[i].keys():
       # Open all files in file_list
       try:
         self.OpenFileOut('interval_dist_'+week+'_'+disp+'.txt')
       except:
         sys.stderr.write("Data Files join aborted.\n")
         raise ValueError() 
       # Write header
       line='Interval Frequency\n'
       self.handle_out.write(line)
       for interv in range(self.min,self.max+1):
          interv='%d' %interv
          if self.counter[i][disp].has_key(interv):
            count=self.counter[i][disp][interv]
          else:
            count=0
          count='%d' %count
          line=interv+' '+count+'\n'
          self.handle_out.write(line)
       self.handle_out.close() 
      
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Calculator Object
  try:
    ToCalc=Calculator(argv[1:])
  except ValueError:
    sys.stderr.write( "Files Joining aborted.\n" )
    return

  # Join Files
  ToCalc.Statistics()

 
if __name__=="__main__":
  main()






     
