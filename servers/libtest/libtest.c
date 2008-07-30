
extern const unsigned long long int val[4];

extern unsigned long long int get_value();
extern unsigned long long int get_value2();

void _start(unsigned long long int sa, void (*syscall)(unsigned long long int))
{
    syscall(val[3]);
    
    syscall(get_value());
    syscall(get_value2());
    
    syscall(get_value());
    syscall(get_value2());
    
    syscall(get_value());
    syscall(get_value2());
    
    for(;;){}
}
