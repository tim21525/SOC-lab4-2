module wb_axi
#(  
	parameter pADDR_WIDTH = 12,
   parameter pDATA_WIDTH = 32,
   parameter Tape_Num    = 11
)
(
   input clk,
   input wb_rst_i,
   input wbs_stb_i,
   input wbs_cyc_i,
   input wbs_we_i,
   input [31:0] wbs_dat_i,
   input [31:0] wbs_adr_i,
   output reg wbs_ack_o,
   output reg [31:0] wbs_dat_o
);

   wire                        awready;
   wire                        wready;
   reg                         awvalid;
   reg   [(pADDR_WIDTH-1): 0]  awaddr;
   reg                         wvalid;
   reg signed [(pDATA_WIDTH-1) : 0] wdata;
   
   wire                        arready;
   reg                         rready;
   reg                         arvalid;
   reg         [(pADDR_WIDTH-1): 0] araddr;
   wire                        rvalid;
   wire signed [(pDATA_WIDTH-1): 0] rdata;
   
   reg                         ss_tvalid;
   reg signed [(pDATA_WIDTH-1) : 0] ss_tdata;
   reg                         ss_tlast;
   wire                        ss_tready;
   
   reg                         sm_tready;
   wire                        sm_tvalid;
   wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
   wire                        sm_tlast;
   reg                         axis_clk;
   reg                         axis_rst_n;

   wire [3:0]               tap_WE;
   wire                     tap_EN;
   wire [(pDATA_WIDTH-1):0] tap_Di;
   wire [(pADDR_WIDTH-1):0] tap_A;
   wire [(pDATA_WIDTH-1):0] tap_Do;
   
   wire [3:0]               data_WE;
   wire                     data_EN;
   wire [(pDATA_WIDTH-1):0] data_Di;
   wire [(pADDR_WIDTH-1):0] data_A;
   wire [(pDATA_WIDTH-1):0] data_Do;

   wire                     rst_n;
   assign rst_n = ~wb_rst_i;
   
   reg sm_tready_cnt;
   reg xn, yn;

   reg [3:0] cnt;
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) cnt <= 4'd1;
      else if(wbs_ack_o == 1)
         cnt <= 4'd1;
      else if(wbs_cyc_i == 1 && cnt == 4'd1)
         cnt <= cnt + 4'd1;
      else if(cnt == 4'd10)
         cnt <= cnt;
      else if(cnt != 4'd1)
         cnt <= cnt + 4'd1;
   end
   
   always@(*) begin
      if(cnt == 4'd10) begin
         if(wready==1)
            wbs_ack_o = 1;
         else if(rvalid==1)
            wbs_ack_o = 1;
         else if(ss_tvalid&ss_tready == 1)
            wbs_ack_o = 1;
         else if(sm_tready_cnt == 1)
            wbs_ack_o = 1;
         else if(wbs_adr_i == 32'h30000030)
            wbs_ack_o = 1;
         else if(wbs_adr_i == 32'h30000034)
            wbs_ack_o = 1;
         else
            wbs_ack_o = 0;
      end
      else
         wbs_ack_o = 0;
   end
   
   always@(*) begin
      if(cnt == 4'd10) begin
         if(rvalid == 1)
            wbs_dat_o = rdata;
         else if(sm_tready_cnt)
            wbs_dat_o = sm_tdata;
         else if(wbs_adr_i == 32'h30000030)
            wbs_dat_o = xn;
         else if(wbs_adr_i == 32'h30000034)
            wbs_dat_o = yn;
         else
            wbs_dat_o = 0;
         end
      else
         wbs_dat_o = 0;
   end
   
   reg [3:0] wtap_cnt;
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         awvalid  <= 0;
         awaddr   <= 0;
         wvalid   <= 0;
         wdata    <= 0;
         wtap_cnt <= 4'd0;
      end
      else if(cnt == 4'd10 && wbs_we_i == 1) begin
         if(wready == 1) begin
            awvalid  <= 0;
            awaddr   <= 0;
            wvalid   <= 0;
            wdata    <= 0;
            if(wbs_adr_i == 32'h30000040)
               wtap_cnt <= wtap_cnt + 1;
            else
               wtap_cnt <= wtap_cnt;
         end
         else if(wready == 0 && (wbs_adr_i == 32'h30000000 || wbs_adr_i == 32'h30000010)) begin
            awvalid <= 1;
            awaddr  <= wbs_adr_i[11:0];
            wvalid  <= 1;
            wdata   <= wbs_dat_i;
            wtap_cnt <= 4'd0;
         end
         else if(wready == 0 && wbs_adr_i == 32'h30000040) begin
            awvalid  <= 1;
            awaddr   <= 12'h20 + 1*wtap_cnt;
            wvalid   <= 1;
            wdata    <= wbs_dat_i;
            wtap_cnt <= wtap_cnt;
         end
         else begin
            awvalid  <= 0;
            awaddr   <= 0;
            wvalid   <= 0;
            wdata    <= 0;
            wtap_cnt <= wtap_cnt;
         end
      end
      else begin
         awvalid  <= 0;
         awaddr   <= 0;
         wvalid   <= 0;
         wdata    <= 0;
         wtap_cnt <= wtap_cnt;
      end
   end
   
   reg [3:0] rtap_cnt;
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         arvalid  <= 0;
         araddr   <= 0;
         rready   <= 0;
         rtap_cnt <= 0;
      end
      else if(cnt == 4'd10 && wbs_we_i == 0) begin
         if(rvalid == 1) begin
            arvalid  <= 0;
            araddr   <= 0;
            rready   <= 0;
            if(wbs_adr_i == 32'h30000040)
               rtap_cnt <= rtap_cnt + 1;
            else
               rtap_cnt <= rtap_cnt;          
         end
         else if(rvalid == 0 && (wbs_adr_i == 32'h30000000 || wbs_adr_i == 32'h30000010)) begin
            arvalid <= 1;
            araddr  <= wbs_adr_i[11:0];
            rready  <= 1;
            rtap_cnt <= 4'd0;
         end
         else if(rvalid == 0 && wbs_adr_i == 32'h30000040) begin
            arvalid  <= 1;
            araddr   <= 12'h20 + 1*rtap_cnt;
            rready   <= 1;
            rtap_cnt <= rtap_cnt;
         end
         else begin
            arvalid  <= 0;
            araddr   <= 0;
            rready   <= 0;
            rtap_cnt <= rtap_cnt;
         end
      end
      else begin
            arvalid  <= 0;
            araddr   <= 0;
            rready   <= 0;
            rtap_cnt <= rtap_cnt;
      end
   end

   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         ss_tvalid <= 0;
         ss_tdata  <= 0;
      end
      else if(cnt == 4'd10 && wbs_we_i == 1) begin
         if(ss_tvalid&ss_tready == 1) begin
            ss_tvalid <= 0;
            ss_tdata  <= ss_tdata;
         end
         else if(wbs_adr_i == 32'h30000080 && xn == 1) begin
            ss_tvalid <= 1;
            ss_tdata  <= wbs_dat_i;
         end
         else begin
            ss_tvalid <= 0;
            ss_tdata  <= ss_tdata;
         end
      end
      else begin
            ss_tvalid <= 0;
            ss_tdata  <= ss_tdata;
      end
   end
   
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         sm_tready <= 0;
      end
      else if(cnt == 4'd10 && wbs_we_i == 0 && yn == 1) begin
         if(sm_tready_cnt==1) begin
            sm_tready <= 0;
         end
         else if(wbs_adr_i == 32'h30000084) begin
            sm_tready <= 1;
         end
         else begin
            sm_tready <= 0;
         end
      end
      else begin
         sm_tready <= 0;
      end
   end
   
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) xn <= 1;
      else if(xn == 1 && ss_tvalid&ss_tready==1)
         xn <= 0;
      else if(xn == 0 && sm_tvalid&sm_tready==1)
         xn <= 1;
   end
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) yn <= 1;
      else if(sm_tready_cnt == 1)
         yn <= 0;
      else if(yn == 0 && ss_tvalid&ss_tready==1)
         yn <= 1;
   end
   
   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) sm_tready_cnt <= 0;
      else if(yn == 1 && sm_tvalid&sm_tready==1)
         sm_tready_cnt <= 1;
      else 
         sm_tready_cnt <= 0;
   end

   bram11 tap_RAM (
      .CLK(clk),
      .WE(tap_WE[0]),
      .EN(tap_EN),
      .Di(tap_Di),
      .A(tap_A),
      .Do(tap_Do)
   );

   // RAM for data: choose bram11 or bram12
   bram11 data_RAM(
      .CLK(clk),
      .WE(data_WE[0]),
      .EN(data_EN),
      .Di(data_Di),
      .A(data_A),
      .Do(data_Do)
   );
   
   fir fir_DUT(
     .awready(awready),
     .wready(wready),
     .awvalid(awvalid),
     .awaddr(awaddr),
     .wvalid(wvalid),
     .wdata(wdata),
     .arready(arready),
     .rready(rready),
     .arvalid(arvalid),
     .araddr(araddr),
     .rvalid(rvalid),
     .rdata(rdata),
     .ss_tvalid(ss_tvalid),
     .ss_tdata(ss_tdata),
     .ss_tlast(ss_tlast),
     .ss_tready(ss_tready),
     .sm_tready(sm_tready),
     .sm_tvalid(sm_tvalid),
     .sm_tdata(sm_tdata),
     .sm_tlast(sm_tlast),

     // ram for tap
     .tap_WE(tap_WE),
     .tap_EN(tap_EN),
     .tap_Di(tap_Di),
     .tap_A(tap_A),
     .tap_Do(tap_Do),

     // ram for data
     .data_WE(data_WE),
     .data_EN(data_EN),
     .data_Di(data_Di),
     .data_A(data_A),
     .data_Do(data_Do),

     .clk(clk),
     .rst_n(rst_n)
     
     );

endmodule