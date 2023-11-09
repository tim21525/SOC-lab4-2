#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	//initfir();
	//write down your fir
   int data_len = 64;
   for(int i=1;i<=data_len;i++){
      if(reg_xn == 1)
         reg_fir_x = i; // rand() % 10;
      if(reg_yn == 1) {
         if(i==data_len){
            outputsignal = (reg_fir_y<<24)|0x005A0000;
         }
         else{
            outputsignal = reg_fir_y;
         }  
      } 
   }
   
	return &outputsignal;
}
		
