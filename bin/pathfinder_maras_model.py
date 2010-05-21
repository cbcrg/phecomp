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
  if(len(arg)<2):
    # Not enough arguments
    sys.stderr.write("\nHMM Path Finder using PheCom Data. Returns the path sequence corresponding to the observation data sequence provided.\n")
    sys.stderr.write("Usage:\t python %s observation_file\n" % arg[0])
    sys.stderr.write("where:\n'observation_file' is a .jnd file having observation sequences for obtaining states path\n") 
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
    self.path=''
    self.interfeed=120
    self.seq_param={}  # Store statistics per training sequence



  def OpenFile(self,file_list):
    ''' Open files '''
    self.handles=[]  # Stores file handles of filenames provided
        
    # Open Train data (.jnd) file
    if (file_list[0].endswith('.jnd')):
      try: 
        self.handles.append(open(file_list[0],'r'))
      except: 
        sys.stderr.write("Unable to open %s" % filename)
        raise ValueError()
    else :
      sys.stderr.write("Error: .jnd file expected!\n")
      raise ValueError()
    # Open output data (.pth) file
    try: 
      self.handles.append(open(file_list[0][:-4]+'maras.pth','w'))
    except: 
      sys.stderr.write("Unable to open states path ouput file")
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
    while (line.find("-")==-1):   # Observation Sequence Header
      self.header=self.header+line  # Save file header info to be copied into output file
      line = self.handles[0].readline() 
    self.header=self.header+line 
    self.handles[1].write(self.header)



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


  def GetInfoRound(self):
    ''' Get frequencies of symbols in a given training sequence '''
  
    self.NoEatInterval=0  # Number of '0.00' from last eating event  ???
    self.Meal={}    # Stores interfeed intervals freq. in Meal Events
    self.NoMeal={}    # Stores interfeed intervals freq. in No Meal Events
    self.Interval={}
    self.Snack={}
    self.transitions={}
    self.transitions['Meal2Interval']=0
    self.transitions['Meal2NoMeal']=0
    self.transitions['Interval2Meal']=0
    self.transitions['Interval2Interval']=0
    self.transitions['NoMeal2NoMeal']=0
    self.transitions['NoMeal2Meal']=0
    self.transitions['NoMeal2Snack']=0
    self.transitions['Snack2NoMeal']=0
    self.transitions['Meal']={}
    self.transitions['Snack']={}
    self.currentst='start'
    self.oldst='start'
    self.old_incr='0.00'

    self.length=0

    # Get to the starting data point 
    line = self.handles[0].readline()
    #while (line!='' and line!='\n'):
    j=0
    while j<1:
      self.param={}
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handles[0].readline()
    
      # Get Training Sequence
      line = self.handles[0].readline()
      self.seq=line.split()
      self.MealDetect(self.seq) # Detect Meal Events and upgrade symbol frequencies
      line = self.handles[0].readline()
      j+=1
       
  
  def GetFrequencies(self):
    ''' Get frequencies of symbols in a given training sequence  for all specified intefeed  intervals'''
  
    self.GetInfoRound()
    self.SavePath()
    line = self.handles[0].close()  # Close file to start analysis for the next round
        
    
  def UpdateState(self,incr,interval):
    ''' updates current state'''
    if incr=='0': 
      if self.currentst=='start':
        self.currentst='NoMeal'
      elif self.currentst=='Meal':
        self.currentst='Interval'
      if interval > self.interfeed :
        self.currentst='NoMeal'
    else:
      '''if self.currentst=='start':
        self.currentst='Meal'
      if interval <= self.interfeed :
        self.currentst='Meal'''
      self.currentst='Meal'


  def UpdateOldState(self, incr):
    ''' Updates Old State value'''
    self.oldst=self.currentst
    self.old_incr=incr
        
  def UpdateTransitionLast(self,interval,last_value,incr):
    ''' Updates transition counters in last value'''
    if self.currentst=='NoMeal':
      if last_value=='1':
        self.path+='s '
        self.transitions['NoMeal2Snack']+=1
        if self.transitions['Snack'].has_key(incr):
          self.transitions['Snack'][incr]+=1
        else:
          self.transitions['Snack'][incr]=1 
      else:
        if self.oldst=='NoMeal':
          self.path+='s '
          self.transitions['NoMeal2Snack']+=1 
          self.transitions['Snack2NoMeal']+=1
        elif self.oldst=='Interval':  
          self.path+='M '
          self.transitions['Interval2Meal']+=1
          self.transitions['Meal2NoMeal']+=1 
        self.transitions['NoMeal2NoMeal']+=interval
        for i in range(interval):
          self.path+='- '
    elif self.currentst=='Interval':
      if last_value=='1':
        self.transitions['Interval2Meal']+=1
        self.path+='M '
        if self.transitions['Meal'].has_key(incr):
          self.transitions['Meal'][incr]+=1
        else:
          self.transitions['Meal'][incr]=1
      else:      
        if self.oldst=='NoMeal':
          self.transitions['NoMeal2Snack']+=1 
          self.transitions['Snack2NoMeal']+=1
          self.path+='s '
        elif self.oldst=='Interval':        
          self.transitions['Interval2Meal']+=1
          self.transitions['Meal2NoMeal']+=1 
          self.path+='M '
        self.transitions['NoMeal2NoMeal']+=interval
        for i in range(interval):
          self.path+='- ' 

  def UpdateTransition(self, interval,incr):
    ''' Updates transition counters'''
    
    if self.currentst=='NoMeal':
      if self.oldst=='NoMeal':
        self.path+='s '
        self.transitions['NoMeal2Snack']+=1 
        self.transitions['Snack2NoMeal']+=1
        if self.transitions['Snack'].has_key(incr):
          self.transitions['Snack'][incr]+=1
        else:
          self.transitions['Snack'][incr]=1
      elif self.oldst=='Interval':
        self.transitions['Interval2Meal']+=1
        self.transitions['Meal2NoMeal']+=1 
        self.path+='M '
        if self.transitions['Meal'].has_key(incr):
          self.transitions['Meal'][incr]+=1
        else:
          self.transitions['Meal'][incr]=1
      self.transitions['NoMeal2NoMeal']+=interval-1
      for i in range(interval):
        self.path+='- '
    elif self.currentst=='Interval':
      
      if self.oldst=='NoMeal':
        self.transitions['NoMeal2Meal']+=1
      elif  self.oldst=='Interval':
        self.transitions['Interval2Meal']+=1
        
      self.transitions['Meal2Interval']+=1
      if self.transitions['Meal'].has_key(incr):
        self.transitions['Meal'][incr]+=1
      else:
        self.transitions['Meal'][incr]=1
      self.path+='M '
      self.transitions['Interval2Interval']+=interval-1
      for i in range(interval):
        self.path+='_ '    


  def MealDetect(self,seq):
    ''' Detects Meal Events according to interfeed interval and upgrade symbol frequencies '''
    eat=''
    interval=0
    self.last=False
    # Follow the sequence
    for i in range(len(seq)):
      #line= 'seq='+seq[i]+'\tstate='+self.currentst+'\toldstate='+self.oldst+'\teat='+eat+'\tinterval=%d' %interval
      #print line
      if (i==len(seq)-1):
        self.last=True
      if seq[i]=='0.00' :  
        interval+=1
        self.UpdateState('0',interval)
      elif seq[i]!='0.00':
        #eat=self.UpdateEatEvent()
        #self.UpdateTransition(eat,interval)
        self.UpdateTransition(interval, self.old_incr)
        self.UpdateOldState(seq[i])
        self.UpdateState('1',interval)
        interval=0
      if self.last==True:
        if seq[i]=='0.00':
          self.UpdateTransitionLast(interval,'0',seq[i])
        else:
          self.UpdateTransitionLast(interval,'1',seq[i])
       




  def ApplyModel(self):
    ''' Applies model to the observation sequence and obtains the corresponding sequence path sequence. The observation seq file may contain more than one sequence and the model will be applied to all sequences in the file'''

    self.NoEatInterval=0  # Number of '0.00' from last eating event  ???
    self.Meal={}    # Stores interfeed intervals freq. in Meal Events
    self.NoMeal={}    # Stores interfeed intervals freq. in No Meal Events
    self.Interval={}
    self.Snack={}
    self.transitions={}
    self.transitions['Meal2Interval']=0
    self.transitions['Meal2NoMeal']=0
    self.transitions['Interval2Meal']=0
    self.transitions['Interval2Interval']=0
    self.transitions['NoMeal2NoMeal']=0
    self.transitions['NoMeal2Meal']=0
    self.transitions['NoMeal2Snack']=0
    self.transitions['Snack2NoMeal']=0
    self.transitions['Meal']={}
    self.transitions['Snack']={}
    self.currentst='start'
    self.oldst='start'
    self.old_incr='0.00'

    self.length=0
    self.header=''

    end=0
    line = self.handles[0].readline()
    while (end==0):
      # Get Data Header 
      self.GetHeader(line)
      # Get Observation Sequence
      line = self.handles[0].readline()
      #self.handles[2].write('\n'+line) # Copy observation sequence
      seq=line.split()
      '''# Divide in small packets f
      seq=self.GroupData(seq)'''
      # Process all packets
      '''for s in seq:     
        obs_seq=EmissionSequence(self.ALPH, s)
        # Obtain States Path
        self.path=self.hmm.viterbi(obs_seq)
        # Save path
        self.SavePath()'''
      # Obtain States Path
      self.MealDetect(seq)         
      # Save path
      self.SavePath(seq)
      #self.handles[2].write(line)

      '''states=''
      for s in self.path[0]:
        states+= (self.LabelState(s)+' ')
      self.handles[2].write(states+'\n')'''
      
      # Get new line
      line = self.handles[0].readline() 
      if (line=='' or line=='\n'):  # End of file reached
        end=1

    # Close files
    for i in range(len(self.handles)):
      self.handles[i].close() 
   
            



  def SavePath(self,seq):
    ''' Save States Path'''
    line=''
    state=''
    st=0
    sp=3600
    end=False
    if (len(seq)< sp):
     sp=len(seq)
    
    while end==False :
      for i in range(st,sp):
        line=line+seq[i]+' '
        state=state+self.path[i] # Put a readable label to the state
      #self.handles[1].write(line+'\n')   
      self.handles[1].write(state+'\n') 
      line=''
      state=''
      st=sp
      sp+=3600
      if (len(seq)< sp):
        sp=len(seq)
      if (i==len(seq)-1):
        end=True
  

     
    
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
  Path.ApplyModel()
  
 
if __name__=="__main__":
  main()






     
