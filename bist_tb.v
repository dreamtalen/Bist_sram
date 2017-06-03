//`timescale 1ns/1ns
module bist_tb;
  
reg tb_clk;
reg tb_rst_n;
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
   
bist BIST(.clk(tb_clk),
          .rst_n(tb_rst_n),
          .bist_fail(tb_bist_fail),
          .bist_done(tb_bist_done),

endmodule
  
