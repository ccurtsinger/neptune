#!/usr/bin/python

import os
import sys
from optparse import OptionParser

# Grab command-line options
opt_parser = OptionParser(usage="nicedump.py [options] INPUT_FILE",
                          version="nicedump.py 0.1",
                          description="A utility to clean up objdump output");

opt_parser.add_option("-t", "--target", dest="target", default=None,
                      help="Specify the system the binary was compiled for")

opt_parser.add_option("-s", "--symbol", dest="symbol", default=None,
                      help="Print a specific specific symbol")

opt_parser.add_option("--symbol-containing", dest="symbol_substr",
                      default=None,
                      help="Print out symbols containing a substring")

(options, args) = opt_parser.parse_args()

if(len(args) != 1):
    opt_parser.error("Must provide exactly one input file")

