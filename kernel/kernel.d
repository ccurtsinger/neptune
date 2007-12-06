
module kernel.kernel;

import std.string;
import std.port;

import neptune.arch.idt;

ulong time;

void main()
{
    time = 0;
    
	bool run = true;
	
	while(run)
	{
		System.output.write("% ");
		char[] line = System.input.readln(System.output);
		
		//if(line.length > 1)
			//run = parseCommand(line[0..(length-1)]);
		
		delete line;
	}
}
