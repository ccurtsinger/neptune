/**
 * Kernel events management
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.event;

import std.context;
import std.string;
import std.stdio;

abstract class EventHandler
{
    public abstract void opCall(char[] domain, EventSource source);
}

class FunctionEventHandler : EventHandler
{
    void function(char[] domain, EventSource source) handler;
    
    public this(void function(char[] domain, EventSource source) handler)
    {
        this.handler = handler;
    }
    
    public void opCall(char[] domain, EventSource source)
    {
        this.handler(domain, source);
    }
}

class DelegateEventHandler : EventHandler
{
    void delegate(char[] domain, EventSource source) handler;
    
    public this(void delegate(char[] domain, EventSource source) handler)
    {
        this.handler = handler;
    }
    
    public void opCall(char[] domain, EventSource source)
    {
        this.handler(domain, source);
    }
}

abstract class EventSource
{
    
}

class InterruptEventSource: EventSource
{
    public Context* context;
    
    public this(Context* context)
    {
        this.context = context;
    }
}

class EventDomain
{
    EventHandler[] handlers;
    EventDomain[char[]] subdomains;
    
    public void addHandler(char[] event, EventHandler h)
    {
        char[][] parts = explode(".", event, 2);
        
        if(!(parts[0] in subdomains))
        {
            subdomains[parts[0]] = new EventDomain();
        }
    
        if(parts.length == 1)
        {
            subdomains[parts[0]].handlers ~= h;
        }
        else
        {
            subdomains[parts[0]].addHandler(parts[1], h);
        }
        
        delete parts;
    }
    
    public void raiseEvent(char[] event, EventSource source)
    {
        if(event.length > 0)
        {
            char[][] parts = explode(".", event, 2);

            if(parts[0] in subdomains)
            {
                if(parts.length == 1)
                {
                    subdomains[parts[0]].raiseEvent("", source);
                }
                else
                {
                    subdomains[parts[0]].raiseEvent(parts[1], source);
                }
            }
            
            delete parts;
        }
        
        foreach(h; handlers)
        {
            h(event, source);
        }
    }
}
