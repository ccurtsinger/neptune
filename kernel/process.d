/**
 * Process abstraction
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.process;

import kernel.arch.common;
import kernel.arch.constants;
import kernel.arch.paging;

import kernel.spec.elf;

import kernel.mem.addrspace;
import kernel.mem.range;
import kernel.mem.physical;

struct Process
{
    AddressSpace addr;
    size_t pagetable;
    size_t k_stack;
    Context context;
    
    public static Process opCall(ElfHeader* elf)
    {
        Process p;
        
        PageTable* pagetable = get_page_table();
        size_t pagetable_phys = pagetable.lookup(pagetable);
        
        PageTable* new_pagetable = pagetable.clone();
        p.pagetable = pagetable.lookup(new_pagetable); 
        
        size_t elf_base = size_t.max;
        size_t elf_top = 0;
        
        foreach(h; elf.getProgramHeaders())
        {
            if(h.getVirtualAddress() < elf_base)
                elf_base = h.getVirtualAddress();
                
            if(h.getMemorySize() + h.getVirtualAddress() > elf_top)
                elf_top = h.getMemorySize() + h.getVirtualAddress();
        }

        // Pass a zero kernel size, since this address space will never be used to allocate on the kernel heap
        p.addr = AddressSpace(new_pagetable, elf_base, elf_top - elf_base, 0);

        load_page_table(p.pagetable);
        
        auto binary = p.addr.allocate(ZoneType.BINARY, elf_top - elf_base);
        auto stack = p.addr.allocate(ZoneType.STACK, FRAME_SIZE);
        auto kernel_stack = p.addr.allocate(ZoneType.KERNEL_STACK, FRAME_SIZE);
        
        p.k_stack = kernel_stack.top - size_t.sizeof;
        
        foreach(h; elf.getProgramHeaders())
        {
            ubyte[] data = h.getData(elf);
            
            for(size_t i=0; i<data.length; i+=FRAME_SIZE)
            {
                assert(p.addr.map(h.getVirtualAddress() + i, new_pagetable.lookup(data.ptr + i), Permission("r-x"), Permission("rwx"), false, false));
            }
        }

        assert(p.addr.map(stack.base, p_alloc(), Permission("rw-"), Permission("rw-"), false, false));
        
        assert(p.addr.map(kernel_stack.base, p_alloc(), Permission("---"), Permission("rw-"), false, false));
        
        version(arch_i586)
        {
            p.context.eip = cast(size_t)elf.getEntry();
            p.context.cs = GDTSelector.USER_CODE | 0x3;
            p.context.ss = GDTSelector.USER_DATA | 0x3;
            p.context.flags = 0x202;
            
            p.context.esp = stack.top - 2*size_t.sizeof;
            p.context.ebp = stack.top - 1*size_t.sizeof;
        }
        
        load_page_table(pagetable_phys);
        
        return p;
    }
}
