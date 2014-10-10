#!/usr/bin/env python

import int2browser
import argparse

_rules_options = ['all', 'one_per_channel']
tr_rules_options = ['split_all', 'join_all'] 

parser = argparse.ArgumentParser(description = 'Script to transform behavioral data into GB readable data')
parser.add_argument('-i','--input', help='Input file name',required=True)
parser.add_argument('-f','--file_config',help='Configuration file with genome browser fields correspondence', required=False)
parser.add_argument('-t','--tracks', help='List of selected tracks', required=False, type=int, nargs='+')
parser.add_argument('-r','--track_rules', help='Help msg here', required=False, choices=tr_rules_options)
parser.add_argument('-d','--dataTypes_rules', help='Unique values of the field should dump on different data structures or not', required=False, choices=_rules_options)
# parser.add_argument('-','--dataTypes_rules', help='Unique values of the field should dump on different data structures or not', required=False)
parser.add_argument('-c','--chrom_rules', help='Unique values of the field chrom should be dump on different data structures or not', required=False)

args = parser.parse_args()

## Show arguments selected
print("This are the selected options: -f  /Users/jespinosa/git/phecomp/lib/python/examples/b2g.txt -i /Users/jespinosa/git/phecomp/lib/python/examples/shortDev.int -t all")
print("Input file: %s" % args.input )
print("Configuration file: %s" % args.file_config)
print("Track rules is: %s" % args.track_rules)

path = args.input

## CONFIGURATION FILE
configFilePath = args.file_config
configFileDict = int2browser.ConfigInfo(configFilePath)

# Handling Argument tracks
sel_tracks = args.tracks 
print "Selected tracks are: ", sel_tracks

track_rules = args.track_rules
print "Track rules are: ", track_rules

print "Print all the options set by pergola_rules end here!"

intData = int2browser.intData(path, ontology_dict=configFileDict.correspondence, relative_coord=True)

# Generation of the files set by the user by command line
bed_str =  intData.convert(mode = "bedGraph", relative_coord = True, split_dataTypes=True, tracks=sel_tracks, track_rules='join_all')

for key in bed_str:
    print key     
    