/**
 * Process scheduler
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.scheduler;

import kernel.arch.common;
import kernel.process;

Process[] processes;
size_t current = size_t.max;

void add_process(Process p)
{
    processes ~= p;
}

void task_switch(Context* context)
{
    if(current == size_t.max)
    {
        current = 0;
        load_page_table(processes[current].pagetable);
        set_kernel_entry_stack(processes[current].k_stack);
        *context = processes[current].context;
    }
    else
    {
        processes[current].context = *context;
        
        current++;
        
        if(current >= processes.length)
            current = 0;
        
        load_page_table(processes[current].pagetable);
        set_kernel_entry_stack(processes[current].k_stack);
        *context = processes[current].context;
    }
}
