#ifndef _ACCELEROMETER
#define _ACCELEROMETER


/* functions */

void InitAcc(void);   // to be called before starting using accelerometer
void GetAcc(int *x, int *y,int *z); // to get analog value of accelerometer
#endif
