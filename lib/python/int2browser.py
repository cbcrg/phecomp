#!/usr/bin/env python

from __future__ import division

__author__ = 'Jose Espinosa-Carrasco'

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

#Contains class and file extension
_dict_file = {'bed' : ('Bed', 'track_convert2bed', '.bed'),              
              'bedGraph': ('BedGraph', 'track_convert2bedGraph', '.bedGraph'),
              'txt': ('dataIter', '', '.txt')}

# _options_split_dataTypes = ('one_per_channel','list_all', 'True', 'False') #del
_options_track_rules = ('split_all', 'join_all', 'join_odd', 'join_even') 
tr_act_options = ('split_all', 'join_all', 'join_odd', 'join_even') 
dt_act_options = ['all', 'one_per_channel']

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
        self.fieldsB = self._set_fields_b(kwargs.get('fields'))
        self.fieldsG = [ontology_dict [k] for k in self.fieldsB]
        self.data, self.min, self.max = self._new_read(multiply_t = kwargs.get('multiply_t', 1), intervals=kwargs.get('intervals', False))
#         print ":::::::::::::::::::",type(self.data)  
        self.dataTypes = self.get_field_items(field ="dataTypes", data = self.data)
        self.tracks  =  self.get_field_items(field="track", data = self.data)

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
       
    def read(self, fields=None, relative_coord=False, intervals=True, fields2rel=None, multiply_t=1,**kwargs):
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
        print >>sys.stderr, ("Relative coordinates is true", relative_coord) 
           
        if relative_coord:             
            print >>sys.stderr, "Relative coordinates is true"
            
            if fields2rel is None and intervals:
                _f2rel = ["chromStart","chromEnd"] 
            elif fields2rel is None and not intervals:
                _f2rel = ["chromStart"]    
            else:
                if isinstance(fields2rel, basestring): fields2rel = [fields2rel]
                _f2rel = [f for f in fields2rel if f in self.fieldsG]
                
            try:
                idx_fields2rel = [self.fieldsG.index(f) for f in _f2rel]                
            except ValueError:
                raise ValueError("Field '%s' not in file %s mandatory when option relative_coord=T." % (f, self.path))
            
            self.data = self.time2rel_time(idx_fields2rel)
                
        idx_fields2int = [10000000000000]
        
#         l_startChrom = l_endChrom = []
        
#         if not intervals:             
#             print >>sys.stderr, "Intervals inferred from timepoints"
#             _time_points = ["chromStart"]
#             try:
#                 idx_fields2int = [self.fieldsG.index(f) for f in _time_points]                
#             except ValueError:
#                 raise ValueError("Field '%s' not in file %s." % (f, self.path))
#             
#             l_time_points = (map(int, (str(row[0]).replace(".", "")  for row in self.read(fields=_time_points))))
#             l_startChrom, l_endChrom = interv(l_time_points)
#             self.fieldsG.append("chromEnd")
        
                                                  
#         return dataIter(self._read(indexL, idx_fields2rel, idx_fields2int, l_startChrom, l_endChrom, multiply_t), self.fieldsG)

        return self.data
#         return dataIter(self._new_read(indexL, idx_fields2rel, idx_fields2int, l_startChrom, l_endChrom, multiply_t), self.fieldsG)
    def time2rel_time(self, i_fields):
        list_rel = list()

        for row in self.data:
            temp = []
            for i in range(len(row)):
                
                if i in i_fields:
#                     temp.append(row[i]- self.min + 1)
                    temp.append(row[i]- self.min)
                else:
                    temp.append(row[i])

            list_rel.append((tuple(temp)))   
            
        return (list_rel)
    
    def _read(self, indexL, idx_fields2rel, idx_fields2int,l_startChrom, l_endChrom, multiply_t):
        self.inFile  = open(self.path, "rb")
        self.reader = csv.reader(self.inFile, delimiter='\t')
        self.reader.next()
        
        for interv in self.reader:
            j = self.reader.line_num -2 #header removed and list starts at 0 #modify
            temp = []            
            for i in indexL:                                
                if i in idx_fields2int and i in idx_fields2rel:
                    temp.append(l_startChrom[j] - self.min + 1)
                    temp.append(l_endChrom[j] - self.min + 1) 
                elif i in idx_fields2int and not i in idx_fields2rel:
                    temp.append(l_startChrom[j])
                    temp.append(l_endChrom[j]) 
                elif i not in idx_fields2int and i in idx_fields2rel:
                    temp.append(int(interv[i]) - self.min + 1)
                elif i not in idx_fields2int and not i in idx_fields2rel:    
                    temp.append(interv[i])  
            
            yield(tuple(temp))
                         
        self.inFile.close()
        
    def _new_read(self, multiply_t, intervals=False):
        """
        el min y maximo lo puedo recoger
        y luego si se pide el cambio de coordenadas 
        entonces el dataIter modificarlo
        """
        list_data = list()
        self.inFile  = open(self.path, "rb")
        self.reader = csv.reader(self.inFile, delimiter='\t')
        self.reader.next()
                        
        _int_points = ["chromStart", "chromEnd"]
        idx_fields2int = [10000000000000]
        i_new_field = [10000000000000]                                    
        
        if intervals:             
            print >>sys.stderr, "Intervals inferred from timepoints"
            _time_points = ["chromStart"]
            f_int_end = "chromEnd"
        
            if f_int_end in self.fieldsG:
                raise ValueError("Intervals can not be generated as '%s' already exists in file %s." % (f_int_end, self.path))
                
            try:
                idx_fields2int = [self.fieldsG.index(f) for f in _time_points]              
            except ValueError:
                raise ValueError("Field '%s' not in file %s." % (f, self.path))
            
            self.fieldsG.append(f_int_end)   
            i_new_field = [len(self.fieldsG) - 1]
        
        try:            
            f=""
            name_fields2mult = [f for f in _int_points if f in self.fieldsG] 
            idx_fields2mult = [self.fieldsG.index(f) for f in name_fields2mult]
                 
        except ValueError:
            raise ValueError("Field '%s' not in file %s." % (f, self.path))
        
        p_min = None
        p_max = None
        
        _start_f = ["chromStart"]
        try:
            i_min = [self.fieldsG.index(f) for f in _start_f]              
        except ValueError:
            raise ValueError("Field '%s' for min interval calculation time not in file %s." % (f, self.path))
            
        _end_f = ["chromEnd"]
        try:
            i_max = [self.fieldsG.index(f) for f in _end_f]              
        except ValueError:
            raise ValueError("Field '%s' for max interval calculation time not in file %s." % (f, self.path))
              
        v = 0
        p_v = 0
        first = True
        p_temp = []
        
        for interv in self.reader:            
            temp = []            

            for i in range(len(self.fieldsG)): 
                if i in idx_fields2mult and i in idx_fields2int:
                    v = int(float(interv[i]) * multiply_t)
                    temp.append(v)
                    p_v = v - 1
                    if intervals: last_start = v
                elif i in i_new_field and i in idx_fields2mult:
                    if first:
                        pass
                    else:
                        p_temp.append(p_v)                        
                elif i in idx_fields2mult and i not in idx_fields2int:
                    v = int(float(interv[i]) * multiply_t)
                    temp.append(v)
                else: 
                    v = interv[i]              
                    temp.append(v)
                
                if i in i_min:
                    if p_min is None: p_min = v
                    if p_min > v: p_min = v
                
                if i in i_max:
                    if i_max == i_new_field:
                        if first: pass
                        if p_max is None: p_max = p_v
                        if p_max < p_v: p_max = p_v
                    else:
                        if p_max is None: p_max = v
                        if p_max < v: p_max = v
            if first:
                first = False 
                p_temp = temp
            else:               
                list_data.append((tuple(p_temp))) 
                p_temp = temp
            
        # last line of the file when intervals are generated
        if intervals: temp.append(last_start + 1)

        list_data.append((tuple(temp)))             

        self.inFile.close()
#         dataIter(self._read(indexL, idx_fields2rel, idx_fields2int, l_startChrom, l_endChrom, multiply_t), self.fieldsG)
        return (list_data, p_min, p_max)
             
    
#     def get_min_max(self, fields=None, **kwargs): 
#         """
#         Return the minimun and maximun of two given fields by default set to chromStart and chromEnd
#         """
#                 
#         pMinMax = [None,None]
#         
#         if kwargs.get('intervals', True):
#         
#             if fields is None:
#                 _f = ["chromStart","chromEnd"]
#                             
#                 for row in self.read(fields=_f):
#                     
#                     row = map(int, [ i.replace(".", "") for i in map(str, row)])
#                     
#                     if pMinMax[0] is None: pMinMax = list(row)
#                     if pMinMax[0] > row[0]: pMinMax[0] = row[0]
#                     if pMinMax[1] < row[1]: pMinMax[1] = row[1]
#             else:
#                 if isinstance(fields, basestring): fields = [fields]
#                 _f = [f for f in fields if f in self.fieldsG]
#                 if len(_f) == 0:
#                     raise ValueError("Fields %s not in track: %s" % (fields, self.fieldsG))
#                 elif len(_f) != 2:
#                     raise ValueError("Only two fields can be consider for get_min_max %s: %s" % (fields, self.fieldsG))
#             
#             for row in self.read(fields=_f):
#                 row = map(int, [ i.replace(".", "") for i in map(str, row)])
# #                 print "33333",row#del
#                           
#                 if pMinMax[0] is None: pMinMax = list(row)
#                 if pMinMax[0] > row[0]: pMinMax[0] = row[0]
#                 if pMinMax[1] < row[1]: pMinMax[1] = row[1]
#             
#         else:
#             p_min = None
#             p_max = None
#             
#             _f = ["chromStart"]
#             
#             for row in self.read(fields=_f):
#                 
#                 row = map(int, [ i.replace(".", "") for i in map(str, row)])
#                  
# #                 print "33333",row#del                          
#                 if p_min is None: p_min = row[0]
#                 elif p_min > row: p_min = row[0]
#                 elif p_max < row: p_max = row[0]
#                 
#                 pMinMax = p_min, p_max
# 
#         return pMinMax
    
    def get_field_items(self, data, field="dataTypes"): 
        """
        Return a list with all the possible data types present in the column that was set as dataTypes
        """
        
        try:
#             [self.fieldsG.index(f) for f in _bed_fields] 
            [self.fieldsG.index(field)]                
        except ValueError:
            raise ValueError("Field '%s' not in file %s." % (field, self.path))
        
        idx_field = self.fieldsG.index(field)
        field = [field]    
        set_fields = set()
        
        for row in self.data:
            set_fields.add(row[idx_field])
            
#         for it in data:
#             print it    
        return set_fields
                     
    def writeChr(self, mode="w"):
        chrom = 'chr1'
        genomeFile = open(os.path.join(_pwd, chrom + _genomeFileExt), mode)        
        genomeFile.write(">" + chrom + "\n")
#         print(self.max - self.min)
        genomeFile.write (genericNt * (self.max - self.min))
        genomeFile.close()
        print('Genome fasta file created: %s' % (chrom + _genomeFileExt))
              
    def convert(self, mode = 'bed', **kwargs):
        """
        Returns an object/s of the class set by mode
        :param mode: class of the output object, by default is set to bed
         
        """
        kwargs['relative_coord'] = kwargs.get("relative_coord",False)
        
        print >> sys.stderr, self.fieldsG
            
        if mode not in _dict_file: 
            raise ValueError("Mode \'%s\' not available. Possible convert() modes are %s"%(mode,', '.join(['{}'.format(m) for m in _dict_file.keys()])))
        
        dict_tracks = (self._convert2single_track(self.read(**kwargs), mode, **kwargs))
        
        return (dict_tracks)
        
    def _convert2single_track (self, data_tuple,  mode=None, **kwargs):
        """
        Transform data into a bed file if all the necessary fields present
        """   
        dict_split = {}
        
        ###################
        ### Data is separated by track and dataTypes
        idx_fields2split = [self.fieldsG.index("track"), self.fieldsG.index("dataTypes")]
        data_tuple = sorted(data_tuple,key=operator.itemgetter(*idx_fields2split))
#         print "::::::::data tuple ",data_tuple #del
        
        for key,group in itertools.groupby(data_tuple, operator.itemgetter(*idx_fields2split)):
            if not dict_split.has_key(key[0]):
                dict_split [key[0]] = {}
            dict_split [key[0]][key[1]] = tuple(group)
        
        ###################
        ### Filtering tracks
        sel_tracks = []
        if not kwargs.get('tracks'):
            pass
        else:
            sel_tracks = map(str, kwargs.get("tracks",[]))
                
        #When any tracks are selected we consider that any track should be removed
        if sel_tracks != []:
            tracks2rm = self.tracks.difference(sel_tracks)            
            dict_split = self.remove (dict_split, tracks2rm)
            print >> sys.stderr, "Removed tracks are:", ' '.join(tracks2rm)
        
        d_track_merge = {} 
        
        ###################
        ###tracks_merge                 
        if not kwargs.get('tracks_merge'):
            d_track_merge = dict_split
        else:
            tracks_merge = kwargs.get('tracks_merge',self.tracks)

            if not all(tracks in self.tracks for tracks in tracks_merge):
                raise ValueError ("Tracks to merge: %s, are not in the track list: " % ",".join("'{0}'".format(n) for n in tracks_merge), ",".join("'{0}'".format(n) for n in self.tracks))
            print >>sys.stderr, "Tracks that will be merged are: ",tracks_merge
            
            d_track_merge = self.join_by_track(dict_split, tracks_merge)
                                
#         print "dict_track_merge=", (d_track_merge)#del        
        
        d_dataTypes_merge = {}
        
        ##################
        # Joining the dataTypes or natures
        if not kwargs.get('dataTypes_actions') or kwargs.get('dataTypes_actions') == 'one_per_channel':
            d_dataTypes_merge = d_track_merge
        elif kwargs.get('dataTypes_actions') == 'all':
            d_dataTypes_merge = self.join_by_dataType(d_track_merge, mode)
#         print "dict_dataTypes_merge=", (d_dataTypes_merge)#del     
        track_dict = {}                        
   
        #######
        # Generating track dict (output)
        #validacion del diccionario para imprimir o lo que sea
        #mirar si es un diccionario de diccionarios la primera validacion hay que desarrolarla 
        for k, v in d_track_merge.items():
            if isinstance(v,dict):
                print "Is a dictionary"#del
                                   
        window = kwargs.get("window", 300)

#         _dict_col_grad = assign_color (self.dataTypes) #now inside convert2bed
        
        #Output    
        for k, d in d_dataTypes_merge.items():
            for k_2, d_2 in d.items():
#                 track_dict[k,k_2] = globals()[_dict_file[mode][0]](getattr(self,_dict_file[mode][1])(d_2, True, window), track=k, dataType=k_2, color=_dict_col_grad[k_2])
                track_dict[k,k_2] = globals()[_dict_file[mode][0]](getattr(self,_dict_file[mode][1])(d_2, True, window), track=k, dataType=k_2)
                       
        return (track_dict)

    def join_by_track (self, dict_t, tracks2join):  
        
        d_track_merge = {} 
        new_tracks = set()
        
        for key, nest_dict in dict_t.items():
            
            if key not in tracks2join: 
                print "Track not use because was not set when join_by_track is called: %s" % key
                continue
            
            if not d_track_merge.has_key('_'.join(tracks2join)):
                d_track_merge['_'.join(tracks2join)] = {}
                new_tracks.add('_'.join(tracks2join))
            
            for key_2, data in nest_dict.items():                            
                if not d_track_merge['_'.join(tracks2join)].has_key(key_2):
                    d_track_merge['_'.join(tracks2join)] [key_2]= data
                else:  
                    d_track_merge['_'.join(tracks2join)] [key_2] = d_track_merge['_'.join(tracks2join)] [key_2] + data

        self.tracks = new_tracks            
        return (d_track_merge)
    
    def join_by_dataType (self, dict_d, mode):
        
        d_dataTypes_merge = {}
        
        for key, nest_dict in dict_d.items():
            
            d_dataTypes_merge[key] = {}
            new_dataTypes = set()
            
            for key_2, data in nest_dict.items(): 
                
                if not d_dataTypes_merge[key].has_key('_'.join(nest_dict.keys())):
                    d_dataTypes_merge[key]['_'.join(nest_dict.keys())] = data
                    new_dataTypes.add('_'.join(nest_dict.keys())) 
                else:                    
                    d_dataTypes_merge[key]['_'.join(nest_dict.keys())] = d_dataTypes_merge[key]['_'.join(nest_dict.keys())] + data
                    new_dataTypes.add('_'.join(nest_dict.keys()))          
        
        if mode == 'bedGraph':
            self.dataTypes = new_dataTypes

        return (d_dataTypes_merge)
    
    def remove (self, dict_t, tracks2remove):
        for key in tracks2remove:
            key = str(key)
    
            dict_t.pop(key, None)
    
            if key in self.tracks:
                self.tracks.remove(key)
        return (dict_t) 
               
    def track_convert2bed (self, track, in_call=False, restrictedColors=None, **kwargs):
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
        
        #Generate dictionary of field and color gradients
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
                    
    def track_convert2bedGraph(self, track, in_call=False, window=300): #modify
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
        ini_window = 0
        delta_window = window      
        end_window = delta_window
        partial_value = 0 
        cross_interv_dict = {}
        
        #When the tracks have been join it is necessary to order by chr_start
        track = sorted(track, key=operator.itemgetter(*[i_chr_start]))
        for row in track:
            print "row in convert is:",row                            
        for row in track:
            temp_list = []
            chr_start = row[i_chr_start]
            chr_end = row[i_chr_end]
            data_value = float(row[i_data_value])
            self.fieldsG.index(f) 
            print "type &&&&&&&&&", type(row[i_data_value])#del
            #Intervals happening after the current window
            #if there is a value accumulated it has to be dumped otherwise 0
            print "@@@@@@@@@@@@@@@@@@chr_start > end_window",chr_start, end_window
            if chr_start > end_window:
                while (end_window < chr_start):                                      
                    print "that is rounded",type(cross_interv_dict.get(ini_window,0))
                    partial_value = partial_value + cross_interv_dict.get(ini_window,0)
                    temp_list.append("chr1")
                    temp_list.append(ini_window)
                    temp_list.append(end_window)
                    temp_list.append(partial_value)
                    partial_value = 0
                    ini_window += delta_window + 1
                    end_window += delta_window + 1                                 
                    yield(tuple(temp_list))
                    temp_list = []
                    print "end_window after adding delta_w is:", end_window    
                #Value must to be weighted between intervals
                if chr_end > end_window:
                    print "@@@@@@@@@@@@@@@@@@chr_end > end_window",chr_end, end_window                 
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
                        cross_interv_dict[start_w] = float(cross_interv_dict.get(start_w,0)) + float(weighted_value)                      
                        start_new = end_w
                        value2weight = value2weight - weighted_value                        

                        if ((end_w + delta_window) >= chr_end):
                            new_start_w = start_w + delta_window
                            cross_interv_dict[new_start_w] = cross_interv_dict.get(new_start_w,0) + value2weight
                            break
                        
                        end_w = end_w + delta_window
                        print "end_w after adding delta_w is:", end_w
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
                    print "end_w after adding delta_w is:", end_w
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
                        print "end_w after adding delta_w is:", end_w
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
            raise ValueError("Must specify a 'fields' attribute for %s." % self.__str__())
        
        self.data = data
        self.fields = fields       
        self.format = kwargs.get("format",'txt')
        self.track = kwargs.get('track', "")
        self.dataType = kwargs.get('dataType', "")
        
    def __iter__(self):
        return self.data

    def next(self):
        return self.data.next()

    def write(self, mode="w"):#modify maybe I have to change the method name now is the same as the os.write()???
        
        if not(isinstance(self, dataIter)):
            raise Exception("Not writable object, type not supported '%s'."%(type(self)))    
        
        try:
            file_ext = _dict_file.get(self.format)[2]      
        except KeyError:
            raise ValueError("File types not supported \'%s\'"%(self.format))
                                                           
        if self.track is "": 
            self.track = "1"
        
        if self.dataType is "":
            self.dataType = "a"
                
        name_file = "tr_" + self.track + "_dt_" + self.dataType + file_ext
        print >>sys.stderr, "File %s generated" % name_file       

        track_file = open(os.path.join(_pwd, name_file), mode)
                
        #Annotation track to set the genome browser interface
        annotation_track = ''
        if self.format == 'bed':
            annotation_track = 'track type=' + self.format + " " + 'name=\"' +  self.track + "_" + self.dataType + '\"' + " " + '\"description=' + self.track + " " + self.dataType + '\"' + " " + "visibility=2 itemRgb=\"On\" priority=20" 
        elif self.format == 'bedGraph':
            annotation_track = 'track type=' + self.format + " " + 'name=\"' + self.track + "_" + self.dataType + '\"' + " " + '\"description=' + self.track + "_" + self.dataType + '\"' + " " + 'visibility=full color=' + self.color[7] + ' altColor=' + self.color[8] + ' priority=20'        
        
            track_file.write (annotation_track + "\n")
           
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
    def __init__(self, data, **kwargs):
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
        self.color = kwargs.get('color',_blue_gradient)
        dataIter.__init__(self,data,**kwargs)
        
class ObjectContainer():
    pass 

def assign_color (set_dataTypes, color_restrictions=None):
    """
    Assign colors to fields, it is optional to set given color to given fields, for example set water to blue
    different data types get a different color in a circular manner
    
    :param set_dataTypes: (list) each of the fields that should be linked to colors
    :param color_restrictions: (dict) fields with colors set by the user
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
    assert isinstance(path, basestring), "Expected string or unicode, found %s." % type(path)
    try:
        open(path, "r")
    except IOError:
        raise IOError('File does not exist: %s' % path)
    return path      
    
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
            print "llll",config_file_list#del
            
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
            l=row.split(">")
            print "row is",l[1].split(":")[1].rstrip()
            dict_correspondence[l[0].split(":")[1].rstrip()] = l[1].split(":")[1].rstrip('\t\n')        

        return (dict_correspondence)   
    
    def write(self, indent=0):
        for key, value in self.correspondence.iteritems():
            print '\t' * indent + str(key),
            
            if isinstance(value, dict):
                self.write(value, indent+1)
            else:
                print '\t' * (indent+1) + str(value)

def read_track_actions (tracks, track_action = "split_all"):
    """ 
    Read track actions and returns a set with the tracks to be joined
    
    :param tracks: (set) of tracks to which track_action should be applied set([1,2])
    :param track_action: (str) option to join tracks (join_all, split_all, join_odd, join_evens) 
    """
    
    if track_action not in tr_act_options:
        raise ValueError("Track_action \'%s\' not allowed. Possible values are %s"%(track_action,', '.join(['{}'.format(m) for m in tr_act_options])))
    
    tracks2merge = ""
    print >>sys.stderr, "Tracks to merge are: ", ",".join(tracks2merge)
    if track_action == "join_all":
        tracks2merge = tracks
    elif track_action == 'join_odd':
        tracks2merge = set([t for t in tracks if int(t) % 2])
    elif track_action == 'join_even':
        tracks2merge = set([t for t in tracks if not int(t) % 2])
    else:
        tracks2merge = ""
    print >>sys.stderr,"Tracks to merge are: ", ",".join("'{0}'".format(t) for t in tracks2merge)
       
    if not tracks2merge:
        print >>sys.stderr,("No track action applied as track actions \'%s\' can not be applied to list of tracks provided \'%s\'"%(track_action, " ".join(tracks)))
        
    return (tracks2merge)

def read_dataTypes_actions (tracks, dt_action = "split_all"):
    """ 
    Read dataTypes action and returns the option set
    
    :param tracks: (set) of tracks to which dt_action should be applied e.g. set([1,2])
    :param dt_actions: (str) option to join dataTypes ('all', 'one_per_channel') 
    """
    
    if dt_action not in dt_act_options:
        raise ValueError("dt_action \'%s\' not allowed. Possible values are %s"%(dt_action,', '.join(['{}'.format(m) for m in tr_act_options])))
     
    tracks2merge = ""
# 
#     if track_rules == "join_all":
#         tracks2merge = tracks
#     elif track_rules == 'join_odd':
#         tracks2merge = set([t for t in tracks if int(t) % 2])
#     elif track_rules == 'join_even':
#         tracks2merge = set([t for t in tracks if not int(t) % 2])
#     else:
#         tracks2merge = ""
#     
#     print >>sys.stderr, "Tracks to merge are: ", ",".join(tracks2merge)
#     
#     if not tracks2merge:
#         print >>sys.stderr,("No track rules applied as track rules \'%s\' can not be applied to list of tracks provided \'%s\'"%(track_rules, " ".join(tracks)))
#         
#     return (tracks2merge)

def interv(n_list):
    """ 
    Creates the correspondent intervals from a list of integers
    
    :param : (n_list) list of integers
    """
    temp_list = []
    list_chromStart = list()
    list_chromEnd = list() 
    n_list = [n * 10 for n in n_list]
    
    for i, v in enumerate(n_list):

        list_chromStart.append(v)
        
        if (i < len(n_list)-1):
            list_chromEnd.append(n_list[i+1]-1)
        else:
            list_chromEnd.append(n_list[i]+1)
    
    return list_chromStart, list_chromEnd
