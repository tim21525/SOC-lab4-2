`timescale 1ns / 1ps
`timescale 1ns / 1ps
module fir 
#(  
	parameter pADDR_WIDTH = 12,
   parameter pDATA_WIDTH = 32,
   parameter Tape_Num    = 11
)
(
	output  reg                      awready,
	output  reg                      wready,
	input   wire                     awvalid,
	input   wire [(pADDR_WIDTH-1):0] awaddr,
	input   wire                     wvalid,
	input   wire [(pDATA_WIDTH-1):0] wdata,
	
	output  reg                      arready,
	input   wire                     rready,
	input   wire                     arvalid,
	input   wire [(pADDR_WIDTH-1):0] araddr,
	output  reg                      rvalid,
	output  reg  [(pDATA_WIDTH-1):0] rdata, 
   
	input   wire                     ss_tvalid, 
	input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
	input   wire                     ss_tlast, 
	output  reg                      ss_tready, 
	
	input   wire                     sm_tready, 
	output  reg                      sm_tvalid, 
	output  reg  [(pDATA_WIDTH-1):0] sm_tdata, 
	output  reg                      sm_tlast, 

	// bram for tap RAM
	output  reg [3:0]                tap_WE,
	output  wire                     tap_EN,
	output  wire[(pDATA_WIDTH-1):0]  tap_Di,
	output  reg [(pADDR_WIDTH-1):0]  tap_A,
	input   wire [(pDATA_WIDTH-1):0] tap_Do,

	// bram for data RAM
	output  reg  [3:0]               data_WE,
	output  wire                     data_EN,
	output  reg  [(pDATA_WIDTH-1):0] data_Di,
	output  reg  [(pADDR_WIDTH-1):0] data_A,
	input   wire [(pDATA_WIDTH-1):0] data_Do,

	input   wire                     clk,
	input   wire                     rst_n
);

	reg 		   ap_start;
	reg 		   ap_done;
	reg 		   ap_idle;
	
	reg  [31:0] idx;
	reg  [31:0] data_length;
	reg 		   finish;
	reg 		   input_full;
	reg  [ 1:0] fir_cnt;
	reg  [31:0] an32Coef;
	reg  [31:0] an32Data;
	reg  [31:0] n32Acc;
	reg  [11:0] fir_addr;
	reg  [11:0] clr_data_ram;
	
	reg  [11:0] tem_addr;
	
	reg  [ 2:0] state;
	reg  [ 2:0] next_state;
	localparam ST_IDLE = 3'b000;
	localparam ST_SET  = 3'b001;
	localparam ST_LOOP = 3'b010;
	localparam ST_CAL  = 3'b011;
	localparam ST_OUT  = 3'b100;
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 					  idx <= 0;
		else if(state == ST_LOOP) idx <= idx + 32'b1;
		else 							  idx <= idx;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) state <= ST_IDLE;
		else		  state <= next_state;
	end
	always@(*) begin
		next_state <= state;
		case(state)
			ST_IDLE: if(ap_start == 1 && ap_idle == 1) 						next_state <= ST_SET;
						else									  	 						next_state <= ST_IDLE;
			ST_SET : if(data_length!=32'h0 && clr_data_ram >= 12'h28)   next_state <= ST_LOOP;
						else									  	 						next_state <= ST_SET;
			ST_LOOP:	if(idx < data_length)			  	 						next_state <= ST_CAL;
						else 									  	 						next_state <= ST_IDLE;
			ST_CAL : if(~finish)														next_state <= ST_CAL;
						else 									    						next_state <= ST_OUT;
			ST_OUT :	if(fir_cnt == 2'b11 && sm_tready == 1)				  	next_state <= ST_LOOP;
			default:											  	 						next_state <= ST_IDLE;
		endcase
	end
	
	// AXI4-Lite Read
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 									  					  arready <= 0;
		else if(arvalid == 1 && arready == 1) 					  arready <= 0;
		else if(arvalid == 1 && arready == 0 && rvalid == 0) arready <= 1;
		else 											  					  arready <= 0;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 									  rvalid <= 0;
		else if(arvalid == 1 && arready == 1) rvalid <= 1;
		else if(rvalid  == 1 && rready  == 0) rvalid <= 1;
		else if(rvalid  == 1 && rready  == 1) rvalid <= 0;
		else 											  rvalid <= 0;
	end
	always@(*) begin
		if(rvalid == 1 && rready == 1 && araddr == 12'h00) begin
			if(ap_done == 1) rdata = 32'h02;
			else if(ap_idle == 0) rdata = 32'h04;
			else 						 rdata = 32'h0;
		end
		else rdata = tap_Do;
	end

	// AXI4-Lite Write
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 									  					  awready <= 0;
		else if(awvalid == 1 && awready == 1) 					  awready <= 0;
		else if(awvalid == 1 && awready == 0 && wready == 0) awready <= 1;
		else 											  					  awready <= 0;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 									  wready <= 0;
		else if(awvalid == 1 && awready == 1) wready <= 1;
		else if(wvalid  == 0 && wready  == 1) wready <= 1;
		else if(wvalid  == 1 && wready  == 1) wready <= 0;
		else 											  wready <= 0;
	end
	
	// tap RAM
	assign tap_EN = rst_n;
	assign tap_Di = wdata;
	always@(*) begin
		if(wvalid == 1 && wready == 1 && awaddr == 12'h00 && tap_Di == 32'h01) // ap_start = 1
			tap_WE = 4'h0;
		else if(wvalid == 1 && wready == 1 && awaddr == 12'h10)					  // read data length
			tap_WE = 4'h0;
		else if(wvalid == 1 && wready == 1 && ap_idle == 0)
			tap_WE = 4'hf;
		else if(rvalid == 1 && rready == 1 && ap_idle == 0)
			tap_WE = 4'h0;
		else																 
			tap_WE = 4'h0;
	end
	always@(*) begin
		if(state == ST_LOOP)																		  tap_A = fir_addr + 12'h01;
		else if(state == ST_OUT || finish)													  tap_A = fir_addr;
		else if(state == ST_CAL)		  														  tap_A = fir_addr + 12'h01;
		else if(awvalid == 1 && awready == 1 && ap_idle == 0 && awaddr != 12'h00) tap_A = awaddr - 12'h20;
		else if(arvalid == 1 && arready == 1 && ap_idle == 0 && araddr != 12'h00) tap_A = araddr - 12'h20;
		else 																							  tap_A = tem_addr;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) tem_addr <= 12'h0;
		else if(state == ST_CAL && fir_cnt == 2'b00)
			tem_addr <= fir_addr + 12'h01;
		else if(awvalid == 1 && awready == 1 && ap_idle == 0 && awaddr != 12'h00)
			tem_addr <= awaddr - 12'h20;
		else if(arvalid == 1 && arready == 1 && ap_idle == 0 && araddr != 12'h00)
			tem_addr <= araddr - 12'h20;
		else
			tem_addr <= tem_addr;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 					 
			data_length <= 0;
		else if(wvalid == 1 && wready == 1 && awaddr == 12'h10)
			data_length <= tap_Di;
		else 							 
			data_length <= data_length;
	end
	
	// AXI4-Stream Xn(ss)
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 																		 input_full <= 0;
      else if(finish == 1)                                            input_full <= 1; // modify
      else if(input_full == 1 && ss_tvalid == 1)                      input_full <= 0; // modify
		//else if(input_full == 0 && state == ST_OUT && fir_cnt == 2'b11) input_full <= 1;
		//else																				 input_full <= 0;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)
			ss_tready <= 0;
		else if(input_full == 1)
			ss_tready <= 1;
      else if(ss_tvalid&ss_tready==1)
         ss_tready <= 0;
		else if(input_full == 0 && ss_tvalid == 1)
			ss_tready <= 0;
	end
	
	// AXI4-Stream Yn(sm)
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)  sm_tvalid <= 0;
		else if(state == ST_OUT && fir_cnt == 2'b10) sm_tvalid <= 1;
		// else if(sm_tready == 0)								sm_tvalid <= 1;
		else														sm_tvalid <= 0;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)  sm_tdata <= 0;
		else if(state == ST_OUT && fir_cnt == 2'b10) sm_tdata <= n32Acc;
		else if(sm_tready == 0)								sm_tdata <= sm_tdata;
		else														sm_tdata <= 0;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) sm_tlast <= 0;
		else if(state == ST_OUT && fir_cnt == 2'b10 && idx == data_length)
			sm_tlast <= 1;
		else
			sm_tlast <= 0;
	end
	
	// data RAM	
	assign data_EN = rst_n;
	always@(*) begin
		if(state == ST_SET)		  data_WE = 4'hf; // reset data memory
		else if(fir_cnt == 2'b00) data_WE = 4'h0;
		else if(fir_cnt == 2'b01) data_WE = 4'hf;
		else if(fir_cnt == 2'b10) data_WE = 4'h0;
		else							  data_WE = 0;
	end
	always@(*) begin
		if(state == ST_SET)									data_Di = 0;
		else if(state == ST_CAL && fir_cnt == 2'b01) data_Di = an32Data;
		else if(state == ST_OUT)
			data_Di = an32Data;
		else														data_Di = 0;
	end
	
	always@(*) begin
		if(state == ST_SET)									data_A = clr_data_ram;
		else if(fir_cnt == 2'b00) 		  				   data_A = fir_addr; // fir_addr - 12'h04
		else if(state == ST_CAL && fir_cnt == 2'b01) data_A = fir_addr;
		else if(state == ST_CAL && fir_cnt == 2'b10) data_A = fir_addr;
		else if(state == ST_OUT)							data_A = fir_addr;
		else 														data_A = 0;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) clr_data_ram <= 12'h00;
		else if(state == ST_SET) clr_data_ram <= clr_data_ram + 12'h01;
	end
	
	// FIR
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)
			ap_start <= 0;
		else if(wvalid == 1 && wready == 1 && awaddr == 12'h00 && tap_Di == 32'h0000_0001 && ap_idle == 0 && ap_done == 0)
			ap_start <= 1;
		else if(ap_idle == 1)
			ap_start <= 0;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) ap_idle <= 0;
		else if(ap_start == 1 && ap_idle == 0)
			ap_idle <= 1;
		else if(ap_done == 1)
			ap_idle <= 0;
		else
			ap_idle <= ap_idle;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n)
			ap_done <= 0;
		else if(state == ST_LOOP && idx == data_length)
			ap_done <= 1;
		else
			ap_done <= 0;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) fir_cnt <= 0;
		else if(state == ST_LOOP) 							fir_cnt <= 0;
		else if(state == ST_CAL && finish == 1)		fir_cnt <= 0;
		else if(state == ST_CAL && fir_cnt != 2'b10) fir_cnt <= fir_cnt + 2'b1;
		else if(state == ST_CAL && fir_cnt == 2'b10) fir_cnt <= 0;
      else if(state == ST_OUT && (ss_tvalid&ss_tready) == 0 && fir_cnt == 2'b00) begin
         fir_cnt <= fir_cnt; // modify
      end
		else if(state == ST_OUT && fir_cnt != 2'b10) fir_cnt <= fir_cnt + 2'b1;
		else if(state == ST_OUT && fir_cnt == 2'b10 && sm_tready == 1) fir_cnt <= fir_cnt + 2'b1;
		else if(state == ST_OUT && fir_cnt == 2'b11) fir_cnt <= 0;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 												fir_addr <= 12'h09; // 12'h09 << 2 = 12'h24
		else if(state == ST_LOOP) 							fir_addr <= 12'h09;
		else if(state == ST_CAL && fir_cnt == 2'b00) fir_addr <= fir_addr + 12'h01;
		else if(state == ST_CAL && fir_cnt == 2'b01 && fir_addr != 12'h01)
			fir_addr <= fir_addr - 12'h02;
		else if(state == ST_CAL && fir_cnt == 2'b01 && fir_addr == 12'h01)
			fir_addr <= 12'h00;
		else if(state == ST_OUT && fir_cnt == 2'b11)
			fir_addr <= 12'h09;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) 												an32Data <= 0;
		else if(state == ST_CAL && fir_cnt == 2'b00) an32Data <= data_Do;
		else if(state == ST_OUT && fir_cnt == 2'b00) an32Data <= ss_tdata;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) an32Coef <= 0;
		else if(state == ST_CAL && fir_cnt == 2'b00) an32Coef <= tap_Do;
		else if(state == ST_OUT && fir_cnt == 2'b00) an32Coef <= tap_Do;
	end
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) n32Acc <= 0;
		else if(state == ST_LOOP) n32Acc <= 0;
		else if(state == ST_CAL && fir_cnt == 2'b01) n32Acc <= n32Acc + an32Coef*an32Data;
		else if(state == ST_OUT && fir_cnt == 2'b01) n32Acc <= n32Acc + an32Coef*an32Data;
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) finish <= 0;
		else if(state == ST_CAL && fir_cnt == 2'b01 && fir_addr == 12'h01)
			finish <= 1;
		else
			finish <= 0;
	end

endmodule