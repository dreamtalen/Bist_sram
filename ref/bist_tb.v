/////////////////////////////////////////////////////////////////
// 
//File Name : bist.v
//Author    : Jin Xuwei
//
//---------------------------------------------------------------
//Description
//Built-In Self-Test for SRAM ( mem_e8kw32s.v ) base on March C+
//---------------------------------------------------------------
//Revision History
//Version  Date         Author        Change Description
//1.0      06/02/2016   Jin Xuwei     first version
//
////////////////////////////////////////////////////////////////////

//`timescale 1ns/1ns
 module bist_tb;
  
reg tb_clk;
reg tb_rst_n;
reg tb_start;

wire [3:0] tb_wen;
wire [8:0] tb_state;
wire [13:0] tb_addr;
wire [31:0] tb_mem_dataout;
wire tb_bist_fail;
wire tb_bist_done;

initial
  begin
    tb_clk = 0;
  end
  
always
  begin
    #50 tb_clk = ~tb_clk;
  end
  
  initial
  begin
    tb_rst_n = 1;
    #100 tb_rst_n = 0;
    #50 tb_rst_n = 1;
  end
  
  
  
  initial begin
      
    $display("\n\n");
	  $display("*********************************************************");
	  $display("************** BIST START ! **************",$time,);
	  $display("*********************************************************");
	  $display("\n");
	  tb_start <= 1;
    end
     
	 always @( posedge tb_clk )
	 begin
   if( tb_bist_done == 1 && tb_bist_fail ==0 )begin
      $display("*********************************************************");
	     $display("************** BIST DONE ! ***************",$time);
	     $display("*********************************************************");
	     $display("\n");
	     $stop; 
    end
  end

  
bist BIST(.clk(tb_clk),
          .rst_n(tb_rst_n),
          .start(tb_start),
          .mem_dataout(tb_mem_dataout),
          .state(tb_state),
          .addr(tb_addr),
          .bist_fail(tb_bist_fail),
          .bist_done(tb_bist_done),
          .wen(tb_wen));

endmodule
  
