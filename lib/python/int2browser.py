#!/usr/bin/env python

from __future__ import division

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
import itertools
import operator
        
## VARIABLES
_pwd = os.getcwd ()
_genomeFileExt = ".fa"
_bedFileExt = ".bed"
_bedGraphFileExt = ".bedGraph"
genericNt = "N"

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

_dict_Id = {'Phase' :'chrom', 
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

_dict_colors = {
                'black' : _black_gradient,
                'blue' : _blue_gradient,
                'red' : _red_gradient,
                'green' : _green_gradient}
  
# esto tiene que ser implementado en una funcion 
# para cada uno de los fields que haya asignarle un color diferente
# mirar la parte del codigo que utilizaba esto, asignar el diccionario despues de llamar la 
# funcion y utilizarlo
_dict_col_grad = {
                  'water' : _blue_gradient,
                  'drink' : _blue_gradient,
                  'food' : _black_gradient,
                  'food_sc' : _black_gradient,
                  'food_cd' : _red_gradient,
                  'food_fat' : _red_gradient}
    
class intData: # if I name it as int I think is like self but with a better name
    """
    Generic class for data
    Possible thinks to implement
    .. attribute:: fieldsB 
    
    list with the behavioral fields corresponding each column in the original file
     
    """
    #le meto el diccionario entre behavior and genomic data como un parametro y por defecto le pongo el diccionario del ejemplo
    def __init__(self, path, **kwargs):
        self.path = self._check_path(path)
        self.delimiter = kwargs.get('delimiter',"\t")
        self.delimiter = self._check_delimiter(self.path)
        self.header = kwargs.get('header',True)
        self.fieldsB = self._set_fields_b(kwargs.get ('fields'))        
        self.fieldsG = [_dict_Id [k] for k in self.fieldsB]         
        self.min =  int(self.get_min_max(fields = ["chromStart","chromEnd"])[0])
        self.max =  int(self.get_min_max(fields = ["chromStart","chromEnd"])[1])
        self.tracks  =  self.get_field_items (field="track")
        self.dataTypes = self.get_field_items (field="dataTypes")
#         self.format = "csv"
    
    def _check_path(self, path):
        ''' Check if the input file exists and is accessible. '''
        print (path)
        assert isinstance(path, basestring), "Expected string or unicode, found %s." % type(path)
        try:
            f = open(path, "r")
        except IOError:
            raise IOError('File does not exist: %s' % path)
        return path        
    
    def _check_delimiter (self, path):
        """ Check whether the delimiter works, if delimiter is not set
        then tries ' ', '\t' and ';'"""
        if self.delimiter is None: 
            raise ValueError("Delimiter must be set \'%s\'"%(self.delimiter))
        
        self.inFile  = open(path, "rb")
        
        for row in self.inFile:            
            if row.count(self.delimiter) > 1: break
            else: raise ValueError("Input delimiter does not correspond to delimiter found in file \'%s\'"%(self.delimiter))
            
            if row.count(" ") > 1:
                self.delimiter = " "
                break
            if row.count("\t") > 1:
                self.delimiter = "\t"
                break
            if row.count(";") > 1:
                self.delimiter = "\t"
                break      
        return self.delimiter
    
    def _set_fields_b(self, fields):
        """
        Reading the behavioral fields from the header file or otherwise setting  
        the fields to numeric values correspoding the colunm index starting at 0    
        """ 
        if fields:
            pass
        elif self.header == True:       
            self.inFile  = open(self.path, "rb")
            self.reader = csv.reader(self.inFile, delimiter=self.delimiter)
            header = self.reader.next()
            first_r = self.reader.next()
            if len(header) == len(first_r):
                fieldsB = [header[0].strip('# ')]+header[1:]
            else:
                raise ValueError("Number of fields in header '%d' does not match number of fields in first row '%d'" % (len(header), len(first_r)))     
                #Achtung if I use open the I would have to get rid of \n
                #fieldsB=[header[0].strip('# ')]+header[1:-1]+[header[-1][:-1]]
            self.inFile.close()
        else:
            self.inFile  = open(path, "rb")
            self.reader = csv.reader(self.inFile, delimiter=self.delimiter)
            first_r = self.reader.next()
            fieldsB = range(0,len(first_r))  
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
        self.inFile  = open(self.path, "rb")
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
                elif split_dataTypes and len(key)==2:                 
                    track_dict[key]=Bed(self.track_convert2bed(track_tuple, True))
                else:    
                    raise ValueError("Key of converted dictionary needs 1 or two items %s" % (str(key)))
            elif mode=='bedGraph':
                if not split_dataTypes and len(key)==1:
                    track_dict[(key, '_'.join(self.dataTypes))]=BedGraph(self.track_convert2bedGraph(track_tuple, True))                    
                elif split_dataTypes and len(key)==2:                 
                    track_dict[key]=Bed(self.track_convert2bedGraph(track_tuple, True))    
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
        
        i_track = self.fieldsG.index("track")
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

            #Intervals happening after the current window
            #if there is a value accumulated it has to be dumped otherwise 0
            if chr_start > end_window:
                while (end_window < chr_start):                                      
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
                    
                #Value must to be weighted between intervals
                if chr_end > end_window:                 
                    value2weight = data_value
                    end_w = end_window
                    start_new = chr_start
                    end_new = chr_end
                    
                    for start_w in range (ini_window, chr_end, delta_window):
                        weighted_value = 0
                        
                        if (end_w == start_w):
                            weighted_value = (end_w - start_new + 1) / (end_new - start_new)
                        else:     
                            weighted_value = (end_w - start_new) / (end_new - start_new)
                            
                        weighted_value *= value2weight
                        cross_interv_dict[start_w] = int(cross_interv_dict.get(start_w,0)) + float(weighted_value)                      
                        start_new = end_w
                        value2weight = value2weight - weighted_value                        

                        if ((end_w + delta_window) >= chr_end):
                            new_start_w = start_w + delta_window
                            cross_interv_dict[new_start_w] = cross_interv_dict.get(new_start_w,0) + value2weight
                            break
                        
                        end_w = end_w + delta_window
                else:
                    partial_value = partial_value + data_value
                            
            elif (chr_start <= end_window and chr_start >= ini_window):
                if chr_end <= end_window:
                    partial_value = partial_value + data_value                 
                
                else:
                    value2weight = data_value
                    end_w = end_window
                    start_new = chr_start
                    end_new = chr_end
                    
                    for start_w in range (ini_window, chr_end, delta_window):
                        weighted_value = 0
                        
                        if (end_w == start_w):
                            weighted_value = (end_w - start_new + 1) / (end_new - start_new)
                        else:    
                            weighted_value = (end_w - start_new) / (end_new - start_new)
                            
                        weighted_value *= value2weight
                        cross_interv_dict[start_w] = int(cross_interv_dict.get(start_w,0)) + float(weighted_value)
                        start_new = end_w
                        value2weight = value2weight - weighted_value
                        
                        if ((end_w + delta_window) >= chr_end):
                            new_start_w = start_w + delta_window
                            cross_interv_dict[new_start_w] = cross_interv_dict.get(new_start_w,0) + value2weight
                            break
                        
                        end_w = end_w + delta_window
            
            else:
                print ("FATAL ERROR: Something went wrong")    
                                                  
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

    def write(self, file_type="bed", mode="w", track=None):
        if not(isinstance(self, dataIter)):
            raise Exception("Not writable object, type not supported '%s'."%(type(self)))

        if file_type not in _dict_file: 
            raise ValueError("File types not supported \'%s\'"%(file_type))
                                                                                           
        if track is None: 
            track = "cage1_test"
        
        print "File extension is: '%s'"%_dict_file.get(file_type)
        
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

def assign_color (set_dataTypes, color_restrictions):
    """
    Assign colors to fields, it is optional to set given color to given fields, for example set water to blue
    different data types get a different color in a circular manner
    """

    rest_colors = (list (color_restrictions.values()))

    #If there are restricted colors they should be on the default colors list
    if not all(colors in _dict_colors for colors in rest_colors):
        raise ValueError("Not all restricted colors are available") 
    
    #If there are fields link to related colors they also must be in the data type list 
    if not all(key in set_dataTypes for key in color_restrictions):                      
        raise ValueError("Some values of data types provided as color restriction are not present in the file")
    
    d_dataType_color = {}
    
    for dataType in color_restrictions:
        d_dataType_color[dataType] = _dict_colors[color_restrictions[dataType]] 
    
    colors_not_used = _dict_colors.keys()
    colors_not_used.remove (color_restrictions[dataType])

    for dataType in set_dataTypes:        
        if not colors_not_used:
           colors_not_used = _dict_colors.keys() 
        
        if dataType in d_dataType_color:
            print ("Data type color gradient already set '%s'."%(dataType))
        else:
            d_dataType_color[dataType] = _dict_colors[colors_not_used.pop(0)]
            print (colors_not_used)      
            
    return d_dataType_color