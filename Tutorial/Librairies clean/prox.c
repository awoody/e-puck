/****************************************************************
* 			Control proximity sensor of e-puck	with timer 1	*	 		*
*			December 2004: first version                        *
*			Lucas Meier & Francesco Mondada  					*
*			Version 1.0 november 2005							*
*			Michael Bonani										*
*																*
****************************************************************/


#include "ad_conv.h"
#include "epuck_ports.h"
#include "prox.h"

/* internal variables for prox */
int ambient_ir[8];				 // ambient light measurement
int ambient_and_reflected_ir[8]; // light when led is on
int reflected_ir[8];			 // variation of light


/* internal calls for prox */
void InitTMR1(void)
{
  T1CON = 0;                    // 
  T1CONbits.TCKPS = 1;          // prescsaler = 8
  TMR1 = 0;                     // clear timer 1
  PR1 = (350.0*MICROSEC)/8.0;   // first interrupt after 350us with 8 prescaler
  IFS0bits.T1IF = 0;            // clear interrupt flag
  IEC0bits.T1IE = 1;            // set interrupt enable bit
  T1CONbits.TON = 1;            // start Timer1
}

void _ISRFAST _T1Interrupt(void)
{

// read ambient light and switch on leds in a first phase
// wait 350 us to let the phototransistor react
// read reflected light and switch off the leds in a second phase
// wait 3 ms before stating again
// repeat these two steps for the four couples of prox sensors

  static int ir_phase=0;	// phase can be 0 (ambient) or 1 (reflected)	
  static int ir_number=0;	// number goes from 0 to 3 (4 couples of sensors)	

  IFS0bits.T1IF = 0;            // clear interrupt flag

  switch (ir_number)
  {
    case 0:		// ir sensors 0 and 4
    {
      if (ir_phase == 0)
      {
        PR1 = (350.0*MICROSEC)/8.0;		// next interrupt in 350 us
		ambient_ir[0] = ReadAd(IR0);
        ambient_ir[4] = ReadAd(IR4);
        pulse_IR0 = 1;			// led on for next measurement
        ir_phase = 1;			// next phase
      }
      else
      {
        PR1 = (2100.0*MICROSEC)/8.0;		// next interrupt in 3 ms
        ambient_and_reflected_ir[0] = ReadAd(IR0);
        ambient_and_reflected_ir[4] = ReadAd(IR4);
		reflected_ir[0] = ambient_ir[0] - ambient_and_reflected_ir[0];
		reflected_ir[4] = ambient_ir[4] - ambient_and_reflected_ir[4];
        pulse_IR0 = 0;			// led off
        ir_phase = 0;			// reset phase
        ir_number = 1;			// next two sensors
      }
      break;
    }
    case 1:		// ir sensors 1 and 5
    {
      if (ir_phase == 0)
      {
        PR1 = (350.0*MICROSEC)/8.0;		// next interrupt in 350 us
        ambient_ir[1] = ReadAd(IR1);
        ambient_ir[5] = ReadAd(IR5);
        pulse_IR1 = 1;			// led on for next measurement
        ir_phase = 1;			// next phase
      }
      else
      {
        PR1 = (2100.0*MICROSEC)/8.0;		// next interrupt in 3 ms
        ambient_and_reflected_ir[1] = ReadAd(IR1);
        ambient_and_reflected_ir[5] = ReadAd(IR5);
		reflected_ir[1] = ambient_ir[1] - ambient_and_reflected_ir[1];
		reflected_ir[5] = ambient_ir[5] - ambient_and_reflected_ir[5];
        pulse_IR1 = 0;			// led off
        ir_phase = 0;			// reset phase
        ir_number = 2;			// next two sensors
      }
      break;
    }
    case 2:		// ir sensors 2 and 6
    {
      if (ir_phase == 0)
      {
        PR1 = (350.0*MICROSEC)/8.0;		// next interrupt in 350 us
        ambient_ir[2] = ReadAd(IR2);
        ambient_ir[6] = ReadAd(IR6);
        pulse_IR2 = 1;			// led on for next measurement
        ir_phase = 1;			// next phase
      }
      else
      {
        PR1 = (2100.0*MICROSEC)/8.0;		// next interrupt in 3 ms
        ambient_and_reflected_ir[2] = ReadAd(IR2);
        ambient_and_reflected_ir[6] = ReadAd(IR6);
		reflected_ir[2] = ambient_ir[2] - ambient_and_reflected_ir[2];
		reflected_ir[6] = ambient_ir[6] - ambient_and_reflected_ir[6];
        pulse_IR2 = 0;			// led off
        ir_phase = 0;			// reset phase
        ir_number = 3;			// next sensor
      }
      break;
    }
    case 3:		// ir sensors 3 and 7
    {
      if (ir_phase == 0)
      {
        PR1 = (350.0*MICROSEC)/8.0;		// next interrupt in 350 us
        ambient_ir[3] = ReadAd(IR3);
        ambient_ir[7] = ReadAd(IR7);
        pulse_IR3 = 1;			// led on for next measurement
        ir_phase = 1;			// next phase
      }
      else
      {
        PR1 = (2100.0*MICROSEC)/8.0;		// next interrupt in 3 ms
        ambient_and_reflected_ir[3] = ReadAd(IR3);
        ambient_and_reflected_ir[7] = ReadAd(IR7);
		reflected_ir[3] = ambient_ir[3] - ambient_and_reflected_ir[3];
		reflected_ir[7] = ambient_ir[7] - ambient_and_reflected_ir[7];
        pulse_IR3 = 0;			// led off
        ir_phase = 0;			// reset phase
        ir_number = 0;			// next sensor (back to beginning)
      }
      break;
    }
  }
  
}

/* ---- user calls ---- */

int GetProx(unsigned int sensor_number)
	{
	if (sensor_number > 7)
		return 0;
	else
		return reflected_ir[sensor_number];
	}

int GetAmbientLight(unsigned int sensor_number)
	{
	if (sensor_number > 7)
		return 0;
	else
		return ambient_ir[sensor_number];
	}

void InitProx(void)
	{
	InitAd();				// init AD converter module
	InitTMR1();				// init timer 1 for ir processing
	}

