import os
import re
import subprocess
from demangle import demangle

# Recognizes parts of the objdump output for cleaning
header_re = re.compile('[^:]*:\s*file format.*')
section_re = re.compile('Disassembly of section.*')
symbol_re = re.compile('(?P<location>[0-9a-f]*)\s\<(?P<symbol>.*)\>\:\s*$')
instruction_re = re.compile('(?P<location>[0-9a-f]*)\:\s*(?P<bytes>([0-9a-f]{2}\s)*[0-9a-f]{2})\s*(?P<instruction>[^\s].*)')
null_instruction_re = re.compile('[0-9a-f]*\:\s*([0-9a-f]{2}\s)*[0-9a-f]{2}\s*')

num_re = re.compile('0x(?P<num>[0-9a-f]+)')
jmp_re = re.compile('(?P<instruction>call|callq|jmp|jmpq|je|jne|jg|jge|jl|jle|jo|jz|jnz|ja|jae|jb|jbe)\s+(?P<num>[0-9a-f]+)\s+\<(?P<location>[^+-]*)(?P<offset>(\+|\-)0x[0-9a-f]*)?\>$')

comment_re = re.compile('(?P<real_code>[^\#]*)\#(?P<comment>.*)')

pic_re = re.compile('[0-9]+\(\%rip\)')
pic_loc_re = re.compile('[0-9a-f]{16}\s*\<(?P<location>.*)\>$')

# TODO: keep enough information to be able to track in-function jumps
def cleanupInstruction(instruction):
    """ Makes instructions somewhat more readable, mostly demangling names"""
    
    comment_match = comment_re.match(instruction)
    if comment_match != None:
        d = comment_match.groupdict()
        instruction = d['real_code'].strip()
        comment = d['comment'].strip()
    else:
        comment = ''

    
    # The cleaning for jump and call instructions
    jmp_match = jmp_re.match(instruction)
    if jmp_match != None:
        d = jmp_match.groupdict()
        
        inst = d['instruction']
        pad = ' ' * (7 - len(inst))
        
        if d['offset'] == None:
            t = (inst, pad, demangle(d['location']), '')
        else:
            t = (inst, pad, demangle(d['location']), d['offset'])
            
        return '%s%s<%s%s>' % t
    
    # The cleanining for normal instructions
    cleaned = ''
    end = 0

    for num in num_re.finditer(instruction):
        cleaned += instruction[end:num.start()]
        end = num.end()
        num = int(num.groupdict()['num'], 16)

        if(num > 2 ** 63):
            num = num - 2 ** 64
            
        cleaned += str(num)

    instruction = cleaned + instruction[end:]

    # Taking care of position independent code
    pic_match = pic_re.search(instruction)
    pic_loc_match = pic_loc_re.match(comment)
    if pic_match != None and pic_loc_match != None:
        location = pic_loc_match.groupdict()['location']
        start = instruction[:pic_match.start()]
        end = instruction[pic_match.end():]
        instruction =  '%s<%s>%s' % (start, location, end)

    return instruction

class Instruction:
    """Representation of an instruction and its offset from the symbol start"""
    def __init__(self, offset, contents, size):
        self.offset = offset
        self.contents = contents
        self.size = size
        # TODO: better size estimate, this includes trailing 0's
        # the compiler adds for alignment

    def __str__(self):
        return "+0x%x:\t\t%s" % (self.offset, self.contents)

    def __repr__(self):
        return str(self)

class Symbol:
    """Representation of a symbol"""
    def __init__(self, name, location):
        self.name = name
        self.location = location
        self.contents = []

    def size(self):
        last = self.contents[-1]
        return last.offset + last.size

    def __str__(self):
        t = (self.name, self.location, self.size())
        s = '<%s> (at 0x%x; size 0x%x):' % t
        s += '\n' + '\n'.join(map(str, self.contents))

        return s

    def __repr__(self):
        return str(self)


class Disassembly:
    """The disassembly of a binary file"""
    
    def __init__(self, obj_file, target=None):
        # Figure out the proper objdump to call
        if target == None:
            objdump = 'objdump'
        else:
            objdump = target + '-objdump'
            
        f = os.tmpfile()
            
        # Call objdump
        subprocess.call([objdump, '-dCS', str(obj_file)], stdout=f)

        # Read out and clean the disassembly
        f.seek(0)
        self.symbols = []
        
        for line in f.readlines():
            line = line.strip()
            
            if line == "":
                continue
            elif line == "...":
                continue
            
            if header_re.match(line) != None:
                continue
    
            if section_re.match(line) != None:
                continue
            
            symbol_match = symbol_re.match(line)
            if symbol_match != None:
                name = demangle(symbol_match.groupdict()['symbol'])
                location = int(symbol_match.groupdict()['location'], 16)

                self.symbols.append(Symbol(name, location))
                continue

            instruction_match = instruction_re.match(line)
            if instruction_match != None:
                d = instruction_match.groupdict()
                
                location = int(d['location'], 16)
                offset = location - self.symbols[-1].location
                size = (len(d['bytes']) + 1) / 3

                instruction = cleanupInstruction(d['instruction'])


                instruction = Instruction(offset, instruction, size)
                self.symbols[-1].contents.append(instruction)
                continue
            
            if null_instruction_re.match(line) != None:
                continue

            raise "Unrecognized line: '%s'" % line
                

    def __str__(self):
        return '\n\n'.join(map(str, self.symbols))

    def __repr__(self):
        return str(self)
