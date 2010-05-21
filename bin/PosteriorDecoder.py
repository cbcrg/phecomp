# Posterior decoder HMM trainer
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' Posterior Decoder '''   

import sys
from sys import *
import math
from math import log
import random
import string


class PosteriorDecoder:
  ''' Posterior Decoder'''


  def __init__(self,transition,emission):
    # Class Constructor
    self.a=transition
    self.e=emission
    values=self.a.keys()
    self.states={}
    for value in values:
      self.states[value]=value
    self.symbols={}
    values=self.e['0'].keys()
    for value in values:
      self.symbols[value]=value
   
  def LogXBaseN(self,x,n):
    '''Calculates the log of a number (x) in a given base (n) '''
    if (x==0):
      return -999
    else:
      if (n=='e' or n=='E'):
        return math.log(x)
      else:
        return math.log(x,n)


  def Exp(self,x):
    '''Calculates the exponential value in base e-> e^x '''
    if (x<=-900):
      return 0
    else:
      return math.exp(x)
    

  def GetLogLikelihood(self):
    ''' Calculates log-likelihood'''
    likelihood=0
    for s in self.s: 
      likelihood+=self.LogXBaseN(1/s,2) 
    likelihood*=(-1)
    self.log_prob_sum+=likelihood
    self.log_likelihood_list.append(self.log_prob_sum)
    #print self.log_prob_sum


  def GetForward(self,seq):
    ''' Calculate forward variables using scaling variables'''
       
    self.f={}
    self.s=[]
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
      summe=0
      f={} 
      for newstate in self.states.keys():
        summf=0
        for state in self.states.keys():
          summf+=self.f[state][i]*self.a[state][newstate]
        f[newstate]=self.e[newstate][seq[i]]*summf
        summe+=self.e[newstate][seq[i]]*summf
      self.s.append(summe) 
      #print self.s
      #print self.f
      for newstate in self.states.keys():
        self.f[newstate].append(f[newstate]/self.s[i])# s[i+1]
    # Termination
    ''' The log(P(x)) can be computed, but not P since it would be out of the dynamic range of the computer -> underflow!'''
    '''summ=0
    for si in self.s:
      summ+=self.LogXBaseN(1/si,2) 
    likelihood=(-1)*summ
      #print self.seq_prob
    print likelihood'''
    '''print len(seq)
    print len(self.s)
   
    print self.seq_prob'''
    '''return self.seq_prob'''
    '''length= '%d' %len(self.f['0'])
    print 'Forward length'+length
    length= '%d' %len(self.s)
    print 'Scaling length'+length
    print self.f
    print self.s'''

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
        prob[len(seq)-1]=1/self.s[-1]
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
          self.b[state][i]=summ/self.s[i]#s[i+1]
          #b[state][i]=summ
    #print self.b
    '''length= '%d' %len(self.b['0'])
    print 'Backward length'+length
    print self.b'''
       
  def CalculatePosteriorProbatilities(self,seq):
    ''' Calculate the posterior probabilities for each state '''
    self.posterior={}
   
    # Expected transmission reestimation
    for state in self.states.keys():
       self.posterior[state]={}
       for i in range(len(seq)):
         index='%d' %i
         print 'Index: '+index+'\n'
         print self.f[state][i]
         print self.b[state][i]
         print self.s[i]
         posterior=self.LogXBaseN(self.f[state][i+1],'e')+self.LogXBaseN(self.b[state][i],'e')+self.LogXBaseN(self.s[i],'e')
         print posterior
         self.posterior[state][i]=self.Exp(posterior)
         print self.posterior[state][i]
    return self.posterior


  def Decode(self,seq):
    '''Trains HMM with provided training sequence'''
      
    self.GetForward(seq)
    self.GetBackward(seq)
    post_prob=self.CalculatePosteriorProbatilities(seq)
    
    return (post_prob)   

