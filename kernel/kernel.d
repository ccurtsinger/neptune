module kernel.kernel;

import kernel.task.Thread;
import kernel.buildinfo;

import std.event.Event;

void main()
{
    System.output.write("Neptune Kernel - SVN version").newline;
    System.output.write(svninfo).newline;

    KernelThread t = new KernelThread(&thread);

    System.input.readln(System.output);

    System.dispatcher.register(&handler);

    System.dispatcher.dispatch(new EventA());

    t.start();

    thread();

    for(;;){}
}

void handler(EventA e)
{
	System.output.write("EventA handler").newline;
}

void thread()
{
	while(true)
	{
		System.output.writef("thread %u", System.scheduler.current.id).newline;

		pause();
	}
}

void pause()
{
    for(size_t i=0; i<10000000; i++)
    {

    }
}

class EventA : Event
{

}
