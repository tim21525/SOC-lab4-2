// bram behavior code (can't be synthesis)
// 11 words
module bram11 
(
    CLK,
    WE,
    EN,
    Di,
    Do,
    A
);

   parameter ADDR_WIDTH = 12;
   parameter SIZE = 11;
   parameter BIT_WIDTH = 32;

    input              CLK;
    input              WE;
    input              EN;
    input      [BIT_WIDTH-1:0]  Di;
    output reg [BIT_WIDTH-1:0]  Do;
    input      [ADDR_WIDTH-1:0] A; 


    //  11(tap) words
	(* ram_style = "block" *) reg [BIT_WIDTH-1:0] RAM[0:SIZE];
   //reg [11:0] r_A;

    //always @(posedge CLK) begin
        //r_A <= A;
    //end

    //assign Do = {32{EN}} & RAM[r_A>>2];    // read

    /*always @(posedge CLK) begin
      if(EN) begin
			if(WE[0]) RAM[A>>2][ 7: 0] <= Di[ 7: 0];
         if(WE[1]) RAM[A>>2][15: 8] <= Di[15: 8];
         if(WE[2]) RAM[A>>2][23:16] <= Di[23:16];
         if(WE[3]) RAM[A>>2][31:24] <= Di[31:24];
        end
    end*/
    
        
   always @(posedge CLK)begin
        if(~WE) Do <= RAM[A];
    end
    
   always @(posedge CLK)begin
     if(WE) RAM[A] <= Di;
   end

endmodule