/**
 * Kernel events management
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.event;

import std.string;

struct EventHandler
{
    size_t pid;
    void function(char[] domain) handler;
    
    public static EventHandler opCall(size_t pid, void function(char[] domain) handler)
    {
        EventHandler e;
        e.pid = pid;
        e.handler = handler;
        return e;
    }
}

struct EventDomain
{
    EventHandler[] handlers;
    EventDomain[char[]] subdomains;
    
    public static EventDomain opCall()
    {
        EventDomain d;
        return d;
    }
    
    public void addHandler(char[] event, EventHandler h)
    {
        char[][] parts = explode(".", event, 2);
        
        if(!(parts[0] in subdomains))
        {
            subdomains[parts[0]] = EventDomain();
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
    
    public void raiseEvent(char[] event)
    {
        if(event.length > 0)
        {
            char[][] parts = explode(".", event, 2);

            if(parts[0] in subdomains)
            {
                if(parts.length == 1)
                {
                    subdomains[parts[0]].raiseEvent("");
                }
                else
                {
                    subdomains[parts[0]].raiseEvent(parts[1]);
                }
            }
            
            delete parts;
        }
        
        foreach(h; handlers)
        {
            if(h.pid == 0)
                h.handler(event);
            else
                assert(false, "Only kernel events are supported at this time");
        }
    }
}
