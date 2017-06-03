`timescale 1ns /1ns
 module bist(clk, rst_n, bist_fail, bist_done);

input clk;
input rst_n;
output bist_fail;
output bist_done;
wire [31:0] mem_dataout;
reg bist_fail = 0;
reg bist_done = 0;
reg cen = 1'b0;
reg oen = 1'b0;
reg [3:0] wen = 4'b1111;
reg [8:0] state, nextstate;
reg [13:0]  addr = 14'b0000_0000_0000_0; 
reg p_updata = 1'b0;
reg [31:0] data_input = 32'b0;
reg p_updata_reg0 = 0;
reg p_updata_reg1 = 0;
reg [31:0] pattern_0;
reg [31:0] pattern_1;
reg p_updata_complete =0;
reg [2:0] pattern_index =3'b000;	

reg state2_start  = 1'b0;
reg state3_start  = 1'b0;
reg state4_start  = 1'b0;
reg state5_start  = 1'b0;

reg state1_complete = 1'b0;
reg state2_complete = 1'b0;
reg state3_complete = 1'b0;
reg state4_complete = 1'b0;
reg state5_complete = 1'b0;
reg state6_complete = 1'b0;

parameter IDLE = 9'b0000_0000_1;
parameter START = 9'b0000_0001_0;
parameter STATE1 = 9'b0000_0010_0;
parameter STATE2 = 9'b0000_0100_0;
parameter STATE3 = 9'b0000_1000_0;
parameter STATE4 = 9'b0001_0000_0;
parameter STATE5 = 9'b0010_0000_0;
parameter STATE6 = 9'b0100_0000_0;
parameter COMPLETE = 9'b1000_0000_0;

reg [2:0] state2_state;
parameter STATE2_IDLE = 3'b001;
parameter STATE2_R0 = 3'b010;
parameter STATE2_W1 = 3'b011;
parameter STATE2_R1 = 3'b100;

reg [2:0] state3_state;
parameter STATE3_IDLE = 3'b001;
parameter STATE3_R1 = 3'b010;
parameter STATE3_W0 = 3'b011;
parameter STATE3_R0 = 3'b100;

reg [2:0] state4_state;
parameter STATE4_IDLE = 3'b001;
parameter STATE4_R0 = 3'b010;
parameter STATE4_W1 = 3'b011;
parameter STATE4_R1 = 3'b100;

reg [2:0] state5_state;
parameter STATE5_IDLE = 3'b001;
parameter STATE5_R1 = 3'b010;
parameter STATE5_W0 = 3'b011;
parameter STATE5_R0 = 3'b100;

	
mem_e8kw32s mem(.Q(mem_dataout),
	              .CLK(clk),
	              .CEN(cen),0
	              .WEN(wen),
	              .A(addr[12:0]),
	              .D(data_input),
	              .OEN(oen));
	
always @(posedge clk or negedge rst_n)
		
begin
	p_updata_reg0 <= p_updata;
	p_updata_reg1 <= p_updata_reg0;
	if(!rst_n)
		begin
			pattern_index <=3'b000;
			p_updata_complete <= 1'b0;
		end
	else
		begin
			if((p_updata_reg0)&&(!p_updata_reg1) )
				begin
					pattern_index <= pattern_index + 1'b1;
					p_updata_complete <=1'b1;
				end
			else
				begin
					if ((!p_updata_reg0)&&(p_updata_reg1) )
						p_updata_complete <=1'b0;
				end
		end
end
		
always @(posedge clk or negedge rst_n)
		
	begin
		case(pattern_index)
			3'b001: begin
						pattern_0 <= 32'b0000_0000_0000_0000_0000_0000_0000_0000;
						pattern_1 <= 32'b1111_1111_1111_1111_1111_1111_1111_1111;
					end
			3'b010: begin
						pattern_0 <= 32'b0101_0101_0101_0101_0101_0101_0101_0101;
						pattern_1 <= 32'b1010_1010_1010_1010_1010_1010_1010_1010;
					end
			3'b011: begin
						pattern_0 <= 32'b0011_0011_0011_0011_0011_0011_0011_0011;
						pattern_1 <= 32'b1100_1100_1100_1100_1100_1100_1100_1100;
					end
			3'b100: begin
						pattern_0 <= 32'b0000_1111_0000_1111_0000_1111_0000_1111;
						pattern_1 <= 32'b1111_0000_1111_0000_1111_0000_1111_0000;
					end
			3'b101: begin
						pattern_0 <= 32'b0000_0000_1111_1111_0000_0000_1111_1111;
						pattern_1 <= 32'b1111_1111_0000_0000_1111_1111_0000_0000;
					end
			3'b110: begin
						pattern_0 <= 32'b0000_0000_0000_0000_1111_1111_1111_1111;
						pattern_1 <= 32'b1111_1111_1111_1111_0000_0000_0000_0000;
					end
			default: begin
						pattern_0 <= 32'b1111_1111_1111_1111_1111_1111_1111_1111;
						pattern_1 <= 32'b1111_1111_1111_1111_1111_1111_1111_1111;
					end
		endcase
	end	         
		
		
always@(posedge clk or  negedge rst_n)
	begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nextstate;
	end
		
always@(posedge clk or negedge rst_n or state)
	begin
		if(!rst_n)
			nextstate = IDLE;
		else
			begin
				nextstate = IDLE;
				case(state)
					IDLE:	nextstate = START;
					START:	nextstate = (p_updata_complete)? STATE1:START; 
					STATE1:	nextstate = (state1_complete)? STATE2: STATE1; 
					STATE2:	nextstate = (state2_complete)? STATE3: STATE2; 
					STATE3:	nextstate = (state3_complete)? STATE4: STATE3; 
					STATE4:	nextstate = (state4_complete)? STATE5: STATE4; 
					STATE5:	nextstate = (state5_complete)? STATE6: STATE5; 
					STATE6:	nextstate = (state6_complete)? COMPLETE: STATE6; 
					COMPLETE:	nextstate = START;
					default:	nextstate = IDLE;
				endcase
			end
	end
		
always  @(posedge clk or negedge rst_n)
	begin
	  cen <= 1'b0;
	  oen <=1'b0;
	
	if(!rst_n)
		begin
			addr <= 14'b0;
			p_updata <=1'b0;
		  	state1_complete <= 1'b0;
		  
			state2_start <= 1'b0;
			state3_start <= 1'b0;
			state4_start <= 1'b0;
			state5_start <= 1'b0;

			state2_complete <= 1'b0;
			state3_complete <= 1'b0;
			state4_complete <= 1'b0;
			state5_complete <= 1'b0;
			state6_complete <= 1'b0;
			
			state2_state <= STATE2_IDLE;
			state3_state <= STATE3_IDLE;
			state4_state <= STATE4_IDLE;
			state5_state <= STATE5_IDLE;
		end
	else
	begin
		case(state)
			IDLE: addr<= 14'b0000_0000_0000_00;
			START:p_updata<= 1'b1;

			//up(W0)//
			STATE1:
			begin
				wen <= 4'b0000;   
				p_updata <= 1'b0;
				addr <= addr + 14'b0000_0000_0000_01;
				data_input <= pattern_0;
				if (addr == 14'b01111_1111_1111_1)
					begin
						state1_complete <= 1'b1;
						addr <= 14'b01111_1111_1111_1;
					end
			end

			//up(R0,W1,R1)//
			STATE2:
			begin
				state1_complete <= 1'b0;
				state2_start <= 1'b1;  
				case(state2_state)
					STATE2_IDLE:
					begin
						addr <= 14'b00000_0000_0000_0 - 1'b1;							
						if(state2_complete==0)
							state2_state <= STATE2_R0;
						else state2_state <= STATE2_IDLE;
						wen <= 4'bzzzz;
					end
					STATE2_R0:
					begin									
					    addr <= addr + 1'b1;
					    wen <= 4'b1111;
					    state2_state <= STATE2_W1;
				    end				   
					STATE2_W1:
					begin
						wen <= 4'b0000;
						data_input <= pattern_1;
						state2_state <= STATE2_R1;
   					end 
					STATE2_R1:
					begin
						wen <=4'b1111;
						if(addr == 14'b01111_1111_1111_1)
							begin
								addr <= 14'b01111_1111_1111_1;
								state2_start <=1'b0;
								state2_complete <= 1'b1;
								state2_state <= STATE2_IDLE;
							end
						else 
						    begin
				    			state2_start <=1'b1;
								state2_complete <= 1'b0;
								state2_state <= STATE2_R0;
							end
					end
					default:
					begin
						wen <= 4'bzzzz;
						data_input <= 32'b0;
					    state2_start <=1'b0;
					    state2_complete <= 1'b1;  
					    state2_state <= STATE2_IDLE;
				    end 
				endcase
			end

			//up(R1,W0,R0)//
			STATE3:
			begin
				state2_complete <= 1'b0;
				state3_start <= 1'b1;						
				case(state3_state)
					STATE3_IDLE:
					begin
						addr <= 14'b00000_0000_0000_0 - 1'b1 ;
						if(state3_complete==0)
							state3_state <= STATE3_R1;
						else state3_state <= STATE3_IDLE;
						wen <= 4'bzzzz;
					end										  
					STATE3_R1:
					begin
						addr <= addr+1'b1;
						wen <= 4'b1111;
						state3_state <= STATE3_W0;
					end
					STATE3_W0:
					begin
						wen <=4'b0000;
						data_input <= pattern_0;
						state3_state <= STATE3_R0;
					end			 
					STATE3_R0:
					begin
						wen <=4'b1111;
						if(addr == 14'b01111_1111_1111_1)
							begin
								addr <= 14'b00000_0000_0000_0;
								state3_start <=1'b0;
								state3_complete <= 1'b1;
								state3_state <= STATE3_IDLE;
							end
						else
							begin
								state3_start <=1'b1;
								state3_complete <= 1'b0;
								state3_state <= STATE3_R1;
							end
					end
					default:
					begin
						wen <= 4'bzzzz;
						state3_start <=1'b0;
						state3_complete <= 1'b1;  
						state3_state <= STATE3_IDLE;
					end
				endcase
			end

			//down(R0,W1,R1)//
			STATE4:
			begin
				state3_complete <= 1'b0;
				state4_start <= 1'b1;  
				case(state4_state)
					STATE4_IDLE:
					begin
						addr <= 14'b10000_0000_0000_0 ;
						if(state4_complete==0)
							state4_state <= STATE4_R0;
						else state4_state <= STATE4_IDLE;
						wen <= 4'bzzzz;
					end
					STATE4_R0:
					begin
						addr<=addr-1'b1;
						wen <=4'b1111;
						state4_state <= STATE4_W1;
					end
					STATE4_W1:
					begin
						wen <=4'b0000;
						data_input <= pattern_1;
						state4_state <= STATE4_R1;
					end
					STATE4_R1:
					begin
						wen <=4'b1111;
						if(addr == 14'b00000_0000_0000_0)
							begin
								addr <= 14'b00000_0000_0000_0;
								state4_start <=1'b0;
								state4_complete <= 1'b1;
								state4_state <=STATE4_IDLE;
							end
						else
							begin
								state4_start <=1'b1;
								state4_complete <= 1'b0;
								state4_state <= STATE4_R0;
							end
					end
					default:
					begin
						wen <= 4'bzzzz;
						data_input <= 32'b0;
						state4_start <=1'b0;
						state4_complete <= 1'b1;  
						state4_state <= STATE4_IDLE;
					end 
				endcase
			end

			//down(R1,W0,R0)//					
			STATE5:
			begin
				state4_complete <= 1'b0;
				state5_start <= 1'b1;
				case(state5_state)
					STATE5_IDLE:
					begin
						addr <= 14'b10000_0000_0000_0;
						if(state5_complete==0)
							state5_state <= STATE5_R1;
						else state5_state <= STATE5_IDLE;
						wen <= 4'bzzzz;
					end
					STATE5_R1:
					begin
						addr<=addr-1'b1;
						wen <=4'b1111;
						state5_state <= STATE5_W0;
					end
					STATE5_W0:
					begin
						wen <= 4'b0000;
						data_input <= pattern_0;
						state5_state <= STATE5_R0;
					end			 
					STATE5_R0:
					begin	
						wen <=4'b1111;
						if(addr == 14'b00000_0000_0000_0)
							begin
								addr <= 14'b01111_1111_1111_1;
								state5_start <=1'b0;
								state5_complete <= 1'b1;
								state5_state <= STATE5_IDLE;
							end
						else
							begin
								state5_start <=1'b1;
								state5_complete <= 1'b0;
								state5_state <= STATE5_R1;
							end
					end
					default:
					begin
						wen <= 4'bzzzz;
						state5_start <=1'b0;
						state5_complete <= 1'b1;  
						state5_state <=STATE5_IDLE;
					end 
				endcase
			end
							
			//down(R0)//
			STATE6:
			begin
				state5_complete <= 1'b0;
				wen <= 4'b1111;
				addr <= addr -1'b1;
				if(addr == 14'b00000_0000_0000_0)
					state6_complete <= 1'b1;
			end
										
			COMPLETE:
			begin
				addr <= 14'b00000_0000_0000_0;
				state6_complete<=1'b0;
			end
			
			default:
			begin
				addr <= 14'b00000_0000_0000_1;
				wen <= 4'b1111;
			end
		endcase		
	end
end

always @(posedge clk or negedge rst_n)	
    begin
    	if(mem_dataout==pattern_0||mem_dataout==pattern_1)
    		bist_fail<=0;
    	else bist_fail<=1;
    	if((addr==14'b11111_1111_1111_1)&&(mem_dataout==32'b1111_1111_1111_1111_1111_1111_1111_1111)&&(bist_fail==1'b0))
        	bist_done<=1;
	end
	
endmodule
