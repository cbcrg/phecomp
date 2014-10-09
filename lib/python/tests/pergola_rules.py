#!/usr/bin/env python

import int2browser
import argparse

_rules_options=["all", "one_per_channel"]
parser = argparse.ArgumentParser(description = 'Script to transform behavioral data into GB readable data')
parser.add_argument('-i','--input', help='Input file name',required=True)
parser.add_argument('-f','--file_config',help='Configuration file with genome browser fields correspondence', required=False)
parser.add_argument('-r','--track_rules', help='Unique values of the field track should be dump on different data structures or not', required=False, choices=_rules_options)
parser.add_argument('-t','--tracks', help='List of selected tracks', required=False, type=int, nargs='+')
parser.add_argument('-d','--dataTypes_rules', help='Unique values of the field should dump on different data structures or not', required=False)
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
track_numbers = args.tracks 
print "track numbers: ",track_numbers
print "type-------: ",type(track_numbers)
print "type: ",type(track_numbers[0])
print "ooooooooooo",type(track_numbers.split(','))

intData = int2browser.intData(path, ontology_dict=configFileDict.correspondence, relative_coord=True)

i = (1,2,3)
print(type(i))
print(type (i[0]))