#!/usr/bin/env python

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
#import sys
#print (sys.version)

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
chromStartLab = 'StartT' 
chromEndLab = 'EndT'
chromLab = 'phase'

############################################
inFile  = open (args.input, "rb")
reader = csv.reader (inFile, delimiter='\t')

headers = reader.next ()
indexChromStart = headers.index (chromStartLab)
indexChromEnd = headers.index (chromEndLab)

if chromLab :
    indexChrom = headers.index (chromLab)
else :
    indexChrom = -1

print 'chromStart corresponding field is: %s' % (headers [indexChromStart])
#def getColInd (header, label):
# " This function returns the "
# indexChromStart = headers.index (chromStartLab)
# indexChromEnd = headers.index (chromEndLab)
# print 'chromStart corresponding field is: %s' % (headers [indexChromStart])

dataInt = []

for row in reader:
    dataInt.append (row)
inFile.close()

chromStart = []
chromEnd = []
chromPhases = []

for row in dataInt:
    chromStart.append (int (row [indexChromStart]))
    chromEnd.append (int (row [indexChromEnd]))
    
    if indexChrom != -1 :
        chromPhases.append (row [indexChrom])
    else:
        chromPhases = ['chr1']
    
minChromStart = min (chromStart)
maxChromEnd = max (chromEnd)
print minChromStart
print maxChromEnd

setPhases = set (chromPhases) 

# Reading phases in set of phases
for phChr in setPhases:
    genomeFile = open (os.path.join (pwd, phChr + genomeFileExt), "w")
    genomeFile.write (">" + phChr + "\n")
    genomeFile.write (genericNt * (maxChromEnd - minChromStart))
    genomeFile.close()
    print ('Genome bed file created: %s' % (phChr + genomeFileExt))

# Stuff that might be interesting
#import numpy as np
#A = np.array (dataInt)

#def genGenome (endChr, "N"):
  
## Example with pandas http://stackoverflow.com/questions/16503560/read-specific-columns-from-csv-file-with-python-csv
#import pandas as pd
#df = pd.read_csv (args.input)
#col = df [chromStart]
#print '------%-4s' % (col)



