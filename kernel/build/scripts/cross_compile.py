import os
import SCons
import SCons.Environment

class ToolException:
    def __init__(self, tool, target):
        self.tool = tool
        self.target = target

    def __str__(self):
        return 'No %s found for target "%s"' % (self.tool, self.target)

def getCrossTool(env, tool, target):
    cross_tool_name = target + '-' + env[tool]
    
    if env.Detect(cross_tool_name) == None:
        raise ToolException(env[tool], target)

    return cross_tool_name

def environment(target):
    """ Creates a cross-compiling environment for the given target """

    # Create an environment
    env = SCons.Environment.Base()

    # Use a reasonable PATH
    # TODO: Windows compatibility?
    env['ENV']['PATH'] = os.environ.get('PATH')

    # Make all references to the cross tools
    env['AR']  = getCrossTool(env, 'AR', target)
    env['AS']  = getCrossTool(env, 'AS', target)
    env['CC']  = getCrossTool(env, 'CC', target)
    env['CXX'] = getCrossTool(env, 'CXX', target)
    env['RANLIB'] = getCrossTool(env, 'RANLIB', target)

    # A hack for the linker, if we feel like doing this later
    env['LINK'] = '%s-ld' % target


    # TODO: Update version info
    
    return env
