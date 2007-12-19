module kernel.kernel;

import std.string;
import std.port;

alias void function(Event e) handler_t;

void main()
{
    System.output.write("Hello D!").newline;
    
    Dispatcher d = new Dispatcher();
    
    d.register(&test);
    d.register(&test2);
    
    d.dispatch(new EventA());

    int* x = cast(int*)0xA000F000;
    *x = 123;
    System.output.writef("%u", *x).newline;
}

void test(EventA e)
{
    System.output.write("test").newline;
}

void test2(EventB e)
{
    System.output.write("test2").newline;
}

class HandlerList
{
    handler_t[] handlers;
    TypeInfo t;
    
    public this(TypeInfo t)
    {
        this.t = t;
    }
    
    public void register(T)(void function(T e) h)
    {
        handlers.length = handlers.length + 1;
        handlers[length-1] = cast(handler_t)h;
    }
    
    public void dispatch(T)(T e)
    {
        foreach(handler_t h; handlers)
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
    
    public void dispatch(T)(T e)
    {
        TypeInfo t = typeid(T);
        
        handlers[t].dispatch(e);
    }
}

class Event
{
    
}

class EventA : Event
{
    
}

class EventB : Event
{
    
}
