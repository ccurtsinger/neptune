/**
 * Constants for the i586 architecture
 *
 * Copyright: 2008 The Neptune Project
 */
 
module kernel.arch.i586.constants;

const size_t KERNEL_VIRTUAL_BASE = 0xC0000000;
const size_t USER_VIRTUAL_TOP = KERNEL_VIRTUAL_BASE;

const size_t STACK_TOP = 0xA0000000;
const size_t KERNEL_STACK_TOP = 0xE0000000;

const size_t PHYSICAL_MEMORY_MAX = 0xFFFFFFFF;
const size_t VIRTUAL_MEMORY_MAX = 0xFFFFFFFF;

const size_t FRAME_SIZE = 0x400000;
const size_t FRAME_BITS = 22;
const size_t HZ = 4;

enum GDTSelector
{
    KERNEL_CODE = 0x8,
    KERNEL_DATA = 0x10,
    USER_CODE = 0x18,
    USER_DATA = 0x20,
    TSS = 0x28
}

enum GDTIndex
{
    KERNEL_CODE = 1,
    KERNEL_DATA = 2,
    USER_CODE = 3,
    USER_DATA = 4,
    TSS = 5
}
