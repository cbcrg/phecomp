# PheCom Data Interfeed Maximum Length Finder
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Interfeed Maximum Length Finder
    Usage:
          findinterfeed path_file
    where:
         'path_file' is a .pth file having the sequence labelled with the predicted path

'''   

import sys
from sys import *
import string
import ghmm
from ghmm import *


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<2):
    # Not enough arguments
    sys.stderr.write("\nInterfeed Maximum Length Finder.\n")
    sys.stderr.write("Usage:\t python %s path_file\n" % arg[0])
    sys.stderr.write("where:\n") 
    sys.stderr.write("'path_file' is a .pth file having the sequence labelled with the predicted path\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class InterfeedFinder:
  ''' Finds the interfeed with maximum length '''

  def __init__(self,file_list):
    # Class Constructor
    
       
    # Open all files in file_list
    try:
      self.OpenFile(file_list)
    except: 
      sys.stderr.write("Open Files operation failed\n")
      raise ValueError()

    self.interval=0 
    self.position=0


  def OpenFile(self,file_list):
    ''' Open files '''
    self.handles=[]  # Stores file handles of filenames provided
    # Open Hmm parameters (.pth) file
    if (file_list[0].endswith('.pth')):
      try: 
        self.handles.append(open(file_list[0],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .pth file expected!\n")
      raise ValueError()
   
      
  
  def GetHeader(self,line):
    ''' Skips Path File Header'''
    self.header=''  # Stores File Header
    inloop=False
    # Get to starting data point
    while len(line)< 50:   # Observation Sequence Headerwhile 
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handles[0].readline() 
      inloop=True 
    return inloop, line


  def GetMaxInterval(self,interval,position):
    '''Keeps maximum Interfeed interval in a Meal'''
    if (interval> self.interval):
      self.interval=interval
      self.position=position


  def FindInterfeed(self):
    ''' Applies HMM to the observation sequence and obtains the corresponding sequence path sequence. The observation seq file may contain more than one sequence and HMM will be applied to all sequences in the file'''

    end=0
    m=0
    line = self.handles[0].readline()
    interval=0
    position=0
    while (end==0):
      # Get Data Header 
      new_seq,states=self.GetHeader(line)
      if new_seq==True:
        self.GetMaxInterval(interval,position)
        interval=0

      # Get Observation Sequence
      #states = self.handles[0].readline()
      states=states.split()
      for i in range(len(states)):
        if (states[i]=='M'):  # Meal
          self.GetMaxInterval(interval,position)
          interval=0
        elif (states[i]=='_' or states[i]=='=' or states[i]=='#'):  # Interfeed interval, for more than one meal interval type
          interval+=1
        position+=1
      # Get new line
      line = self.handles[0].readline()
      if (line=='' or line=='\n'):  # End of file reached
        end=1
    
    # Print the result:
    line='Interfeed maximum interval:\t%d' %self.interval
    print line
    line='Position:\t%d' %self.position
    
    # Close files
    for i in range(len(self.handles)):
      self.handles[i].close() 
   
       
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:             
    Interval=InterfeedFinder(argv[1:])
  except ValueError:
    sys.stderr.write( "HMM Train aborted.\n" )
    return

  # Join Files
  Interval.FindInterfeed()
  
 
if __name__=="__main__":
  main()






     
