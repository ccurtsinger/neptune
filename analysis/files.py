"""Stuff for manipulating files"""

import os
import os.path

class Filename:
    """Maniplating and making queries based on just the filename"""
    
    def __init__(self, s = '.'):
        """Initialize from string"""
        self.s = s

    def parsed(self):
        """Returns the path split into components"""
        
        def pathSplit(s):
            head, tail = os.path.split(s)
            
            if len(head) > 0:
                return pathSplit(head) + [tail]
            else:
                return [tail]

        l = pathSplit(str(self))
        root,ext = os.path.splitext(l[-1])
        
        if len(root) > 0 and len(ext) > 0:
            l[-1] = (root,ext)

        return l

    def normalized(self):
        """Normalizes the path, see os.path.normath"""
        return Filename(os.path.normcase(os.path.normpath(str(self))))

    def absolute(self, base=None):
        """Gets an absolute path"""
        if base == None:
            return Filename(abspath(self.s))
        else:
            return Filename(os.path.join(str(base), self.s))

    def isAbsolute(self):
        return os.path.isabs(str(self))

    def isFile(self):
        return os.path.isfile(str(self))

    def isDirectory(self):
        return os.path.isdir(str(self))

    def isLink(self):
        return os.path.islink(str(self))

    def isMount(self):
        return os.path.ismount(str(self))

    def isHidden(self):
        """Whether a file or one of its parent directories is hidden"""
        l = self.parsed()

        for c in l:
            if type(c) == tuple:
                d = c[0]
            else:
                d = c

            if d[0] == '.' and d != '.' and d != '..':
                return True

        return False

    def extension(self):
        """Gets the file extension"""
        root,ext = os.path.splitext(str(self))

        if len(root) > 0 and len(ext) > 1:
            return ext[1:]
        else:
            return None

    def __add__(A, B):
        return Filename(os.path.join(str(A), str(B)))

    def __eq__(A, B):
        return os.path.samefile(str(A), str(B))

    def __str__(self):
        return self.s

    def __repr__(self):
        return self.s

def walk(base, show_hidden = False):
    """Generator which recursively descends directories and returns contents"""
    
    for t in os.walk(str(base)):
        dirpath, dirnames, filenames = t

        for b in dirnames + filenames:
            p = Filename(dirpath) + Filename(b)

            if show_hidden or not p.isHidden():
                yield p
