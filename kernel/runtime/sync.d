module sync;

import kernel.lock;
import kernel.monitor;

struct CriticalSection
{
	Lock mutex;
	CriticalSection* next;
}

CriticalSection* cslist = null;
Lock lock;
size_t count = 0;

extern(C) void _d_criticalenter(CriticalSection* cs)
{
	lock.spinlock();
	
	CriticalSection* c = cslist;
	
	while(c !is null)
	{
		if(c == cs)
			break;
		else
			c = c.next;
	}
	
	if(c is null)
	{
		cs.mutex = Lock();
		cs.next = cslist;
		cslist = cs;
		count++;
	}
	
	lock.unlock();
	
	cs.mutex.spinlock();
}

extern(C) void _d_criticalexit(CriticalSection* cs)
{
	cs.mutex.unlock();
}

/*********************
 * Monitors
 */

extern (C) void _d_monitordelete(Object h, bool det)
{
    Monitor* m = getMonitor(h);

    if (m !is null)
    {
        IMonitor i = m.impl;

        if (det && (cast(void*) i) !is (cast(void*) h))
        {
            delete i;
        }
        
        delete m;
            
        setMonitor(h, null);
    }
}

extern (C) void _d_monitorcreate(Object h)
{
	Monitor* m = new Monitor;
	
	m.impl = new SimpleMonitor();
	
	setMonitor(h, m);
}

extern (C) void _d_monitorenter(Object h)
{
    Monitor* m = getMonitor(h);

    if (m is null)
    {
        _d_monitorcreate(h);
        m = getMonitor(h);
        
        assert(m !is null, "Monitor creation failed");
    }

    IMonitor i = m.impl;

    i.lock();
}

extern (C) void _d_monitorexit(Object h)
{
    Monitor* m = getMonitor(h);
    IMonitor i = m.impl;

    i.unlock();
}
