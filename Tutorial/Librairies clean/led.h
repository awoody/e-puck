#ifndef _LED
#define _LED

/* functions */
void SetLed(unsigned int led_number, unsigned int value); // set led_number (0-7) to value (0=off 1=on higher=inverse) 
void LedClear(void);

void SetBodyLed(unsigned int value); // value (0=off 1=on higher=inverse) 
void SetFrontLed(unsigned int value); //value (0=off 1=on higher=inverse) 

#endif

