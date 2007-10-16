module dev.kb;

import dev.screen;
import dev.port;
import interrupt.idt;

char[128] keymap;
bool caps;

void kb_install()
{
    idt_install_handler(33, cast(ulong)&kb_handler);

    caps = false;

    for(int i=0; i<128; i++)
    {
        keymap[i] = '\0';
    }

    keymap[15] = '\t';
    keymap[16] = 'q';
    keymap[17] = 'w';
    keymap[18] = 'e';
    keymap[19] = 'r';
    keymap[20] = 't';
    keymap[21] = 'y';
    keymap[22] = 'u';
    keymap[23] = 'i';
    keymap[24] = 'o';
    keymap[25] = 'p';
    keymap[26] = '[';
    keymap[27] = ']';
    keymap[28] = '\n';

    keymap[30] = 'a';
    keymap[31] = 's';
    keymap[32] = 'd';
    keymap[33] = 'f';
    keymap[34] = 'g';
    keymap[35] = 'h';
    keymap[36] = 'j';
    keymap[37] = 'k';
    keymap[38] = 'l';
    keymap[39] = ';';


    keymap[44] = '\\';
    keymap[44] = 'z';
    keymap[45] = 'x';
    keymap[46] = 'c';
    keymap[47] = 'v';
    keymap[48] = 'b';
    keymap[49] = 'n';
    keymap[50] = 'm';
    keymap[51] = ',';
    keymap[52] = '.';
    keymap[53] = '/';

    keymap[57] = ' ';
}

void kb_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    ulong k = inp(0x60);

    // Shift down, shift up, caps lock
    if(k == 42 || k == 170 || k == 58)
    {
        caps = !(caps == true);
    }
    else if(k < 128 && keymap[k] != '\0')
    {
        if(caps == true)
        {
            printc(keymap[k] + 'A' - 'a');
        }
        else
        {
            printc(keymap[k]);
        }
    }
    else
    {
        //print_uint_dec(k);
        //printc('\n');
    }

    outp(0x20, 0x20);
}

