#!/usr/bin/env python

from __future__ import division

__author__ = 'Jose Espinosa-Carrasco'

import argparse
import csv
import os
import itertools
import operator
import sys
from re import match, compile
        
## VARIABLES
_pwd = os.getcwd ()
# this could be better in a dictionary
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

# _options_split_dataTypes = ('one_per_channel','list_all', 'True', 'False') #del
_options_track_rules = ('split_all', 'join_all')

_black_gradient = ["226,226,226", "198,198,198", "170,170,170", "141,141,141", "113,113,113", "85,85,85", "56,56,56", "28,28,28", "0,0,0"]
_blue_gradient = ["229,229,254", "203,203,254", "178,178,254", "152,152,254", "127,127,254", "102,102,254", "76,76,173", "51,51,162", "0,0,128"]
_red_gradient = ["254,172,182", "254,153,162", "254,134,142", "254,115,121", "254,96,101", "254,77,81", "254,57,61", "254,38,40", "254,19,20"]
_green_gradient = ["203,254,203", "178,254,178", "152,254,152", "127,254,127", "102,254,102", "76,254,76", "51,254,51", "0,254,0", "25,115,25"]

_dict_colors = {
                'black' : _black_gradient,
                'blue' : _blue_gradient,
                'red' : _red_gradient,
                'green' : _green_gradient}
      
class intData: # if I name it as int I think is like self but with a better name
    """
    Generic class for data
    Possible thinks to implement
    .. attribute:: fieldsB 
    
    list with the behavioral fields corresponding each column in the original file
     
    """
    #le meto el diccionario entre behavior and genomic data como un parametro y por defecto le pongo el diccionario del ejemplo
    def __init__(self, path, ontology_dict, **kwargs):
        self.path = check_path(path)
        self.delimiter = kwargs.get('delimiter',"\t")
        self.delimiter = self._check_delimiter(self.path)
        self.header = kwargs.get('header',True)
        self.fieldsB = self._set_fields_b(kwargs.get ('fields'))        
        self.fieldsG = [ontology_dict [k] for k in self.fieldsB]         
#         self.min =  int(self.get_min_max(fields = ["chromStart","chromEnd"])[0])
#         self.max =  int(self.get_min_max(fields = ["chromStart","chromEnd"])[1])
        self.min, self.max =  self.get_min_max(fields = ["chromStart","chromEnd"])
        self.tracks  =  self.get_field_items (field="track")
        self.dataTypes = self.get_field_items (field="dataTypes")
#         self.format = "csv"
          
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
        the fields to numeric values corresponding the column index starting at 0    
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
            self.inFile  = open(self.path, "rb")
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
            print >>sys.stderr, "Relative coord is true"
            
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
                row = map(int,pMinMax)
                print(type (row[0])) 
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
            row = map(int,row)            
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
        """
        Returns an object/s of the class set by mode
        :param mode: class of the output object, by default is set to bed
         
        """
        kwargs['relative_coord'] = kwargs.get("relative_coord",False)

        print >> sys.stderr, self.fieldsG
        
        if mode not in _dict_file: 
            raise ValueError("Mode \'%s\' not available. Possible convert() modes are %s"%(mode,', '.join(['{}'.format(m) for m in _dict_file.keys()])))
        
#         dict_beds = ({ 'bed': self._convert2bed, 'bedGraph': self._convert2bedGraph}.get(mode)(self.read(**kwargs), kwargs.get('split_dataTypes')))
#         dict_tracks = (self._convert2single_track(self.read(**kwargs), kwargs.get('split_dataTypes'), mode, **kwargs)) 
    
        dict_tracks = (self._convert2single_track(self.read(**kwargs), mode, **kwargs))
        return (dict_tracks)
        
#     def _convert2single_track (self, data_tuple, split_dataTypes=False, mode=None, **kwargs):
    def _convert2single_track (self, data_tuple,  mode=None, **kwargs):
#     def _convert2track_by_rules (self, data_tuple,  mode=None, **kwargs):
        
        """
        Transform data into a bed file if all the necessary fields present
        """   
        dict_split = {}
#         tracks2remove = ['1'] 

        #First remove
#         data_tuple = [tup for tup in data_tuple if not any(i in tup[self.fieldsG.index("track")] for i in tracks2remove)]
        
#         results = [t[1] for t in data_tuple if t[0] == 10]
        
       
            
        
        #Second separate data by track and dataTypes
        idx_fields2split = [self.fieldsG.index("track"), self.fieldsG.index("dataTypes")]
        data_tuple = sorted(data_tuple,key=operator.itemgetter(*idx_fields2split))
        
#         print data_tuple
        
        track_rules = kwargs.get("track_rules", "split_all")
        
        if track_rules not in _options_track_rules: 
            raise ValueError("Track_rules \'%s\' not allowed. Possible values are %s"%(track_rules,', '.join(['{}'.format(m) for m in _options_track_rules])))
        
        
        for key,group in itertools.groupby(data_tuple, operator.itemgetter(*idx_fields2split)):
#             print "keys are:" , key[0],key[1]
            if not dict_split.has_key(key[0]):
                dict_split [key[0]] = {}
            dict_split [key[0]][key[1]] = tuple(group)
            
#         print dict_split
        
        ###################
        ### Filtering tracks
        tracks2remove = [3] 
        #remove tracks
        for key in tracks2remove:
            key = str(key)
            print "$$$$$$$$$$$$$$",key
            dict_split.pop(key, None)
#             self.tracks.remove(key)
            if key in self.tracks:
                self.tracks.remove(key)
                

        d_track_merge = {}
        
        ##################
        # Joining tracks in track_list
        # make a function!!!   
        track_list = self.tracks # in this case I will join all
        ### cuidado si quito 
           
        for key, nest_dict in dict_split.items():
            if key not in track_list: 
                print "Track skipped: %s" % key
                continue
            print "000000000000", '_'.join(track_list)
            if not d_track_merge.has_key('_'.join(track_list)):
                d_track_merge['_'.join(track_list)] = {}
            for key_2, data in nest_dict.items():
                                
                if not d_track_merge['_'.join(track_list)].has_key(key_2):
                    d_track_merge['_'.join(track_list)] [key_2]= data
                else:  
                    d_track_merge['_'.join(track_list)] [key_2] = d_track_merge['_'.join(track_list)] [key_2] + data
                    
#         for key, value in b.items():
#             new.setdefault(key, []).extend(value)
        print d_track_merge
        
        d_dataTypes_merge = {}
        
        ##################
        # Joining the dataTypes or natures
#         dataTypes_list = self.dataTypes
        
        for key, nest_dict in d_track_merge.items():
            d_dataTypes_merge[key] = {}
            for key_2, data in nest_dict.items():            
                d_dataTypes_merge[key]['_'.join(nest_dict.keys())]= data                
                                
        print d_dataTypes_merge
        
        ####
        # merge everything that is as getting the data as it is entering into the function
        # but without filtering
        
        track_dict = {}
         
        ### 
        # Here I join dataTypes and tracks if selected
        for k, d in d_dataTypes_merge.items():
            for k_2, d_2 in d.items():
                track_dict[k,k_2] = Bed(self.track_convert2bed(d_2, True))
#         if mode is None:
#             mode='bed' 
#         
        for k, v in d_track_merge.items():
            if isinstance(v,dict):
                print "is a dictionary"
        return (track_dict)
#             track_dict[(key, '_'.join(self.dataTypes))]=BedGraph(self.track_convert2bedGraph(track_tuple, True, window))   

#         split_dataTypes = kwargs.get("split_dataTypes", False)
#         
#         if not isinstance (kwargs.get("split_dataTypes"), bool):
#             raise ValueError("Split_dataTypes is a boolean flag, value \'%s\' not allowed."%(kwargs.get("split_dataTypes")))
#         
#         print ("split_dataTypes has been set to:", split_dataTypes)
#         
#         #By default all tracks are splitted
#         track_rules = kwargs.get("track_rules", "split_all")
#         # esto me puede servir para cuando haga los filtros por cage 1,3,5 por ejemplo
# #         if split_dataTypes not in _options_split_dataTypes: 
# #             raise ValueError("Split mode \'%s\' not available. Possible ways of splitting data are %s"%(split_dataTypes,', '.join(['{}'.format(m) for m in _options_split_dataTypes])))        
#         if track_rules not in _options_track_rules: 
#             raise ValueError("Track_rules \'%s\' not allowed. Possible values are %s"%(track_rules,', '.join(['{}'.format(m) for m in _options_track_rules])))        
#         
#         print ("id of the present tracks",self.tracks)
#         idx_fields2split = []
#         print ("track rules are=========", track_rules)#del   
#         # Aqui me dice cuales son los campos para separar, esto lo podria utilizar si le paso yo la informacion
#         # Si existia split_dataTypes separaba por track y nature (dataTypes) y sino solo separaba por track animal
#         # Lo otro estaria on top of that una vez he separado las tuples las podria volver a agregar, aunque no se si se puede extender una tuple  
#         
#         # ESTA ES LA LINEA CLAVE PARA CAMBIAR LAS TRACKS QUE QUIERO INCLUIR EN EL SELF.FIELDSG.INDEX
#         idx_fields2split = [self.fieldsG.index("track"), self.fieldsG.index("dataTypes")] if split_dataTypes else [self.fieldsG.index("track")]
# #         if split_dataTypes and track_rules == "split_all":
# #             idx_fields2split = [self.fieldsG.index("track"), self.fieldsG.index("dataTypes")]            
# #             data_tuple = sorted(data_tuple,key=operator.itemgetter(*idx_fields2split))
# #         elif not split_dataTypes and track_rules == "split_all":
# #             idx_fields2split = [self.fieldsG.index("track")]
# #             data_tuple = sorted(data_tuple,key=operator.itemgetter(*idx_fields2split))
#         
#             
#         
#         print("aquesta es la key", '_'.join(self.tracks),'_'.join(self.dataTypes))
#         # en lugar de esto puedo hacer una 
#         track_dict = {}
#         print ("length-------------", len(idx_fields2split))#del
#         data_tuple = sorted(data_tuple,key=operator.itemgetter(*idx_fields2split))
# #         print (data_tuple)#del
#         if track_rules=="join_all":        
#         #El for solo deberia correr cuando no hay el join all
#             for key,group in itertools.groupby(data_tuple, operator.itemgetter(*idx_fields2split)):
#                 track_tuple = tuple()
#                 if mode=='bed':
#                     if not split_dataTypes:
#                         track_dict['_'.join(self.tracks),'_'.join(self.dataTypes)] = Bed(self.track_convert2bed(track_tuple, True))
#                     else:
#                         track_dict[(key, '_'.join(self.tracks))] = Bed(self.track_convert2bed(track_tuple, True))
#                 elif mode == 'bedGraph':
#                     track_dict['_'.join(self.tracks)] = Bed(self.track_convert2bed(track_tuple, True))                                                        
#                 else:
#                     raise ValueError("Track mode does not exist %s"%mode)
#             
#         else:
#             for key,group in itertools.groupby(data_tuple, operator.itemgetter(*idx_fields2split)):
#                 if key[0] is '1': 
#                     print "##############"
#                     continue            
#                 print ("88888888888",self.dataTypes)#del          
#                 print ("key is-----", key[0])
#                 print ("type group is: ", type(group))  
#                 track_tuple = tuple(group)
#                 print ("type of track tuple is: ", type(track_tuple))
#     #             filter_list=[1]
#     #             [tup for tup in tup_list if any(i in tup for i in filter_list)]
#                 print "============lllll",  ('_'.join(self.dataTypes) + '_' +  '_'.join(self.tracks))
#                 if mode=='bed':
#                     print >> sys.stderr, "culo", key
#                     # mirar como funciona esto cuando hay solo una cage o un nature
#                     if not split_dataTypes and len(key)==1:
#                         print "============ (key, '_'.join(self.dataTypes))"
#                         track_dict[(key, '_'.join(self.dataTypes))]=Bed(self.track_convert2bed(track_tuple, True))                     
#                     elif split_dataTypes and len(key)==2:                 
#                         track_dict[key]=Bed(self.track_convert2bed(track_tuple, True))
#                     else:    
#                         raise ValueError("Key of converted dictionary needs 1 or 2 items %s" % (str(key)))
#                 elif mode=='bedGraph':
#                     window = kwargs.get("window", 300)
#                     print >> sys.stderr, "Window size is set to:", window
#                     
#                     if not split_dataTypes and len(key)==1:
#                         track_dict[(key, '_'.join(self.dataTypes))]=BedGraph(self.track_convert2bedGraph(track_tuple, True, window))                    
#                     elif split_dataTypes and len(key)==2:                 
#                         track_dict[key]=Bed(self.track_convert2bedGraph(track_tuple, True, window))    
#                     else:    
#                         raise ValueError("Key of converted dictionary needs 1 or two items %s" % (str(key)))
#                 else:
#                     raise ValueError("Track mode does not exist %s"%mode)
#                      
#         return track_dict
    
    def track_convert2bed (self, track, in_call=False, restrictedColors=None):
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
        
        #Generate dictionary of field and colors
        _dict_col_grad = assign_color (self.dataTypes)
            
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
                    
    def track_convert2bedGraph(self, track, in_call=False, window=300):
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
#         delta_window = 300
        delta_window = window        
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

def assign_color (set_dataTypes, color_restrictions=None):
    """
    Assign colors to fields, it is optional to set given color to given fields, for example set water to blue
    different data types get a different color in a circular manner
    
    :param set_dataTypes: (list) each of the fields that should be linked to colors
    :param color_restricitons: (dict) fields with colors set by the user
    """
    d_dataType_color = {}
    colors_not_used = []
    
    if color_restrictions is not None:
        rest_colors = (list (color_restrictions.values()))

        #If there are restricted colors they should be on the default colors list
        if not all(colors in _dict_colors for colors in rest_colors):
            raise ValueError("Not all restricted colors are available") 
        
        #If there are fields link to related colors they also must be in the data type list 
        if not all(key in set_dataTypes for key in color_restrictions):                      
            raise ValueError("Some values of data types provided as color restriction are not present in the file")
            
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
            
    return d_dataType_color

def check_path(path):
    """ 
    Check whether the input file exists and is accessible and if OK returns path
    :param path: path to the intervals file
    """
#         print (path)
    assert isinstance(path, basestring), "Expected string or unicode, found %s." % type(path)
    try:
        open(path, "r")
    except IOError:
        raise IOError('File does not exist: %s' % path)
    return path      
    
# class ConfigInfo(dict):
class ConfigInfo():
    """
    Class holds a dictionary with the ontology between the genomic fields and the phenomics fields
    Ontology can be read both from a tabulated file or a ontology format file 
    #EXPAND Put the name of the file and the link to the source
    
    :param path: (str) name of/path to a configuration file
    
    :method write: print the ontology dictionary on stout
    """
    def __init__(self, path, **kwargs):
        self.path = check_path(path)
        self.correspondence = self._correspondence_from_config(self.path)
    
    def _correspondence_from_config(self, path):
        with open(path) as config_file:
            #We eliminate possible empty lines at the end
            config_file_list = filter(lambda x:  not match(r'^\s*$', x), config_file)
            
            if config_file_list[0][0] == '#':
                del config_file_list [0]
                return(self._tab_config(config_file_list))

            elif config_file_list[0][0] == '!':
                del config_file_list[:2]
                return(self._mapping_config(config_file_list))
            else:
                raise TypeError("Configuration file format is not recognized: \"%s\"." % (path))
                
                
    def _tab_config(self, file_tab):
        dict_correspondence ={}
        
        for row in file_tab:
            row_split = row.rstrip('\n').split('\t')
            dict_correspondence[row_split[0]] = row_split[1]
        return (dict_correspondence)    
    
    def _mapping_config(self, file_map):
        dict_correspondence ={}
       
        for row in file_map:
            l=row.rstrip('\n').replace(" ","").replace("\t","").split(">")
            dict_correspondence[l[0].split(":")[1]] = l[1].split(":")[1]        

        return (dict_correspondence)   
    
    def write(self, indent=0):
        for key, value in self.correspondence.iteritems():
            print '\t' * indent + str(key),
            
            if isinstance(value, dict):
                self.write(value, indent+1)
            else:
                print '\t' * (indent+1) + str(value)
   
