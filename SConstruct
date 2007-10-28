import sys
import os
import os.path

# Import our special build scripts
sys.path.append(os.path.join('build', 'scripts'))
import cross_compile
from linker import Linker
from linker import PartialLinker
from cd import CDBuilder
import doxygen

# Set up custom builders
yasm = Builder(action = 'yasm $YASMFLAGS -o $TARGET $SOURCE')
gdc = Builder(action = 'x86_64-pc-elf-gdc $GDCFLAGS -c -o $TARGET $SOURCE')
obj = Builder(action = '')

link = Linker()
partial_link = PartialLinker()

def setupEnv(target, **kw_args):
    """ Creates a custom environment for the target """

    # Start with a standard cross compile environment
    env = cross_compile.environment(target)

    # Our custom builders
    env['BUILDERS']['yasm']        = yasm
    env['BUILDERS']['gdc']         = Builder(action = '%s-gdc $GDCFLAGS -fdoc-dir=docs -fdoc-inc=docs/candydoc/candy.ddoc -fdoc-inc=docs/candydoc/modules.ddoc -c -o $TARGET $SOURCE' % target)
    env['BUILDERS']['obj']         = obj
    env['BUILDERS']['Link']        = link
    env['BUILDERS']['PartialLink'] = partial_link

    # Set to the maximum warning level
    env['CXXFLAGS'] += ['-Wall']

    for key in kw_args:
        env[key] = kw_args[key]

    return env

i586_env = setupEnv('i586-pc-elf',   YASMFLAGS = '-f elf', GDCFLAGS =   ' -fversion=i586' +
                                                                        ' -Itriton' +
                                                                        ' -Ikernel' +
                                                                        ' -mno-red-zone' +
                                                                        ' -fno-exceptions' +
                                                                        ' -O4')

# Set up the x86_64 environment
env = setupEnv('x86_64-pc-elf', YASMFLAGS = '-f elf64', GDCFLAGS =  ' -fversion=x86_64' +
                                                                    ' -Itriton' +
                                                                    ' -Ikernel' +
                                                                    ' -mno-red-zone' +
                                                                    ' -fno-exceptions' +
                                                                    ' -O4' +
                                                                    ' -mcmodel=kernel')

# Build the Loader
loader = SConscript('loader/SConscript', exports='i586_env')

# Build Triton
triton = SConscript('triton/SConscript', exports='env')

# Build Neptune
neptune = SConscript('neptune/SConscript', exports='env')

# Build the Kernel
kernel = SConscript('kernel/SConscript', exports='env')

Depends(kernel, triton)
Depends(neptune, triton)
Depends(kernel, neptune)

# Build the CD
cd_env = Environment(BUILDERS={'CD': CDBuilder})
cd_env.CD('neptune.iso', [loader, kernel, 'grub/stage2_eltorito', 'grub/iso-menu.lst'])

Default('neptune.iso')
