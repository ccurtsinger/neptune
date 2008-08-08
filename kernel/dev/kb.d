/**
 * Keyboard device
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.dev.kb;

import std.port;
import std.context;

import util.arch.cpu;
import kernel.core.env;

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
	private Key[] keymap = [Key(),
                            Key(), //escape
                            Key('1', '!'),
                            Key('2', '@'),
                            Key('3', '#'),
                            Key('4', '$'),
                            Key('5', '%'),
                            Key('6', '^'),
                            Key('7', '&'),
                            Key('8', '*'),
                            Key('9', '('),
                            Key('0', ')'),
                            Key('-', '_'),
                            Key('=', '+'),
                            Key('\b', '\b'),
                            Key('\t', '\t'),
                            Key('q', 'Q'),
                            Key('w', 'W'),
                            Key('e', 'E'),
                            Key('r', 'R'),
                            Key('t', 'T'),
                            Key('y', 'Y'),
                            Key('u', 'U'),
                            Key('i', 'I'),
                            Key('o', 'O'),
                            Key('p', 'P'),
                            Key('[', '{'),
                            Key(']', '}'),
                            Key('\n', '\n'),
                            Key(), //control
                            Key('a', 'A'),
                            Key('s', 'S'),
                            Key('d', 'D'),
                            Key('f', 'F'),
                            Key('g', 'G'),
                            Key('h', 'H'),
                            Key('j', 'J'),
                            Key('k', 'K'),
                            Key('l', 'L'),
                            Key(';', ':'),
                            Key('\'', '"'),
                            Key('`', '~'),
                            Key('\0', '\0', true), // left shift down
                            Key('\\', '|'),
                            Key('z', 'Z'),
                            Key('x', 'X'),
                            Key('c', 'C'),
                            Key('v', 'V'),
                            Key('b', 'B'),
                            Key('n', 'N'),
                            Key('m', 'M'),
                            Key(',', '<'),
                            Key('.', '>'),
                            Key('/', '?'),
                            Key('\0', '\0', true), // right shift down
                            Key(), //print screen
                            Key(), //alt
                            Key(' ', ' '),
                            Key('\0', '\0', true), // caps lock
                            Key(), //F1
                            Key(), //F2
                            Key(), //F3
                            Key(), //F4
                            Key(), //F5
                            Key(), //F6
                            Key(), //F7
                            Key(), //F8
                            Key(), //F9
                            Key(), //F10
                            Key(), //numlock
                            Key(),
                            Key(), //home
                            Key(), //up
                            Key(), //page up
                            Key(),
                            Key(), //left
                            Key(),
                            Key(), //right
                            Key(),
                            Key(), //end
                            Key(), //down
                            Key(), //page down
                            Key(), //insert
                            Key(), //delete
                            Key(),
                            Key(),
                            Key(),
                            Key(), //F11
                            Key(), //F12
                            Key(),
                            Key(),
                            Key(), //windows
                            Key(),
                            Key(), //right click key
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(), //unknown (99)
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key(),
                            Key('\0', '\0', true) ];
                            
	private char[] queue;
    
    public void init(ubyte interrupt)
    {
        caps = false;
        
        //localscope.setHandler(interrupt, &handler);
    }
    
    public char getc()
    {
        volatile while(queue.length == 0)
        {
            CPU.halt();
        }
        
        char c = queue[0];
        queue[0..length-1] = queue[1..length];
        queue.length = queue.length - 1;
        
        return c;
    }
    
    public bool handler(Context*)
    {
        ubyte s = inp(0x60);

        Key k = Key();

        if(s < keymap.length)
            k = keymap[s];
        
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
            queue ~= c;
        }

        outp(0x20, 0x20);
            
        return true;
    }
}
