
void test(char* str, char* str2)
{
    asm("int $128");
}

void _start()
{
    while(1<2)
    {
        test("Hello World!\n", "Hello Again!\n");
    }
}
