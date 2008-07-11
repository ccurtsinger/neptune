module kernel.lock;

struct Lock
{
    private bool state;
    
    public static Lock opCall(bool initial = true)
    {
        Lock l;
        l.state = !initial;
        return l;
    }
    
    private bool lock()
    {
        bool ret = false;
        
        asm
        {
            "lock xchgb %%al, (%[result])" : "=a" ret : [result] "Nd" &state, "a" 1;
        }
        
        return ret;
    }
    
    public bool trylock()
    {
        return !lock();
    }
    
    public bool spinlock(size_t limit = 0)
    {
        if(limit == 0)
        {
            while(lock())
            {
                asm{"pause";}
            }
            return true;
        }
        else
        {
            for(size_t i=0; i<limit; i++)
            {
                if(!lock())
                    asm{"pause";}
                else
                    return true;
            }
            
            return false;
        }
    }
    
    public void unlock()
    {
        state = false;
    }
}
