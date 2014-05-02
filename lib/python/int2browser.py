#!/usr/bin/env python

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
import itertools
import operator
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
_bedFileExt = ".bed"
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

_intervals = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 1, 1000]

_dict_out_files = {'bed' : '_convert2bed',
                   'bedGraph': '.bedGraph'}
_black_gradient = ["226,226,226", "198,198,198", "170,170,170", "141,141,141", "113,113,113", "85,85,85", "56,56,56", "28,28,28", "0,0,0"]
_blue_gradient = ["229,229,254", "203,203,254", "178,178,254", "152,152,254", "127,127,254", "102,102,254", "76,76,173", "51,51,162", "0,0,128"]
_red_gradient = ["254,172,182", "254,153,162", "254,134,142", "254,115,121", "254,96,101", "254,77,81", "254,57,61", "254,38,40", "254,19,20"]
_green_gradient = ["203,254,203", "178,254,178", "152,254,152", "127,254,127", "102,254,102", "76,254,76", "51,254,51", "0,254,0", "25,115,25"]

_dict_col_grad = {
                  'water' : _blue_gradient,
                  'drink' : _blue_gradient,
                  'food' : _black_gradient,
                  'food_sc' : _black_gradient,
                  'food_cd' : _red_gradient,
                  'food_fat' : _red_gradient}


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
        self.tracks =  self.get_field_items (field="track")
        self.dataTypes = self.get_field_items (field="dataTypes")
        self.format = "csv"
                    
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
                _f2rel = ["chromStart","chromEnd"]        
            else:
                if isinstance(fields2rel, basestring): fields2rel = [fields2rel]
                _f2rel = [f for f in fields2rel if f in self.fieldsG]
                
            try:
                idx_fields2rel = [self.fieldsG.index(f) for f in _f2rel]                
            except ValueError:
                raise ValueError("Field '%s' not in file %s." % (f, self.path))
    
        return dataIter(self._read(indexL, idx_fields2rel), self.fieldsG)
       
    def _read(self, indexL, idx_fields2rel):
        self.inFile  = open(path, "rb")
        self.reader = csv.reader(self.inFile, delimiter='\t')
        self.reader.next()
        
        for interv in self.reader:
            temp = []            
            for i in indexL:
                if i in idx_fields2rel: 
                    temp.append(int(interv [i]) - self.min + 1)
                else:
                    temp.append(interv [i])
                
            yield(tuple(temp))
                         
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
    
    def get_field_items(self, field="dataTypes"): 
        """
        Return a list with all the possible data types present in the column that was set as dataTypes
        """
        try:
            field in self.fieldsG                
        except ValueError:
            raise ValueError("Field '%s' not in file %s." % (f, self.path))
        
        idx_field = self.fieldsG.index (field)
        field = [field]    
        set_fields = set()
               
        for row in self.read():
#             if row[idx_field] not in set_fields: # Not needed
            set_fields.add(row[idx_field])
                    
        return set_fields
                     
    def writeChr(self, mode="w"):
        chrom = 'chr1'
        genomeFile = open(os.path.join(_pwd, chrom + _genomeFileExt), mode)        
        genomeFile.write(">" + chrom + "\n")
#         print(self.max - self.min)
        genomeFile.write (genericNt * (self.max - self.min))
        genomeFile.close()
        print('Genome fasta file created: %s' % (chrom + _genomeFileExt))
              
    def convert(self, mode = None, **kwargs):
        kwargs['relative_coord'] = kwargs.get("relative_coord",False)
        print self.fieldsG
        if mode not in _dict_out_files: 
            raise ValueError("Mode \'%s\' not available. Possible convert() modes are %s"%(mode,', '.join(['{}'.format(m) for m in _dict_out_files.keys()])))
        
        dict = ({ 'bed': self._convert2bed, 'bedGraph': self._convert2bedGraph}.get(mode)(self.read(**kwargs))) 
#         return Bed({ 'bed': self._convert2bed, 'bedGraph': self._convert2bedGraph}.get(mode)(self.read(**kwargs)))  
#             return { 'bed': self._convert2bed, 'bedGraph': self._convert2bedGraph}.get(mode)(self.read(**kwargs))
        return (dict)
    
    def _convert2bed (self, data_tuple, split_dataType=False):
        """
        Transform data into a bed file if all the necessary fields present
        """                        
        ### Muy importante aqui puedo implementar las opciones de que separan en multiples bedGraph 
        ## dependiendo del numero de dataTypes y tracks
        track = "cage1_test"
        mode = "w"
        bed_file = open(os.path.join(_pwd, track + _bedFileExt), mode)        
        bed_file.write('track name="cage 1;drink" description="cage 1;drink" visibility=2 itemRgb="On" priority=20' + "\n")
        
        track_dict = {}
        
        for key,group in itertools.groupby(data_tuple,operator.itemgetter(self.fieldsG.index("track"))):
            track_tuple = tuple(group)
            #Esto lo tengo que poner en otra funcion privada que cree el bed quiza lo podria sacar fuera tambien al convert
            # el problema de sacarlo fuera es la llamada a la funcion pero puedo resolverlo quiza llamandola una por cada vez con 
            # la misma sintaxis
            track_dict[key]=Bed(self.track_convert2bed(track_tuple, True))
        return track_dict
            
    def track_convert2bed (self, track, in_call=False):    
        #fields pass to read should be the ones of bed file
        _bed_fields = ["track","chromStart","chromEnd","dataTypes", "dataValue"]         
        #Check whether these fields are in the original otherwise raise exception
        try:
            idx_f = [self.fieldsG.index(f) for f in _bed_fields]                          
        except ValueError:
            raise ValueError("Mandatory field for bed creation '%s' not in file %s." % (f, self.path))

        if (not in_call and len(self.tracks)  != 1):            
            raise ValueError("Your file '%s' has more than one track, only single tracks can be converted to bed" % (self.path)) 
        
        for row in track:
            temp_list = [] 
                      
            for i in idx_f:
                if self.fieldsG[i] == "track":
                    temp_list.append("chr" + row[i])
        #                     bed_file.write("chr%s\t"%row[i])
                elif self.fieldsG[i] == "chromStart":
                    thickStart = row[i]
        #                     bed_file.write("%s\t"%row[i])
                    temp_list.append(row[i])
                elif self.fieldsG[i] == "chromEnd":
                    thickEnd = row[i]
        #                     bed_file.write("%s\t"%row[i])
                    temp_list.append(row[i])
                elif self.fieldsG[i] == "dataValue":
        #                     bed_file.write("%s\t"%row[i])
                    temp_list.append(row[i])
                    for v in _intervals:
                        if float(row[i]) <= v:
                            j = _intervals.index(v)                        
                            type = row [self.fieldsG.index("dataTypes")]                        
                            color = _dict_col_grad[type][j]
                            break        
                else:
        #                     bed_file.write("%s\t"%row[i])
                    temp_list.append(row[i])
        #             bed_file.write("+\t")
            temp_list.append("+")
        #             bed_file.write("%s\t"%thickStart)
            temp_list.append(thickStart)
        #             bed_file.write("%s\t"%thickEnd)
            temp_list.append(thickEnd)
        #             bed_file.write("%s\t"%color)
            temp_list.append(color) 
        #             bed_file.write("\n")
        #             bed_file.close
            yield(tuple(temp_list))
    
    def _convert2bedGraph(self, data_tuple):
        print "Sorry still not develop"
        
    def _error (self, data_tuple):
        raise ValueError("culo")
         
################################################################################
class dataIter(object):
    def __init__(self, data, fields=None):
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
    
    ### WRITE TIENE QUE ESTAR AQUI DE MANERA QUE TODOS LAS CLASES QUE HEREDAN BED, BEDGRAPH ETC SE PUEDA HACER EL OUTPUT A UN ARCHIVO
#     def write(self):
        

def write (data, file_type="bed", mode="w"):    
    if not(isinstance(data, dataIter)):
        t = type(data)
        raise Exception("Object must be dataIter, '%s' of '%s' is not supported."%(data, t))
   
    _fileFields = ["track","chromStart","chromEnd","dataTypes", "dataValue"]
#     _bedfile_fields = ["track","chromStart","chromEnd","dataValue"] 
     
    f2print = [data.fields.index(f) for f in _fileFields]
    
    print (f2print)
    track = "cage1_test"
    bed_file = open(os.path.join(_pwd, track + _bedFileExt), mode)        
    bed_file.write('track name="cage 1;drink" description="cage 1;drink" visibility=2 itemRgb="On" priority=20' + "\n")
    for row in data.data:         
        for i in f2print:
            if data.fields[i] == "track":
                bed_file.write("chr%s\t"%row[i])
            elif data.fields[i] == "chromStart":
                thickStart = row[i]
                bed_file.write("%s\t"%row[i])
            elif data.fields[i] == "chromEnd":
                thickEnd = row[i]
                bed_file.write("%s\t"%row[i])
            elif data.fields[i] == "dataValue":
                bed_file.write("%s\t"%row[i])
                for v in _intervals:
                    if float(row[i]) <= v:
                        j = _intervals.index(v)                        
                        type = row [data.fields.index("dataTypes")]                        
                        color = _dict_col_grad[type][j]
                        break        
            else:
                bed_file.write("%s\t"%row[i])
                
        bed_file.write("+\t")
        bed_file.write("%s\t"%thickStart)
        bed_file.write("%s\t"%thickEnd)
        
        bed_file.write("%s\t"%color) 
        bed_file.write("\n")
    bed_file.close
                     

################################ Bed ##########################################

class Bed(dataIter):
    """
    dataInt class for bed file format data
    
    Fields used in this application are:
        
         ['chr','start','end','name','score','strand',
          'thick_start','thick_end','item_rgb']
          
    """
    def __init__(self,data,**kwargs):
#         kwargs['format'] = 'bed'
        kwargs['fields'] = ['chr','start','end','name','score','strand','thick_start','thick_end','item_rgb']
        dataIter.__init__(self,data,**kwargs)

class ObjectContainer():
    pass 
        
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

##########################
## Examples of executions 
         
intData = intData(path)
print (intData.get_field_items("dataTypes"))
print(intData.min)
# intData2 = intData.relative_coord()
 
intData.convert(mode = "bed", relative_coord = True)   
bedFiles = intData.convert(mode = "bed", relative_coord = True)
s=intData.read()
bedFile = intData.track_convert2bed(s)
for line in bedFile:
     print (line) 






# for key in bedFiles:
#     bed = bedFiles [key]
#     print ("bed file" + key)
#     for line in bed:  print line

# s = intData.read(relative_coord = True, )

# print (s.fields)
# write(s)

# print (intData.get_min_max(fields=["dataValue", "dataValue"]))
# print (intData.tracks)
# print (intData.dataTypes)

# s2=write(s)
# for line in s2: print line
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

#pybedtools examples
# import pybedtools
# x = pybedtools.BedTool('path/to/bam')
# x.genome_coverage(bg=True, genome='hg19', split=True)\
#     .saveas('path/to/bedgraph', trackline='track name="test track" visibility="full" type=bedGraph')
        


data=[(1, 'A', 'foo'),
    (2, 'A', 'bar'),
    (100, 'A', 'foo-bar'),
     (300, 'A', 'foo-bar'),
 
    ('xx', 'B', 'foobar'),
    ('yy', 'B', 'foo'),
    ('yx', 'B', 'foo'),
     
    (1000, 'C', 'py'),
    (200, 'C', 'foo'),
    ]
#  
# for key,group in itertools.groupby(data,operator.itemgetter(1,2)):
#     print(tuple(group))
