/**
 * Processor allocator for scheduler activations
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.task.procallocator;

import std.context;
import std.activation;

import kernel.core.env;
import kernel.task.process;

class Processor
{
    private size_t processor_id;
    private Process current_process;
    private size_t current_activation;
    
    public this(size_t id)
    {
        this.processor_id = id;
        current_process = null;
    }
    
    public size_t id()
    {
        return processor_id;
    }
    
    public Process process()
    {
        return current_process;
    }
    
    // Just a hack for now.  Needs to do this with an inter-processor interrupt once there are
    // multiple processors running at once
    public void loadContext(size_t activation_id, Context* dest, Context* context, Process process)
    {
        current_activation = activation_id;
        
        current_process = process;
        *dest = *context;

        cpu.pagetable = process.pagetable;
        cpu.loadPageDir();
    }
}

class ProcessorAllocator
{
    private Processor[] free;
    private Process[] requests;
    private size_t next_activation_id = 0;
    
    public this()
    {
        
    }
    
    public void add(Processor p)
    {
        free ~= p;
    }
    
    public Activation* getActivation()
    {
        Activation* sa = new Activation;
        
        *sa = Activation(next_activation_id);
        next_activation_id++;
        
        return sa;
    }
    
    public void request(Process process)
    {
        requests ~= process;
    }
    
    public void tick(Context* context)
    {
        if(free.length > 0)
        {
            // Handle all requests with available processors
            while(requests.length > 0 && free.length > 0)
            {
                Processor p = free[0];
                free[0..length-1] = free[1..length];
                free.length = free.length - 1;
                
                Process process = requests[0];
                requests[0..length-1] = requests[1..length];
                requests.length = requests.length-1;
                
                process.upcall(p, context);
            }
        }
        else if(requests.length > 0)
        {
            // Preempt the current processor only
            Process process = requests[0];
            requests[0..length-1] = requests[1..length];
            requests.length = requests.length - 1;
            
            if(local.process !is null)
            {
                // Allocate and initialize a new activation for the process being preempted
                local.process.sa = new Activation;
                *local.process.sa = Activation(SA_PREEMPTED, local.current_activation, next_activation_id, context);
                
                next_activation_id++;
                
                // Create a new request for the current context
                requests ~= local.process;
            }
            
            process.upcall(local, context);
        }
    }
}
