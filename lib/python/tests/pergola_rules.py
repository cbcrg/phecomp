#!/usr/bin/env python

import int2browser
from argparse import ArgumentParser, ArgumentTypeError
import sys
import re

def parseNumList(string):
    m = re.match(r'(\d+)(?:-(\d+))?$', string)

    if not m:
        raise ArgumentTypeError("'" + string + "' is not a range of number. Expected '0-5' or '2'.")
    start = m.group(1)
    end = m.group(2) or start
    list_range=list(range(int(start,10), int(end,10)+1))
    set_range=set(["{}".format(t) for t in list_range]) #modify probably I should change or set of tracks to integers and not string
    
    return set_range

dt_act_options = ['all', 'one_per_channel']
tr_act_options = ['split_all', 'join_all', 'join_odd', 'join_even', 'join_range', 'join_list'] 

parser = ArgumentParser(description = 'Script to transform behavioral data into GB readable data')
parser.add_argument('-i','--input', help='Input file name',required=True)
parser.add_argument('-f','--file_config',help='Configuration file with genome browser fields correspondence', required=False)
parser.add_argument('-t','--tracks', help='List of selected tracks', required=False, type=int, nargs='+')
parser.add_argument('-a','--track_actions', help='Option of action with tracks selected, split_all, join_all, join_odd, join_even, join_range or join_list', required=False, choices=tr_act_options)
parser.add_argument('-d','--dataTypes_actions', help='Unique values of the field should dump on different data structures or not', required=False, choices=dt_act_options)
parser.add_argument('-r','--range', help='Numeric range to set tracks to select tracks', required=False, type=parseNumList)

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
print >>sys.stderr, "@@@Pergola_rules.py Track rules are: ", track_act

tracks2merge = args.range
print >>sys.stderr, "@@@Pergola_rules.py Track list in range are: ", tracks2merge

dataTypes_act = args.dataTypes_actions
print >>sys.stderr, "@@@Pergola_rules.py dataTypes actions are: ", dataTypes_act

print >>sys.stderr, "@@@Print all the options set by pergola_rules end here!"

intData = int2browser.intData(path, ontology_dict=configFileDict.correspondence, relative_coord=True)
track_list = intData.tracks
        
# tracks2merge = int2browser.read_track_rules(tracks=track_list, track_rules="join_odd")        
# print >>sys.stderr, "@@@Pergola_rules.py Tracks2merge=",tracks2merge
# # tracks2merge=2       
# # Generation of the files set by the user by command line
bed_str =  intData.convert(mode = "bedGraph", relative_coord = True, split_dataTypes=True, tracks=sel_tracks, tracks_merge=tracks2merge)
# 
# for key in bed_str:
#     print key