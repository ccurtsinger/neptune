// -*- c-basic-offset:4 -*-

#include <iostream>
using std::cout;
using std::endl;

#include <stdint.h>
#include "cpuinfo.hpp"
#include "masks.hpp"

union Register32Bytewise
{
    uint32_t value;
    char bytes[4];
};

inline void cpuid(uint32_t fn,
    uint32_t &eax,
    uint32_t &ebx,
    uint32_t &ecx,
    uint32_t &edx)
{
    asm("cpuid": "=a" (eax), "=b" (ebx), "=c" (ecx), "=d" (edx) : "a" (fn));
}

inline void copyRegisterStr(uint32_t reg_value, char *dst)
{
    reinterpret_cast<uint32_t *>(dst)[0] = reg_value;
}

inline int takeLowerBits(uint32_t &value, unsigned int num_bits)
{
    // Mask out the bits we want
    uint32_t mask = (1 << num_bits) - 1;
    int ret = value & mask;

    // Kill them once we're done
    value >>= num_bits;

    return ret;
}

inline bool hasFeature(uint32_t reg_value, unsigned int bit)
{
    return (reg_value & bitMask(bit)) != 0;
}

inline uint8_t L2Associativity(uint8_t raw_value)
{
    switch(raw_value) {
    case 0:
        return 0;
    case 1:
        return 1;
    case 2:
        return 2;
    case 4:
        return 4;
    case 6:
        return 8;
    case 8:
        return 16;
    case 0xF:
        return 0xFF;
    }
}

CPUInfo::CPUInfo()
{
    unsigned int maxFunc;
    unsigned int eax, ebx, ecx, edx;

    cpuid(0, eax, ebx, ecx, edx);

    // The maximum allowed function
    maxFunc = eax;


    // Grab the manufacturer string
    copyRegisterStr(ebx, manufacturer_string);
    copyRegisterStr(edx, &manufacturer_string[4]);
    copyRegisterStr(ecx, &manufacturer_string[8]);
    manufacturer_string[12] = '\0';

    if(maxFunc >= 1) {

    unsigned int base_model,  extended_model;
    unsigned int base_family, extended_family;

    cpuid(1, eax, ebx, ecx, edx);

    // Get the processor model
    stepping        = takeLowerBits(eax, 4);
    base_model      = takeLowerBits(eax, 4);
    base_family     = takeLowerBits(eax, 4);
    eax >>= 3;
    extended_model  = takeLowerBits(eax, 4);
    extended_family = takeLowerBits(eax, 8);

    if(base_family > 0xF) {
        model  = (extended_model << 4) | base_model;
        family = (0xB0 | base_family) + extended_family;
    }
    else {
        model  = base_model;
        family = base_family;
    }

    // Grab some miscellaneous info
    local_apic_id           = takeLowerBits(ebx, 8);
    logical_processor_count = takeLowerBits(ebx, 8);
    clflush_size            = takeLowerBits(ebx, 8);
    brand_id                = takeLowerBits(ebx, 8);

    // Grab feature bits from ecx and edx
    cmpxchg16b                  = hasFeature(ecx, 13);
    sse3                        = hasFeature(ecx, 0);
    hyper_threading             = hasFeature(edx, 28);
    sse2                        = hasFeature(edx, 26);
    sse                         = hasFeature(edx, 25);
    fxsr                        = hasFeature(edx, 24);
    mmx                         = hasFeature(edx, 23);
    clflush                     = hasFeature(edx, 19);
    page_size_extensions36      = hasFeature(edx, 17);
    page_attribute_table        = hasFeature(edx, 16);
    cmov                        = hasFeature(edx, 15);
    machine_check_architecture  = hasFeature(edx, 14);
    page_global_extension       = hasFeature(edx, 13);
    memory_type_range_registers = hasFeature(edx, 12);
    sys_enter_sys_exit          = hasFeature(edx, 11);
    apic                        = hasFeature(edx, 9);
    cmpxchg8b                   = hasFeature(edx, 8);
    machine_check_exception     = hasFeature(edx, 7);
    physical_address_extension  = hasFeature(edx, 6);
    model_specific_registers    = hasFeature(edx, 5);
    time_stamp_counter          = hasFeature(edx, 4);
    page_size_extensions        = hasFeature(edx, 3);
    debugging_extensions        = hasFeature(edx, 2);
    virtual_mode_enhancements   = hasFeature(edx, 1);
    fpu                         = hasFeature(edx, 0);

    }

    // Looking at Extended CPUID values
    cpuid(0x80000000, eax, ebx, ecx, edx);
    maxFunc = eax;

    if(maxFunc < 1) {
      return;
    }

    
    cpuid(0x80000001, eax, ebx, ecx, edx);

    alt_mov_cr8            = hasFeature(ecx, 4);
    secure_virtual_machine = hasFeature(ecx, 2);
    cmp_legacy             = hasFeature(ecx, 1);
    lahf_sahf              = hasFeature(ecx, 0);
    threed_now             = hasFeature(edx, 31);
    threed_now_ext         = hasFeature(edx, 30);
    long_mode              = hasFeature(edx, 29);
    rdtsp                  = hasFeature(edx, 27);
    ffxsr                  = hasFeature(edx, 25);
    mmx_ext                = hasFeature(edx, 22);
    nx_bit                 = hasFeature(edx, 20);
    sys_call_sys_ret       = hasFeature(edx, 11);

    // Grab the processor name
    cpuid(0x80000002, eax, ebx, ecx, edx);
    copyRegisterStr(eax, &processor_name[0]);
    copyRegisterStr(ebx, &processor_name[4]);
    copyRegisterStr(ecx, &processor_name[8]);
    copyRegisterStr(edx, &processor_name[12]);

    cpuid(0x80000003, eax, ebx, ecx, edx);
    copyRegisterStr(eax, &processor_name[16]);
    copyRegisterStr(ebx, &processor_name[20]);
    copyRegisterStr(ecx, &processor_name[24]);
    copyRegisterStr(edx, &processor_name[28]);

    cpuid(0x80000004, eax, ebx, ecx, edx);
    copyRegisterStr(eax, &processor_name[32]);
    copyRegisterStr(ebx, &processor_name[36]);
    copyRegisterStr(ecx, &processor_name[40]);
    copyRegisterStr(edx, &processor_name[44]);

    // L1 Cache info
    cpuid(0x80000005, eax, ebx, ecx, edx);

    // L1 TLB for 2MB/4MB pages
    L1_instructions_tlb.large_page_size = takeLowerBits(eax, 8);
    L1_instructions_tlb.large_page_associativity = takeLowerBits(eax, 8);
    L1_data_tlb.large_page_size = takeLowerBits(eax, 8);
    L1_data_tlb.large_page_associativity = takeLowerBits(eax, 8);


    // L1 TLB for 4KB pages
    L1_instructions_tlb.small_page_size = takeLowerBits(ebx, 8);
    L1_instructions_tlb.small_page_associativity = takeLowerBits(ebx, 8);
    L1_data_tlb.small_page_size = takeLowerBits(ebx, 8);
    L1_data_tlb.small_page_associativity = takeLowerBits(ebx, 8);


    // L1 Data Cache
    L1_data.line_size = takeLowerBits(ecx, 8);
    L1_data.lines_per_tag = takeLowerBits(ecx, 8);
    L1_data.associativity = takeLowerBits(ecx, 8);
    L1_data.size = takeLowerBits(ecx, 8);

    L1_instructions.line_size = takeLowerBits(edx, 8);
    L1_instructions.lines_per_tag = takeLowerBits(edx, 8);
    L1_instructions.associativity = takeLowerBits(edx, 8);
    L1_instructions.size = takeLowerBits(edx, 8);

    // L2 Cache info
    cpuid(0x80000006, eax, ebx, ecx, edx);

    L2_tlb_unified = (eax >> 16) == 0 && (ebx >> 16) == 0;

    // L2 TLB for 2MB/4MB pages
    L2_instructions_tlb.large_page_size = takeLowerBits(eax, 12);
    L2_instructions_tlb.large_page_associativity = 
    L2Associativity(takeLowerBits(eax, 4));


    L2_data_tlb.large_page_size = takeLowerBits(eax, 12);
    L2_data_tlb.large_page_associativity = 
    L2Associativity(takeLowerBits(eax, 4));

  
    // L2 TLB for 4KB pages
    L2_instructions_tlb.small_page_size = takeLowerBits(ebx, 12);
    L2_instructions_tlb.small_page_associativity = 
    L2Associativity(takeLowerBits(ebx, 4));


    L2_data_tlb.small_page_size = takeLowerBits(ebx, 12);
    L2_data_tlb.small_page_associativity = 
    L2Associativity(takeLowerBits(ebx, 4));


    // L2 Cache
    L2.line_size = takeLowerBits(ecx, 8);
    L2.lines_per_tag = takeLowerBits(ecx, 4);
    L2.associativity = L2Associativity(takeLowerBits(ecx, 4));
    L2.size = takeLowerBits(ecx, 16);


    cpuid(0x80000007, eax, ebx, ecx, edx);

    tsc_invariant            = hasFeature(edx, 8);
    software_thermal_control = hasFeature(edx, 5);
    hardware_thermal_control = hasFeature(edx, 4);
    thermtrip                = hasFeature(edx, 3);
    voltage_id               = hasFeature(edx, 2);
    frequency_id             = hasFeature(edx, 1);
    temperature_sensor       = hasFeature(edx, 0);

    cpuid(0x80000008, eax, ebx, ecx, edx);
    physical_address_bits    = takeLowerBits(eax, 8);
    virtual_address_bits     = takeLowerBits(eax, 8);


    core_count               = takeLowerBits(ecx, 8) + 1;

    ecx >>= 4;

    unsigned int num_bits = takeLowerBits(ecx, 8);

    if(num_bits != 0) {
        max_core_count = 1 << num_bits;
    }
    else {
        max_core_count = core_count;
    }

    // TODO: SVM revision
    // TODO: Look at intel docs
    // TODO: make sure we're not past maxFunc
}



