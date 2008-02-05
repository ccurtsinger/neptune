
module std.task.Thread;

abstract class Thread
{
	private size_t threadID;
	private static size_t nextID = 0;
	private ThreadState threadState;
	
	public synchronized this()
	{
	    threadState = ThreadState.New;
	    
		threadID = nextID;
		nextID++;
	}
	
	public void init();
	
	public size_t id()
	{
		return threadID;
	}
	
	public synchronized ThreadState state()
	{
		return threadState;
	}
	
	public synchronized void state(ThreadState s)
	{
		threadState = s;
	}
	
	public synchronized void saveContext(void* context);
	
	public synchronized void loadContext(void* context);
	
    protected void run();
    
    public synchronized final void start()
    {
    	System.scheduler.addThread(this);
    }
}
