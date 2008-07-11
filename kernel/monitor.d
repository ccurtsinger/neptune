module kernel.monitor;

import kernel.lock;

class SimpleMonitor : IMonitor
{
	private Lock l;
	
	public this()
	{
		l = Lock();
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
