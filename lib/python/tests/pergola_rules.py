#!/usr/bin/env python

## -f  /Users/jespinosa/git/phecomp/lib/python/examples/b2g.txt -i /Users/jespinosa/git/phecomp/lib/python/examples/shortDev.int -a join_odd  -d all -r 1-2
## -c  /Users/jespinosa/git/phecomp/lib/python/examples/b2g.txt -i /Users/jespinosa/git/phecomp/lib/python/examples/shortDev.int -r 1-2 -d all -f bedGraph

import int2browser
from argparse import ArgumentParser, ArgumentTypeError
import sys
import re

def parseNumRange(string):
    m = re.match(r'(\d+)(?:-(\d+))?$', string)

    if not m:
        raise ArgumentTypeError("'" + string + "' is not a range of number. Expected '0-5' or '2'.")
    start = m.group(1)
    end = m.group(2) or start
    list_range=list(range(int(start,10), int(end,10)+1))
#     set_range = set(list_range)
#     print "************##############",list_range
    set_range=set(['{0}'.format(t) for t in list_range]) #modify probably I should change or set of tracks to integers and not string
    
    return set_range

def parseNumList(string):
    
    pass

dt_act_options = ['all', 'one_per_channel']
tr_act_options = ['split_all', 'join_all', 'join_odd', 'join_even', 'join_list'] 

parser = ArgumentParser(description = 'Script to transform behavioral data into GB readable data')
parser.add_argument('-i','--input', help='Input file name',required=True)
parser.add_argument('-c','--config_file',help='Configuration file with genome browser fields correspondence', required=False)
parser.add_argument('-t','--tracks', help='List of selected tracks', required=False, type=int, nargs='+')
parser.add_argument('-a','--track_actions', help='Option of action with tracks selected, split_all, join_all, join_odd, join_even, join_range or join_list', required=False, choices=tr_act_options)
parser.add_argument('-d','--dataTypes_actions', help='Unique values of the field should dump on different data structures or not', required=False, choices=dt_act_options)
parser.add_argument('-r','--range', help='Numeric range of tracks', required=False, type=parseNumRange)
parser.add_argument('-l','--list', help='Numeric list of tracks', required=False, type=str, nargs='+')
parser.add_argument('-f','--format', help='Write file output format f', required=False, type=str)

# parser.add_argument('-c','--chrom_rules', help='Unique values of the field chrom should be dump on different data structures or not', required=False)

args = parser.parse_args()

## Show arguments selected
print("This are the selected options: -f  /Users/jespinosa/git/phecomp/lib/python/examples/b2g.txt -i /Users/jespinosa/git/phecomp/lib/python/examples/shortDev.int -t all")
print("Input file: %s" % args.input )
print("Configuration file: %s" % args.config_file)
print("Track actions is: %s" % args.track_actions)

path = args.input

# abc = [chr(x) for x in range(97, 123)]
# 
# print "#############", abc
# out = []

# import random
import itertools
# 
def ranges(i):
    
    temp_list = []
    
    for a, b in itertools.groupby(enumerate(i), lambda (x, y): y - x):        
        b = list(b)
        temp_list.append (b[0][1])
        temp_list.append (b[-1][1])
        
        yield tuple(temp_list)
        temp_list = []
        
print "?????????????????",(list(int2browser.interv([0, 1, 3, 4, 7, 8, 9, 11,12,13])))
# print ">>>>>>>>>>>>>>>>>>",list(enumerate([0, 1, 3, 4, 7, 8, 9, 11,12,13]))
# out.append(abc[0])
# for item in abc[1:]:
#     out += [''] * random.randrange(4, 8)
#     out.append(item)
# 
# print "+++++++++++++++++++++++++++++++",out     
## CONFIGURATION FILE
configFilePath = args.config_file
configFileDict = int2browser.ConfigInfo(configFilePath)

print "########" , configFileDict.correspondence
# Handling Argument tracks
sel_tracks = args.tracks 
print >>sys.stderr, "@@@Pergola_rules.py Selected tracks are: ", sel_tracks

# Handling list or range of tracks to join if set
if (args.list):
    tracks2merge = args.list
elif (args.range):
    tracks2merge = args.range
else:
    tracks2merge = ""
    
# exists args.range or args.list by default without setting any action they are joined keeping it simple
if tracks2merge and args.track_actions:
    raise ValueError ("Options --list -l or --range -r are incompatible with --track_actions -t, please change your options")
if tracks2merge:
    print tracks2merge
    print ' '.join(str(i) for i in tracks2merge)
    print >>sys.stderr, "@@@Pergola_rules.py Tracks to join are: %s"%(",".join("'{0}'".format(t) for t in tracks2merge))

# Handling argument track actions
track_act = args.track_actions
print >>sys.stderr, "@@@Pergola_rules.py Track actions are: ", track_act

# Handling argument dataTypes actions
dataTypes_act = args.dataTypes_actions
print >>sys.stderr, "@@@Pergola_rules.py dataTypes actions are: ", dataTypes_act

# Handling argument format
write_format = args.format
print >>sys.stderr, "@@@Pergola_rules.py format to write files: ", write_format

#End  of options
print >>sys.stderr, "@@@Print all the options set by pergola_rules end here!"

# intData = int2browser.intData(path, ontology_dict=configFileDict.correspondence, intervals=True, multiply_t=1000, window=30)
intData = int2browser.intData(path, ontology_dict=configFileDict.correspondence)


print intData.fieldsG

# print intData.data

for i in intData.data:
#     print i
    pass

print intData.min
print intData.max
#     print i
# iter=intData.read()
# iter=intData.read(relative_coord=True, intervals=False)
#buscar al manera de que si esta timepoint en el configuration file entonces crea de uno 
# for  i in iter:
#     print i
# 
# track_list = intData.tracks
#         
# #Lo que podria hacer es dejar esto aqui y no leer nada dentro de la funcion de convert, asi siempre le paso la lista tracks2merge que es mas limpio
# #aunque esto evitaria que pudiera como crear una odd y otra even a la vez mirar como puedo hacer eso
#         
# # tracks2merge = int2browser.read_track_actions(tracks=track_list, track_action="join_odd")
# # tracks2merge = int2browser.read_track_actions(tracks=track_list, track_action=track_act) 
# print "====================", tracks2merge       
# # print >>sys.stderr, "@@@Pergola_rules.py Tracks2merge=",tracks2merge
# # # tracks2merge=2       
# # # Generation of the files set by the user by command line
# print ":::::::::::::::::::::::::::::::::", write_format 
# print "===================$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", tracks2merge
bed_str =  intData.convert(mode = write_format, relative_coord = True, dataTypes_actions=dataTypes_act, tracks=sel_tracks, tracks_merge=tracks2merge, window=300)
for key in bed_str:
    print "key.......: ",key
    bedSingle = bed_str[key]
    print bedSingle
    bedSingle.write()