#!/usr/bin/env python

## -f  /Users/jespinosa/git/phecomp/lib/python/examples/b2g.txt -i /Users/jespinosa/git/phecomp/lib/python/examples/shortDev.int -a join_odd  -d all -r 1-2

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
    set_range=set(["{}".format(t) for t in list_range]) #modify probably I should change or set of tracks to integers and not string
    
    return set_range

def parseNumList(string):
    
    pass

dt_act_options = ['all', 'one_per_channel']
tr_act_options = ['split_all', 'join_all', 'join_odd', 'join_even', 'join_list'] 

parser = ArgumentParser(description = 'Script to transform behavioral data into GB readable data')
parser.add_argument('-i','--input', help='Input file name',required=True)
parser.add_argument('-f','--file_config',help='Configuration file with genome browser fields correspondence', required=False)
parser.add_argument('-t','--tracks', help='List of selected tracks', required=False, type=int, nargs='+')
parser.add_argument('-a','--track_actions', help='Option of action with tracks selected, split_all, join_all, join_odd, join_even, join_range or join_list', required=False, choices=tr_act_options)
parser.add_argument('-d','--dataTypes_actions', help='Unique values of the field should dump on different data structures or not', required=False, choices=dt_act_options)
parser.add_argument('-r','--range', help='Numeric range of tracks', required=False, type=parseNumRange)
parser.add_argument('-l','--list', help='Numeric list of tracks', required=False, type=int, nargs='+')

# parser.add_argument('-','--dataTypes_rules', help='Unique values of the field should dump on different data structures or not', required=False)
parser.add_argument('-c','--chrom_rules', help='Unique values of the field chrom should be dump on different data structures or not', required=False)

args = parser.parse_args()

## Show arguments selected
print("This are the selected options: -f  /Users/jespinosa/git/phecomp/lib/python/examples/b2g.txt -i /Users/jespinosa/git/phecomp/lib/python/examples/shortDev.int -t all")
print("Input file: %s" % args.input )
print("Configuration file: %s" % args.file_config)
print("Track actions is: %s" % args.track_actions)

path = args.input

## CONFIGURATION FILE
configFilePath = args.file_config
configFileDict = int2browser.ConfigInfo(configFilePath)

# Handling Argument tracks
sel_tracks = args.tracks 
print >>sys.stderr, "@@@Pergola_rules.py Selected tracks are: ", sel_tracks

track_act = args.track_actions
print >>sys.stderr, "@@@Pergola_rules.py Track actions are: ", track_act

if (args.list):
    tracks2merge = args.list
elif (args.range):
    tracks2merge = args.range
else:
    tracks2merge = ""
    
# exists args.range or args.list by default without setting any action they are joined keeping it simple
# if (not in_call and len(self.tracks) != 1):
# tracks2merge = args.range
print >>sys.stderr, "@@@Pergola_rules.py Tracks to join are: ", tracks2merge

dataTypes_act = args.dataTypes_actions
print >>sys.stderr, "@@@Pergola_rules.py dataTypes actions are: ", dataTypes_act

print >>sys.stderr, "@@@Print all the options set by pergola_rules end here!"

intData = int2browser.intData(path, ontology_dict=configFileDict.correspondence, relative_coord=True)
track_list = intData.tracks
        
#Lo que podria hacer es dejar esto aqui y no leer nada dentro de la funcion de convert, asi siempre le paso la lista tracks2merge que es mas limpio
#aunque esto evitaria que pudiera como crear una odd y otra even a la vez mirar como puedo hacer eso
        
# tracks2merge = int2browser.read_track_actions(tracks=track_list, track_action="join_odd")
# tracks2merge = int2browser.read_track_actions(tracks=track_list, track_action=track_act) 
print "====================", tracks2merge       
# print >>sys.stderr, "@@@Pergola_rules.py Tracks2merge=",tracks2merge
# # tracks2merge=2       
# # Generation of the files set by the user by command line
bed_str =  intData.convert(mode = "bedGraph", relative_coord = True, split_dataTypes=True, tracks=sel_tracks, tracks_merge=tracks2merge)
 
for key in bed_str:
    print key