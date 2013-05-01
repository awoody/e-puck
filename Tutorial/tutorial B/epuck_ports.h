/****************************************************************
* 			Defintition of all port of e-puck			 		*
*			Version 1.0 november 2005							*
*			Michael Bonani, Francesco Mondada, Davis Dadie		*
*																*
****************************************************************/
#ifndef _EPUCK_PORTS
#define _EPUCK_PORTS
#include "p30f6014.h"
/*********************GENERAL SETUP************************/

#define FOSC   7.3728e6     // 7.3728Mhz crystal in XTL mode 
#define PLL    8.0       	// 8x PLL
 
#define FCY     ((FOSC*PLL)/(4.0))	// Instruction cycle frequency 
#define MILLISEC  (FCY/1.0e3)		// 1mSec delay constant
#define MICROSEC  (FCY/1.0e6)		// 1uSec delay constant
#define NANOSEC   (FCY/1.0e9)		// 1nSec delay constant
#define	TCY_PIC		(1e9/FCY)		//time instruction cycle in [ns]
#define	INTERRUPT_DELAY	(10*TCY_PIC)//delay to start an interrupt in [ns] (observe with p30f6014) 
#define TRUE	1
#define FALSE	0
/********************** OUTPUTS ***************************/
#define OUTPUT_PIN 0 
/*LEDS*/
/*First in front of robot than turning clokwise*/
#define LED0 _LATA6
#define LED1 _LATA7
#define LED2 _LATA9
#define LED3 _LATA12
#define LED4 _LATA10
#define LED5 _LATA13
#define LED6 _LATA14
#define LED7 _LATA15
#define LED0_dir _TRISA6
#define LED1_dir _TRISA7
#define LED2_dir _TRISA9
#define LED3_dir _TRISA12
#define LED4_dir _TRISA10
#define LED5_dir _TRISA13
#define LED6_dir _TRISA14
#define LED7_dir _TRISA15
#define front_LED _LATC1
#define front_LED_dir _TRISC1
#define body_LED _LATC2
#define body_LED_dir _TRISC2
/*IR*/
#define pulse_IR0 _LATF7		// pulse IR 0 and 4
#define pulse_IR1 _LATF8		// pulse IR 1 and 5
#define pulse_IR2 _LATG0		// pulse IR 2 and 6
#define pulse_IR3 _LATG1		// pulse IR 3 and 7
#define pulse_IR0_dir _TRISF7
#define pulse_IR1_dir _TRISF8
#define pulse_IR2_dir _TRISG0
#define pulse_IR3_dir _TRISG1
/*First in front left of robot than turning clokwise*/
#define IR0 8  // ir proximity sensor 0 on AD channel 8
#define IR1 9  // ir proximity sensor 1 on AD channel 9
#define IR2 10  // ir proximity sensor 2 on AD channel 10
#define IR3 11  // ir proximity sensor 3 on AD channel 11
#define IR4 12  // ir proximity sensor 4 on AD channel 12
#define IR5 13  // ir proximity sensor 5 on AD channel 13
#define IR6 14  // ir proximity sensor 6 on AD channel 14
#define IR7 15  // ir proximity sensor 7 on AD channel 15
/*analog*/
#define MIC1 2  // microphone 1 on AD channel 2
#define MIC2 3  // microphone 2 on AD channel 3
#define MIC3 4  // microphone 3 on AD channel 4
#define ACCX 5  // X Axis of accelerometer on AD channel 5
#define ACCY 6  // Y Axis of accelerometer on AD channel 6
#define ACCZ 7  // Z Axis of accelerometer on AD channel 7
/*basic audio*/
#define audio_on _LATF0
#define audio_on_dir _TRISF0
/*motors*/
#define motor1_pha _LATD0
#define motor1_phb _LATD1
#define motor1_phc _LATD2
#define motor1_phd _LATD3
#define motor2_pha _LATD4
#define motor2_phb _LATD5
#define motor2_phc _LATD6
#define motor2_phd _LATD7
#define motor1_pha_dir _TRISD0
#define motor1_phb_dir _TRISD1
#define motor1_phc_dir _TRISD2
#define motor1_phd_dir _TRISD3
#define motor2_pha_dir _TRISD4#define motor2_phb_dir _TRISD5#define motor2_phc_dir _TRISD6#define motor2_phd_dir _TRISD7/*camera*/#define CAM_reset _LATC13#define CAM_reset_dir _TRISC13/* I2C */#define SIO_D	_LATG3#define SIO_D_dir	_TRISG3#define SIO_C	_LATG2#define SIO_C_dir	_TRISG2/********************** INPUTS **************************/#define INPUT_PIN 1/*low battery signal active low when Vbatt<3.4V*/#define batt_low _RF1#define batt_low_dir _TRISF1/* selector on normal extension*/#define selector0 _RG6#define selector1 _RG7#define selector2 _RG8#define selector3 _RG9#define selector0_dir _TRISG6#define selector1_dir _TRISG7#define selector2_dir _TRISG8#define selector3_dir _TRISG9/*IR TV receiver on normal extension*/#define remote _RF6#define remote_dir _TRISF6/*CAMERA*//*data higher 8 bits of port D*/#define CAM_data PORTD;#define CAM_y0 _RD8#define CAM_y1 _RD9#define CAM_y2 _RD10#define CAM_y3 _RD11#define CAM_y4 _RD12#define CAM_y5 _RD13#define CAM_y6 _RD14#define CAM_y7 _RD15#define CAM_y0_dir _TRISD8#define CAM_y1_dir _TRISD9#define CAM_y2_dir _TRISD10#define CAM_y3_dir _TRISD11#define CAM_y4_dir _TRISD12#define CAM_y5_dir _TRISD13#define CAM_y6_dir _TRISD14#define CAM_y7_dir _TRISD15/*clock interupt*/#define CAM_pwdn _RC2#define CAM_vsync _RC4#define CAM_href _RC3#define CAM_pclk _RC14#define CAM_pwdn_dir _TRISC2#define CAM_vsync_dir _TRISC4#define CAM_href_dir _TRISC3#define CAM_pclk_dir _TRISC14/*********************** ASEMBLER SMALL FUNCTCION********************** */#define Nop() {__asm__ volatile ("nop");}#define ClrWdt() {__asm__ volatile ("clrwdt");}#define Sleep() {__asm__ volatile ("pwrsav #0");}#define Idle() {__asm__ volatile ("pwrsav #1");}#define InterruptOFF() {__asm__ volatile ("disi	#10000");}#define InterruptON() {__asm__ volatile ("disi	#2");}#endif