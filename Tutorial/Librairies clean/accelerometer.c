/****************************************************************
* 			Accelerometer sensor of e-puck						*
*			Version 1.0 november 2005							*
*			Michael Bonani										*
*																*
****************************************************************/

#include "ad_conv.h"
#include "epuck_ports.h"
#include "accelerometer.h"

void InitAcc(void)
{
	InitAd();	// init AD converter module
}


void GetAcc(int *x, int *y,int *z)
{
T1CONbits.TON = 0;//cut of proximity timer
*x=ReadAd(ACCX);
*y=ReadAd(ACCY);
*z=ReadAd(ACCZ);
T1CONbits.TON = 1;
}
				
