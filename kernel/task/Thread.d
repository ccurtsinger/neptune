
module kernel.task.Thread;

import neptune.arch.idt;

class Thread
{
    private ulong id;
    private InterruptStack context;
    
    this(ulong id, ulong stack)
    {
        this.id = id;
        context.rsp = stack;
    }
    
    public void setID(ulong id)
    {
        this.id = id;
    }
    
    public ulong getID()
    {
        return id;
    }
    
    public void setContext(InterruptStack context)
    {
        this.context = context;
    }
    
    public InterruptStack* getContext()
    {
        return &context;
    }
}
