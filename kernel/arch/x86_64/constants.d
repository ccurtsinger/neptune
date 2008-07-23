/**
 * Constants for the i586 architecture
 *
 * Copyright: 2008 The Neptune Project
 */
 
module kernel.arch.x86_64.constants;

const size_t KERNEL_VIRTUAL_BASE = 0xFFFFFFFF80000000;
const size_t USER_VIRTUAL_TOP = 0x80000000;

const size_t STACK_TOP = 0xA0000000;
const size_t KERNEL_STACK_TOP = 0xE0000000;

const size_t PHYSICAL_MEMORY_MAX = 0xFFFFFFFF;
const size_t VIRTUAL_MEMORY_MAX = 0xFFFFFFFFFFFFFFFF;

const size_t KERNEL_PHYSICAL_ENTRY = 0x1000000;
const size_t KERNEL_ENTRY = 0xFFFFFFFF81000000;

const size_t FRAME_SIZE = 0x1000;
const size_t FRAME_BITS = 12;
const size_t HZ = 4;    

enum GDTSelector
{
    KERNEL_CODE = 0x10,
    KERNEL_DATA = 0x20,
    USER_CODE = 0x30,
    USER_DATA = 0x40,
    TSS = 0x50
}

enum GDTIndex
{
    KERNEL_CODE = 1,
    KERNEL_DATA = 2,
    USER_CODE = 3,
    USER_DATA = 4,
    TSS = 5
}
