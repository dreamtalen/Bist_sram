`timescale 1ns/1ns
module bist_tb;
  
reg clk_tb;
reg rst_n_tb;
wire bist_fail_tb;
wire bist_done_tb;

bist BIST(.clk(clk_tb),
       .rst_n(rst_n_tb),
       .bist_fail(bist_fail_tb),
       .bist_done(bist_done_tb));

wire [31:0] data_output_tb = BIST.data_output;
wire [31:0] pattern_0_tb = BIST.pattern_0;
wire [31:0] pattern_1_tb = BIST.pattern_1;

initial
begin
  clk_tb = 0;
end
  
always
begin
  #50 clk_tb = ~clk_tb;
end
  
initial
begin
  rst_n_tb = 0;
  #100 rst_n_tb = 1;
  $display("Start memory built in self test at time %d", $time);
end

always @(pattern_0_tb or pattern_1_tb or rst_n_tb) begin
  if (rst_n_tb) begin
  $display("Begin to test pattern %b and %b at time %d", pattern_0_tb, pattern_1_tb, $time);  
  end
end

always @( posedge clk_tb )
begin
if( bist_done_tb == 1 && bist_fail_tb == 0 )begin
    $display("Finish memory built in self test at time: ",$time);
    $stop; 
 end
end

endmodule