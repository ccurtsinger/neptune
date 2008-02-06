import os, popen2, fcntl, select
import os.path
import sys
from SCons.Builder import Builder

def getCommandOutput(command):
    child = os.popen(command)
    data = child.read()
    err = child.close()
    if err:
	raise RuntimeError, '%s failed w/ exit code %d' % (command, err)
    return data

def info_gen(target, source, env):

    info_defines = {'revision': '123',
                    'svninfo': getCommandOutput('svn info').strip()}

    for a_target, a_source in zip(target, source):
        outfile = file(str(a_target), "w")
        infile = file(str(a_source), "r")
        outfile.write(infile.read() % info_defines)
        infile.close()
        outfile.close()

    return None

InfoBuilder = Builder(action = info_gen, suffix = '.d', src_suffix = '.in')
