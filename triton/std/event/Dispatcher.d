
module std.event.Dispatcher;

import std.event.Event;

alias void function(Event e) func_handler_t;
alias void delegate(Event e) del_handler_t;

class HandlerList
{
    func_handler_t[] func_handlers;
    del_handler_t[] del_handlers;
    
    TypeInfo t;
    
    public this(TypeInfo t)
    {
        this.t = t;
    }
    
    public void register(T)(void function(T e) h)
    {
        func_handlers.length = func_handlers.length + 1;
        func_handlers[length-1] = cast(func_handler_t)h;
    }
    
    public void register(T)(void delegate(T e) h)
    {
    	del_handlers.length = del_handlers.length + 1;
    	del_handlers[length-1] = cast(del_handler_t)h;
    }
    
    public void dispatch(T)(T e)
    {
        foreach(func_handler_t h; func_handlers)
        {
            h(e);
        }
        
        foreach(del_handler_t h; del_handlers)
        {
        	h(e);
        }
    }
}

class Dispatcher
{
    HandlerList[TypeInfo] handlers;

    public void register(T)(void function(T e) handler)
    {
        TypeInfo t = typeid(T);
        
        if(!(t in handlers))
            handlers[t] = new HandlerList(t);
        
        handlers[t].register(handler);
    }
    
    public void register(T)(void delegate(T e) handler)
    {
        TypeInfo t = typeid(T);
        
        if(!(t in handlers))
            handlers[t] = new HandlerList(t);
        
        handlers[t].register(handler);
    }
    
    public void dispatch(T)(T e)
    {
        TypeInfo t = typeid(T);
        
        handlers[t].dispatch(e);
    }
}
