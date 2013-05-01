#ifndef _UART_TXRX_CHAR
#define _UART_TXRX_CHAR

/* functions */
void InitUart1(void); 			//init uart 1 at 11500bps, 8 data bits, 1 stop bit, Enable ISR for RX and TX
int  GetcharUart1(char *); 		//read 1 char and put in pointer, return 1 if char avaible, 0 if not.  
void SendUart1Char(char*buff, int lenght); //send char buffer lengh

void InitUart2(void); 			//init uart 2 at 11500bps, 8 data bits, 1 stop bit, Enable ISR for RX and TX
int  GetcharUart2(char *); 		//read 1 char and put in pointer, return 1 if char avaible, 0 if not.  
void SendUart2Char(char *buff, int lenght); //send char buffer lengh 

#endif
/*
exemple of use:
-------------------------------------------------------------
	sprintf(buffer, "\n\rHello word!");
	SendUart2Char(buffer,strlen(buffer));  //send string
-------------------------------------------------------------
	send[0]=0x02; 
	send[1]=0x52;
	send[2]=0x16;
	send[3]=0x00;
	send[4]=0x00;
	send[5]=0x68;
	send[6]=0x03;
	SendUart1Char(send,7);
-------------------------------------------------------------	
	do
    {
      if (GetcharUart2(&command[i]))
		{	
			c=command[i];
     		i++;
		}	
    }
    while (((char)c != '\n')&&((char)c != '\x0d'));
-------------------------------------------------------------	
*/
