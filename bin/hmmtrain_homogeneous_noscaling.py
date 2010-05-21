# PheCom Data HMM Trainer 
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
import BaumWelchTrainerHomogeneous_noscaling
from BaumWelchTrainerHomogeneous_noscaling import *


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nHMM Trainer using PheCom Data. Returns new Hmm Model parameters saved in a .hmm file. Training sequences are composed by bins with homogeneous contents. Non-scaling variables used.\n")
    sys.stderr.write("Usage:\t python %s classes train_file\n" % arg[0])
    sys.stderr.write("where:\n'classes' is the number of classes (models) to construct\n") 
    sys.stderr.write("'train_file' is a .jnd file having train sequences for HMM Model\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Trainer:
  ''' Trains HMM with provided data'''

  def __init__(self,classes,train_file):
    # Class Constructor
    self.classes=classes
    self.datafile=train_file
    self.rounds=1
    # Open all files in file_list
    try:
      self.OpenFileOut()
    except: 
      sys.stderr.write("Open Files operation failed2\n")
      raise ValueError()


  def OpenFileIn(self):
    ''' Open files '''
    # Open Train data (.jnd) file
    if (self.datafile.endswith('.jnd')):
      try: 
        self.handle=open(self.datafile,'r')
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .jnd file expected!\n")
      raise ValueError()
   

  def OpenFileOut(self):
    ''' Open files '''
        
    # Open output data (.hmm) file
    try: 
      self.handle_out=open(self.datafile[:-4]+'.hmm','w')
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
    line = self.handle.readline()  
    while (line.find("A")==-1):   # Transition Probabilities Header
      line = self.handle[0].readline()

    # Store Transition Probabilities 
    self.states=line.split()  # Get the number of states
    line = self.handle.readline()  
    while (line.find("E")==-1):   # Emission Probabilities Header
      A.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handle.readline()
    
    # Store Emission Probabilities
    self.symbols=line.split()  # Get the number of symbols
    line = self.handle.readline()  
    while (line.find("PI")==-1):   # Initial state distribution probability
      if(line.find("E")!=-1):  # Emission Probabilities Header 
        pass
      else:
        E.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handle.readline()

    # Store Initial state distribution probability
    line = self.handle.readline()
    PI=self.Ascii2Float(line) # Convert Ascii data into Float

    # Store the List of possible symbols to be emitted
    line = self.handle.readline()  
    while (line.find("ALPH")==-1):   # List of symbols
      line = self.handle.readline()   
    line = self.handle.readline() 
    ALPH=line.split()
     
    # Store the Labels of the states
    line = self.handle.readline()  
    while (line.find("LABELS")==-1):   # List of labels
      line = self.handle.readline()       
    line = self.handle.readline() 
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

    line = self.handle.readline()
    #print line
    if (line.find('SYMBOLS')==-1):
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handle.readline()
      #print line 
      # Get Training Sequence
      line = self.handle.readline()  
      #print line
      train_seq=line.split()
      #print 'to train seq'
      #print train_seq
      return train_seq
    else:
      return ''
 

  def Train(self):
    ''' Trains HMM using Default model as a starting point and using data from the training data file '''
    
    # Initialize model
    #self.GetParam()
    self.log_likelihood_old=None
    threshold=False
    trainer=BaumWelchTrainerHomogeneous(self.classes,self.datafile)
    trainer.GetRandomParam()
    #trainer.GetHmmInitParam()
    print self.rounds
    
    r=0
    while r < self.rounds:
      print r
      self.OpenFileIn()
      trainer.BaumWelchInit()
      train_seq=self.GetTrainSeq()
      #j=0
      #while j<2:
      while (len(train_seq)>1 and threshold==False):
        #print 'training train seq:'
        #print train_seq 
        threshold,self.Hmm=trainer.BaumWelchTrain(train_seq)
        train_seq=self.GetTrainSeq()
        #j+=1
      self.handle.close()  
      r+=1
    self.SaveHmmParam()

  def SaveHmmParam(self):
    ''' Save Hmm Parameters after Training '''
    header=''
    # Save Transition Probabilities
    states=sorted(self.Hmm['A'].keys())
    symbols=sorted(self.Hmm['E']['0'].keys())
    for i in range(len(states)):
      header=header+'A%d\t' % i
    self.handle_out.write(header[:-1]+'\n')
       
    for i in range(len(states)):
      line=''
      for j in range(len(states)):
        line=line+'%f\t' % self.Hmm['A'][states[i]][states[j]]
      self.handle_out.write(line[:-1]+'\n')

    # Save Emission Probabilities
    for i in range(len(states)):
      header=''
      for j in range(len(symbols)):
        header=header+'E%d%d\t' %(i,j)
      self.handle_out.write(header[:-1]+'\n')
      prob=self.Hmm['E'][states[i]]
      line=''
      for s in range(len(symbols)):
        line=line+'%f\t' % self.Hmm['E'][states[i]][symbols[s]]
      self.handle_out.write(line[:-1]+'\n')
    
    '''# Save Initial state distribution
    self.handle_out.write('PI\n')
    line=''    
    for i in range(len(self.states)):
      line=line+'%f\t' % self.Hmm['A'][0][i+1]
    self.handle_out.write(line[:-1]+'\n')'''

    # Save Symbols List 
    self.handle_out.write('ALPH\n')
    line=''
    for i in range(len(symbols)):
      s=symbols[i]
      line=line+s+'\t'
    self.handle_out.write(line[:-1]+'\n')

    # Save States Labels 
    self.handle_out.write('STATES\n')
    line=''
    for i in range(len(states)):
      s=states[i]
      line=line+s+'\t'
    self.handle_out.write(line[:-1]+'\n')
    
    # Close files

   
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:             
    ToTrain=Trainer(argv[1],argv[2])
  except ValueError:
    sys.stderr.write( "HMM Train aborted.\n" )
    return

  # Join Files
  ToTrain.Train()
  
  # Save Trained Model parammete 
  
 
if __name__=="__main__":
  main()






     
