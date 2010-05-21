# PheCom Data HMM Path Finder 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' HMM Path Finder using PheCom Data. Returns the path sequence corresponding to the observation data sequence provided
    Usage:
          hmmpath params_file observation_file
    where:
       'params_file' is a .hmm/.par file having HMM parammeters
       'observation_file' is a .jnd file having observation sequences for obtaining HMM path

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
    sys.stderr.write("\nHMM Path Finder using PheCom Data. Returns the path sequence corresponding to the observation data sequence provided.\n")
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
    # Open output data (.pth) file
    try: 
      self.handles.append(open(file_list[1][:-4]+'.pth','w'))
    except: 
      sys.stderr.write("Unable to open states path ouput file")
      raise ValueError()
     
    # Open output data (.ptt) file a path together
    try: 
      self.handles.append(open(file_list[1][:-4]+'.ptt','w'))
    except: 
      sys.stderr.write("Unable to open states path ouput file")
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
    while (line.find("ALPH")==-1):   # Initial state distribution probability
      if(line.find("E")!=-1):  # Emission Probabilities Header 
        pass
      else:
        self.E.append(self.Ascii2Float(line)) # Convert Ascii data into Float 
      line = self.handles[0].readline()
    
    self.E=self.E[1:]
    
    line = self.handles[0].readline()  
    '''while (line.find("ALPH")==-1):   # List of symbols
      line = self.handles[0].readline()   
    line = self.handles[0].readline()'''
    self.sym_list=line.split()
    self.ALPH=Alphabet(self.sym_list)

    self.PI=self.A[0]
    self.PI=self.PI[1:]
    self.A=self.A[1:]
    for i in range(len(self.A)):
      self.A[i]=self.A[i][1:]
    
    
    # Store the Labels of the states
    line = self.handles[0].readline()  
    while (line.find("STATES")==-1):   # List of labels
      line = self.handles[0].readline()       
    line = self.handles[0].readline() 
    self.LABELS=line.split()



  def GetHeader(self,line):
    ''' Saves Observation File Header'''
    self.header=''  # Stores File Header

    # Get to starting data point
    while (line.find("-")==-1):   # Observation Sequence Header
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handles[1].readline() 
    self.header=self.header+line 
    self.handles[2].write(self.header)
    #p=[]
    #self.paths.append(p)


  def GroupData(self, seq):
    ''' Groups data in small packets to allow HMM program work properly '''
    
    packed=[]
    st_point=0
    sp_point=6500
    seq_len=len(seq)
    if seq_len< sp_point:
      return seq
    while sp_point < seq_len :
      packed.append(seq[st_point:sp_point])
      st_point=sp_point
      sp_point=sp_point+6500

    return packed 


  def ApplyHMM(self):
    ''' Applies HMM to the observation sequence and obtains the corresponding sequence path sequence. The observation seq file may contain more than one sequence and HMM will be applied to all sequences in the file'''

    self.header=''
    self.paths=[]
        
    end=0
    line = self.handles[1].readline()
    while (end==0):
      # Get Data Header 
      self.GetHeader(line)
      # Get Observation Sequence
      line = self.handles[1].readline()
      #self.handles[2].write('\n'+line) # Copy observation sequence
      seq=line.split()
      text='seq_length:%d' % len(seq)
      self.handles[3].write(text+'\n') 
      print 'sip'
      '''# Divide in small packets f
      seq=self.GroupData(seq)'''
      # Process all packets
      '''for s in seq:     
        obs_seq=EmissionSequence(self.ALPH, s)
        # Obtain States Path
        self.path=self.hmm.viterbi(obs_seq)
        # Save path
        self.SavePath()'''
   
      obs_seq=EmissionSequence(self.ALPH, seq)
      # Obtain States Path
      self.path=self.hmm.viterbi(obs_seq)
      self.likelihood=self.hmm.loglikelihood(obs_seq)
      print self.path
      # Save path
      self.SavePath(seq)
      #self.handles[2].write(line)

      '''states=''
      for s in self.path[0]:
        states+= (self.LabelState(s)+' ')
      self.handles[2].write(states+'\n')'''
      
      # Get new line
      line = self.handles[1].readline() 
      if (line.find('SYMBOLS')!=-1):  # End of file reached   if (line=='' or line=='\n'): 
        end=1

      
  def LabelState(self,state):
    ''' Puts a readable label to state'''
    
    for i in range(len(self.LABELS)):
      if state==i :  
        return self.LABELS[i]
    return ''  
          
  def SavePath(self,seq):
    ''' Save States Path'''
    line=''
    state=''
    compl_state=''
    st=0
    sp=3600
    end=False
    if (len(seq)< sp):
     sp=len(seq)
    line='Seq Length: %d' %sp
    self.handles[2].write(line+'\n')
    # Save Loglikelihood value
    line='Loglikelihood\t%f' %self.likelihood
    self.handles[2].write(line+'\n') 
    line=''
    while end==False :
      for i in range(st,sp):
        line=line+seq[i]+' '
        state=state+self.LabelState(self.path[0][i])+' ' # Put a readable label to the state
            
      compl_state+=state
      #self.handles[2].write(line+'\n') 
      
      self.handles[2].write(state+'\n') 
      line=''
      state=''
      continous_path=''
      st=sp
      sp+=3600
      if (len(seq)< sp):
        sp=len(seq)
      if (i==len(seq)-1):
        end=True
    self.paths.append(compl_state)    


  def SaveVector(self):
    ''' Save States Path as a Vector'''
    for path in range(len(self.paths)):
      line=''
      path_len=len(self.paths[path])
      text='path_len:%d'%path_len
      self.handles[3].write(text+'\n') 
      for position in range(path_len):
        line+=self.paths[path][position]+' '
      self.handles[3].write(line+'\n') 

    '''for position in range(len(self.paths[0])):
      line=''
      for path in range(len(self.paths)):
        line+=self.paths[path][position]+' '
      self.handles[3].write(line+'\n') '''
    
    # Close files
    for i in range(len(self.handles)):
      self.handles[i].close()    
    

  def GetPath(self):
    '''Obtains hidden states sequence from an observation sequence, applying HMM provided. Stores the states sequence in .pth file'''
    
    # Get HMM Parameters from file
    self.GetParam()
  
    # Create HMM with the parammeters
    self.hmm = HMMFromMatrices(self.ALPH, DiscreteDistribution(self.ALPH), self.A, self.E,self.PI)
  
    # Train HMM
    self.ApplyHMM()

    #Print path to furhter analysis
    self.SaveVector()
       
    
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






     
