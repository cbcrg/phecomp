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
        self.fieldsB = self._set_fields_b(kwargs.get ('fields'))        
        self.fieldsG = [_dict_Id [k] for k in self.fieldsB] 
        self.min =  int(self.get_min_max(fields = ["chromStart","chromEnd"])[0])
        self.max =  int(self.get_min_max(fields = ["chromStart","chromEnd"])[1])
                    
    def _set_fields_b(self, fields):
        """
        Reading the behavioral fields from the header file    
        """        
        self.inFile  = open(path, "rb")
        self.reader = csv.reader(self.inFile, delimiter='\t')
        fieldsB = self.reader.next()
        self.inFile.close()
        return fieldsB
    
    def read(self, fields=None, relative_coord=False, fields2rel=None):
        # If I don't have fields then I get all the columns of the file
        if fields is None:
            fields = self.fieldsG
            indexL = range(len(self.fieldsG))
        else:
            try:
                indexL = [self.fieldsG.index(f) for f in fields]                
            except ValueError:
                raise ValueError("Field '%s' not in file %s." % (f, self.path))
        
        idx_fields2rel = [10000000000000]
            
        if relative_coord:
            print "Relative coord is true"
            
            if fields2rel is None:
                print "Iwas here"
                _f2rel = ["chromStart","chromEnd"]        
            else:
                if isinstance(fields2rel, basestring): fields2rel = [fields2rel]
                _f2rel = [f for f in fields2rel if f in self.fieldsG]
                
            try:
                idx_fields2rel = [self.fieldsG.index(f) for f in _f2rel]                
            except ValueError:
                raise ValueError("Field '%s' not in file %s." % (f, self.path))
    
        return dataIter(self._read(indexL, idx_fields2rel))
       
    def _read(self, indexL, idx_fields2rel):
        self.inFile  = open(path, "rb")
        self.reader = csv.reader(self.inFile, delimiter='\t')
        self.reader.next()
        
#         ncol = range (len (self.fieldsG))
        
        for interv in self.reader:
            temp = []            
            for i in indexL:
                if i in idx_fields2rel: 
                    temp.append(int(interv [i]) - self.min + 1)
                else:
                    temp.append(interv [i])
                
            yield(tuple(temp))
            
#         for interv in self.reader:
#             yield tuple (interv [n]
#                          for n in indexL)                    
        self.inFile.close()
        
    def get_min_max(self, fields=None): 
        """
        Return the minimun and maximun of two given fields by default set to chromStart and chromEnd
        """
        pMinMax = [None,None]
        
        if fields is None:
            _f = ["chromStart","chromEnd"]
                        
            for row in self.read(fields=_f):
#                 print row
                if pMinMax[0] is None: pMinMax = list(row)
                if pMinMax[0] > row[0]: pMinMax[0] = row[0]
                if pMinMax[1] < row[1]: pMinMax[1] = row[1]
        else:
            if isinstance(fields, basestring): fields = [fields]
            _f = [f for f in fields if f in self.fieldsG]
            if len(_f) == 0:
                raise ValueError("Fields %s not in track: %s" % (fields, self.fieldsG))
            elif len(_f) != 2:
                raise ValueError("Only two fields can be consider for get_min_max %s: %s" % (fields, self.fieldsG))
        
        for row in self.read(fields=_f):
                if pMinMax[0] is None: pMinMax = list(row)
                if pMinMax[0] > row[0]: pMinMax[0] = row[0]
                if pMinMax[1] < row[1]: pMinMax[1] = row[1]
        
        return pMinMax
                     
    def writeChr(self, mode="w"):
        chrom = 'chr1'
        genomeFile = open(os.path.join(_pwd, chrom + _genomeFileExt), mode)        
        genomeFile.write(">" + chrom + "\n")
        print(self.max - self.min)
        genomeFile.write (genericNt * (self.max - self.min))
        genomeFile.close()
        print('Genome fasta file created: %s' % (chrom + _genomeFileExt))
    
    def writeBed(self, feature="dataValue"):
        try:
            idxFeature = self.fieldsG.index(feature)
            print idxFeature
        except ValueError:
                raise ValueError("Field '%s' correspondence with dataValue was not set for file %s." % (feature, self.path))
        
        idxfields = [self.fieldsG.index('chromStart'), self.fieldsG.index('chromEnd'), idxFeature]
        data_r = self.read()
        
        for row in data_r:
            yield tuple(row [i]
                         for i in idxfields)

################################################################################
class dataIter(object):
    def __init__(self, data, fields="culo"):
        print (type(data))
        if isinstance(data,(tuple)):            
            data = iter(data)
        if not fields:
#             if hasattr(data, 'description'):
#                 fields = [x[0] for x in data.description]
#             else: raise ValueError("Must specify a 'fields' attribute for %s." % self.__str__())
            raise ValueError("Must specify a 'fields' attribute for %s." % self.__str__())
        self.data = data
        self.fields = fields
        
    def __iter__(self):
        return self.data

    def next(self):
        return self.data.next()
    
##########################
## Examples of executions 
         
intData = intData(path)
# intData2 = intData.relative_coord()
# for line in intData2: print line
# # print (intData.max)

s = intData.read(relative_coord=True)
# s.relativ_coor()

for line in s:  print line

# print (type (s))
# d=iter(s)
# n=d.next()
# print n
# i = dataIter(s)
# int=i.next()
# print int
# if isinstance(s,(list,tuple)):
#     print "culo"
# else:
#     print "pedo"    
# Tengo que crear las clases de los objetos correspondientes a cada tipo de datas bed, bedgraph y si hay alguno mas
# Tendran un metodo para hacer write que puede ser diferente segun el tipo o directamente si lo hago bien, simplemente
# cogera las lineas y sera capaz de hacerlo con una funcion generica
# intDataBed = intData.writeBed (feature="dataValue")
# 
# for line in intDataBed:
#     for item in line:
#         print (item),  
#     print ('\n'),


# Stuff that might be interesting
#import numpy as np
#A = np.array (dataInt)

#def genGenome (endChr, "N"):
  
## Example with pandas http://stackoverflow.com/questions/16503560/read-specific-columns-from-csv-file-with-python-csv
#import pandas as pd
#df = pd.read_csv (args.input)
#col = df [chromStart]
#print '------%-4s' % (col)



