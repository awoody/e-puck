#ifndef _PROX
#define _PROX


/* functions */

void InitProx(void);   // to be called before starting using prox
int GetProx(unsigned int sensor_number); // to get a prox value
int GetAmbientLight(unsigned int sensor_number); // to get ambient light value

#endif
