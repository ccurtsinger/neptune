import sys
import os
import os.path

# Import our special build scripts
sys.path.append(os.path.join('build', 'scripts'))

from linker import Linker
from linker import PartialLinker
from cd import CDBuilder
from buildinfo import InfoBuilder

# Set up custom builders
yasm = Builder(action = 'yasm $YASMFLAGS -o $TARGET $SOURCE')
yasm64 = Builder(action = 'yasm $YASM64FLAGS -o $TARGET $SOURCE')
gdc = Builder(action = 'gdc $GDCFLAGS -c -o $TARGET $SOURCE')
obj = Builder(action = '')

link = Linker()
partial_link = PartialLinker()

def setupEnv(target, version, **kw_args):
    """ Creates a custom environment for the target """

    # Start with a standard cross compile environment
    env = Environment(  ENV = {'PATH': ['/usr/cross/%s-pc-elf/bin' % (target), '/bin', '/usr/bin', '/usr/local/bin']})

    env['target'] = target
    env['version'] = version

    # Our custom builders
    env['BUILDERS']['yasm']        = yasm
    env['BUILDERS']['yasm64']      = yasm64
    env['BUILDERS']['gdc']         = gdc
    env['BUILDERS']['obj']         = obj
    env['BUILDERS']['Link']        = link
    env['BUILDERS']['PartialLink'] = partial_link
    env['BUILDERS']['info']        = InfoBuilder

    # Set global GDC flags
    env['GDCFLAGS']  = ' -fversion=arch_' + target
    env['GDCFLAGS'] += ' -Ikernel/runtime'
    env['GDCFLAGS'] += ' -mno-red-zone'
    env['GDCFLAGS'] += ' -fno-exceptions'

    env['YASMFLAGS'] = '-f elf'
    env['YASM64FLAGS'] = '-f elf64'

    if(target == 'x86_64'):
        env['GDCFLAGS'] += ' -mcmodel=kernel'

    # Set version-specific flags
    if(version == 'debug'):
        env['GDCFLAGS'] += ' -O0'
        env['GDCFLAGS'] += ' -funittest'
    elif(version == 'release'):
        env['GDCFLAGS'] += ' -Os'
        env['GDCFLAGS'] += ' -frelease'
    else:
        print 'Invalid version: ' + version
        raise

    # Set global linker flags
    env['LINKFLAGS']  = ' -nostdlib'
    env['LINKFLAGS'] += ' -nostartfiles'
    env['LINKFLAGS'] += ' -nodefaultlibs'

    # push any additional arguments into the environment
    for key in kw_args:
        env[key] = kw_args[key]

    return env

# Set up the i586 environment
env = setupEnv('i586', 'debug')

# Build the Kernel
kernel = SConscript('kernel/SConscript', exports='env', build_dir='build/kernel', duplicate=0)

test = SConscript('test/SConscript', exports='env', build_dir='build/test/', duplicate=0)
test2 = SConscript('test2/SConscript', exports='env', build_dir='build/test2/', duplicate=0)

Depends('neptune.iso', kernel)
Depends('neptune.iso', test)
Depends('neptune.iso', test2)

# Build the CD
cd_env = Environment(BUILDERS={'CD': CDBuilder})
AlwaysBuild(cd_env.CD('neptune.iso', [kernel, 'grub/stage2_eltorito', 'grub/iso-menu.lst', test, test2]))

Default('neptune.iso')
