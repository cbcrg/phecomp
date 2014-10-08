#!/usr/bin/env python

import int2browser

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
configFilePath = args.file_config
configFileDict = int2browser.ConfigInfo(configFilePath)
