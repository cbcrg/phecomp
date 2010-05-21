# PheCom Data HMM Trainer 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' HMM Trainer using PheCom Data. Returns new Hmm Model parameters saved in a .hmm file. Uses GHMM library
    Usage:
          hmmtrain params_file train_file
    where:
       'params_file' is a .par file having HMM default parammeters
       'train_file' is a .jnd file having train sequences for HMM Model

'''   

import sys
from sys import *
import string
import ghmm
from ghmm import *


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nHMM Trainer using PheCom Data. Returns new Hmm Model parameters saved in a .hmm file. Uses GHMM library\n")
    sys.stderr.write("Usage:\t python %s params_file train_file\n" % arg[0])
    sys.stderr.write("where:\n'params_file' is a .par file having HMM default parammeters\n") 
    sys.stderr.write("'train_file' is a .jnd file having train sequences for HMM Model\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Trainer:
  ''' Trains HMM with provided data'''

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
    # Open Hmm parameters (.par) file
    if (file_list[0].endswith('.par')):
      try: 
        self.handles.append(open(file_list[0],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .par file expected!\n")
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
    # Open output data (.hmm) file
    try: 
      self.handles.append(open(file_list[0][:-4]+'.hmm','w'))
    except: 
      sys.stderr.write("Unable to open ouput HMM parameters file")
      raise ValueError()
        
     
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

    self.A=[]  	# Stores Transition Probabilities
    self.E=[]  	# Stores Emission Probabilities
    self.PI=[]	 # Stores Initial State Distribution Probabilities
    self.ALPH=[]  # Stores the List of possible symbols to be emitted
    self.LABELS=[] # Stores the labels of the states

    # Look for Transition Probabilities
    line = self.handles[0].readline()  
    while (line.find("A")==-1):   # Transition Probabilities Header
      line = self.handles[0].readline()

    # Store Transition Probabilities 
    self.states=line.split()  # Get the number of states
    line = self.handles[0].readline()  
    while (line.find("E")==-1):   # Emission Probabilities Header
      self.A.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handles[0].readline()
    
    # Store Emission Probabilities
    self.symbols=line.split()  # Get the number of symbols
    line = self.handles[0].readline()  
    while (line.find("PI")==-1):   # Initial state distribution probability
      if(line.find("E")!=-1):  # Emission Probabilities Header 
        pass
      else:
        self.E.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handles[0].readline()

    # Store Initial state distribution probability
    line = self.handles[0].readline()
    self.PI=self.Ascii2Float(line) # Convert Ascii data into Float

    # Store the List of possible symbols to be emitted
    line = self.handles[0].readline()  
    while (line.find("ALPH")==-1):   # List of symbols
      line = self.handles[0].readline()   
    line = self.handles[0].readline() 
    self.sym_list=line.split()
    self.ALPH=Alphabet(self.sym_list)
     
    # Store the Labels of the states
    line = self.handles[0].readline()  
    while (line.find("LABELS")==-1):   # List of labels
      line = self.handles[0].readline()       
    line = self.handles[0].readline() 
    self.LABELS=line.split()

  def CreateDefaultHMM(self):
    ''' Creates the fist HMM model with the parameters given by .par file.'''

    # Get Parameters from file
    self.GetParam()
    
    # Create Default HMM
    self.hmm = HMMFromMatrices(self.ALPH, DiscreteDistribution(self.ALPH), self.A, self.E,self.PI)
       

  def TrainModel(self):
    ''' Trains HMM using Default model as a starting point and using data from the training data file '''

    # Get to starting data point
    line = self.handles[1].readline()
    if (line!='' and line!='\n'):
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handles[1].readline() 
      
      # Get Training Sequence
      line = self.handles[1].readline()  
      seq=line.split()
      train_seq=EmissionSequence(self.ALPH, seq)
   
      # Train HMM
      self.hmm.baumWelch(train_seq)
      self.TrainModel()
    else:
      pass
  
  def SaveHmmParam(self):
    ''' Save Hmm Parameters after Training '''
    header=''
    # Save Transition Probabilities
    
    for i in range(1,len(self.states)+1):
      header=header+'A%d\t' % i
    self.handles[2].write(header[:-1]+'\n')
       
    for i in range(len(self.states)):
      line=''
      for j in range(len(self.states)):
        line=line+'%f\t' % self.hmm.getTransition(i,j)
      self.handles[2].write(line[:-1]+'\n')

    # Save Emission Probabilities
    for i in range(1,len(self.states)+1):
      header=''
      for j in range(1,len(self.symbols)+1):
        header=header+'E%d%d\t' %(i,j)
      self.handles[2].write(header[:-1]+'\n')
      prob=self.hmm.getEmission(i-1)
      line=''
      for p in range(len(prob)):
        line=line+'%f\t' % prob[p]
      self.handles[2].write(line[:-1]+'\n')
    
    # Save Initial state distribution
    self.handles[2].write('PI\n')
    line=''    
    for i in range(len(self.states)):
      line=line+'%f\t' % self.hmm.getInitial(i)
    self.handles[2].write(line[:-1]+'\n')

    # Save Symbols List 
    self.handles[2].write('ALPH\n')
    line=''
    for s in self.sym_list:
      line=line+s+'\t'
    self.handles[2].write(line[:-1]+'\n')

    # Save States Labels 
    self.handles[2].write('LABELS\n')
    line=''
    for s in self.LABELS:
      line=line+s+'\t'
    self.handles[2].write(line[:-1]+'\n')
    

    # Close files
    for i in range(len(self.handles)):
      self.handles[i].close()


  def Train(self):
    '''Creates a default HMM and trains it with the data given. New HMM parameters are stored in a .hmm file'''
    
    # Create default HMM
    self.CreateDefaultHMM()
  
    # Train HMM
    self.TrainModel()
   
    # Save New HMM Parameters
    self.SaveHmmParam()
   
    
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:             
    ToTrain=Trainer(argv[1:])
  except ValueError:
    sys.stderr.write( "HMM Train aborted.\n" )
    return

  # Join Files
  ToTrain.Train()
  
 
if __name__=="__main__":
  main()






     
