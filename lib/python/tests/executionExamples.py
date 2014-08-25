#!/usr/bin/env python

import int2browser, operator, csv

# import pybedtools
# a = pybedtools.example_bedtool('a.bed')
# b = pybedtools.example_bedtool('b.bed')
# print a.intersect(b)


# a_with_b = a.intersect(b, u=True)

# import operator
#import sys
#print (sys.version)

## fieldG --> field in genome format
## fieldP --> correspoding field in phenome format

_rules_options=["all", "one_per_channel"]
parser = int2browser.argparse.ArgumentParser (description = 'Script to transform behavioral data into GB readable data')
parser.add_argument ('-i','--input', help='Input file name',required=True)
parser.add_argument ('-f','--file_config',help='Configuration file with genome browser fields correspondence', required=False)
parser.add_argument ('-t','--track_rules', help='Unique values of the field track should be dump on different data structures or not', required=False, choices=_rules_options)
parser.add_argument ('-d','--dataTypes_rules', help='Unique values of the field should dump on different data structures or not', required=False)
parser.add_argument ('-c','--chrom_rules', help='Unique values of the field chrom should be dump on different data structures or not', required=False)

args = parser.parse_args ()

## show values ##
print ("Input file: %s" % args.input )
print ("Configuration file: %s" % args.file_config)
print ("Track rules is: %s" % args.track_rules)
path = args.input

## CONFIGURATION FILE
# Old way of given configuration file
# My be is better to just delete this option and eliminated this part of the code
# filename = '/Users/jespinosa/git/phecomp/lib/python/examples/configFile.txt'
configFilePath = args.file_config

# Ahora funciona pero quiza deberia hacer una clase que solo devolviera el diccionario #EXPAND
configFileDict = int2browser.ConfigInfo(configFilePath)

print (configFileDict.correspondence)
configFileDict.write()

print ("=============")

## Input debugging file
#cat 20120502_FDF_CRG_hab_filtSHORT.csv | sed 's/ //g' | awk '{print $1"\t"$14"\t"$6"\t"$11"\t"$16"\thabituation"}' > shortDev.int

# print (path)

## Generation of a genome file
intData = int2browser.intData (path, ontology_dict=configFileDict.correspondence,relative_coord=True)

# print (type(intData.min))
# print (intData.min)

## Checking type
# Now before applying read it has not class data_iter ask someone whether this is ok or not
# print(type(intData))
intData_data_iter = intData.read()
# print(type(intData_data_iter))

## Writing chromosome file
# intData.writeChr()

## Convert to bed
bed_str = intData.convert(mode = "bed", relative_coord = True)
# separating by data types (nature)
bed_str =  intData.convert(mode = "bed", relative_coord = True, split_dataTypes=True)

# Class of each object of the dictionary
# print (type(bed_str[('2', 'water')]))
# print (bed_str)

# with open("input.txt", "r") as handle:
#     lookup = dict((x[2], x[1]) for x in (x.split('t') for x in handle.read().split('n') if x))



# with open(filename) as config_file:
#     culo=dict((row[0], row[1]) for row in (csv.reader(config_file, delimiter='\t')))
# #     list_of_dicts = list(csv.DictReader(file_object,delimiter='\t'))
#     
# print culo

















##################
# 
# print ("===============")
# d_rest_colors = {'water' : 'green'}
# set_dataTypes = intData.dataTypes
# print set_dataTypes
  
# print (int2browser.assign_color (set_dataTypes, _dict_rest_colors))

# print (int2browser.assign_color (set_dataTypes))
##########################
## Examples of executions 
         
# intData = intData(path, relative_coord=True)
# print ("===============")
# _dict_rest_colors = {
#                       'water' : 'blue'}
# set_dataTypes = intData.dataTypes
# print set_dataTypes
# 
# assign_color (set_dataTypes, _dict_rest_colors)

# print (intData.get_field_items("dataTypes"))
# for row in intData.read(relative_coord=True):
#     print row
# print(intData.min)

 
# intData.convert(mode = "bed", relative_coord = True)   
# bedFiles = intData.convert(mode = "bed", relative_coord = True, split_dataTypes=False, restrictedColors=d_rest_colors)
# bedFiles=intData.convert(mode = "bedGraph", window=300, split_dataTypes=False, relative_coord=True)
# 
# for key in bedFiles: 
#     print (key), 
#     print ("---------")
#     bedSingle = bedFiles[key]
#     name_file='_'.join(key)
#     print ("---------")
#     print (name_file)
#     bedSingle.write(track=name_file, file_type="bedGraph")
#     for line in bedSingle: print line
#  
#  
#         
# s=intData.read(relative_coord=True)
#   
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
        


# data=[(1, 'A', 'foo'),
#     (2, 'A', 'bar'),
#     (100, 'A', 'foo-bar'),
#      (300, 'A', 'foo-bar'),
#  
#     ('xx', 'B', 'foobar'),
#     ('yy', 'B', 'foo'),
#     ('yx', 'B', 'foo'),
#     (500, 'A', 'foo-bar'),
#      
#     (1000, 'C', 'py'),
#     (200, 'C', 'foo'),
#     ]
#
# data2=sorted(data,key=operator.itemgetter(2))

  
# for key,group in itertools.groupby(data2,operator.itemgetter(1,2)):
#     print(tuple(group))
#     print key
