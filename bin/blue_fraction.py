# Calculates the fraction of the "blue state" 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Gets the states fraction per cage
    Usage:
          blue_fraction posterior_decoding_file
    where:
       'posterior_decoding_file' is a .pdg with the % probabilities of each state in posterior decoding
       
'''   

import sys
from sys import *
import string
sys.path.append('/home/ifernan/analysis_soft')


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<2):
    # Not enough arguments
    sys.stderr.write("\nGets the states fraction per Pehcomp cage.\n")
    sys.stderr.write("Usage:\t python %s posterior_decoding_file\n" % arg[0])
    sys.stderr.write("where:\n 'posterior_decoding_file' is a .pdg with the % probabilities of each state in posterior decoding\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Calculator:
  ''' Calculates the fraction of states '''

  def __init__(self,filename):
    # Class Constructor
    
       
    # Open all files in file_list
    try:
      self.OpenFile(filename)
    except: 
      sys.stderr.write("Open Files operation failed\n")
      raise ValueError()
    

  def OpenFile(self,filename):
    ''' Open files '''
   
    # Open file
    if filename.endswith('.pdg'):
      try: 
        self.handle=open(filename,'r')
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .pdg file expected!\n")
      raise ValueError()
    # Open output data (.pdg) file
    try: 
      self.handleout=open(filename[:-4]+'_fraction.pdg','w')
    except: 
      sys.stderr.write("Unable to open fraction ouput file")
      raise ValueError()
     
  
  def Ascii2Float(self,line):
    ''' Convert Ascii data into Float '''
    
    values=line.split()
    for i in range(len(values)):
      values[i]=float(values[i])
    return values

  
  def GetHeader(self,line):
    ''' Saves Observation File Header'''
    self.header=''  # Stores File Header

    # Get to starting data point
    while (line.find("-")==-1 and line.find("State")==-1):   # Observation Sequence Header
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handle.readline() 
    self.header=self.header+line 
    self.handleout.write(self.header)
    #p=[]
    #self.paths.append(p)


  def GetHeader(self,line):
    ''' Saves Observation File Header'''
    self.header=''  # Stores File Header

    # Get to starting data point
    while (line.find("-")==-1):   # Observation Sequence Header
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handle.readline() 
    self.header=self.header+line 
    self.handleout.write(self.header)
    
  def GetCalc(self):
    '''Calculates state fractions'''
    self.header=''  # Stores File Header
   
    line = self.handle.readline() 
    # Get to starting data point
    while line.find("-")==-1:   # Observation Sequence Header
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handle.readline() 
    self.cage=line.split()
    self.cage=self.cage[0]
    self.header=self.header+line 
    self.handleout.write(self.header)
    line = self.handle.readline()    
    self.add={}
    self.length={}
    self.state=''
    while line!='':
      #self.GetHeader(line)
      if line.find("-")!=-1: # Observation Sequence Header
        cage=line.split()
        cage=cage[0]
        if cage!=self.cage :
          self.Fraction() 
          self.handleout.write(line)
          self.cage=cage
        line = self.handle.readline()  
      print line
      if line.find("State")!=-1:
        self.state=line
        line = self.handle.readline()
      seq=self.Ascii2Float(line)
      self.Addition(seq)
      line = self.handle.readline()
     
    self.Fraction()
    self.handle.close()

  
  def Addition(self,seq):
    ''' Calculates the fraction of each state x cage '''
    if self.add.has_key(self.state)==False:
      self.add[self.state]=0.0
      self.length[self.state]=0
    for value in seq:
      self.add[self.state]+=value
    self.length[self.state]+=len(seq)
    
  def Fraction(self):
    ''' Calculates the fraction of each state x cage '''
    for key in self.add.keys():
      if self.length[key]!=0:
        fraction=self.add[key]/self.length[key]
        fraction*=100 
        printvalue='%.2f' %fraction
        self.handleout.write(key+':'+printvalue+'\n') 
      self.length[key]=0
      self.add[key]=0.0
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:             
    Calc=Calculator(argv[1])
  except ValueError:
    sys.stderr.write( "Calculation Aborted.\n" )
    return

  # Join Files
  Calc.GetCalc()
  
 
if __name__=="__main__":
  main()






     
