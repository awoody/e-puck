/****************************************************************
* 			Control motor of e-puck	with timer 4 and 5	 		*
*			December 2004: first version                        *
*			Lucas Meier & Francesco Mondada  					*
*			Version 1.0 november 2005							*
*			Michael Bonani										*
*																*
****************************************************************/

#include <stdlib.h>
#include "epuck_ports.h"
#include "init_port.h"


/* internal variables */

int left_speed = 0;
int right_speed = 0;
int	nbr_pas_left = 0;
int nbr_pas_right = 0;

/* internal calls */
 
void _ISRFAST _T5Interrupt(void) // interrupt for motor 1 (of two) = left motor
{
  static int motor_phase=0;		 // phase can be 0 to 3

  IFS1bits.T5IF = 0;             // clear interrupt flag

  // increment or decrement phase depending on direction

  if (left_speed > 0) // inverted for the two motors
    {
    nbr_pas_left++;
	motor_phase--;
    if (motor_phase < 0) motor_phase = 3;
    }
  else 
    {
    nbr_pas_left--;
    motor_phase++;
    if (motor_phase > 3) motor_phase = 0;
    }
  
  // set the phase on the port pins

  switch (motor_phase)
  {
    case 0:
    {
      motor1_pha = 0;
      motor1_phb = 1;
      motor1_phc = 0;
      motor1_phd = 1;
      break;
    }
    case 1:
    {
      motor1_pha = 0;
      motor1_phb = 1;
      motor1_phc = 1;
      motor1_phd = 0;
      break;
    }
    case 2:
    {
      motor1_pha = 1;
      motor1_phb = 0;
      motor1_phc = 1;
      motor1_phd = 0;
      break;
    }
    case 3:
    {
      motor1_pha = 1;
      motor1_phb = 0;
      motor1_phc = 0;
      motor1_phd = 1;
      break;
    }
  }
}

void _ISRFAST _T4Interrupt(void)  // interrupt for motor 2 (of two) = right motor
{
  static int motor_phase=0;	// phase can be 0 to 3

  IFS1bits.T4IF = 0;             // clear interrupt flag

  // increment or decrement phase depending on direction

  if (right_speed < 0)
    {
    nbr_pas_right--;
    motor_phase--;
    if (motor_phase < 0) motor_phase = 3;
    }
  else 
    {
    nbr_pas_right++;
    motor_phase++;
    if (motor_phase > 3) motor_phase = 0;
    }
  
  // set the phase on the port pins

  switch (motor_phase)
  {
    case 0:
    {
      motor2_pha = 0;
      motor2_phb = 1;
      motor2_phc = 0;
      motor2_phd = 1;
      break;
    }
    case 1:
    {
      motor2_pha = 0;
      motor2_phb = 1;
      motor2_phc = 1;
      motor2_phd = 0;
      break;
    }
    case 2:
    {
      motor2_pha = 1;
      motor2_phb = 0;
      motor2_phc = 1;
      motor2_phd = 0;
      break;
    }
    case 3:
    {
      motor2_pha = 1;
      motor2_phb = 0;
      motor2_phc = 0;
      motor2_phd = 1;
      break;
    }
  }
}

/* ---- user calls ---- */

int GetStepsLeft(void)
{
  return nbr_pas_left;
}

void SetStepsLeft(int set_steps)
{
  InterruptOFF();
  nbr_pas_left = set_steps;
  InterruptON();
}

int GetStepsRight(void)
{
  return nbr_pas_right;
}

void SetStepsRight(int set_steps)
{
  InterruptOFF();
  nbr_pas_right = set_steps;
  InterruptON();
}

void SetSpeedLeft(int motor_speed)  // motor speed in steps/s
{
  if (motor_speed == 0)
  {
    T5CONbits.TON = 0;            // stop Timer5
    motor1_pha = 0;
    motor1_phb = 0;
    motor1_phc = 0;
    motor1_phd = 0;
  }
  else
  {
    T5CONbits.TON = 0;            // stop Timer5

    left_speed = motor_speed;

    T5CON = 0;                    // 
    T5CONbits.TCKPS=3;            // prescsaler = 256
    TMR5 = 0;                     // clear timer 5
    PR5 = (FCY/256)/abs(motor_speed);  // interrupt every Xms with 256 prescaler
    IFS1bits.T5IF = 0;            // clear interrupt flag
    IEC1bits.T5IE = 1;            // set interrupt enable bit
    T5CONbits.TON = 1;            // start Timer5
  }
}


void SetSpeedRight(int motor_speed)  // motor speed in steps/s
{
  if (motor_speed == 0)
  {
    T4CONbits.TON = 0;   
 	motor2_pha = 0;
    motor2_phb = 0;
    motor2_phc = 0;
    motor2_phd = 0;         // stop Timer5
  }
  else
  {
    T4CONbits.TON = 0;            // stop Timer5

    right_speed = motor_speed;

    T4CON = 0;                    // 
    T4CONbits.TCKPS=3;            // prescsaler = 256
    TMR4 = 0;                     // clear timer 4
    PR4 = (FCY/256)/abs(motor_speed);  // interrupt every Xms with 256 prescaler
    IFS1bits.T4IF = 0;            // clear interrupt flag
    IEC1bits.T4IE = 1;            // set interrupt enable bit
    T4CONbits.TON = 1;            // start Timer4
  }
}


void InitMotors(void)
{
  InitPort();				// init general ports
}

