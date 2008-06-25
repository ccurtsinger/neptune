class QName:
    """A data structure for a parsed qname"""
    
    def __init__(self, s, top_level = True):
        """Creates a parsed qname from a demangled name"""

        # Splits a string into a head and tail by a given character,
        # from the right, remaining outside parentheses
        def split(s, c):
            paren_level = 0
            
            for i in xrange(len(s)-1, -1, -1):
                if s[i] == c and paren_level == 0:
                    return s[:i],s[i+1:]
                elif s[i] == '(':
                    paren_level += 1
                elif s[i] == ')':
                    paren_level -= 1

            return '',s

        # Fully splits a string into sections by a given character,
        # remaining outside parentheses
        def fullSplit(s, c):
            l = []

            h, t = split(s, c)
            while h != '':
                l[:0] = [t]
                h, t = split(h, c)
            l[:0] = [t]

            return l

        head, tail = split(s, '.')

        # self.head
        if head == '':
            self.head = None
        else:
            self.head = QName(head, False)

        # Deal with the base name
        if tail.find('!(') != -1:
            self.type = 'template'
            
            i = tail.find('!(')
            self.name = tail[:i]
            self.args = [QName(s) for s in fullSplit(tail[i+2:-1], ',')]
            
        elif tail.find('(') != -1:
            self.type = 'function'

            i = tail.find('(')
            self.name = tail[:i]
            self.args = [QName(s) for s in fullSplit(tail[i+1:-1], ',')]
            
        elif top_level:
            self.type = 'unknown'
            self.name = tail

        else:
            self.type = 'namespace'
            self.name = tail

    def __hash__(self):
        return hash(str(self))

    def __eq__(A, B):
        return str(A) == str(B)

    def __str__(self):
        if self.head == None:
            s = ''
        else:
            s = str(self.head) + '.'

        if self.type == 'template':
            s += '%s!(%s)' % (self.name, ','.join(map(str, self.args)))
        elif self.type == 'function':
            s += '%s(%s)' % (self.name, ','.join(map(str, self.args)))
        else:
            s += self.name
        
        return s

    def __repr__(self):
        return str(self)
