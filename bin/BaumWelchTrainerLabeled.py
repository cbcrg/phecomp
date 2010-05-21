# Baum-Welch HMM trainer using labeled data and no scaling variables
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Baum-Welch HMM Trainer '''   

import sys
from sys import *
import math
from math import log



class BaumWelchTrainerLabeled:
  ''' Baum-Welch trainer'''

  def __init__(self):
    # Class Constructor
    self.log_likelihood_old=None
    self.log_prob_sum=0
    self.A={}
    self.E={} 
    

  def GetHmmInitParam(self,HMM):
    ''' Gets HMM initial parameters '''
    self.HMM=HMM
    # States. Add Begin and End State
    self.states=[]
    self.states.append('B')
    self.states+=self.HMM['States']
    # Symbols
    self.symbols=self.HMM['Symbols']
    # Transition probabilities, add begin state values. Notation a[k][l], where k is initial state and l next state
    self.a={}
    a=[]
    a.append(0.0)
    for k in range(len(self.HMM['PI'])):
      a.append(self.HMM['PI'][k])
    self.a[self.states[0]]=a 
    for k in range(len(self.HMM['A'])):
      a=[]
      a.append(0.0)
      for l in range(len(self.HMM['A'])):
        a.append(self.HMM['A'][k][l])
      self.a[self.states[k+1]]=a
    # Emission probabilities, add begin state values . Notation E[k][b], where k is the state and b is the symbol
    e=[]
    for b in range(len(self.symbols)):
      e.append(0.0)
    self.e={}
    self.e[self.states[0]]=(e)
    for k in range(len(self.HMM['E'])):
      self.e[self.states[k+1]]=self.HMM['E'][k]
    

  def Symbol2Index(self,symbol):
   ''' Converts symbols to index in emission prob matrix '''
   for i in range(len(self.symbols)):
     if symbol==self.symbols[i]:
       return i


  def BaumWelchInit(self):
    ''' Initialize expectec transition / emission counts '''
    # Adding pseudocounts
    '''for k in range(len(self.states)):
      A=[]
      E=[]
      for l in range(len(self.states)):
        if l==0:
          A.append(0)
        else:
          A.append(1)
        # Expected Transition counts
      self.A[self.states[k]]=A
      for b in range(len(self.symbols)):
        if k==0:
          E.append(0)
        else:
          E.append(1)
        # Expected Emission counts
      self.E[self.states[k]]=E'''
    # No adding pseudocounts
    for k in range(len(self.states)):
      A=[]
      E=[]
      for l in range(len(self.states)):
        '''if k==2 and l==2:
          A.append(1)
        else:'''
        A.append(0)
      # Expected Transition counts
      self.A[self.states[k]]=A
      #print self.A
      for b in range(len(self.symbols)):
        E.append(0)
      # Expected Emission counts
      self.E[self.states[k]]=E


  def State2Number(self,state):
    ''' Converts state label into a number '''
    for i in range(len(self.states)):
      if state==self.states[i]:
        return i
    sys.stderr.write("Log-likelihood change reached\n")
    raise ValueError()

  
  def GetCounts(self,seq,states):
    ''' Calculate forward variables using scaling variables'''
       
    # A={}
    #E={}
    old_state='B'
    for i in range(len(seq)):  # or len(states), must have the same length
      state=self.State2Number(states[i])        
      self.A[old_state][state]+=1 # increment A[k][l] count
      b=self.Symbol2Index(seq[i])
      self.E[states[i]][b]+=1  # Increment E[k][b] count
      old_state=states[i]

    # Add transition from last position to end state
    state=self.State2Number('E')    
    self.A[old_state][state]+=1



  def CalculateParam(self):
    ''' Calculate new HMM parameters '''
    self.sumA={}
    self.sumE={}
    

    # Transition probabilities
    for k in range(len(self.states)):
      summ=0
      for l in range(len(self.states)):
        summ+=self.A[self.states[k]][l]
      self.sumA[self.states[k]]=summ
    
    for k in range(len(self.states)):
      for l in range(len(self.states)):
        if self.sumA[self.states[k]]==0:
          #if self.states[k]!='B':  #  transition from B to the rest of the states is maintainted
          self.a[self.states[k]][l]=0.0
          
        else:
          #print self.states[k]
          #if self.states[k]!='B':  # transition from B to the rest of the states is maintainted
          self.a[self.states[k]][l]= float(self.A[self.states[k]][l])/self.sumA[self.states[k]]
    #print 'after akl recalculation'
    #print self.a
    # Emission probabilities
    for k in range(len(self.states)):
      summ=0
      for b in range(len(self.symbols)):
        summ+=self.E[self.states[k]][b]
      self.sumE[self.states[k]]= summ
   
    for k in range(len(self.states)):
      for b in range(len(self.symbols)):
        if self.sumE[self.states[k]]==0:
          self.e[self.states[k]][b]=0.0
        else: 
          self.e[self.states[k]][b]= float(self.E[self.states[k]][b])/self.sumE[self.states[k]] 
    
    
    # Upgrade Model Parameters
    self.UpgradeHmm()    

  
  def LogXBaseN(self,x,n):
    '''Calculates the log of a number (x) in a given base (n) '''
    if (x==0):
      return 999
    else:
      return math.log(x,n)
    

  def GetLogLikelihood(self):
    ''' Calculates log-likelihood'''
    
    likelihood=0
    '''print self.prob_list
    for p in self.prob_list: 
      likelihood += math.log(p,2) 
    print likelihood
    return likelihood    '''
    for s in self.s: 
      '''if s==0:
        s=0.00000000001'''
      likelihood+=self.LogXBaseN(1/s,2) 
    likelihood*=(-1)
    self.log_prob_sum+=likelihood
    print self.log_prob_sum
    

  def UpgradeHmm(self):
    '''Upgrades HMM'''
    for k in range(len(self.states)):
      if k==len(self.HMM['A']):
        self.HMM['A'].append(self.a[self.states[k]])
      else:
        self.HMM['A'][k]=self.a[self.states[k]]
      
    for k in range(1,len(self.states)):
      self.HMM['E'][k-1]=self.e[self.states[k]]


  def BaumWelchTrain(self,seq,states):
    '''Trains HMM with provided training sequence'''
    self.GetCounts(seq,states)
    self.CalculateParam()
    '''self.GetLogLikelihood()
    if  self.log_likelihood_old is not None:
      log_likelihood_incr=abs(abs(self.log_prob_sum)-abs(self.log_likelihood_old))
      if log_likelihood_incr < 0.0001 :
        sys.stderr.write("Log-likelihood change reached\n")
        raise ValueError()
        print ("Log-likelihood change reached\n")
        return (True, self.HMM)
    self.log_likelihood_old=self.log_prob_sum'''
    return (False,self.HMM)
   
         
