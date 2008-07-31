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
gdc = Builder(action = 'gdc $GDCFLAGS -c -o $TARGET $SOURCE')
obj = Builder(action = '')

link = Linker()
partial_link = PartialLinker()

def setupEnv(target, version, **kw_args):
    """ Creates a custom environment for the target """

    # Start with a standard cross compile environment
    env = Environment(  ENV = {'PATH': ['/usr/cross/%s-pc-elf/bin' % (target), '/bin', '/usr/bin', '/usr/local/bin']})

    # Our custom builders
    env['BUILDERS']['yasm']        = yasm
    env['BUILDERS']['gdc']         = gdc
    env['BUILDERS']['obj']         = obj
    env['BUILDERS']['Link']        = link
    env['BUILDERS']['PartialLink'] = partial_link
    env['BUILDERS']['info']        = InfoBuilder
    
    # Set global GDC flags
    env['GDCFLAGS']  = ' -fversion=' + target
    env['GDCFLAGS'] += ' -Ilib/triton'
    env['GDCFLAGS'] += ' -Ilib'
    env['GDCFLAGS'] += ' -mno-red-zone'
    env['GDCFLAGS'] += ' -fno-exceptions'
    
    # Set target-specific YASM and GDC flags
    if(target == 'i586'):
        env['YASMFLAGS'] = '-f elf'
    elif(target == 'x86_64'):
        env['YASMFLAGS'] = '-f elf64'
        env['GDCFLAGS'] += ' -mcmodel=kernel'
    else:
        print 'Invalid target: ' + target
        raise
    
    # Set version-specific flags
    if(version == 'debug'):
        env['GDCFLAGS'] += ' -O0'
        env['GDCFLAGS'] += ' -funittest'
        env['GDCFLAGS'] += ' -fversion=unwind'
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
i586_env = setupEnv('i586', 'debug')

# Set up the x86_64 environment
x86_64_env = setupEnv('x86_64', 'debug')

# Build libraries for x86_64-pc-elf
lib64 = SConscript('lib/SConscript', exports={'env': x86_64_env}, build_dir='build/x86_64/lib', duplicate=0)

# Build libraries for i586-pc-elf
lib32 = SConscript('lib/SConscript', exports={'env': i586_env}, build_dir='build/i586/lib', duplicate=0)

# Build the Loader
loader = SConscript('loader/SConscript', exports={'env': i586_env, 'lib' : lib32}, build_dir='build/i586/loader', duplicate=0)

# Build the Kernel
kernel = SConscript('kernel/SConscript', exports={'env': x86_64_env, 'lib' : lib64}, build_dir='build/x86_64/kernel', duplicate=0)

# Build servers
servers = SConscript('servers/SConscript', exports={'env': x86_64_env, 'lib' : lib64}, build_dir='build/x86_64/servers', duplicate=0)

# Set library and linker script dependencies
Depends(kernel, lib64['triton'])
Depends(kernel, 'kernel/link/linker.ld')
Depends(loader, lib32['triton'])

Depends('neptune.iso', kernel)
Depends('neptune.iso', servers)

# Build the CD
cd_env = Environment(BUILDERS={'CD': CDBuilder})
AlwaysBuild(cd_env.CD('neptune.iso', [loader, kernel, 'grub/stage2_eltorito', 'grub/iso-menu.lst'] + servers))

Default('neptune.iso')
