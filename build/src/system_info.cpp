// -*- c-basic-offset:4 -*-

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <boost/format.hpp>
#include "cpuinfo.hpp"

std::string readFormatFile(const char *format_file);
void printCPUHeader(std::ostream &, const CPUInfo &);
void printCPUFeatures(std::ostream &, const CPUInfo &);

int main(int argc, char **argv)
{
    printCPUFeatures(std::cout, CPUInfo());

    return 0;
}


std::string readFormatFile(const char *format_file)
{
    std::stringstream format;
    std::fstream file;
    char c;

    file.open(format_file, std::ios::in);
    c = file.get();

    while(!file.eof()) {
        format.put(c);
        c = file.get();
    }


    file.close();

    return format.str();
}

void printCPUHeader(std::ostream &stream, const CPUInfo &cpu)
{
    boost::format format(readFormatFile("cpu_header.hpp"));

    stream<<format
        % cpu.getManufacturerString()
        % cpu.getProcessorName()
        % cpu.getStepping() 
        % cpu.getFamily()
        % cpu.getModel()
        % cpu.getVirtualAddressBits() 
        % cpu.getPhysicalAddressBits()
        % cpu.getLogicalProcessorCount()
        % cpu.L1_data.getLineSize();
}

void printCPUFeatures(std::ostream &stream, const CPUInfo &cpu)
{
    using namespace std;

    stream<<"#ifndef __SYSTEM_INFO_FEATURES_HPP__"<<endl;
    stream<<"#define __SYSTEM_INFO_FEATURES_HPP__"<<endl<<endl;

    stream<<"// Floating-point features"<<endl;
    if(cpu.hasFPU()) {
        stream<<"#define X87"<<endl;
    }
    if(cpu.hasMMX()) {
        stream<<"#define MMX"<<endl;
    }
    if(cpu.hasMMXExt()) {
        stream<<"#define MMXExt"<<endl;
    }
    if(cpu.has3DNow()) {
        stream<<"#define 3DNow"<<endl;
    }
    if(cpu.has3DNowExt()) {
        stream<<"#define 3DNowExt"<<endl;
    }
    if(cpu.hasSSE()) {
        stream<<"#define SSE"<<endl;
    }
    if(cpu.hasSSE2()) {
        stream<<"#define SSE2"<<endl;
    }
    if(cpu.hasSSE3()) {
        stream<<"#define SSE3"<<endl;
    }

    stream<<endl<<"#endif // #ifndef __SYSTEM_INFO_FEATURES_HPP__"<<endl;
}
