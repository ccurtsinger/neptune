/**
 * A simple test server implementation
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */
 
int main()
{
    int value = 0;
    
	while(1 < 2)
	{
	    value++;
		__asm__("int $128" : : "a" (value));
	}
}

