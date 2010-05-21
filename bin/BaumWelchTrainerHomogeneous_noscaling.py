# Baum-Welch HMM trainer. Non-scaling variables
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Baum-Welch HMM Trainer '''   

import sys
from sys import *
import math
from math import log
import random
import string


class BaumWelchTrainerHomogeneous:
  ''' Baum-Welch trainer'''


  def __init__(self,states,train_file):
    # Class Constructor
    self.statesnbr=int(states)
    self.datafile=train_file
    self.log_likelihood_old=None
    self.log_prob_sum=0.0
    self.log_likelihood_list=[]
    self.A={}
    self.E={} 
    self.countXstate_old={}
    self.prob_fwd=0.0

  def GetRandomParam(self):
    ''' Gets HMM initial parameters randomdly'''
 
    self.e={}  # emission probabilities
    self.a={}  # transition probabilities
    self.states={}
    self.symbols={}
        
    # Initialize Counters
    for state in range(0,self.statesnbr+1):
      state='%d'%state
      self.a[state]={}
      self.e[state]={}
      for newstate in range(0,self.statesnbr+1):
        newstate='%d'%newstate
        self.a[state][newstate]=0
        self.e[state]={}
      self.states[state]=state
    try:
      self.OpenFileIn()
    except: 
      sys.stderr.write("Open Files operation failed2\n")
      raise ValueError()
    # Fill in counters
    line = self.handle.readline()
    #print line
    while (line.find("SYMBOLS")==-1):
      while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
        line = self.handle.readline()
        #print line
      # Get Training Sequence
      line = self.handle.readline()  
      #print line
      train_seq=line.split()
      self.AssigRandomStates(train_seq)
      line = self.handle.readline()
      #print line
    # Save symbol list  
    line = self.handle.readline()
    #print line
    for symbol in line.split():
      self.symbols[symbol]=symbol
    print self.symbols
    self.InitSymbol()
    # Get initial probabilities
    self.GetProb()
    # Init counters for next step
    '''for state in self.states:
      self.countXstate_old[state]={}
      for symbol in self.symbols:
        self.countXstate_old[state][symbol]=0'''
    self.handle.close()

  def PrintHMM(self):
    # Initial HMM parameters
    print 'Transition Probabilities'
    line='\t'
    states=sorted(self.a.keys())
    line+=string.join(states,'\t')
    print line
    for state in sorted(self.a.keys()):
      a=''
      line=state+'\t'
      for newstate in sorted(self.a[state].keys()):
        a='%f\t' % self.a[state][newstate]
        line+=a
      print line
    print 'Emission Probabilities'
    line='\t'
    symbols=sorted(self.e['0'].keys())
    line+=string.join(symbols,'\t')
    print line
    for state in sorted(self.e.keys()):
      e=''
      line=state+'\t'
      for symbol in sorted(self.e[state].keys()):
        e='%f\t' %self.e[state][symbol]
        line+=e
      print line
    

  def AssigRandomStates(self,seq):
    ''' Asigns data randomly to states and update counters for statistics'''  
    old_state='0'
    #print seq
    for interv in seq:
      # Assign a state randomly
      state=random.randint(1, self.statesnbr)
      state='%d'%state 
      #print state
      # Counter for emission probabilities   
      if self.e[state].has_key(interv):
        # If exists add one
        self.e[state][interv]+=1
      else:  # Initialize
        self.e[state][interv]=1
      # Counter for transition probabilities  
      if self.a[old_state].has_key(state):
        # If exists add one
        self.a[old_state][state]+=1
      else:  # Initialize
        self.a[old_state][state]=1
      old_state=state
    #print self.e
    #print self.a


  def OpenFileIn(self):
    ''' Open files '''
    # Open Train data (.jnd) file
    if (self.datafile.endswith('.jnd')):
      try: 
        self.handle=open(self.datafile,'r')
      except: 
        sys.stderr.write("Unable to open %s" % self.datafile)
        raise ValueError()
    else :
      sys.stderr.write("Error: .jnd file expected!\n")
      raise ValueError()

    
  def InitSymbol(self):
    ''' Initializes symbol entries to '0', in case the symbol has not been emmited in any state'''
    for state in self.states:
      for symbol in self.symbols:
        if self.e[state].has_key(symbol):  # add pseudocounts
          pass
        else:
          self.e[state][symbol]=0
      for newstate in self.states:
        if self.a[state].has_key(newstate):  # add pseudocounts
          pass
        else:
          self.a[state][newstate]=0

 
  def GetProb(self):
    ''' Obtains probabilities from counts '''
    # Emission Probabilities
    sume={}
    for state in self.e.keys():
      sume[state]=0
      for symbol in self.e[state].keys():
        sume[state]+=self.e[state][symbol]
    e={}
    for state in self.e.keys():
      e[state]={}
      for symbol in self.e[state].keys():
        if sume[state]==0:
          e[state][symbol]=0.0
        else:
          e[state][symbol]=self.e[state][symbol]/float(sume[state])
    # Transition Probabilities
    suma={}
    for oldstate in self.a.keys():
      suma[oldstate]=0
      for state in self.a[oldstate].keys():
        suma[oldstate]+=self.a[oldstate][state]
    a={}
    for oldstate in self.a.keys():
      a[oldstate]={}
      for state in self.a[oldstate].keys():
        if suma[oldstate]==0:
          a[oldstate][state]=0.0
        else:
          a[oldstate][state]=self.a[oldstate][state]/float(suma[oldstate]) 
    # Add Initial state (begin)
    for symbol in self.symbols.keys():
      e['0'][symbol]=0.0
    a['0']={}
    for state in self.states.keys():
      a['0'][state]=1/float(len(self.states)-1)
      a[state]['0']=0.0 
   
    # Assign to global variables
    self.e=e
    self.a=a


  
  def CheckCountXstateIncrement(self):
    ''' Checks if states have incremented the symbols counter. If none of them has increaded, initial HMM is ready'''
    for state in self.states:
      #print state
      for symbol in self.symbols:
        '''print symbol
        print 'self.countXstate[state][symbol]'
        print self.countXstate[state][symbol]
        print 'self.countXstate_old[state][symbol]'
        print self.countXstate_old[state][symbol]'''
        if self.countXstate[state][symbol]==self.countXstate_old[state][symbol]:
          pass
        else:
          return False
    return True       

       
  def GetGreatProbState(self,interv,oldstate):
    ''' Look for emission probabilities of the symbol and keep the state that has the greater.
        In case there is more than one state with the same max prob, assign the state randomly'''
    prob=0
    states=[]
    f={}
    for state in self.states:
      f[state]=self.a[oldstate][state]*self.e[state][interv]
      if f[state] > prob :
        prob=f[state]
    for state in self.states:
      if f[state]==prob :
        states.append(state)
    
    if len(states)>1: # more than one state with the same max prob,assign the state randomly
      maxi=len(states)-1
      #print maxi
      rand=random.randint(0,maxi)
      state=states[rand]
    else:
      state=states[0] 
    return state


  def AssigStates(self,seq):
    ''' Asigns data to states depending on emission probabilites and update counters for statistics'''  
    old_state='0'
    # Update self.e_old/self.a_old
    for state in self.states:
      for newstate in self.states:
        self.a_old[state][newstate]+=self.a[state][newstate]
      for symbol in self.symbols:
        self.e_old[state][symbol]+=self.e[state][symbol]
    
    self.a={}
    self.e={}
    # Init counters
    for state in range(len(self.states)):
      state='%d'%state
      self.a[state]={}
      self.e[state]={}
      for newstate in range(len(self.states)):
        newstate='%d'%newstate
        self.a[state][newstate]=0
      for symbol in self.symbols:
        self.e[state][symbol]=0
    for interv in seq:
      # Look for emission probabilities of the symbol and keep the state that has the greater
      state=self.GetGreatProbState(interv,old_state)
      #state='%d'%state 
      # Counter for emission probabilities   
      self.e[state][interv]+=1
      self.countXstate[state][interv]+=1
      # Counter for transition probabilities  
      self.a[old_state][state]+=1
      old_state=state      


  def GetHmmInitParam(self,datafile):
    '''  Classify training data depending on symbol probabilities  and obtaind Initial parameters'''
    self.e_old={}  # emission probabilities
    self.a_old={}  # transition probabilities
    self.countXstate={}
    iterate=True
   
    while iterate== True:
      # Initialize self.e_old/self.a_old
      self.e_old=self.e
      self.a_old=self.a
      print 'iteration'
 
      for state in self.states:
       self.countXstate[state]={}
       for symbol in self.symbols:
         self.countXstate[state][symbol]=0
      self.OpenFileIn(datafile)
      # Fill in counters
      line =self.handle.readline()
      while (line.find("SYMBOLS")==-1):
        while (line.find("-")==-1):   # Train Sequence Header Eg. C1-
          line = self.handle.readline()
        # Get Training Sequence
        line = self.handle.readline()
        train_seq=line.split()
        self.AssigStates(train_seq)
        line = self.handle.readline()
      # Get initial probabilities
      self.e=self.e_old
      self.a=self.a_old
      self.GetProb()
      self.handle.close()
      #print self.e
      #print self.a
      print self.countXstate_old
      print self.countXstate
      '''if(self.CheckCountXstateIncrement()==False):
        for state in self.states:
          for symbol in self.symbols:
            self.countXstate_old[state][symbol]=self.countXstate[state][symbol]
      else:
        iterate=True '''
        
    # Initial HMM parameters
    print 'Initial HMM'
    print self.e
    print self.a
   
 
  def BaumWelchInit(self):
    ''' Initialize expectec transition / emission counts '''
    self.A={}
    self.E={}  
    '''# No adding pseudocounts
    for k in range(len(self.states)):
      A=[]
      E=[]
      for l in range(len(self.states)):
        A.append(0)
      # Expected Transition counts
      self.A[self.states[k]]=A
      #print self.A
      for b in range(len(self.symbols)):
        E.append(0)
      # Expected Emission counts
      self.E[self.states[k]]=E'''

    for state in self.states.keys():
      A={}
      E={}
      for newstate in self.states.keys():
        A[newstate]=0
      # Expected Transition counts
      self.A[state]=A
      for symbol in self.symbols.keys():
        E[symbol]=0
      # Expected Emission counts
      self.E[state]=E
    

  def GetForward(self,seq):
    ''' Calculate forward variables using scaling variables'''
       
    self.f={}
    #self.s=[]
    # Initialitsation
    for state in self.states.keys():
      prob=[]
      if state=='0':
        prob.append(1)
      else:
        prob.append(0)
      self.f[state]=prob
    # Recursion
    for i in range(len(seq)):
      # Scaling variables
      #summe=0
      for newstate in self.states.keys():
        summf=0
        for state in self.states.keys():
          summf+=self.f[state][i]*self.a[state][newstate]
        self.f[newstate].append(self.e[newstate][seq[i]]*summf)
        #summe+=self.e[newstate][seq[i]]*summf
      #self.s.append(summe) 
      #print self.s
      #print self.f
      #for newstate in self.states.keys():
      #  self.f[newstate].append(f[newstate]/self.s[i])# s[i+1]
    # Termination
    self.prob_fwd=0.0
    for state in self.states.keys():
      self.prob_fwd+=self.f[state][-1]
    print self.prob_fwd
    '''summ=1
    for si in self.s[1:]:
      summ*=si
    self.prob_fwd=summ
    return self.prob_fwd'''


  def GetBackward(self,seq):
    ''' Calculate backward variables '''
    self.b={}
    b={}
    # Initialitsation
    for state in self.states.keys():
      prob=[]
      for index in range(len(seq)):
        prob.append(0)
      if state=='0':
        prob[len(seq)-1]=0
      else:
        prob[len(seq)-1]=1#prob[len(seq)-1]=1/self.s[-1]
      self.b[state]=prob
      '''for state in self.states.keys():
        for i in range(len(self.states[state])):
           b[state][i]=self.b[state][i]*self.s[-1]'''
     
    # Recursion  
    for i in range(len(seq)-2,-1,-1):
      for state in self.states.keys():
        summ=0
        if state=='0':
          self.b[state][i]=0
        else:
          for newstate in self.states.keys():
            summ+=self.b[newstate][i+1]*self.e[newstate][seq[i+1]]*self.a[state][newstate]
          self.b[state][i]=summ#summ/self.s[i]
          #b[state][i]=summ
    #print self.b
    # Termination
    '''summ=0
    b=self.Symbol2Index(seq[0])
    for l in range(len(self.states)):
      summ+=self.a[self.states[0]][l]*self.e[self.states[l]][b]*self.b[self.states[l]][0]
    #self.prob_bwd=summ'''
   
  def Reestimation(self,seq):
    ''' Calculate Expected transition and emission counts '''
       
    # Expected transmission reestimation
    for state in self.states.keys():
      '''print 'state'
      print state'''
      for newstate in self.states.keys():
        '''print 'newstate'
        print newstate'''
        summ=0
        for i in range(len(seq)):
          '''print 'i'
          print i
          print seq[i]
          print 'self.f[state][i]'
          print self.f[state][i]
          print 'self.a[state][newstate]'
          print self.a[state][newstate]
          print 'self.e[newstate][seq[i]]'
          print self.e[newstate][seq[i]]
          print 'self.b[newstate][i+1]'
          print self.b[newstate][i]'''
          summ+=self.f[state][i]*self.a[state][newstate]*self.e[newstate][seq[i]]*self.b[newstate][i] #self.b has the same index as seq 
          '''print 'summ'
          print summ'''
        self.A[state][newstate]+=summ
    # Expected emission reestimation
    for state in self.states.keys():
      '''print 'state'
      print state'''
      for symbol in self.symbols.keys():
        '''print 'symbol'
        print symbol'''
        summ=0
        for i in range(len(seq)):
          if seq[i]==symbol:
            '''print 'i'
            print i+1
            print 'self.f[state][i+1]'
            print self.f[state][i+1]
            print 'self.b[state][i]'
            print self.b[state][i]
            print 'self.s[i]'
            print self.s[i]''' 
            summ+=self.f[state][i+1]*self.b[state][i]# *self.s[i]
            '''print 'summ'
            print summ'''
        self.E[state][symbol]+=summ
    '''print 'self.A'
    print self.A
    print 'self.E' 
    print self.E'''


  def CalculateParam(self):
    ''' Calculate new HMM parameters '''
    self.sumA={}
    self.sumE={}

    # Transition probabilities
    for state in self.states.keys():
      summ=0
      for newstate in self.states.keys():
        summ+=self.A[state][newstate]
      self.sumA[state]=summ
    
    for state in self.states.keys():
      for newstate in self.states.keys():
        if self.sumA[state]==0:
          if state!='0':  #  transition from B to the rest of the states is maintainted
            self.a[state][newstate]=0.0
        else: 
          if state!='0':  # transition from B to the rest of the states is maintainted
            if self.A[state][newstate]/self.sumA[state]!=0.0:
              self.a[state][newstate]= self.A[state][newstate]/self.sumA[state]
          '''else:
            self.a[state][newstate]= self.A[state][newstate]/self.sumA[state]'''
    # Emission probabilities
    for state in self.states.keys():
      summ=0
      for symbol in self.symbols.keys():
        summ+=self.E[state][symbol]
      self.sumE[state]= summ
         
    for state in self.states.keys():
      for symbol in self.symbols.keys():
        if self.sumE[state]==0:
          self.e[state][symbol]=0.0
        else: 
          self.e[state][symbol]= self.E[state][symbol]/self.sumE[state] 
    
    # Upgrade Model Parameters
    self.UpgradeHmm()    
    '''print 'self.sumA'
    print self.sumA
    print 'self.sumE'
    print self.sumE
    print 'self.a'
    print self.a
    print 'self.e'
    print self.e'''
  
  def LogXBaseN(self,x,n):
    '''Calculates the log of a number (x) in a given base (n) '''
    if (x==0):
      return 999
    else:
      return math.log(x,n)
    

  def GetLogLikelihood(self):
    ''' Calculates log-likelihood'''
    
    '''likelihood=0
    for s in self.s: 
      likelihood+=self.LogXBaseN(1/s,2) 
    likelihood*=(-1)
    self.log_prob_sum+=likelihood
    self.log_likelihood_list.append(self.log_prob_sum)'''
    likelihood=self.LogXBaseN(self.prob_fwd,2) 
    self.log_likelihood_list.append(likelihood)
    #print self.log_prob_sum
    

  def UpgradeHmm(self):
    '''Upgrades HMM'''
    self.HMM['A']={}
    self.HMM['E']={}
    for state in self.states.keys():
      self.HMM['A'][state]=self.a[state]
      self.HMM['E'][state]=self.e[state]
    

  def PrintValues(self,seq):
    ''' Print calculated f,b,s,A,E,a,e valued for manual checking '''
    # Print header
    
    forward=''
    backward=''
    for state in sorted(self.states.keys()):
      forward+='f_'+state+'[i]\t'
      backward+='b_'+state+'[i]\t'
    
    print 'Calculations'
    print 'i\tx[i]\ts[i]\t'+forward+backward

    # Print initial values
    f_0=''
    b_0=''
    for state in sorted(self.f.keys()):
      f='%f\t' %self.f[state][0]
      f_0+=f+'\t'
      b_0+='-\t'
    line='0\t-\t-\t'+f_0+b_0
    print line
    
    # Print rest of values
    for i in range(len(seq)):#for i in range(len(seq))
      index=i+1
      index='%d\t' %index
      f_i=''
      b_i='' 
      for state in sorted(self.f.keys()):
        f='%f\t' %self.f[state][i+1]
        f_i+=f+'\t'
      for state in sorted(self.b.keys()):
        b='%f\t' %self.b[state][i]
        b_i+=b+'\t'
      s_i='%f\t' %self.s[i]
      line=index+seq[i]+'\t'+s_i+f_i+b_i
      print line


  def BaumWelchTrain(self,seq):
    '''Trains HMM with provided training sequence'''
    self.HMM={}
    # manual parameters
    self.e={'0': {'T': 0.0, 'C': 0.0, 'A': 0.0, 'G':0.0 }, '1': {'T': 0.2, 'C': 0.3, 'A': 0.2, 'G':0.3  }, '2': {'T': 0.3, 'C': 0.2, 'A': 0.3, 'G':0.2 }}
    self.a={'0': {'0': 0.0, '1': 0.5, '2': 0.5}, '1': {'0': 0.0, '1': 0.5, '2': 0.5}, '2': {'0': 0.0, '1': 0.4, '2': 0.6}}
    '''self.e={'0': {'1': 0.0, '2': 0.0, '3': 0.0, '4':0.0,'5':0.0,'6':0.0 }, '1': {'1': 0.18, '2': 0.15, '3': 0.18, '4':0.15, '5':0.18, '6':0.15  }, '2': {'1': 0.15, '2': 0.18, '3': 0.15, '4':0.18, '5':0.15, '6':0.18}}
    self.a={'0': {'0': 0.0, '1': 0.5, '2': 0.5}, '1': {'0': 0.0, '1': 0.6, '2': 0.4}, '2': {'0': 0.0, '1': 0.4, '2': 0.6}}'''
    self.PrintHMM()
    i=0
    while i<300:
      self.GetForward(seq)
      self.GetBackward(seq)
      self.Reestimation(seq)
      self.CalculateParam()
      self.GetLogLikelihood()
      #self.PrintHMM()
      i+=1 
      #self.PrintValues(seq)
    print 'Log-likelihood evolution'
    for log in self.log_likelihood_list:
      print log

    self.PrintHMM()  # To be removed

    if  self.log_likelihood_old is not None:
      log_likelihood_incr=abs(abs(self.log_prob_sum)-abs(self.log_likelihood_old))
      if log_likelihood_incr < 0.0001 :
        sys.stderr.write("Log-likelihood change reached\n")
        raise ValueError()
        print ("Log-likelihood change reached\n")
        return (True, self.HMM)
    self.log_likelihood_old=self.log_prob_sum
    return (False,self.HMM)
       

