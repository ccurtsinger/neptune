def demangle(mangled_name):
    def parseNumber(s):
        # Retrieves an integer off of os
        i = 0
        while s[i].isdigit():
            i += 1

        return int(s[:i]), s[i:]

    def parseName(s):
        # Retrieves a single name off of s
        i, s = parseNumber(s)

        if s[:3] == '__T':
            return parseTemplateName(s, i)

        return s[:i], s[i:]

    def parseFunction(s):
        if s[0] == 'Z':
            return ('void', [], '', False), s[1:]
        
        # Delegate or member function...
        delegate = False
        member_function = False

        while s[0] in ['D', 'M']:
            if s[0] == 'D':
                delegate = True
            elif s[0] == 'M':
                member_function = True
            s = s[1:]
        
        # The language
        if s[0] == 'F':
            lang = ''
        elif s[0] == 'U':
            lang = 'extern (C) '
        elif s[0] == 'W':
            lang = 'extern (Windows) '
        elif s[0] == 'V':
            lang = 'extern (Pascal) '
        elif s[0] == 'R':
            lang = 'extern (C++) '
        s = s[1:]

        # The argument list
        args = []

        while True:
            if s[0] == 'Z':
                break
            elif s[0] == 'X' or s[0] == 'Y':
                args.append('...')
                break
            else:
                if s[0] == 'J':
                    extra = 'out '
                    s = s[1:]
                elif s[0] == 'K':
                    extra = 'inout '
                    s = s[1:]
                elif s[0] == 'L':
                    extra = 'lazy '
                    s = s[1:]
                else:
                    extra = ''

                t, s = parseType(s)
                args.append(extra + t)

        if member_function or delegate:
            args.append('this')
            
        # Return type
        return_type, s = parseType(s)

        return (return_type, args, lang, delegate), s
            
        

    def parseType(s, is_delegate = False, this_ptr = False):
        # Retrieves a type off of s
        
        BASIC_TYPES = {'v': 'void', 'b': 'bool', 'g': 'byte', 'h': 'ubyte',
                       's': 'short', 't': 'ushort', 'i': 'int', 'k': 'uint',
                       'l': 'long', 'm': 'ulong', 'f': 'float', 'd': 'double',
                       'e': 'real', 'o': 'ifloat', 'p': 'idouble',
                       'j': 'ireal', 'q': 'cfloat', 'r': 'cdouble',
                       'c': 'creal', 'a': 'char', 'u': 'wchar', 'w': 'dchar'}

        if s[0] in BASIC_TYPES:
            return BASIC_TYPES[s[0]], s[1:]
        
        # Compound types
        elif s[0] == 'A': # dynamic array
            t, s = parseType(s[1:])
            return '%s[]' % t, s
        
        elif s[0] == 'P': # pointer
            t, s = parseType(s[1:])
            return '%s*' % t, s
        
        elif s[0] == 'G': # static array
            i, s = parseNumber(s[1:])
            t, s = parseType(s)

            return '%s[%d]' % (t, i) , s
        
        elif s[0] == 'H': # associative array
            index_type, s = parseType(s[1:])
            value_type, s = parseType(s)

            return '%s[%s]' % (value_type, index_type), s

        # Function
        elif s[0] in ['D', 'M', 'F', 'U', 'W', 'V', 'R']:
            f, s = parseFunction(s)
            return_type, args, lang, delegate = f

            t = (return_type, ','.join(args))
            if delegate:
                return '%s delegate(%s)' % t, s
            else:
                return '%s function(%s)' % t, s

        # Class/struct/etc
        elif s[0] in ['C', 'S', 'E', 'T']:
            return parseQName(s[1:])

        
        else:
            return None, s

    def parseTemplateName(s, i):
        # Retrieves a template instance off of s
        t = s[3:i]
        s = s[i:]

        name, t = parseName(t)
        
        args = []
        while True:
            if t[0] == 'T':
                a, t = parseType(t[1:])
                args.append(a)
            elif t[0] == 'S':
                a, t = parseName(t[1:])
                args.append(a)
            elif t[0] == 'Z':
                break
            else:
                raise 'Error'
        
        return '%s!(%s)' % (name,','.join(args)), s

    def parseQName(s):
        # Retrieves an entire qualified name off of s
        r = []
        while len(s) > 0 and s[0].isdigit():
            n, s = parseName(s)
            r.append(n)

        return '.'.join(r), s

    #print mangled_name
    
    # Check for and remove the '_D'
    if mangled_name[0:2] != '_D' or not mangled_name[2].isdigit():
        return mangled_name
    mangled_name = mangled_name[2:]

    # Parse the function name
    name, s = parseQName(mangled_name)
    function, s = parseFunction(s)
    return_type, args, lang, delegate = function

    #print function

    if return_type == None:
        return '%s(%s)' % (name, ','.join(args))
    else:
        return '%s %s(%s)' % (return_type, name, ','.join(args))
