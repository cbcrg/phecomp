#!/usr/bin/env python

import int2browser, operator

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

parser = int2browser.argparse.ArgumentParser (description = 'Script to transform behavioral data into GB readable data')
parser.add_argument ('-i','--input', help='Input file name',required=True)
parser.add_argument ('-o','--output',help='Output file name', required=False)
args = parser.parse_args ()

## show values ##
print ("Input file: %s" % args.input )
print ("Output file: %s" % args.output )

path = args.input

## Input debugging file
#cat 20120502_FDF_CRG_hab_filtSHORT.csv | sed 's/ //g' | awk '{print $1"\t"$14"\t"$6"\t"$11"\t"$16"\thabituation"}' > shortDev.int

# print (path)
intData = int2browser.intData(path, relative_coord=True)

print ("===============")
d_rest_colors = {'water' : 'green'}
set_dataTypes = intData.dataTypes
print set_dataTypes
  
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
bedFiles = intData.convert(mode = "bed", relative_coord = True, split_dataTypes=False, restrictedColors=d_rest_colors)
# bedFiles=intData.convert(mode = "bedGraph", window=300, split_dataTypes=False, relative_coord=True)
# 
for key in bedFiles: 
    print (key), 
    print ("---------")
    bedSingle = bedFiles[key]
    name_file='_'.join(key)
    print ("---------")
    print (name_file)
    bedSingle.write(track=name_file, file_type="bedGraph")
    for line in bedSingle: print line
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
