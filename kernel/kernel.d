
module kernel.kernel;

void main()
{
    spawn_thread(System.memory.stack.allocate(), &thread_function);
	spawn_thread(System.memory.stack.allocate(), &thread_function);
	spawn_thread(System.memory.stack.allocate(), &thread_function);
		
	while(true)
	{
		char[] line = System.input.readln(System.output);
		System.output.write(line);
		delete line;
		System.output.writef("typing in thread %u", System.thread.getID()).newline;
		yield();
	}
}

void thread_function()
{
    while(true)
    {
        System.output.writef("hello from thread %u", System.thread.getID()).newline;
        yield();
    }
}

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
}
