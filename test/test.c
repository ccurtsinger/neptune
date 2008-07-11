
typedef struct Test
{
    int a;
    int b;
    int c;
} Test;

void test(char* str, Test t)
{
    asm("int $128");
}

void _start()
{
    Test t;
    
    t.a = 1;
    t.b = 2;
    t.c = 3;
    
    while(1<2)
    {
        t.a++;
        test("Hello World!\n", t);
    }
}
