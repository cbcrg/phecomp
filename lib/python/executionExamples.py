#!/usr/bin/env python

import int2browser
# import argparse

parser = int2browser.argparse.ArgumentParser (description = 'Script to transform behavioral data into GB readable data')
parser.add_argument ('-i','--input', help='Input file name',required=True)
parser.add_argument ('-o','--output',help='Output file name', required=False)
args = parser.parse_args ()

## show values ##
print ("Input file: %s" % args.input )
print ("Output file: %s" % args.output )

path = args.input

# print (path)
intData = int2browser.intData(path, relative_coord=True)
print ("===============")
# _dict_rest_colors = {
#                      'water' : 'blue'}
# set_dataTypes = intData.dataTypes
# print set_dataTypes
# 
# assign_color (set_dataTypes, _dict_rest_colors)