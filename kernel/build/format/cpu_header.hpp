// -*- c-basic-offset:4 -*-

#ifndef __SYSTEM_INFO_CPU_HPP__
#define __SYSTEM_INFO_CPU_HPP__

namespace system_info
{
    namespace cpu
    {
        const char *MANUFACTURER_STRING = "%s";
        const char *PROCESSOR_NAME = "%s";

        const unsigned int STEPPING = %d;
        const unsigned int FAMILY   = %d;
        const unsigned int MODEL    = %d;

        const unsigned int VIRTUAL_ADDRESS_BITS  = %d;
        const unsigned int PHYSICAL_ADDRESS_BITS = %d;

        const unsigned int LOGICAL_PROCESSORS = %d;

        const unsigned int CACHE_LINE_SIZE = %d;
    }
}

#endif // #ifndef __SYSTEM_INFO_CPU_HPP__
