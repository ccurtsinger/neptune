module kernel.dev.kb;

import std.stdio;
import std.port;

import kernel.core.host;

struct Keyboard
{
    /**
     * Struct to hold keycode decoding information
     */
	struct Key
	{
	    /// Character to return when key is pressed in lowercase mode
		char lc;
		
		/// Character to return when key is pressed in uppercase mode
		char uc;
		
		/// Set if the key should toggle the caps mode
		bool shift;
        
        /**
         * Create a new Key decoder object
         *
         * Params:
         *  lc = lowercase character for the key
         *  uc = uppercase character for the key
         *  shift = set if the key should toggle the caps mode
         *
         * Returns: the newly created Key object
         */
		static Key opCall(char lc = '\0', char uc = '\0', bool shift = false)
		{
			Key k;

			k.lc = lc;
			k.uc = uc;
			k.shift = shift;

			return k;
		}
	}
	
	/// Flag is set if character should be decoded in caps mode
	private bool caps;
	
	/// Array of Key decoders
	private Key[256] keymap;
    
    public void init(ubyte interrupt)
    {
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
        keymap[40] = Key('\'', '"');
		keymap[41] = Key('`', '~');
		// Left shift down
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
		
		// Right shift down
        keymap[54] = Key('\0', '\0', true);
        
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
        
        localscope.setHandler(interrupt, &handler);
    }
    
    public bool handler(InterruptStack*)
    {
        ubyte s = inp(0x60);

		Key k = keymap[s];
		
		char c = '\0';

		if(caps)
		{
			c = k.uc;
		}
		else
		{
			c = k.lc;
		}

		if(k.shift)
		{
			caps = !caps;
		}
		
		if(c != '\0')
		{
			//chars.enqueue(c);
			char[1] str;
			str[0] = c;
			write(str);
		}

		outp(0x20, 0x20);
		
		return true;
    }
}
