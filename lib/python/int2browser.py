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
        if self.fieldB is not 'None':
            return self.header.index (self.fieldB)
        else:
            return self.fieldB  
        
        
## VARIABLES
_pwd = os.getcwd ()
_genomeFileExt = ".fa"
genericNt = "N"
parser = argparse.ArgumentParser (description = 'Script to transform behavioral data into GB readable data')
parser.add_argument ('-i','--input', help='Input file name',required=True)
parser.add_argument ('-o','--output',help='Output file name', required=False)
args = parser.parse_args ()

## show values ##
print ("Input file: %s" % args.input )
print ("Output file: %s" % args.output )

path = args.input
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

_dict_Id = {'phase' :'chrom', 
            'StartT' : 'chromStart',  
            'EndT' :'chromEnd', 
            'Nature' : 'dataTypes', 
            'Value' : 'dataValue', 
            'CAGE' : 'track'}

############################################
# inFile  = open (args.input, "rb")
# reader = csv.reader (inFile, delimiter='\t')

# headers = reader.next ()

# chromId = identity ('chrom', _dict_Id, headers)
# chromStartId = identity ('chromStart', _dict_Id, headers)
# chromEndId = identity ('chromEnd', _dict_Id, headers)
# dataTypesId = identity ('dataTypes', _dict_Id, headers)
# dataValueId = identity ('dataValue', _dict_Id, headers)
# 
# print 'My first class is working: ---- %s --- %d' % (chromStartId.fieldB, chromStartId.index())
# 
# print 'My first class is working and even better: ---- %s --- %d' % (chromId.fieldB, chromId.index())

## I have to create a class able to keep the data and the fields

class intData: # if I name it as int I think is like self but with a better name
    """
    Generic class for data
    Possible thinks to implement
    .. attribute:: fieldsB 
    
    list with the behavioral fields corresponding each column in the original file
     
    """
    #le meto el diccionario entre behavior and genomic data como un parametro y por defecto le pongo el diccionario del ejemplo
    def __init__(self, path, **kwargs):
        self.path = path
        self.fieldsB = self._set_fields_b (kwargs.get ('fields'))
#         intev.__init__(self, path, **kwargs)
#         self.intypes = dict((k,v) for k,v in _in_types.iteritems() if k in self.fields)
#         self.fieldsG = self._set_correspondencies ()        
        self.fieldsG = [_dict_Id [k] for k in self.fieldsB] 
        self.min =  int (self.get_min_max ()[0])
        self.max =  int (self.get_min_max (fields = ["chromStart","chromEnd"])[1])
                    
    def _set_fields_b (self, fields):
        """
        Reading the behavioral fields from the header file    
        """        
        self.inFile  = open (path, "rb")
        self.reader = csv.reader (self.inFile, delimiter='\t')
        fieldsB = self.reader.next ()
        self.inFile.close ()
        return fieldsB
        
    def read (self, fields=None):
        # If I don't have fields then I get all the columns of the file
        if fields is None:
            fields = self.fieldsG
            indexL = range (len (self.fieldsG))
        else:
            try:
                indexL = [self.fieldsG.index (f) for f in fields]                
            except ValueError:
                raise ValueError ("Field '%s' not in file %s." % (f, self.path))
        
        self.inFile  = open (path, "rb")
        self.reader = csv.reader (self.inFile, delimiter='\t')
        self.reader.next ()
        
#         print indexL
        for interv in self.reader:
            yield tuple (interv [indexL[n]]
                         for n,f in enumerate(fields))                    
        self.inFile.close()
        
    def get_min_max (self, fields=None): 
        """
        Return the minimun and maximun of two given fields by default set to chromStart and chromEnd
        """
        pMinMax = [None,None]
        
        if fields is None:
            _f = ["chromStart","chromEnd"]
                        
            for row in self.read (fields=_f):
#                 print row
                if pMinMax[0] is None: pMinMax = list (row)
                if pMinMax[0] > row[0]: pMinMax[0] = row[0]
                if pMinMax[1] < row[1]: pMinMax[1] = row[1]
        else:
            if isinstance (fields, basestring): fields = [fields]
            _f = [f for f in fields if f in self.fieldsG]
            if len(_f) == 0:
                raise ValueError("Fields %s not in track: %s" % (fields, self.fieldsG))
            elif len(_f) != 2:
                raise ValueError("Only two fields can be consider for get_min_max %s: %s" % (fields, self.fieldsG))
        
        for row in self.read (fields=_f):
                if pMinMax[0] is None: pMinMax = list(row)
                if pMinMax[0] > row[0]: pMinMax[0] = row[0]
                if pMinMax[1] < row[1]: pMinMax[1] = row[1]
        
        return pMinMax

    def relative_coord (self, fields2rel=None):
        print self.fieldsG
#         print self.fieldsG.index (fields2rel)
        
        if fields2rel is None:
            _f2rel = ["chromStart","chromEnd"]        
        else:
            if isinstance (fields2rel, basestring): fields2rel = [fields2rel]
            _f2rel = [f for f in fields2rel if f in self.fieldsG]
                                                             
        try:
            idxfields = [self.fieldsG.index(f) for f in _f2rel]                
        except ValueError:
            raise ValueError("Field '%s' not in file %s." % (f, self.path))
                
        data_r = self.read ()
        ncol = range (len (self.fieldsG))

        for row in data_r:
            temp = []            
            for i in ncol:
                if i in idxfields: 
                    temp.append(int(row [i]) - self.min + 1)
                else:
                    temp.append(row [i])
                
            yield (tuple (temp))
                     
    def writeChr (self, mode="w"):
        chrom = 'chr1'
        genomeFile = open (os.path.join (_pwd, chrom + _genomeFileExt), mode)        
        genomeFile.write (">" + chrom + "\n")
        print (self.max - self.min)
        genomeFile.write (genericNt * (self.max - self.min))
        genomeFile.close ()
        print ('Genome fasta file created: %s' % (chrom + _genomeFileExt))
    
    def writeBed (self, feature="dataValue"):
        try:
            idxFeature = self.fieldsG.index (feature)
            print idxFeature
        except ValueError:
                raise ValueError ("Field '%s' correspondence with dataValue was not set for file %s." % (feature, self.path))
        
        idxfields = [self.fieldsG.index ('chromStart'), self.fieldsG.index ('chromEnd'), idxFeature]
        data_r = self.read ()
        
        for row in data_r:
#             print row [4]
            yield tuple (row [i]
                         for i in idxfields)
#             print row [idxFeature]
        
            
intData = intData (path, fields = ["chromStart","chromEnd"])

# print (intData.get_min_max())

# intData.writeChr ()
# print intData.get_min_max (fields = ["chromStart","chromEnd"])
intDataBed = intData.writeBed (feature="dataValue")

# for line in intDataBed:
#     for i in line:
#         print i

for line in intDataBed:
    for item in line:
        print (item),  
    print ('\n')

# intDataRel = intData.relative_coord (fields2rel = ["chromStart","chromEnd"])

# for line in intDataRel:
#      print line

# intDataRel.writeBed (feature="dataValue")
# definir una funcion interna en la cual se pueda precisar cual es el field usado para el subset, o none para ponerlo todo en un mismo archivo
# de momento puedo crear una sencilla que lo haga todo en un solo archivo.


# print (intDataCrop.get_min_max ())
# print intData.fieldsB
# print intData.fieldsG
# for x in culo:
#     print x

# print (intData.get_min_max())
# class identity:
#     def __init__(self, fieldG, dictFields, header):
#         self.fieldG = fieldG        
#         self.header = header
#         self.fieldB = dictFields.get (fieldG, 'None')             
#     def index (self):
#         if self.fieldB != 'None':
#             return self.header.index (self.fieldB)
#         else:
#             return self.fieldB  


# dataInt = []
# 
# for row in reader:
# #     dataInt.append (row)
#     dataInt.append ({'chr': row [chromId.index()],
#                      'start': row [chromStartId.index ()],
#                      'end': row [chromEndId.index ()],})
# inFile.close()

## Getting just 

# chromStartData = []
# chromEndData = []
# chromPhasesData = []

## Hacerlo sin copiar los datos mas rapido #del

    
# for row in dataInt:
#     chromStartData.append (int (row [chromStartId.index()]))
#     chromEndData.append (int (row [chromEndId.index ()]))
#     
#     if chromId.index() != -1 :
#         chromPhasesData.append (row [chromId.index()])
#     else:
#         chromPhasesData = ['chr1']
# 
# ## Para cada phase tengo que hacer un chromosoma
#     
# minChromStart = min (chromStartData)
# maxChromEnd = max (chromEndData)
# print minChromStart
# print maxChromEnd
# 
# setPhases = set (chromPhasesData) 
# 
# ## Writing fasta files corresponding to chromosomes
# ## One for each phases
# for phChr in setPhases:
#     genomeFile = open (os.path.join (pwd, phChr + genomeFileExt), "w")
#     genomeFile.write (">" + phChr + "\n")
#     genomeFile.write (genericNt * (maxChromEnd - minChromStart))
#     genomeFile.close ()
#     print ('Genome bed file created: %s' % (phChr + genomeFileExt))
# 
# dataInt2 = {}

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



