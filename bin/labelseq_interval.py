# PheCom Data HMM Trainer 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Labels the training sequence given the maximum interfeed interval
    given the training sequences. Creates an output file storing the states labelling
    Usage:
          labelseq max_interfeed train_file
    where:
         'train_file' is a .jnd file having train sequences for HMM Model
         'max_interfeed' is maximum interfeed interval to consider 2 eating events in a meal
         
'''   

import sys
from sys import *
import string
import math
from math import log



def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments.Calculates probabilities automatically for a range of interfeed interval
    given the training sequences '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nLabels the training sequence given the maximum interfeed interval.\n")
    sys.stderr.write("Usage:\t python %s max_interfeed train_file\n" % arg[0])
    sys.stderr.write("where:\n") 
    sys.stderr.write("'train_file' is a .jnd file having train sequences for HMM Model\n") 
    sys.stderr.write("'max_interfeed' is maximum interfeed interval to consider 2 eating events in a meal\n")
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Labeller:
  ''' Perform statistincs with provided data'''

  def __init__(self,arg):
    # Class Constructor
         
    # Open all files in file_list
    try:
      self.OpenInputFile(arg[1])
    except: 
      sys.stderr.write("Open Files operation failed\n")
      raise ValueError()
    
    self.filename=arg[1]
    try:
      self.OpenOutputFile()
    except: 
      sys.stderr.write("Open Files operation failed\n")
      raise ValueError()
    self.interfeed=int(arg[0])
    self.path='' # Stores path 

   
   
    
  def OpenInputFile(self,filename):
    ''' Open Input file '''
      
    # Open Train data (.jnd) file
    if (filename.endswith('.jnd')):
      try: 
        self.handle=open(filename,'r')
      except: 
        sys.stderr.write("Unable to open %s\n" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .jnd file expected!\n")
      raise ValueError()
    
   
  def OpenOutputFile(self):
    ''' Open Output file '''
      
    # Open Output data (.lab) file
    try: 
      self.output=open(self.filename[:-4]+'.lab','w')
    except: 
      sys.stderr.write("Unable to open .sts file")
      raise ValueError()
  
  def GetStatesInRound(self):
    ''' Get frequencies of symbols in a given training sequence '''
  
    self.NoEatInterval=0  # Number of '0.00' from last eating event  ???
    self.transitions={}
    self.length=0
    # Get to the starting data point 
    line = self.handle.readline()
    while (line!='' and line!='\n'):
      self.param={}
      self.path=''
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        self.output.write(line)  # Copy the header  
        line = self.handle.readline() 
      self.output.write(line)  # Copy the header
      self.transitions['Old']='start'
      # Get Training Sequence
      line = self.handle.readline()
      seq=line.split()
      self.MealDetect(seq) # Detect Meal Events and calculate state labels
      #self.SaveProb()
      line = self.handle.readline()
            
  
  def GetStates(self):
    ''' Get frequencies of symbols in a given training sequence  for all specified intefeed  intervals'''
  
    self.GetStatesInRound()
    self.handle.close()  # Close file to start analysis for the next round
        
    

  def MealDetect(self,seq):
    ''' Detect Meal Events and calculate state labels'''
    
    NoIncrement=0  # Stores no increment frequencies
    OldIncrement='' # Stores old increment to be included in Meal/No Meal in the next incr. finding
    length= len(seq)
    self.length+=length  # Update total length
    # Follow the sequence
      
    for i in range(len(seq)):
      self.path=''
      '''print self.transitions['Old']
      print NoIncrement'''
      if int(seq[i])< self.interfeed+1:
        self.path+='I '
      else:
        self.path+='m '
       
      self.output.write(self.path)     
    self.output.write('\n')

  def LogXBaseN(self,x,n):
    '''Calculates the log of a number (x) in a given base (n) '''
    if (x==0):
      return -999
    else:
      return math.log(x,n)
   

  def SaveProb(self):
    ''' Save Probabilites '''
    
    self.output.write(self.path+'\n')
    

    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:             
    Prob=Labeller(argv[1:])
  except ValueError:
    sys.stderr.write( "State labels calculation aborted.\n" )
    return

  # Get Frequencies
  Prob.GetStates()
  
 
  
  
 
if __name__=="__main__":
  main()






     
