/**
 * Memory system setup and runtime code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.mem;

import kernel.core.env;

import kernel.mem.physical : p_init, p_set;
import kernel.mem.heap : m_init, m_base, m_limit;

import util.arch.cpu;
import util.arch.arch;
import util.arch.paging;

public void memory_setup()
{    
    p_init();
    
    foreach(region; loaderData.memoryRegions[0..loaderData.numMemoryRegions])
    {
        if(region.type == 1)
        {
            for(size_t i = region.base; i < region.base + region.size; i += FRAME_SIZE)
            {
                p_free(i);
            }
        }
    }

    foreach(used_region; loaderData.usedRegions[0..loaderData.numUsedRegions])
    {
        for(size_t i = used_region.base; i < used_region.base + used_region.size; i += FRAME_SIZE)
        {
            p_set(i);
        }
    }
    
    CPU.pagetable = cast(PageTable*)ptov(loaderData.L4);
    
    m_init(CPU.pagetable);
}
