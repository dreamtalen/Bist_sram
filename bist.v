`timescale 1ns /1ns
module bist(clk, rst_n, bist_fail, bist_done);

input clk;
input rst_n;
output bist_fail;
output bist_done;
reg bist_fail = 0;
reg bist_done = 0;

wire [31:0] data_output;
reg chip_enable = 0;
reg [3:0] write_enable = 4'b1111;
reg [13:0] address = 14'b0; 
reg [31:0] data_input = 32'b0;
reg output_enable = 1'b0;

mem_e8kw32s mem(.Q(data_output),
              .CLK(clk),
              .CEN(chip_enable),
              .WEN(write_enable),
              .A(address[12:0]),
              .D(data_input),
              .OEN(output_enable));

reg [31:0] pattern_0;
reg [31:0] pattern_1;
reg [2:0] pattern_index =3'b000;	
reg pattern_update = 1'b0;
reg pattern_update_reg0 = 0;
reg pattern_update_reg1 = 0;
reg pattern_update_complete =0;

reg [3:0] state, next_state;

parameter IDLE = 4'b0001;
parameter START = 4'b0010;
parameter STATE1 = 4'b0011;
parameter STATE2 = 4'b0100;
parameter STATE3 = 4'b0101;
parameter STATE4 = 4'b0110;
parameter STATE5 = 4'b0111;
parameter STATE6 = 4'b1000;
parameter COMPLETE = 4'b1001;

reg state1_complete = 1'b0;
reg [2:0] state2_state;
reg state2_start  = 1'b0;
reg state2_complete = 1'b0;
parameter STATE2_IDLE = 3'b001;
parameter STATE2_R0 = 3'b010;
parameter STATE2_W1 = 3'b011;
parameter STATE2_R1 = 3'b100;
reg [2:0] state3_state;
reg state3_start  = 1'b0;
reg state3_complete = 1'b0;
parameter STATE3_IDLE = 3'b001;
parameter STATE3_R1 = 3'b010;
parameter STATE3_W0 = 3'b011;
parameter STATE3_R0 = 3'b100;
reg [2:0] state4_state;
reg state4_start  = 1'b0;
reg state4_complete = 1'b0;
parameter STATE4_IDLE = 3'b001;
parameter STATE4_R0 = 3'b010;
parameter STATE4_W1 = 3'b011;
parameter STATE4_R1 = 3'b100;
reg [2:0] state5_state;
reg state5_start  = 1'b0;
reg state5_complete = 1'b0;
parameter STATE5_IDLE = 3'b001;
parameter STATE5_R1 = 3'b010;
parameter STATE5_W0 = 3'b011;
parameter STATE5_R0 = 3'b100;
reg state6_complete = 1'b0;

always@(posedge clk or negedge rst_n or state)
begin
	if(!rst_n) begin
		state <= IDLE;	
		next_state = IDLE;
		address <= 14'b0;
		pattern_update <=1'b0;
		state2_start <= 1'b0;
		state3_start <= 1'b0;
		state4_start <= 1'b0;
		state5_start <= 1'b0;
		state1_complete <= 1'b0;	
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
	else begin
		state <= next_state;
		case(state)
			IDLE:	next_state = START;
			START:	next_state = (pattern_update_complete)? STATE1:START; 
			STATE1:	next_state = (state1_complete)? STATE2: STATE1; 
			STATE2:	next_state = (state2_complete)? STATE3: STATE2; 
			STATE3:	next_state = (state3_complete)? STATE4: STATE3; 
			STATE4:	next_state = (state4_complete)? STATE5: STATE4; 
			STATE5:	next_state = (state5_complete)? STATE6: STATE5; 
			STATE6:	next_state = (state6_complete)? COMPLETE: STATE6; 
			COMPLETE:	next_state = START;
			default:	next_state = IDLE;
		endcase
	end
end
		
always  @(posedge clk or negedge rst_n)
begin
	chip_enable <= 1'b0;
	output_enable <= 1'b0;
	if(rst_n)
	begin
		case(state)
			IDLE: address <= 14'b0;
			START: pattern_update <= 1'b1;
			STATE1: begin
				write_enable <= 4'b0000;   
				pattern_update <= 1'b0;
				address <= address + 14'b00000000000001;
				data_input <= pattern_0;
				if (address == 14'b01111111111111)
					begin
						state1_complete <= 1'b1;
						address <= 14'b01111111111111;
					end
			end
			STATE2: begin
				state1_complete <= 1'b0;
				state2_start <= 1'b1;  
				case(state2_state)
					STATE2_IDLE: begin
						address <= 14'b0 - 1'b1;							
						if(state2_complete==0)
							state2_state <= STATE2_R0;
						else state2_state <= STATE2_IDLE;
						write_enable <= 4'bzzzz;
					end
					STATE2_R0: begin									
					    address <= address + 1'b1;
					    write_enable <= 4'b1111;
					    state2_state <= STATE2_W1;
				    end				   
					STATE2_W1: begin
						write_enable <= 4'b0000;
						data_input <= pattern_1;
						state2_state <= STATE2_R1;
   					end 
					STATE2_R1: begin
						write_enable <=4'b1111;
						if(address == 14'b01111111111111) begin
							state2_start <= 1'b0;
							state2_complete <= 1'b1;
							state2_state <= STATE2_IDLE;
						end
						else begin
			    			state2_start <= 1'b1;
							state2_complete <= 1'b0;
							state2_state <= STATE2_R0;
						end
					end
					default: begin
						write_enable <= 4'bzzzz;
						data_input <= 32'b0;
					    state2_start <=1'b0;
					    state2_complete <= 1'b1;  
					    state2_state <= STATE2_IDLE;
				    end 
				endcase
			end
			STATE3:
			begin
				state2_complete <= 1'b0;
				state3_start <= 1'b1;						
				case(state3_state)
					STATE3_IDLE: begin
						address <= 14'b0 - 1'b1;
						if(state3_complete == 0)
							state3_state <= STATE3_R1;
						else state3_state <= STATE3_IDLE;
						write_enable <= 4'bzzzz;
					end										  
					STATE3_R1: begin
						address <= address + 1'b1;
						write_enable <= 4'b1111;
						state3_state <= STATE3_W0;
					end
					STATE3_W0: begin
						write_enable <= 4'b0000;
						data_input <= pattern_0;
						state3_state <= STATE3_R0;
					end			 
					STATE3_R0: begin
						write_enable <= 4'b1111;
						if(address == 14'b01111111111111) begin
							address <= 14'b0;
							state3_start <= 1'b0;
							state3_complete <= 1'b1;
							state3_state <= STATE3_IDLE;
						end
						else begin
							state3_start <= 1'b1;
							state3_complete <= 1'b0;
							state3_state <= STATE3_R1;
						end
					end
					default: begin
						write_enable <= 4'bzzzz;
						state3_start <=1'b0;
						state3_complete <= 1'b1;  
						state3_state <= STATE3_IDLE;
					end
				endcase
			end
			STATE4: begin
				state3_complete <= 1'b0;
				state4_start <= 1'b1;  
				case(state4_state)
					STATE4_IDLE: begin
						address <= 14'b10000000000000 ;
						if(state4_complete==0)
							state4_state <= STATE4_R0;
						else state4_state <= STATE4_IDLE;
						write_enable <= 4'bzzzz;
					end
					STATE4_R0: begin
						address <= address - 1'b1;
						write_enable <= 4'b1111;
						state4_state <= STATE4_W1;
					end
					STATE4_W1: begin
						write_enable <= 4'b0000;
						data_input <= pattern_1;
						state4_state <= STATE4_R1;
					end
					STATE4_R1: begin
						write_enable <= 4'b1111;
						if(address == 14'b0) begin
							state4_start <=1'b0;
							state4_complete <= 1'b1;
							state4_state <=STATE4_IDLE;
						end
						else begin
							state4_start <=1'b1;
							state4_complete <= 1'b0;
							state4_state <= STATE4_R0;
						end
					end
					default: begin
						write_enable <= 4'bzzzz;
						data_input <= 32'b0;
						state4_start <=1'b0;
						state4_complete <= 1'b1;  
						state4_state <= STATE4_IDLE;
					end 
				endcase
			end				
			STATE5:
			begin
				state4_complete <= 1'b0;
				state5_start <= 1'b1;
				case(state5_state)
					STATE5_IDLE: begin
						address <= 14'b10000000000000;
						if(state5_complete == 0)
							state5_state <= STATE5_R1;
						else state5_state <= STATE5_IDLE;
						write_enable <= 4'bzzzz;
					end
					STATE5_R1: begin
						address <= address - 1'b1;
						write_enable <= 4'b1111;
						state5_state <= STATE5_W0;
					end
					STATE5_W0: begin
						write_enable <= 4'b0000;
						data_input <= pattern_0;
						state5_state <= STATE5_R0;
					end			 
					STATE5_R0: begin	
						write_enable <= 4'b1111;
						if(address == 14'b0) begin
							address <= 14'b01111111111111;
							state5_start <= 1'b0;
							state5_complete <= 1'b1;
							state5_state <= STATE5_IDLE;
						end
						else begin
							state5_start <= 1'b1;
							state5_complete <= 1'b0;
							state5_state <= STATE5_R1;
						end
					end
					default: begin
						write_enable <= 4'bzzzz;
						state5_start <= 1'b0;
						state5_complete <= 1'b1;  
						state5_state <= STATE5_IDLE;
					end 
				endcase
			end
			STATE6: begin
				state5_complete <= 1'b0;
				write_enable <= 4'b1111;
				address <= address - 1'b1;
				if(address == 14'b0)
					state6_complete <= 1'b1;
			end
										
			COMPLETE: begin
				address <= 14'b0;
				state6_complete <= 1'b0;
			end
			
			default: begin
				address <= 14'b00000000000001;
				write_enable <= 4'b1111;
			end
		endcase		
	end
end

always @(posedge clk or negedge rst_n)		
begin
	case(pattern_index)
		3'b001: begin
			pattern_0 <= 32'b0;
			pattern_1 <= 32'b11111111111111111111111111111111;
		end
		3'b010: begin
			pattern_0 <= 32'b01010101010101010101010101010101;
			pattern_1 <= 32'b10101010101010101010101010101010;
		end
		3'b011: begin
			pattern_0 <= 32'b00110011001100110011001100110011;
			pattern_1 <= 32'b11001100110011001100110011001100;
		end
		3'b100: begin
			pattern_0 <= 32'b00001111000011110000111100001111;
			pattern_1 <= 32'b11110000111100001111000011110000;
		end
		3'b101: begin
			pattern_0 <= 32'b00000000111111110000000011111111;
			pattern_1 <= 32'b11111111000000001111111100000000;
		end
		3'b110: begin
			pattern_0 <= 32'b00000000000000001111111111111111;
			pattern_1 <= 32'b11111111111111110000000000000000;
		end
		default: begin
			pattern_0 <= 32'b0;
			pattern_1 <= 32'b11111111111111111111111111111111;
		end
	endcase
end	         
		
always @(posedge clk or negedge rst_n)
		
begin
	pattern_update_reg0 <= pattern_update;
	pattern_update_reg1 <= pattern_update_reg0;
	if(!rst_n) begin
		pattern_index <= 3'b000;
		pattern_update_complete <= 1'b0;
	end
	else begin
		if((pattern_update_reg0)&&(!pattern_update_reg1) ) begin
			pattern_index <= pattern_index + 1'b1;
			pattern_update_complete <=1'b1;
		end
		else begin
			if ((!pattern_update_reg0)&&(pattern_update_reg1) )
				pattern_update_complete <=1'b0;
		end
	end
end

always @(posedge clk or negedge rst_n or data_output)
begin
	if(data_output==pattern_0||data_output==pattern_1) bist_fail <= 0;
	else bist_fail <= 1;
end

always @(posedge clk or negedge rst_n)	
begin
   	if ((state==COMPLETE)&&(pattern_index==3'b110)&&(bist_fail==1'b0)) bist_done <= 1;
end
	
endmodule
