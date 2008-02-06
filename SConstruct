import sys
import os
import os.path

# Imports for the svn command execution
import popen2, fcntl, select

from xml.dom.minidom import parseString

# Import our special build scripts
sys.path.append(os.path.join('build', 'scripts'))

from linker import Linker
from linker import PartialLinker
from cd import CDBuilder

# Set up custom builders
yasm = Builder(action = 'yasm $YASMFLAGS -o $TARGET $SOURCE')
gdc = Builder(action = 'gdc $GDCFLAGS -c -o $TARGET $SOURCE')
obj = Builder(action = '')

link = Linker()
partial_link = PartialLinker()

def setupEnv(target, **kw_args):
    """ Creates a custom environment for the target """

    # Start with a standard cross compile environment
    env = Environment(  ENV = {'PATH': ['/usr/cross/%s/bin' % (target), '/usr/bin']})

    # Our custom builders
    env['BUILDERS']['yasm']        = yasm
    env['BUILDERS']['gdc']         = gdc
    env['BUILDERS']['obj']         = obj
    env['BUILDERS']['Link']        = link
    env['BUILDERS']['PartialLink'] = partial_link

    # Set to the maximum warning level
    env['CXXFLAGS'] += ['-Wall']

    for key in kw_args:
        env[key] = kw_args[key]

    return env

def runCommand(command):
    child = os.popen(command)
    data = child.read()
    err = child.close()
    if err:
	raise RuntimeError, '%s failed w/ exit code %d' % (command, err)
    return data

svninfo = runCommand('svn info --xml')

dom = parseString(svninfo)

base = dom.childNodes[0]

revision = base.getElementsByTagName('commit')[0]

revision = revision.getAttribute('revision')

f = open('kernel/svn.d', 'w')
f.write('module kernel.svn;\n')
f.write('const char[] svninfo = "' + revision + '";\n')
f.close()

i586_env = setupEnv('i586-pc-elf',  YASMFLAGS = '-f elf',

                                    GDCFLAGS =  ' -fversion=i586' +
                                                ' -funittest' +
                                                ' -Itriton' +
                                                ' -mno-red-zone' +
                                                ' -fno-exceptions' +
                                                ' -O0',

                                    LINKFLAGS = ' -nostdlib' +
                                                ' -nostartfiles' +
                                                ' -nodefaultlibs')

# Set up the x86_64 environment
env = setupEnv('x86_64-pc-elf', YASMFLAGS = '-f elf64',

                                GDCFLAGS =  ' -fversion=x86_64' +
                                            ' -funittest' +
                                            ' -Itriton' +
                                            ' -mno-red-zone' +
                                            ' -fno-exceptions' +
                                            ' -O0' +
                                            ' -mcmodel=kernel',

                                LINKFLAGS = ' -nostdlib')

# Build the Loader
loader = SConscript('loader/SConscript', exports='i586_env')

# Build Triton
triton = SConscript('triton/SConscript', exports='env')

# Build the Kernel
kernel = SConscript('kernel/SConscript', exports='env')

# Set library and linker script dependencies
Depends(kernel, triton)
Depends(kernel, 'kernel/link/linker.ld');

# Build the CD
cd_env = Environment(BUILDERS={'CD': CDBuilder})
cd_env.CD('neptune.iso', [loader, kernel, 'grub/stage2_eltorito', 'grub/iso-menu.lst'])

Default('neptune.iso')
