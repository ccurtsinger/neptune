/**
 * Base interface for writable objects
 *
 * Authors: Charlie Curtsinger
 * Date: November 4th, 2007
 * Version: 0.2a
 */

module std.io.Writable;

interface Writable
{
	Writable write(char   	arg, int pad = 0);
	Writable write(char[] 	arg, int pad = 0);
	
	Writable write(bool   	arg, int pad = 0);
	Writable write(bool[] 	arg);
	Writable write(void*   	arg, int pad = 0);
	Writable write(void*[] 	arg);
	Writable write(Object   arg, int pad = 0);
	Writable write(Object[] arg);
	
	Writable write(ulong   	arg, int radix = 10, int pad = 0);
	Writable write(ulong[] 	arg, int radix = 10);
	Writable write(uint     arg, int radix = 10, int pad = 0);
	Writable write(uint[] 	arg, int radix = 10);
	Writable write(ushort   arg, int radix = 10, int pad = 0);
	Writable write(ushort[] arg, int radix = 10);
	Writable write(ubyte    arg, int radix = 10, int pad = 0);
	Writable write(ubyte[]  arg, int radix = 10);
	Writable write(long   	arg, int radix = 10, int pad = 0);
	Writable write(long[] 	arg, int radix = 10);
	Writable write(int   	arg, int radix = 10, int pad = 0);
	Writable write(int[] 	arg, int radix = 10);
	Writable write(short   	arg, int radix = 10, int pad = 0);
	Writable write(short[] 	arg, int radix = 10);
	Writable write(byte   	arg, int radix = 10, int pad = 0);
	Writable write(byte[] 	arg, int radix = 10);
	
	Writable writef(...);
}
