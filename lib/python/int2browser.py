#!/usr/bin/env python

from __future__ import division
# from pybedtools import BedTool

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
import itertools
import operator
#import sys
#print (sys.version)

## fieldG --> field in genome format
## fieldP --> correspoding field in phenome format
        
## VARIABLES
_pwd = os.getcwd ()
_genomeFileExt = ".fa"
_bedFileExt = ".bed"
_bedGraphFileExt = ".bedGraph"
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

_dict_file = {'bed' : '.bed',
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
#         self.format = "csv"
                    
    def _set_fields_b(self, fields):
        """
        Reading the behavioral fields from the header file    
        """        
        self.inFile  = open(path, "rb")
        self.reader = csv.reader(self.inFile, delimiter='\t')
        fieldsB = self.reader.next()
        self.inFile.close()
        return fieldsB
       
    def read(self, fields=None, relative_coord=False, fields2rel=None, **kwargs):
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
        
    def get_min_max(self, fields=None, **kwargs): 
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
        
        for row in self.read(fields=_f, **kwargs):
                if pMinMax[0] is None: pMinMax = list(row)
                if pMinMax[0] > row[0]: pMinMax[0] = row[0]
                if pMinMax[1] < row[1]: pMinMax[1] = row[1]
       
        print pMinMax
        return pMinMax
    
    def get_field_items(self, field="dataTypes"): 
        """
        Return a list with all the possible data types present in the column that was set as dataTypes
        """
        try:
            field in self.fieldsG                
        except ValueError:
            raise ValueError("Field '%s' not in file %s." % (field, self.path))
        
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
        kwargs['split_dataTypes'] = kwargs.get("split_dataTypes",False)
        
        print self.fieldsG
        if mode not in _dict_file: 
            raise ValueError("Mode \'%s\' not available. Possible convert() modes are %s"%(mode,', '.join(['{}'.format(m) for m in _dict_file.keys()])))
        
#         dict_beds = ({ 'bed': self._convert2bed, 'bedGraph': self._convert2bedGraph}.get(mode)(self.read(**kwargs), kwargs.get('split_dataTypes')))
        dict_beds = (self._convert2single_track(self.read(**kwargs), kwargs.get('split_dataTypes'), mode)) 
        return (dict_beds)
        
    def _convert2single_track (self, data_tuple, split_dataTypes=False, mode=None):
        """
        Transform data into a bed file if all the necessary fields present
        """   
        if mode is None:
            mode='bed'                      
        idx_fields2split = [self.fieldsG.index("track"), self.fieldsG.index("dataTypes")] if split_dataTypes else [self.fieldsG.index("track")]
        track_dict = {}
        data_tuple=sorted(data_tuple,key=operator.itemgetter(*idx_fields2split))
        
        for key,group in itertools.groupby(data_tuple,operator.itemgetter(*idx_fields2split)):            
            track_tuple = tuple(group)
            if mode=='bed':
                if not split_dataTypes and len(key)==1:
                    track_dict[(key, '_'.join(self.dataTypes))]=Bed(self.track_convert2bed(track_tuple, True))
                    print "====%s"%key 
                elif split_dataTypes and len(key)==2:                 
                    track_dict[key]=Bed(self.track_convert2bed(track_tuple, True))
                    print "====%s"%key
                else:    
                    raise ValueError("Key of converted dictionary needs 1 or two items %s" % (str(key)))
            elif mode=='bedGraph':
                if not split_dataTypes and len(key)==1:
                    track_dict[(key, '_'.join(self.dataTypes))]=BedGraph(self.track_convert2bedGraph(track_tuple, True))
                    print "====%s"%key
                elif split_dataTypes and len(key)==2:                 
                    track_dict[key]=Bed(self.track_convert2bedGraph(track_tuple, True))
                    print "====%s"%key
                else:    
                    raise ValueError("Key of converted dictionary needs 1 or two items %s" % (str(key)))
            else:
                raise ValueError("Track mode does not exist %s"%mode)
                     
        return track_dict
    
    def track_convert2bed (self, track, in_call=False):
        #fields pass to read should be the ones of bed file
        _bed_fields = ["track","chromStart","chromEnd","dataTypes", "dataValue"]
        #Check whether these fields are in the original otherwise raise exception
        try:
            [self.fieldsG.index(f) for f in _bed_fields]
        except ValueError:
            raise ValueError("Mandatory field for bed creation '%s' not in file %s." % (f, self.path))

        if (not in_call and len(self.tracks) != 1):
            raise ValueError("Your file '%s' has more than one track, only single tracks can be converted to bed" % (self.path))
        
#         i_track = self.fieldsG.index("track")
        i_chr_start = self.fieldsG.index("chromStart")
        i_chr_end = self.fieldsG.index("chromEnd")
        i_data_value = self.fieldsG.index("dataValue")
        i_data_types = self.fieldsG.index("dataTypes")
            
        for row in track:
            temp_list = []
            temp_list.append("chr1")
            temp_list.append(row[i_chr_start])
            temp_list.append(row[i_chr_end])
            temp_list.append(row[i_data_types]) 
            temp_list.append(row[i_data_value])   
            temp_list.append("+")
            temp_list.append(row[i_chr_start])
            temp_list.append(row[i_chr_end])
            for v in _intervals:
                if float(row[i_data_value]) <= v:
                    j = _intervals.index(v)
                    d_type = row [self.fieldsG.index("dataTypes")]
                    color = _dict_col_grad[d_type][j]
                    break
            temp_list.append(color)          
            
            yield(tuple(temp_list))
                    
    def track_convert2bedGraph(self, track, in_call=False):
        _bed_fields = ["track","chromStart","chromEnd","dataValue"] 
        #Check whether these fields are in the original otherwise raise exception
        try:
            idx_f = [self.fieldsG.index(f) for f in _bed_fields]                          
        except ValueError:
            raise ValueError("Mandatory field for bed creation '%s' not in file %s." % (f, self.path))
        
        if (not in_call and len(self.tracks)  != 1):            
            raise ValueError("Your file '%s' has more than one track, only single tracks can be converted to bedGraph" % (self.path))
        
        i_track = self.fieldsG.index("track")
        i_chr_start = self.fieldsG.index("chromStart")
        i_chr_end = self.fieldsG.index("chromEnd")
        i_data_value = self.fieldsG.index("dataValue")
        ini_window = 1
        delta_window = 300
        end_window = delta_window
        partial_value = 0 
        cross_interv_dict = {}
                                     
        for row in track:
            temp_list = []
            
            chr_start = row[i_chr_start]
            chr_end = row[i_chr_end]
            data_value = float(row[i_data_value])
            self.fieldsG.index(f) 
                     
            
#             print "^^^^%s"%self.min
#             if ($relIniTime > $endInt)
            #Intervals happening after the current window
            #if there is a value accumulated it has to be dumped otherwise 0
            if chr_start > end_window:
                while (end_window < chr_start):
                    print ("--------%s=====%s"%(chr_start, end_window))                                        
                    partial_value = partial_value + cross_interv_dict.get(ini_window,0)
                    temp_list.append("chr1")
                    temp_list.append(ini_window)
                    temp_list.append(end_window)
                    temp_list.append(partial_value)
                    partial_value = 0
                    ini_window += delta_window
                    end_window += delta_window                                 
                    yield(tuple(temp_list))
                    temp_list = []
            #Value must to be waited between intervals
                if chr_end > end_window:                 
                    value2weight = data_value
                    end_w = end_window
    #                 start_w = ini_window
                    start_new = chr_start
                    end_new = chr_end
                    
    #                 for ($start_w; $start_w<=$relEndTime; $start_w=$start_w+$winSize)
                    for start_w in range (ini_window, chr_end, delta_window):
                        weighted_value = 0
                        
                        if (end_w == start_w):
    #                         $weightedInt = ($end - $startNew + 1) / ($endNew - $startNew);
                            print ("----->%s - %s / %s - %s"%(end_w,start_new,end_new,start_new))#del
                            weighted_value = (end_w - start_new + 1) / (end_new - start_new)
                        else: 
    #                         $weightedInt = ($end - $startNew) / ($endNew - $startNew);
                            print ("----->%s - %s / %s - %s"%(end_w,start_new,end_new,start_new)) #del    
                            weighted_value = (end_w - start_new) / (end_new - start_new)
                            print ("%s ==========weighted value inside else"%weighted_value)
                            print type(weighted_value)
                        print ("%s ==========weighted value"%weighted_value)
                        weighted_value *= value2weight
                        print ("%s ==========weighted value"%weighted_value)
                        cross_interv_dict[start_w] = int(cross_interv_dict.get(start_w,0)) + float(weighted_value)
                        
                        start_new = end_w
                        value2weight = value2weight - weighted_value
                        
    #                     if (($end + $winSize) >= $relEndTime)
                        if ((end_w + delta_window) >= chr_end):
                            new_start_w = start_w + delta_window
#                             print (cross_interv_dict.get(new_start_w,0))#del
#                             print (int(value2weight))#del
                            cross_interv_dict[new_start_w] = cross_interv_dict.get(new_start_w,0) + value2weight
                            break
                        
                        end_w = end_w + delta_window
                else:
                    partial_value = partial_value + data_value
                    
#             elsif ($relIniTime <= $endInt && $relIniTime => $startInt)        
            elif (chr_start <= end_window and chr_start >= ini_window):
                if chr_end <= end_window:
                    partial_value = partial_value + data_value
                 
                
                else:
                    value2weight = data_value
                    end_w = end_window
    #                 start_w = ini_window
                    start_new = chr_start
                    end_new = chr_end
                    
    #                 for ($start_w; $start_w<=$relEndTime; $start_w=$start_w+$winSize)
                    for start_w in range (ini_window, chr_end, delta_window):
                        weighted_value = 0
                        
                        if (end_w == start_w):
    #                         $weightedInt = ($end - $startNew + 1) / ($endNew - $startNew);
                            print ("----->%s - %s / %s - %s"%(end_w,start_new,end_new,start_new))#del
                            weighted_value = (end_w - start_new + 1) / (end_new - start_new)
                        else: 
    #                         $weightedInt = ($end - $startNew) / ($endNew - $startNew);
                            print ("----->%s - %s / %s - %s"%(end_w,start_new,end_new,start_new)) #del    
                            weighted_value = (end_w - start_new) / (end_new - start_new)
                            print ("%s ==========weighted value inside else"%weighted_value)
                            print type(weighted_value)
                        print ("%s ==========weighted value"%weighted_value)
                        weighted_value *= value2weight
                        print ("%s ==========weighted value"%weighted_value)
                        cross_interv_dict[start_w] = int(cross_interv_dict.get(start_w,0)) + float(weighted_value)
                        
                        start_new = end_w
                        value2weight = value2weight - weighted_value
                        
    #                     if (($end + $winSize) >= $relEndTime)
                        if ((end_w + delta_window) >= chr_end):
                            new_start_w = start_w + delta_window
#                             print (cross_interv_dict.get(new_start_w,0))#del
#                             print (int(value2weight))#del
                            cross_interv_dict[new_start_w] = cross_interv_dict.get(new_start_w,0) + value2weight
                            break
                        
                        end_w = end_w + delta_window
            
            else:
                print ("FATAL ERROR: Something went wrong")    
#         return iter(list_tuples)
                                                  
    def _error (self, data_tuple):
        raise ValueError("Fatal error")
         
################################################################################
class dataIter(object):
    def __init__(self, data, fields=None, **kwargs):
        if isinstance(data,(tuple)):            
            data = iter(data)
        if not fields:
#             if hasattr(data, 'description'):
#                 fields = [x[0] for x in data.description]
#             else: raise ValueError("Must specify a 'fields' attribute for %s." % self.__str__())
            raise ValueError("Must specify a 'fields' attribute for %s." % self.__str__())
        self.data = data
        self.fields = fields
#         self.format = format
        kwargs['format'] = kwargs.get("format",'txt')
        
    def __iter__(self):
        return self.data

    def next(self):
        return self.data.next()

    ### WRITE TIENE QUE ESTAR AQUI DE MANERA QUE TODOS LAS CLASES QUE HEREDAN BED, BEDGRAPH ETC SE PUEDA HACER EL OUTPUT A UN ARCHIVO
    def write(self, file_type="bed", mode="w", track=None):
        if not(isinstance(self, dataIter)):
            raise Exception("Not writable object, type not supported '%s'."%(type(self)))

        if file_type not in _dict_file: 
            raise ValueError("File types not supported \'%s\'"%(file_type))
                                                                                           
        if track is None: 
            track = "cage1_test"
        
        print _dict_file.get(file_type)
        file_ext = _dict_file.get(file_type)
            
        track_file = open(os.path.join(_pwd, track + file_ext), mode)
        track_file.write('track name="cage 1;drink" description="cage 1;drink" visibility=2 itemRgb="On" priority=20' + "\n")
        
        for row in self.data:         
            track_file.write('\t'.join(str(i) for i in row))
            track_file.write("\n")      
        track_file.close()
                             
################################ Bed ##########################################

class Bed(dataIter):
    """
    dataInt class for bed file format data
    
    Fields used in this application are:
        
         ['chr','start','end','name','score','strand',
          'thick_start','thick_end','item_rgb']
          
    """
    def __init__(self,data,**kwargs):
        kwargs['format'] = 'bed'
        kwargs['fields'] = ['chr','start','end','name','score','strand','thick_start','thick_end','item_rgb']
        dataIter.__init__(self,data,**kwargs)
        
class BedGraph(dataIter):
    """
    dataInt class for bedGraph file format data
    
    Fields used in this application are:
        
         ['chr','start','end', 'score']
          
    """
    def __init__(self,data,**kwargs):
        kwargs['format'] = 'bedGraph'
        kwargs['fields'] = ['chr','start','end','score']
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
         
intData = intData(path, relative_coord=True)
# print (intData.get_field_items("dataTypes"))
# for row in intData.read(relative_coord=True):
#     print row
# print(intData.min)

 
# intData.convert(mode = "bed", relative_coord = True)   
# bedFiles = intData.convert(mode = "bed", relative_coord = True, split_dataTypes=False)
bedFiles=intData.convert(mode = "bedGraph", window=300,  split_dataTypes=False, relative_coord=True)

for key in bedFiles: 
#     print (key), 
#     print ("---------")
    bedSingle = bedFiles[key]
    name_file='_'.join(key)
    bedSingle.write(track=name_file, file_type="bedGraph")
    for line in bedSingle: print line


       
# s=intData.read(relative_coord=True)

# bedFile = intData.track_convert2bed(s)
# for line in bedFile:    
#     print (line) 






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
    (500, 'A', 'foo-bar'),
     
    (1000, 'C', 'py'),
    (200, 'C', 'foo'),
    ]
#
data2=sorted(data,key=operator.itemgetter(2))

  
# for key,group in itertools.groupby(data2,operator.itemgetter(1,2)):
#     print(tuple(group))
#     print key
