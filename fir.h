#ifndef __FIR_H__
#define __FIR_H__

#include <stdint.h>
#include <stdbool.h>

#define reg_fir_x 	 (*(volatile uint32_t*)0x30000080)
#define reg_fir_y 	 (*(volatile uint32_t*)0x30000084)
#define reg_xn          (*(volatile uint32_t*)0x30000030)
#define reg_yn          (*(volatile uint32_t*)0x30000034)

//int inputbuffer[N];
//int inputsignal[N] = {1,2,3,4,5,6,7,8,9,10,11};
int outputsignal;

#endif
