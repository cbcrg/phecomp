#!/usr/bin/env python

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
#import sys
#print (sys.version)

## Classes
class identity:
    def __init__(self, field, header):
        self.field = field
        self.header = header
    def index (self):
        if self.field:
            return self.header.index (self.field)
        else:
            return -1  
        
        
## VARIABLES
pwd = os.getcwd ()
genomeFileExt = ".fa"
genericNt = "N"
parser = argparse.ArgumentParser (description = 'Script to transform behavioral data into GB readable data')
parser.add_argument ('-i','--input', help='Input file name',required=True)
parser.add_argument ('-o','--output',help='Output file name', required=False)
args = parser.parse_args ()

## show values ##
print ("Input file: %s" % args.input )
print ("Output file: %s" % args.output )

## Input debugging file
#cat 20120502_FDF_CRG_hab_filtSHORT.csv | sed 's/ //g' | awk '{print $1"\t"$14"\t"$6"\t"$11"\t"$16"\thabituation"}' > shortDev.integer

############################################
## This should be in the configuration file
## With name or with column index (OPTION) or check whether is an integer or a string 
## One possible solution might be to read the configuration file in order to generate the command line

## I can use both things, the former if I don't have to separate into different chromosomes given a field and the later if I want
chrom = ''
chrom = 'phase'
chromStart = 'StartT' 
chromEnd = 'EndT'
dataValue = 'Nature'
track = 'CAGE'

############################################
inFile  = open (args.input, "rb")
reader = csv.reader (inFile, delimiter='\t')

headers = reader.next ()
## Old way to get the index, I have change to a class
# indexChromStart = headers.index (chromStart)
# indexChromEnd = headers.index (chromEnd)
# indexDataValue = headers.index (dataValue)
# indexDataValue = headers.index (dataValue)

chromStartId = identity (chromStart, headers)
chromEndId = identity (chromStart, headers)
dataValueId = identity (chromStart, headers)
chromStartId = identity (chromStart, headers)
chromId = identity (chrom, headers)
print 'My first class is working: ---- %s --- %d' % (chromStartId.field, chromStartId.index())

print 'My first class is working and even better: ---- %s --- %d' % (chromId.field, chromId.index())
     
## Getting whether a field to consider as different chromosomes is set, for example experiment phase
# if chrom :
#     indexChrom = headers.index (chrom)
# else :
#     indexChrom = -1
# 
# print 'chromStart corresponding field is: %s' % (chromStartId.index)
#def getColInd (header, label):
# " This function returns the "
# indexChromStart = headers.index (chromStartLab)
# indexChromEnd = headers.index (chromEndLab)
# print 'chromStart corresponding field is: %s' % (headers [indexChromStart])

dataInt = []

for row in reader:
    dataInt.append (row)
inFile.close()

chromStartData = []
chromEndData = []
chromPhasesData = []

# Hacerlo sin copiar los datos mas rapido
for row in dataInt:
    chromStartData.append (int (row [chromStartId.index()]))
    chromEndData.append (int (row [chromEndId.index ()]))
    
    if chromId.index() != -1 :
        chromPhasesData.append (row [chromId.index()])
    else:
        chromPhasesData = ['chr1']
    
minChromStart = min (chromStartData)
maxChromEnd = max (chromEndData)
print minChromStart
print maxChromEnd

setPhases = set (chromPhasesData) 

# Reading phases in set of phases
for phChr in setPhases:
    genomeFile = open (os.path.join (pwd, phChr + genomeFileExt), "w")
    genomeFile.write (">" + phChr + "\n")
    genomeFile.write (genericNt * (maxChromEnd - minChromStart))
    genomeFile.close ()
    print ('Genome bed file created: %s' % (phChr + genomeFileExt))

dataInt2 = {}

# I have to generalize the nature stuff, so what I have to do is to provide as key the field that users have selected as 
# the dataValue of bed and BedGraph files
# Probably when I am more proficiency in python I should do a class by the moment I just code this
# Whan features of the class will be like here acessing values by giving the two keys 
#http://codereview.stackexchange.com/questions/31907/what-are-the-drawbacks-of-this-multi-key-dictionary
# http://en.wikibooks.org/wiki/A_Beginner%27s_Python_Tutorial/Classes
# dict [cage][nature] in my data


# for r in dataInt:
#     dataInt2 [dataInt [indexDataValue]] = 




# Stuff that might be interesting
#import numpy as np
#A = np.array (dataInt)

#def genGenome (endChr, "N"):
  
## Example with pandas http://stackoverflow.com/questions/16503560/read-specific-columns-from-csv-file-with-python-csv
#import pandas as pd
#df = pd.read_csv (args.input)
#col = df [chromStart]
#print '------%-4s' % (col)



