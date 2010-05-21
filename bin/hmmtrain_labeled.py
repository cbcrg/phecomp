# PheCom Data HMM Trainer with labeled data
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' HMM Trainer using PheCom Data. Returns new Hmm Model parameters saved in a .hmm file
    Usage:
          hmmtrain params_file train_file
    where:
       'params_file' is a .par file having HMM default parammeters
       'train_file' is a .jnd file having train sequences for HMM Model

'''   

import sys
from sys import *
import string
sys.path.append('/home/ifernan/analysis_soft')
import BaumWelchTrainerLabeled
from BaumWelchTrainerLabeled import *


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<4):
    # Not enough arguments
    sys.stderr.write("\nHMM Trainer using PheCom Data. Returns new Hmm Model parameters saved in a .hmm file.\n")
    sys.stderr.write("Usage:\t python %s params_file train_file labels_file\n" % arg[0])
    sys.stderr.write("where:\n'params_file' is a .par file having HMM default parammeters\n") 
    sys.stderr.write("'train_file' is a .jnd file having train sequences for HMM Model\n") 
    sys.stderr.write("'labels_file' is a .lab file having the states label sequences for HMM Model\n") 
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
    # Open Labels data (.lab) file
    if (file_list[2].endswith('.lab')):
      try: 
        self.handles.append(open(file_list[2],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .lab file expected!\n")
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

    A=[]  	# Stores Transition Probabilities
    E=[]  	# Stores Emission Probabilities
    PI=[]	 # Stores Initial State Distribution Probabilities
    ALPH=[]  # Stores the List of possible symbols to be emitted
    LABELS=[] # Stores the labels of the states
    self.Hmm={}

    # Look for Transition Probabilities
    line = self.handles[0].readline()  
    while (line.find("A")==-1):   # Transition Probabilities Header
      line = self.handles[0].readline()

    # Store Transition Probabilities 
    self.states=line.split()  # Get the number of states
    line = self.handles[0].readline()  
    while (line.find("E")==-1):   # Emission Probabilities Header
      A.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handles[0].readline()
    
    # Store Emission Probabilities
    self.symbols=line.split()  # Get the number of symbols
    line = self.handles[0].readline()  
    while (line.find("PI")==-1):   # Initial state distribution probability
      if(line.find("E")!=-1):  # Emission Probabilities Header 
        pass
      else:
        E.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handles[0].readline()

    # Store Initial state distribution probability
    line = self.handles[0].readline()
    PI=self.Ascii2Float(line) # Convert Ascii data into Float

    # Store the List of possible symbols to be emitted
    line = self.handles[0].readline()  
    while (line.find("ALPH")==-1):   # List of symbols
      line = self.handles[0].readline()   
    line = self.handles[0].readline() 
    ALPH=line.split()
     
    # Store the Labels of the states
    line = self.handles[0].readline()  
    while (line.find("LABELS")==-1):   # List of labels
      line = self.handles[0].readline()       
    line = self.handles[0].readline() 
    LABELS=line.split()

    self.Hmm['A']=A
    self.Hmm['E']=E
    self.Hmm['PI']=PI
    self.Hmm['States']=LABELS
    self.Hmm['Symbols']=ALPH


  def CreateDefaultHMM(self):
    ''' Creates the fist HMM model with the parameters given by .par file.'''

    # Get Parameters from file
    self.GetParam()
    
    # Create Default HMM
    self.hmm = HMMFromMatrices(self.ALPH, DiscreteDistribution(self.ALPH), self.A, self.E,self.PI)
       

  def GetTrainSeq(self):
    ''' Obtains new training sequence from file '''

    line = self.handles[1].readline()
    #print line
    if (line!='' and line!='\n'):
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handles[1].readline()
      #print line 
      # Get Training Sequence
      line = self.handles[1].readline()  
      #print line
      train_seq=line.split()
      #print 'to train seq'
      #print train_seq
      return train_seq
    else:
      return ''

  
  def GetStatesSeq(self):
    ''' Obtains states labels for the new training sequence '''

    line = self.handles[2].readline()
    #print line
    if (line!='' and line!='\n'):
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handles[2].readline()
      #print line 
      # Get Training Sequence
      line = self.handles[2].readline()  
      #print line
      states_seq=line.split()
      #print 'to train seq'
      #print train_seq
      return states_seq
    else:
      return ''



  def Train(self):
    ''' Trains HMM using Default model as a starting point and using data from the training data file '''
    
    # Initialize model
    self.GetParam()
    self.log_likelihood_old=None
    threshold=False
    trainer=BaumWelchTrainerLabeled()
    trainer.GetHmmInitParam(self.Hmm)
    trainer.BaumWelchInit()
    train_seq=self.GetTrainSeq()
    states_seq=self.GetStatesSeq()
    #j=0
    #while j<2:
    while (len(train_seq)>1 and threshold==False):
      #print 'training train seq:'
      #print train_seq 
      threshold,self.Hmm=trainer.BaumWelchTrain(train_seq,states_seq)
      train_seq=self.GetTrainSeq()
      states_seq=self.GetStatesSeq()
      #j+=1
    self.SaveHmmParam()   


  def SaveHmmParam(self):
    ''' Save Hmm Parameters after Training '''
    header=''
    # Save Transition Probabilities
    
    for i in range(1,len(self.states)+1):
      header=header+'A%d\t' % i
    self.handles[3].write(header[:-1]+'\n')
       
    for i in range(len(self.states)):
      line=''
      for j in range(len(self.states)):
        line=line+'%f\t' % self.Hmm['A'][i+1][j+1]
      self.handles[3].write(line[:-1]+'\n')

    # Save Emission Probabilities
    for i in range(1,len(self.states)+1):
      header=''
      for j in range(1,len(self.symbols)+1):
        header=header+'E%d%d\t' %(i,j)
      self.handles[3].write(header[:-1]+'\n')
      prob=self.Hmm['E'][i-1]
      line=''
      for p in range(len(prob)):
        line=line+'%f\t' % prob[p]
      self.handles[3].write(line[:-1]+'\n')
    
    # Save Initial state distribution
    self.handles[3].write('PI\n')
    line=''    
    for i in range(len(self.states)):
      line=line+'%f\t' % self.Hmm['A'][0][i+1]
    self.handles[3].write(line[:-1]+'\n')

    # Save Symbols List 
    self.handles[3].write('ALPH\n')
    line=''
    for s in self.Hmm['Symbols']:
      line=line+s+'\t'
    self.handles[3].write(line[:-1]+'\n')

    # Save States Labels 
    self.handles[3].write('LABELS\n')
    line=''
    for s in self.Hmm['States']:
      line=line+s+'\t'
    self.handles[3].write(line[:-1]+'\n')
    
    # Close files
    for i in range(len(self.handles)):
      self.handles[i].close()

   
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
  
  # Save Trained Model parammete 
  
 
if __name__=="__main__":
  main()






     
