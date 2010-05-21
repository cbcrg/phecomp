# Baum-Welch HMM trainer not using scaling variables
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Baum-Welch HMM Trainer '''   

import sys
from sys import *
import math
from math import log



class BaumWelchTrainer:
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


   

  def GetForward(self,seq):
    ''' Calculate forward variables using scaling variables'''
       
    self.f={}
    self.s=[]
    # Initialitsation
    for k in range(len(self.states)):
      prob=[]
      if k==0:
        prob.append(1)
      else:
        prob.append(0)
      self.f[self.states[k]]=prob
    #print self.a
    # Recursion
    for i in range(len(seq)):
      b=self.Symbol2Index(seq[i])
      # Scaling variables
      summe=0
      f=[] 
      for l in range(len(self.states)):
        summf=0
        for k in range(len(self.states)):
          summf+=self.f[self.states[k]][i]*self.a[self.states[k]][l]
        f.append(self.e[self.states[l]][b]*summf)
        self.f[self.states[l]].append(f[l])
    print self.f
    # Termination
    summ=0
    end=len(self.states)-1
    print self.a
    for k in range(len(self.states)):
      print self.f[self.states[k]][-1]
      print self.a[self.states[k]][end]
      summ+=self.f[self.states[k]][-1]*self.a[self.states[k]][end]
    self.prob_fwd=summ
    print self.prob_fwd
    # return self.prob_fwd


  def GetBackward(self,seq):
    ''' Calculate backward variables '''
    self.b={}
    # Initialitsation
    for k in range(len(self.states)):
      prob=[]
      for index in range(len(seq)):
        prob.append(0)
      '''if self.s[-1]==0:
        print 's[-1]=0'
        prob[len(seq)-1]=0
      else:'''
      #prob[len(seq)-1]=1/self.s[-1]
      prob[len(seq)-1]=1
      self.b[self.states[k]]=prob
    # Recursion
    for i in range(len(seq)-2,-1,-1):
      b=self.Symbol2Index(seq[i+1])
      for k in range(len(self.states)):
        summ=0
        for l in range(len(self.states)):
          summ+=self.b[self.states[l]][i+1]*self.e[self.states[l]][b]*self.a[self.states[k]][l]
        '''if self.s[i+1]==0:
          self.b[self.states[k]][i]=0
        else:'''
        #self.b[self.states[k]][i]=summ/self.s[i+1]
        self.b[self.states[k]][i]=summ
    # Termination
    summ=0
    b=self.Symbol2Index(seq[0])
    for l in range(len(self.states)):
      summ+=self.a[self.states[0]][l]*self.e[self.states[l]][b]*self.b[self.states[l]][0]
    self.prob_bwd=summ
    print self.prob_bwd
   

  def Reestimation(self,seq):
    ''' Calculate Expected transition and emission counts '''
       
    # Expected transmission reestimation
    for k in range(len(self.states)):
      for l in range(len(self.states)):
        summ=0
        for i in range(len(seq)-1):
          b=self.Symbol2Index(seq[i+1])  # Next position in the sequence
          summ+=self.f[self.states[k]][i+1]*self.a[self.states[k]][l]*self.e[self.states[l]][b]*self.b[self.states[l]][i+1]
        #summ=summ/self.prob_fwd
        self.A[self.states[k]][l]+=summ
    # Expected emission reestimation
    for k in range(len(self.states)):
      for b in range(len(self.symbols)):
        summ=0
        for i in range(len(seq)):
          if seq[i]==self.symbols[b]:
            #summ+=self.f[self.states[k]][i+1]*self.b[self.states[k]][i]*self.s[i+1]
            summ+=self.f[self.states[k]][i+1]*self.b[self.states[k]][i]
        summ=summ/self.prob_bwd
        self.E[self.states[k]][b]+=summ
    

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
          if self.states[k]!='B':  #  transition from B to the rest of the states is maintainted
            self.a[self.states[k]][l]=0.0
        else: 
          if self.states[k]!='B':  # transition from B to the rest of the states is maintainted
           if self.A[self.states[k]][l]/self.sumA[self.states[k]]!=0.0:
             self.a[self.states[k]][l]= self.A[self.states[k]][l]/self.sumA[self.states[k]]
          else:
            self.a[self.states[k]][l]= self.A[self.states[k]][l]/self.sumA[self.states[k]]
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
          self.e[self.states[k]][b]= self.E[self.states[k]][b]/self.sumE[self.states[k]] 
    
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
    #print self.log_prob_sum
    

  def UpgradeHmm(self):
    '''Upgrades HMM'''
    for k in range(len(self.states)):
      if k==len(self.HMM['A']):
        self.HMM['A'].append(self.a[self.states[k]])
      else:
        self.HMM['A'][k]=self.a[self.states[k]]
      
    for k in range(1,len(self.states)):
      self.HMM['E'][k-1]=self.e[self.states[k]]


  def BaumWelchTrain(self,seq):
    '''Trains HMM with provided training sequence'''
    self.GetForward(seq)
    #self.prob_list.append(prob)
    #print self.prob_list
    self.GetBackward(seq)
    self.Reestimation(seq)
    self.CalculateParam()
    self.GetLogLikelihood()
    if  self.log_likelihood_old is not None:
      log_likelihood_incr=abs(abs(self.log_prob_sum)-abs(self.log_likelihood_old))
      if log_likelihood_incr < 0.0001 :
        sys.stderr.write("Log-likelihood change reached\n")
        raise ValueError()
        print ("Log-likelihood change reached\n")
        return (True, self.HMM)
    self.log_likelihood_old=self.log_prob_sum
    return (False,self.HMM)
   
         
