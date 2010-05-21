# PheCom Data HMM Path Finder using Posterior Decoding
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' HMM Path Finder using PheCom Data using Posterior decoding. Returns the path sequence corresponding to the observation data sequence provided and the probability for each state
    Usage:
          hmmpath_posterior params_file observation_file
    where:
       'params_file' is a .hmm/.par file having HMM parammeters
       'observation_file' is a .jnd file having observation sequences for obtaining HMM path

'''   

import sys
from sys import *
import string
sys.path.append('/home/ifernan/analysis_soft')
import PosteriorDecoder
from PosteriorDecoder import *


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nHMM Path Finder using PheCom Data using Posterior decoding. Returns the path sequence corresponding to the observation data sequence provided.\n")
    sys.stderr.write("Usage:\t python %s params_file observation_file\n" % arg[0])
    sys.stderr.write("where:\n'params_file' is a .hmm/.par file having HMM parammeters\n") 
    sys.stderr.write("'observation_file' is a .jnd file having observation sequences for obtaining HMM path\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class PathFinder:
  ''' Finds the hidden path of stated given an observation sequence '''

  def __init__(self,file_list):
    # Class Constructor
    
       
    # Open all files in file_list
    try:
      self.OpenFile(file_list)
    except: 
      sys.stderr.write("Open Files operation failed\n")
      raise ValueError()
    

  def OpenFile(self,file_list):
    ''' Open files '''
    self.handles=[]  # Stores file handles of filenames provided
    self.handle_out1=[]
    self.handle_out2=[]
    # Open Hmm parameters (.hmm) file
    if (file_list[0].endswith('.hmm') or file_list[0].endswith('.par')):
      try: 
        self.handles.append(open(file_list[0],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .hmm/.par file expected!\n")
      raise ValueError()
    # Open Train data (.jnd) file
    if (file_list[1].endswith('.jnd')):
      try: 
        self.handles.append(open(file_list[1],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .jnd file expected!\n")
      raise ValueError()
    # Open output data (.pdg) file
    try: 
      self.handles.append(open(file_list[1][:-4]+'.pdg','w'))
    except: 
      sys.stderr.write("Unable to open states path ouput file")
      raise ValueError()
    # Open output data (.pdg) file
    try: 
      self.handles.append(open(file_list[1][:-4]+'_posterior.pth','w'))
    except: 
      sys.stderr.write("Unable to open states path ouput file")
      raise ValueError()
    # SC
    index=['1','3','5','7','9','11']
    # CD
    #index=['2','4','6','8','10','12']
    for i in range(6):
      self.handle_out1.append(open(file_list[1][:-4]+'_c'+index[i]+'.pdg','w'))
      self.handle_out2.append(open(file_list[1][:-4]+'_posterior_c'+index[i]+'.pth','w'))
     
  
  def Ascii2Float(self,line):
    ''' Convert Ascii data into Float '''
    
    values=line.split()
    for i in range(len(values)):
      values[i]=float(values[i])
    return values


  def GetParam(self):
    ''' Gets Parameters from .par file
    Parameter appear in the following order:
	A1	A2...	AN  -> Header indicating that next lines provide transition prob. Number of columns = Number of States 
	0.3	0.7... 0.0  -> Transition probabilities of 1st state to all all states in the model 
        ...     ...    ... 
	0.7	0.3... 0.0  -> Transition probabilities of Nth state to all all states in the model 
	E11	E12	-> Header indicating the Emission probabilities in the 1st state. Number of columns = Number of symbols
	0.7	0.3	-> Values of the emission probabilities in the 1st state
        ...	...
     	EN1	EN2	-> Header indicating the Emission probabilities in the 1st state. Number of columns = Number of symbols
	0.3	0.7	-> Values of the emission probabilities in the 1st state
	PI		        -> Header indicating the initial state distribution probability
	0.5	0.5... 0.0	-> Values for the initial state distribution probability. Number of columns = Number of States 
	ALPH		-> Header indicatin the list of possible symbols to be emmitted
	0	1	-> List of possible symbols to be emitted'''

    self.e={}  # emission probabilities
    self.a={}  # transition probabilities
    #self.states={}
    #self.symbols={}
    
    # Look for Transition Probabilities
    line = self.handles[0].readline()  
    while (line.find("A")==-1):   # Transition Probabilities Header
      line = self.handles[0].readline()    
    
    states=line.split()  # Get the number of states
    statesnbr=len(states) 

    # Initialize Counters
    for state in range(0,statesnbr): # for state in range(0,self.statesnbr+2):
      state='%d'%state
      self.a[state]={}
      self.e[state]={}
      for newstate in range(0,statesnbr): #for newstate in range(0,self.statesnbr+2):
        newstate='%d'%newstate
        self.a[state][newstate]=0
        self.e[state]={}
      

    # Store Transition Probabilities 
    i=0
    state='%d' %i
    line = self.handles[0].readline() 
    while (line.find("E")==-1):   # Emission Probabilities Header
      prob=line.split()
      for j in range(0,statesnbr):
        newstate='%d' %j
        self.a[state][newstate]=float(prob[j])
      line = self.handles[0].readline()
      i+=1
      state='%d' %i

    i=0
    state='%d' %i
    # Store Emission Probabilities
    symbols=line.split()  # Get the number of symbols
    symbolsnbr=len(symbols)
    line = self.handles[0].readline() 
    while (line.find("ALPH")==-1):   # Initial state distribution probability
      if(line.find("E")!=-1):  # Emission Probabilities Header 
        pass
      else:
        prob=line.split()
        for j in range(1,symbolsnbr+1): 
          #symbol='%d' %j
          self.e[state][j]=float(prob[j-1])
        i+=1
        state='%d' %i
      line = self.handles[0].readline()
      

    line = self.handles[0].readline()  
    symbols=line.split()
    
    # Update self.e with real symbol names
    i=0
    state='%d' %i
    for i in range(0,statesnbr):
      state='%d' %i
      for j in range(1,symbolsnbr+1):
        #symbol='%d'%j
        value=self.e[state].pop(j)
        self.e[state][symbols[j-1]]=value
      
    
    # Store the Labels of the states
    line = self.handles[0].readline()  
    while (line.find("STATES")==-1):   # List of labels
      line = self.handles[0].readline()       
    line = self.handles[0].readline() 
    self.states=line.split()
    
    self.handles[0].close()
   
 
  def GetHeader(self,line):
    ''' Saves Observation File Header'''
    self.header=''  # Stores File Header
    # Get to starting data point
    while (line.find("-")==-1):   # Observation Sequence Header
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handles[1].readline() 
    print line
    self.header=self.header+line 
    self.handles[2].write(self.header)
    self.handles[3].write(self.header)
    if self.first==True:
      self.first=False
      self.cage=line.split()
      self.cage=self.cage[0]
    cage=line.split()
    cage=cage[0]
    if cage!=self.cage:
      self.cage=cage
      self.cage_index+=1

    #p=[]
    #self.paths.append(p)


  def GetPath(self):
    '''Obtains hidden states sequence from an observation sequence, applying HMM provided. Stores the states sequence in .pth file'''
    
    # Get HMM Parameters from file
    self.GetParam() 
    self.first=True
    self.cage='None'
    # Create the decoder
    decoder=PosteriorDecoder(self.a,self.e)  
    self.cage_index=0
    # Calculate Posterior problabilities
    line = self.handles[1].readline()
    while line.find('SYMBOLS')==-1:
      self.GetHeader(line)
      line = self.handles[1].readline()
      decode_seq=line.split()
      length=len(decode_seq)
      probabilities=decoder.Decode(decode_seq)
      self.SaveProbabilities(probabilities,length)
      line = self.handles[1].readline()
    self.handles[1].close()

 
  def SaveProbabilities(self,probabilities,length):
    ''' Save States Path'''
    line=''
    print self.cage_index
    states=probabilities.keys()
    for state in states:
      for i in range(length):
        value='%.6f' %probabilities[state][i]
        line+=value+' '
      self.handles[2].write('State'+state+'\n') 
      self.handles[2].write(line+'\n') 
      self.handle_out1[self.cage_index].write('State'+state+'\n') 
      self.handle_out1[self.cage_index].write(line+'\n') 
      line=''
    line=''

    for i in range(length):
      max_prob=0.0
      step=''      
      for state in states:
        if probabilities[state][i] > max_prob:
          max_prob=probabilities[state][i]
          step=state
      line+=step+' '
    self.handle_out2[self.cage_index].write(line) 
    self.handles[3].write(line+'\n')
    
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:             
    Path=PathFinder(argv[1:])
  except ValueError:
    sys.stderr.write( "HMM Train aborted.\n" )
    return

  # Join Files
  Path.GetPath()
  
 
if __name__=="__main__":
  main()






     
