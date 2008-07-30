import SCons
import SCons.Environment
import SCons.Memoize
import SCons.Node
from SCons.Builder import Builder

command = '$LINK -o $TARGET $LINKFLAGS %s $SOURCES $_LIBDIRFLAGS $_LIBFLAGS'

def getLinkScriptsOpts(env):
    if 'LINKSCRIPTS' in env.Dictionary():
        if type(env['LINKSCRIPTS']) == str:
            scripts = env['LINKSCRIPTS'].split(' ')
        else:
            scripts = env['LINKSCRIPTS']
            
        return " ".join(['-T ' + env.File(s).srcnode().path for s in scripts])
    else:
        return ""
    

def Linker():
    def Generator(source, target, env, for_signature):
        return command % getLinkScriptsOpts(env)
    
    return Builder(generator = Generator)

partial_command = '$LINK -o $TARGET -Ur $LINKFLAGS %s $SOURCES $_LIBDIRFLAGS $_LIBFLAGS'

def PartialLinker():
    def Generator(source, target, env, for_signature):
        return partial_command % getLinkScriptsOpts(env)
    
    return Builder(generator = Generator)
