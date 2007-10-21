module dev.kb;

import std.port;

import neptune.arch.idt;

import dev.screen;

bool caps;

struct Key
{
    char lc;
    char uc;
    bool shift;

    static Key opCall(char lc = '\0', char uc = '\0', bool shift = false)
    {
        Key k;

        k.lc = lc;
        k.uc = uc;
        k.shift = shift;

        return k;
    }
}

Key[256] keymap;

void kb_install()
{
    idt_install_handler(33, cast(ulong)&kb_handler);

    caps = false;

    for(int i=0; i<256; i++)
    {
        keymap[i] = Key();
    }

    // 1 is escape
    keymap[2]  = Key('1', '!');
    keymap[3]  = Key('2', '@');
    keymap[4]  = Key('3', '#');
    keymap[5]  = Key('4', '$');
    keymap[6]  = Key('5', '%');
    keymap[7]  = Key('6', '^');
    keymap[8]  = Key('7', '&');
    keymap[9]  = Key('8', '*');
    keymap[10] = Key('9', '(');
    keymap[11] = Key('0', ')');
    keymap[12] = Key('-', '_');
    keymap[13] = Key('=', '+');
    keymap[14] = Key('\b', '\b');
    keymap[15] = Key('\t', '\t');
    keymap[16] = Key('q', 'Q');
    keymap[17] = Key('w', 'W');
    keymap[18] = Key('e', 'E');
    keymap[19] = Key('r', 'R');
    keymap[20] = Key('t', 'T');
    keymap[21] = Key('y', 'Y');
    keymap[22] = Key('u', 'U');
    keymap[23] = Key('i', 'I');
    keymap[24] = Key('o', 'O');
    keymap[25] = Key('p', 'P');
    keymap[26] = Key('[', '{');
    keymap[27] = Key(']', '}');
    keymap[28] = Key('\n', '\n');
    // 29 is ctrl
    keymap[30] = Key('a', 'A');
    keymap[31] = Key('s', 'S');
    keymap[32] = Key('d', 'D');
    keymap[33] = Key('f', 'F');
    keymap[34] = Key('g', 'G');
    keymap[35] = Key('h', 'H');
    keymap[36] = Key('j', 'J');
    keymap[37] = Key('k', 'K');
    keymap[38] = Key('l', 'L');
    keymap[39] = Key(';', ':');

    keymap[41] = Key('`', '~');
    // Shift down
    keymap[42] = Key('\0', '\0', true);

    keymap[44] = Key('\\', '|');
    keymap[44] = Key('z', 'Z');
    keymap[45] = Key('x', 'X');
    keymap[46] = Key('c', 'C');
    keymap[47] = Key('v', 'V');
    keymap[48] = Key('b', 'B');
    keymap[49] = Key('n', 'N');
    keymap[50] = Key('m', 'M');
    keymap[51] = Key(',', '<');
    keymap[52] = Key('.', '>');
    keymap[53] = Key('/', '?');

    // 55 is print screen
    // 56 is alt
    keymap[57] = Key(' ', ' ');

    // Caps Lock
    keymap[58] = Key('\0', '\0', true);
    // 59 is F1
    // 60 is F2
    // 61 is F3
    // 62 is F4
    // 63 is F5
    // 64 is F6
    // 65 is F7
    // 66 is F8
    // 67 is F9
    // 68 is F10
    // 69 is numlock
    // 71 is home
    // 72 is up
    // 73 is pg up

    // 75 is left
    // 77 is right
    // 79 is end
    // 80 is down
    // 81 is pg down
    // 82 is insert
    // 83 is del

    // 87 is F11
    // 88 is F12

    // 91 is windows key
    // 93 is right-click menu

    keymap[170] = Key('\0', '\0', true);
}

void kb_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    ubyte s = inp(0x60);

    Key k = keymap[s];

    if(caps)
    {
        putc(k.uc);
    }
    else
    {
        putc(k.lc);
    }

    if(k.shift)
    {
        caps = !caps;
    }

    // Used for finding keycodes
    /*if(s < 128 && k.lc == '\0')
    {
        writef("(%u)", s);
    }*/

    outp(0x20, 0x20);
}

