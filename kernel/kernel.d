
module kernel.kernel;

import std.collection.stack;
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
	    System.scheduler.addThread(&thread_function);
	    
		System.output.write("% ");
		char[] line = System.input.readln(System.output);
		
		if(line.length > 1)
			run = parseCommand(line[0..(length-1)]);
		
		delete line;

		System.scheduler.yield();
	}
}

void timer_interrupt(void* p, ulong interrupt, ulong error, InterruptStack* context)
{
    System.scheduler.addThread(&timer);
    outp(PIC1, PIC_EOI);
}

void timer()
{
    time++;
    System.scheduler.exit();
}

bool parseCommand(char[] cmd)
{
	char[][] parts = cmd.explode('.');
	
	if(parts[0] == "System")
	{
		if(parts.length == 1)
		{
			System.output.write("std.System").newline;
		}
		else if(parts[1] == "memory")
		{
			if(parts.length == 2)
			{
				System.output.write(System.memory.toString()).newline;
			}
			else if(parts[2] == "physical")
			{
				if(parts.length == 3)
				{
					System.output.write(System.memory.physical.toString()).newline;
				}
				else if(parts[3] == "getFreeSize()")
				{
					System.output.writef("%016#X", System.memory.physical.getFreeSize()).newline;
				}
				else if(parts[3] == "getAllocatedSize()")
				{
					System.output.writef("%016#X", System.memory.physical.getAllocatedSize()).newline;
				}
				else if(parts[3] == "getOverheadSize()")
				{
					System.output.writef("%016#X", System.memory.physical.getOverheadSize()).newline;
				}
				else if(parts[3] == "getPage()")
				{
					System.output.writef("%016#X", System.memory.physical.getPage()).newline;
				}
				else
				{
					System.output.writef("Unrecognized command 'System.memory.physical.%s'", parts[3]).newline;
				}
			}
			else if(parts[2] == "heap")
			{
				if(parts.length == 3)
				{
					System.output.write(System.memory.heap.toString()).newline;
				}
				else if(parts[3] == "getFreeSize()")
				{
					System.output.writef("%016#X", System.memory.heap.getFreeSize()).newline;
				}
				else if(parts[3] == "getAllocatedSize()")
				{
					System.output.writef("%016#X", System.memory.heap.getAllocatedSize()).newline;
				}
				else if(parts[3] == "getOverheadSize()")
				{
					System.output.writef("%016#X", System.memory.heap.getOverheadSize()).newline;
				}
				else if(parts[3] == "allocate()")
				{
					System.output.writef("%016#X", cast(ulong)System.memory.heap.allocate(1)).newline;
				}
				else
				{
					System.output.writef("Unrecognized command 'System.memory.heap.%s'", parts[3]).newline;
				}
			}
			else if(parts[2] == "stack")
			{
				if(parts.length == 3)
				{
					System.output.write(System.memory.stack.toString()).newline;
				}
				else if(parts[3] == "getFreeSize()")
				{
					System.output.writef("%016#X", System.memory.stack.getFreeSize()).newline;
				}
				else if(parts[3] == "getAllocatedSize()")
				{
					System.output.writef("%016#X", System.memory.stack.getAllocatedSize()).newline;
				}
				else if(parts[3] == "getOverheadSize()")
				{
					System.output.writef("%016#X", System.memory.stack.getOverheadSize()).newline;
				}
				else if(parts[3] == "allocate()")
				{
					System.output.writef("%016#X", cast(ulong)System.memory.stack.allocate()).newline;
				}
				else
				{
					System.output.writef("Unrecognized command 'System.memory.stack.%s'", parts[3]).newline;
				}
			}
			else
			{
				System.output.writef("Unrecognized command 'System.memory.%s'", parts[2]).newline;
			}
		}
		else if(parts[1] == "scheduler")
		{
			if(parts.length == 2)
			{
				System.output.write(System.scheduler.toString()).newline;
			}
			else if(parts[2] == "thread")
			{
			    if(parts.length == 3)
			    {
			        System.output.write(System.scheduler.thread.toString()).newline;
			    }
			    else if(parts[3] == "getID()")
			    {
                    System.output.writef("%u", System.scheduler.thread.getID()).newline;
			    }
			    else
			    {
			        System.output.writef("Unrecognized command 'System.scheduler.thread.%s'", parts[3]).newline;
			    }
			}
			else if(parts[2] == "yield()")
			{
			    System.scheduler.yield();
			}
			else
			{
				System.output.writef("Unrecognized command 'System.scheduler.%s'", parts[2]).newline;
			}
		}
		else if(parts[1] == "time")
		{
			System.output.writef("Current time: %u", time).newline;
		}
		else if(parts[1] == "reboot()")
		{
			return false;
		}
		else
		{
			System.output.writef("Unrecognized command 'System.%s'", parts[1]).newline;
		}
	}
	else
	{
		System.output.writef("Unrecognized object '%s'", parts[0]).newline;
	}
	
	foreach(char[] t; parts)
	{
		delete t;
	}
	
	delete parts;
	
	return true;
}

void thread_function()
{
    while(true)
    {
        System.output.writef("hello from thread %u", System.scheduler.thread.getID()).newline;
        System.scheduler.exit();
    }
}

/*
void yield()
{
    asm
    {
        "int $255";
    }
}

ulong spawn_thread(void* stack, void function() thread)
{
    ulong result;
    
    asm
    {
        "int $254" : "=a" result, "=c" thread : "b" stack, "c" thread;
    }
    
    if(result == 0)
    {
        thread();
        assert(false, "Unhandled thread termination");
    }
    
    return result;
}*/
