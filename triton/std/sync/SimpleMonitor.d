
module std.sync.SimpleMonitor;

import std.sync.Lock;

class SimpleMonitor : IMonitor
{
	private Lock l;
	
	public this()
	{
		l = new Lock();
	}
	
	public ~this()
	{
		delete l;
	}
	
	public void lock()
	{
		l.spinlock();
	}
	
	public void unlock()
	{
		l.unlock();
	}
}
