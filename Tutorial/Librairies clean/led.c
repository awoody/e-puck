/****************************************************************
* 			fonctions for simple LED manipulation      		 	*	*
*			december 2004: first example for microinfo  		*
*			Version 1.0 november 2005							*
*			Michael Bonani, Francesco Mondada					*
*																*
****************************************************************/ 
 
#include "epuck_ports.h"
#include "led.h"

void SetLed(unsigned int led_number, unsigned int value)
// led_number between 0 and 7, value 0 (off) or 1 (on)
// if led_number other than 0-7, all leds are set to value
{
	switch(led_number)
	{
		case 0: 
			{
			if(value>1)
				LED0 = LED0^1; // "^" exclusif OR bit to bit
			else
				LED0 = value;
			break;
			}
		case 1: 
			{
			if(value>1)
				LED1 = LED1^1;
			else
				LED1 = value;
			break;
			}
		case 2: 
			{
			if(value>1)
				LED2 = LED2^1;
			else
				LED2 = value;
			break;
			}
		case 3: 
			{
			if(value>1)
				LED3 = LED3^1;
			else
				LED3 = value;
			break;
			}
		case 4: 
			{
			if(value>1)
				LED4 = LED4^1;
			else
				LED4 = value;
			break;
			}
		case 5: 
			{
			if(value>1)
				LED5 = LED5^1;
			else
				LED5 = value;
			break;
			}
		case 6: 
			{
			if(value>1)
				LED6 = LED6^1;
			else
				LED6 = value;
			break;
			}
		case 7: 
			{
			if(value>1)
				LED7 = LED7^1;
			else
				LED7 = value;
			break;
			}
		default: 
			LED0 = LED1 = LED2 = LED3 = LED4 = LED5 = LED6 = LED7 = value;
	}
}


void SetBodyLed(unsigned int value)
{
	if(value>1)
		body_LED = body_LED^1;
	else
		body_LED = value;
}

void SetFrontLed(unsigned int value)
{
	if(value>1)
		front_LED = front_LED^1;
	else
	front_LED = value;
}

void LedClear(void)
{
	LED0 = 0;
	LED1 = 0;
	LED2 = 0;
	LED3 = 0;
	LED4 = 0;
	LED5 = 0;
	LED6 = 0;
	LED7 = 0;
}
