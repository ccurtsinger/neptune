// -*- c-basic-offset:4 -*-

#include <stdint.h>

class TLB
{
private:
    friend class CPUInfo;

    unsigned int small_page_size;
    unsigned int large_page_size;
    uint8_t small_page_associativity;
    uint8_t large_page_associativity;

public:

    enum PageSize {
        FOUR_KB,
        TWO_MB,
        FOUR_MB
    };

    inline unsigned int getNumEntries(PageSize page_size) const
    {
        switch(page_size) {

        case FOUR_KB:
            return small_page_size;

	case TWO_MB:
	    return large_page_size;

	case FOUR_MB:
	    return (large_page_size / 2);
        }
    }

    inline uint8_t getAssociativity(PageSize page_size) const
    {
        switch(page_size) {

	case FOUR_KB:
	    return small_page_associativity;

	case TWO_MB:
	case FOUR_MB:
	    return large_page_associativity;
        }
    }

    inline bool isDisabled(PageSize page_size) const
    {
        return getAssociativity(page_size) == 0;
    }

    inline bool isDirectMapped(PageSize page_size) const
    {
        return getAssociativity(page_size) == 1;
    }

    inline bool isFullyAssociative(PageSize page_size) const
    {
        return getAssociativity(page_size) == 0xFF;
    }
};

class Cache
{
private:
    friend class CPUInfo;

    unsigned int size;
    unsigned int lines_per_tag;
    unsigned int line_size;
    uint8_t associativity;

public:
    inline unsigned int getSize() const
    {
        return size;
    }

    inline unsigned int getLinesPerTag() const
    {
        return lines_per_tag;
    }

    inline unsigned int getLineSize() const
    {
        return line_size;
    }

    inline uint8_t getAssociativity() const
    {
        return associativity;
    }

    inline bool isDisabled() const
    {
        return associativity == 0;
    }

    inline bool isDirectMapped() const
    {
        return associativity == 1;
    }

    inline bool isFullyAssociative() const
    {
        return associativity == 0xFF;
    }
};

class CPUInfo
{
private:
    char manufacturer_string[13];
    char processor_name[48];

    // Processor revision number
    unsigned int stepping, family, model;

    unsigned int virtual_address_bits;
    unsigned int physical_address_bits;

    unsigned int core_count;
    unsigned int max_core_count;


    // (threads per CPU core) * (CPU cores per processor)
    unsigned int logical_processor_count;


    // An 8-bit Brand ID
    unsigned int brand_id;

    // Media/Floating-point features
    bool fpu;
    bool mmx;
    bool mmx_ext;
    bool threed_now;
    bool threed_now_ext;
    bool sse;
    bool sse2;
    bool sse3;
    bool fxsr;
    bool ffxsr;

    // Special instructions
    bool clflush;
    unsigned int clflush_size; // Size, in qwords, flushed by CLFLUSH
    bool cmov;
    bool cmpxchg8b;
    bool cmpxchg16b;
    bool lahf_sahf;
    bool rdtsp;
    bool sys_call_sys_ret;
    bool sys_enter_sys_exit;

    // Paging features
    bool nx_bit;
    bool page_global_extension;
    bool page_size_extensions;
    bool page_size_extensions36;
    bool page_attribute_table;
    bool physical_address_extension;

    // APIC
    bool apic;
    unsigned int local_apic_id;  // Initial local APIC id

    // Power Managment info
    bool tsc_invariant;
    bool software_thermal_control;
    bool hardware_thermal_control;
    bool thermtrip;
    bool voltage_id;
    bool frequency_id;
    bool temperature_sensor;


    bool hyper_threading;

    bool machine_check_architecture;
    bool memory_type_range_registers;
    bool machine_check_exception;
    bool model_specific_registers;
    bool time_stamp_counter;
    bool debugging_extensions;
    bool virtual_mode_enhancements;
    bool alt_mov_cr8;
    bool secure_virtual_machine;
    bool cmp_legacy;
    bool long_mode;


    bool L2_tlb_unified;

public:
    // Cache info
    Cache L1_instructions;
    Cache L1_data;
    TLB   L1_instructions_tlb;
    TLB   L1_data_tlb;

    TLB   L2_instructions_tlb;
    TLB   L2_data_tlb;
    Cache L2;

    CPUInfo();

    inline const char *getManufacturerString() const
    {
        return manufacturer_string;
    }

    inline const char *getProcessorName() const
    {
        return processor_name;
    }

    inline unsigned int getStepping() const
    {
        return stepping;
    }

    inline unsigned int getFamily() const
    {
        return family;
    }

    inline unsigned int getModel() const
    {
        return model;
    }

    inline unsigned int getVirtualAddressBits() const
    {
        return virtual_address_bits;
    }

    inline unsigned int getPhysicalAddressBits() const
    {
        return physical_address_bits;
    }

    inline unsigned int getLocalAPICID() const
    {
        return local_apic_id;
    }

    inline unsigned int getLogicalProcessorCount() const
    {
        return logical_processor_count;
    }

    inline unsigned int getCLFLUSHSize() const
    {
        return clflush_size;
    }

    inline unsigned int getBrandID() const
    {
        return brand_id;
    }


    inline bool hasFPU() const
    {
      return fpu;
    }

    inline bool hasMMX() const
    {
      return mmx;

    }

    inline bool hasMMXExt() const
    {
      return mmx_ext;
    }

    inline bool has3DNow() const
    {
      return threed_now;
    }

    inline bool has3DNowExt() const
    {
      return threed_now_ext;
    }

    inline bool hasSSE() const
    {
      return sse;
    }

    inline bool hasSSE2() const
    {
      return sse2;
    }

    inline bool hasSSE3() const
    {
      return sse3;
    }

    /**
     * \brief Whether the processor has the FXSAVE and FXRSTOR instructions
     *
     * These are the instructions which allow on to save the floating point
     * registers, and the state of the floating point unit, to main memory.
     */
    inline bool hasFXSR() const
    {
      return fxsr;
    }

    /**
     * \todo Figure out what this is
     */
    inline bool hasFFXSR() const
    {
      return ffxsr;
    }

    inline bool hasCLFLUSH() const
    {
        return clflush;
    }

    /**
     * \brief The number of qwords flushed by the CLFLUSH instruction
     */
    inline unsigned int clflushSize() const
    {
        return clflush_size;
    }

    inline bool hasCMOV() const
    {
        return cmov;
    }

    inline bool hasCMPXCHG8B() const
    {
        return cmpxchg8b;
    }

    inline bool hasCMPXCHG16B() const
    {
        return cmpxchg16b;
    }

    /**
     * \brief Whether the LAHF and SAHF instruction are supported in 64bit mode
     */
    inline bool hasLAHF_SAHF() const
    {
        return lahf_sahf;
    }

    inline bool hasRDTSP() const
    {
        return rdtsp;
    }

    /**
     * \brief Whether SYSCALL and SYSRET instructions are available
     */
    inline bool hasSysCallSysRet() const
    {
        return sys_call_sys_ret;
    }

    /**
     * \brief Whether SYSENTER and SYSEXIT instructions are available
     */
    inline bool hasSysEnterSysExit() const
    {
        return sys_enter_sys_exit;
    }


    /**
     * \brief Whether the No-Execute Bit is supported
     */
    inline bool supportsNXBit() const
    {
        return nx_bit;
    }

    inline bool hasPageGlobalExtensions() const
    {
        return page_global_extension;
    }

    inline bool hasPageSizeExtensions() const
    {
        return page_size_extensions;
    }

    inline bool hasPageSizeExtensions36() const
    {
        return page_size_extensions36;
    }

    inline bool hasPageAttributeTable() const
    {
        return page_attribute_table;
    }

    inline bool hasPhysicalAddressExtensions() const
    {
        return physical_address_extension;
    }

    inline bool hasAPIC() const
    {
        return apic;
    }

    inline unsigned int localAPICID() const
    {
        return local_apic_id;
    }


    inline bool TSCInvariant() const
    {
        return tsc_invariant;
    }

    inline bool hasSoftwareThermalControl() const
    {
        return software_thermal_control;
    }

    inline bool hasHardwareThermalControl() const
    {
        return hardware_thermal_control;
    }

    inline bool hasTHERMTRIP() const
    {
        return thermtrip;
    }

    inline bool hasVoltageIDControl() const
    {
        return voltage_id;
    }

    inline bool hasFrequencyIDControl() const
    {
        return frequency_id;
    }

    inline bool hasTemperatureSensor() const
    {
        return temperature_sensor;
    }

    inline bool hasHyperThreading() const
    {
        return hyper_threading;
    }

    inline bool hasMachineCheckArchitecture() const
    {
        return machine_check_architecture;
    }

    inline bool hasMemoryTypeRangeRegisters() const
    {
        return memory_type_range_registers;
    }

    inline bool hasModelSpecificRegisters() const
    {
        return model_specific_registers;
    }

    inline bool hasTimeStampCounter() const
    {
        return time_stamp_counter;
    }

    inline bool hasDebuggingExtensions() const
    {
        return debugging_extensions;
    }

    inline bool hasVirtualModeEnhancements() const
    {
        return virtual_mode_enhancements;
    }

    inline bool altMoveCR8() const
    {
        return alt_mov_cr8;
    }

    inline bool hasSecureVirtualMachine() const
    {
        return secure_virtual_machine;
    }

    inline bool cmpLegacy() const
    {
        return cmp_legacy;
    }

    inline bool hasLongMode() const
    {
        return long_mode;
    }
};
