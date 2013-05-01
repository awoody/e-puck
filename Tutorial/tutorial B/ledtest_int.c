#include "epuck_ports.h"

// special attributes for an interrupt  routine: 
#define _ISRFAST   __attribute__((interrupt, shadow))  

// interrupt routine and initialization for timer 5

void InitTMR5(void)
{
  T5CON = 0;                    // 
  T5CONbits.TCKPS=3;            // prescsaler = 256
  TMR5 = 0;                     // clear timer 5
  PR5 = (500.0*MILLISEC)/256.0; // interrupt every 500ms with 256 prescaler
  IFS1bits.T5IF = 0;            // clear interrupt flag
  IEC1bits.T5IE = 1;            // set interrupt enable bit
  T5CONbits.TON = 1;            // start Timer5
 
}
 
void _ISRFAST _T5Interrupt(void)
{
  IFS1bits.T5IF = 0;            // clear interrupt flag
  LED0 = !LED0;                 // then blink LED1
}

// main loop:

int main()
{
  InitPort();                  // init ports of e-Puck
  InitTMR5() ;                  // start timer 5 and its interrupt

  for (;;) ;                    // infinite loop that will be interrupted
}
