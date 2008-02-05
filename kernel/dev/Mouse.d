/**
 * Simple Mouse driver
 */

module kernel.dev.Mouse;

//import neptune.arch.idt;
import kernel.arch.IDT;
import kernel.event.Interrupt;

import std.port;

/**
 * Mouse device abstraction
 */
class Mouse
{
    private byte cycle = 0;
    private byte[3] data;
    private int x = 0;
    private int y = 0;
    
    bool[5] buttons;
    
    /**
     * Initialize the mouse device
     */
    public this()
    {
        buttons[0] = false;
        buttons[1] = false;
        buttons[2] = false;
        buttons[3] = false;
        buttons[4] = false;
        
        byte status;
        
        // Enable the auxiliary mouse device
        wait(1);
        outp(0x64, 0xA8);
        
        // Enable interrupts
        wait(1);
        outp(0x64, 0x20);
        wait(0);
        status = inp(0x60) | 2;
        wait(1);
        outp(0x64, 0x60);
        wait(1);
        outp(0x60, status);
        
        // Use default settings
        write(0xF6);
        read();
        
        // Enable the mouse
        write(0xF4);
        read();
    }
    
    /**
     * Wait for a response from the mouse
     */
    private void wait(int type)
    {
        int timeout = 100000;
        
        if(type == 0)
        {
            while(timeout--)
            {
                if((inp(0x64) & 1) == 1)
                    return;
            }
            
            return;
        }
        else
        {
            while(timeout--)
            {
                if((inp(0x64) & 2) == 0)
                    return;
            }
            
            return;
        }
    }
    
    /**
     * Write to the mouse port
     */
    private void write(int b)
    {
        wait(1);
        outp(0x64, 0xD4);
        wait(1);
        outp(0x60, cast(byte)b);
    }
    
    /**
     * Read from the mouse port
     */
    private byte read()
    {
        wait(0);
        return inp(0x60);
    }
    
    /**
     * Interrupt handler for the mouse IRQ
     */
    public void handler(ulong interrupt, InterruptStack* context)
    {
        if(inp(0x64) & 0x21 == 0x21)
        {
            data[cycle] = inp(0x60);
            cycle++;
            
            if(cycle == 3)
            {
                cycle = 0;
                
                x += data[1];
                y += data[2];
            
                for(int i=0; i<3; i++)
                {
                    buttons[i] = (data[0] & (1<<i)) == (1<<i);
                }
            
                System.output.writef("mouse packet: %02#x (%i, %i, %s, %s, %s)", data[0], x, y, buttons[0] ? "down" : "up", buttons[1] ? "down" : "up", buttons[2] ? "down" : "up").newline;
            }
        }
            
        outp(PIC1, PIC_EOI);
        outp(PIC2, PIC_EOI);
    }
}
