/**
 * Scheduler activations support
 *
 * Copyright: 2008 The Neptune Project
 */

module std.activation;

import std.context;

enum : size_t
{
    SA_NEW = 1,
    SA_PREEMPTED = 2
}

struct Activation
{
    Context context;
    
    size_t type;
    size_t data;
    size_t activation_id;
    size_t processor_id;
    
    public static Activation opCall(size_t activation_id)
    {
        Activation a;
        
        a.type = SA_NEW;
        a.activation_id = activation_id;
        
        return a;
    }
    
    public static Activation opCall(size_t type, size_t data, size_t activation_id, Context* context)
    {
        Activation a;
        
        a.type = type;
        a.data = data;
        a.activation_id = activation_id;
        
        a.context = *context;
        
        return a;
    }
}
