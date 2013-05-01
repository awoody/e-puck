#include "init_port.h"

int main(void)
{
	long i;
	int led=0;

	InitPort();

	while(1)
		{
		LED0 = led = led^1;
		for(i=0;i<300000;i++)
			asm("nop");
		}

}
