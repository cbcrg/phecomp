#!/usr/bin/env python

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
#import sys
#print (sys.version)

### Classes
## fieldG --> field in genome format
## fieldP --> correspoding field in phenome format

class identity:
    def __init__(self, fieldG, dictFields, header):
        self.fieldG = fieldG        
        self.header = header
        self.fieldB = dictFields.get (fieldG, 'None')             
    def index (self):
        if self.fieldB != 'None':
            return self.header.index (self.fieldB)
        else:
            return self.fieldB  
        
        
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
# chrom = ''
# chrom = 'phase'
# chromStart = 'StartT' 
# chromEnd = 'EndT'
# dataTypes = 'Nature'
# dataValue = 'Value'
# track = 'CAGE'

dictId = {'chrom': 'phase', 
          'chromStart': 'StartT',  
          'chromEnd': 'EndT', 
          'dataTypes': 'Nature', 
          'dataValue': 'Value', 
          'track': 'CAGE' }

############################################
inFile  = open (args.input, "rb")
reader = csv.reader (inFile, delimiter='\t')

headers = reader.next ()

chromId = identity ('chrom', dictId, headers)
chromStartId = identity ('chromStart', dictId, headers)
chromEndId = identity ('chromEnd', dictId, headers)
dataTypesId = identity ('dataTypes', dictId, headers)
dataValueId = identity ('dataValue', dictId, headers)

print 'My first class is working: ---- %s --- %d' % (chromStartId.fieldB, chromStartId.index())

print 'My first class is working and even better: ---- %s --- %d' % (chromId.fieldB, chromId.index())
     
dataInt = []

for row in reader:
    dataInt.append (row)
inFile.close()

chromStartData = []
chromEndData = []
chromPhasesData = []

## Hacerlo sin copiar los datos mas rapido #del
for row in dataInt:
    chromStartData.append (int (row [chromStartId.index()]))
    chromEndData.append (int (row [chromEndId.index ()]))
    
    if chromId.index() != -1 :
        chromPhasesData.append (row [chromId.index()])
    else:
        chromPhasesData = ['chr1']

## Para cada phase tengo que hacer un chromosoma
    
minChromStart = min (chromStartData)
maxChromEnd = max (chromEndData)
print minChromStart
print maxChromEnd

setPhases = set (chromPhasesData) 

## Writing fasta files corresponding to chromosomes
## One for each phases
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



