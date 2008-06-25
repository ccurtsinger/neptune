#!/usr/bin/python

import sys
import operator
from optparse import OptionParser
import files
import objdump
from qname import *

def objectFiles(base):
    for f in files.walk(base):
        if f.extension() == 'o':
            yield f

def getSizes(base, target=None):
    sizes = []
    
    for obj_file in objectFiles(base):
        disassembly = objdump.Disassembly(obj_file, target)

        if len(disassembly.symbols) == 0:
            sys.stderr.write('Warning: read no symbols from %s\n' % str(obj_file))

        for symbol in disassembly.symbols:
            sizes.append((QName(symbol.name), symbol.size()))

    # Sort the sizes
    sizes.sort(key=operator.itemgetter(1))
    sizes.reverse()

    return sizes
        

# Grab command-line options
opt_parser = OptionParser(usage='sizes.py [options] BASE_DIRECTORY',
                          version='sizes.py 0.1',
                          description="Grabs the size of functions in the kernel");

opt_parser.add_option('-t', '--target', 
                      action='store', type='string',dest='target', default=None,
                      help='Specify the system the binary was compiled for')

opt_parser.add_option('--tree', 
                      action='store_true', dest='tree',
                      help='Display sizes for namespaces + down')

opt_parser.add_option('--list', 
                      action='store_false', dest='tree',
                      help='Display sizes only for symbols (this is the default)')

(options, args) = opt_parser.parse_args()

if len(args) != 1:
    print 'Must specify exactly one base directory to read .o files from\n'
    opt_parser.print_help()
    exit()

sizes = getSizes(args[0], options.target)

if options.tree:
    sizes = dict(sizes)
    subs = {}

    # Gets all of the parents of all of the given qnames
    def namespaces(qnames):
        ns = {}
        for qname in qnames:
            if qname.head in ns:
                ns[qname.head].add(qname)
            else:
                ns[qname.head] = set([qname])

        if None in ns:
            del ns[None]
            
        return ns
    
    # Generate the sizes for all of the tree from the leaves
    ns = namespaces(sizes.keys())
    while len(ns.keys()) > 0:
        for i in ns:
            if i not in subs:
                subs[i] = ns[i]
            else:
                subs[i].update(ns[i])

            if i not in sizes:
                sizes[i] = 0
                    
            for j in ns[i]:
                sizes[i] += sizes[j]

        ns = namespaces(ns.keys())

    # Find the top level of the tree
    top_level = set()
    for n in sizes.keys():
        if n.head == None:
            top_level.add(n)

    # Move top-level names that are not namespaces to the <global> namespace
    top_level.add('<global>')
    subs['<global>'] = set()
    sizes['<global>'] = 0

    for n in list(top_level):
        if n not in subs:
            top_level.remove(n)
            subs['<global>'].add(n)
            sizes['<global>'] += sizes[n]
            
    subs[None] = top_level

    def sortedSizes(names):
        s = []
        
        for name in names:
            s.append((name, sizes[name]))

        s.sort(key=operator.itemgetter(1))
        s.reverse()
    
        return s

    def printNode(node, level):
        print '%s%s (%d)' % ('  ' * level, node, sizes[node])

    def printTree(node=None, level=-1):
        if node != None:
            printNode(node, level)

        if node in subs:
            for n in sortedSizes(subs[node]):
                printTree(n[0], level + 1)

    printTree()
else:
    for s in sizes:
        print s[0], s[1]

