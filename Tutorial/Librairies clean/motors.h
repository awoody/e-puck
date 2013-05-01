#ifndef _MOTORS
#define _MOTORS

/* functions */

void InitMotors(void); // init to be done before using the other calls

void SetSpeedLeft(int motor_speed); 	// motor speed in steps/s
void SetSpeedRight(int motor_speed);  	// motor speed in steps/s
int GetStepsLeft(void);					// motors steps done left
int GetStepsRight(void);				// motors steps done right
void SetStepsLeft(int set_steps);		// set motor steps counter
void SetStepsRight(int set_steps);		// set motor steps counter
#endif
