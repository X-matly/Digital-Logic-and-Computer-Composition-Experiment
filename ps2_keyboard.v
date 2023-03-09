module keyboard(clk,ps2_clk,clrn,ps2_data,ascii_key);         //该模块会在键盘按下时输出ASCII码，松手后输出0
	input clk,ps2_clk,ps2_data,clrn;
	reg shift;
	reg ctrl;
	reg caps;
	wire  [7:0]keydata;
	output wire [7:0]ascii_key;
	reg  [7:0]cur_key;
	reg [7:0]key_count;
	wire ready;
	reg nextdata_n;
	wire overflow;
	reg zero;
	reg off;
	reg off_1;
	reg keep;
	reg clrn_1;
	

	ascii i(.key(cur_key),
			  .asc(ascii_key),
			  .caps(caps),
			  .shift(shift));
	ps2_keyboard A (.clk(clk),
					 .clrn(clrn),
					 .ps2_clk(ps2_clk),
					 .ps2_data(ps2_data),
					 .data(keydata),
					 .ready(ready),
					 .nextdata_n(nextdata_n),
					 .overflow(overflow));
	initial begin 
	 shift=0;
	 ctrl=0;
	 caps=0;
	 clrn_1=1;
	 off_1=0;
	 off=1;
    cur_key=0;
    keep=0;
    zero=0;
    key_count=0;
end

always @ (negedge clk) begin
	 if(overflow) clrn_1<=0;
    if(clrn==0||clrn_1==0)    key_count<=0;
    if(ready) begin
		  clrn_1<=1;
        if(keydata!=8'hF0 && zero==0)begin
            if(keep==0)key_count<=key_count+1;
				if(keep==1&&keydata!=cur_key)key_count<=key_count+1;
				if(keydata==8'h12||keydata==8'h59)shift<=1;
				if(keydata==8'h14)ctrl<=1;
				if(keydata==8'h58&&caps==0&&keep==0)caps<=1;
				else if(keydata==8'h58&&caps==1&&keep==0)caps<=0;
				off<=0;
            cur_key<=keydata;
            nextdata_n<=0;
            keep<=1;
        end
        else if (zero==0)begin
				ctrl<=0;
            keep<=0;
            cur_key<=0;
				off<=1;
            nextdata_n<=0;
            zero<=1;
        end
        else begin
				if(keydata==8'h12||keydata==8'h59)shift<=0;
            cur_key<=0;
				off<=1;
            nextdata_n<=0;
            zero<=0;
        end
    end
    else  begin 
        nextdata_n<=1;
    end
end

endmodule

module ascii(key,asc,caps,shift);
	input [7:0]key;
	input caps;
	input shift;
	output reg[7:0]asc;
	reg [7:0] ram [255:0];

	initial  $readmemh("m1.txt", ram, 0, 255);
	
	always @ (*) begin
		if(caps&&shift==0) begin
			if(ram[key]>8'h60)asc=ram[key]-32;
			else asc=ram[key];
		end
		else if(caps==0&&shift)begin
			if(ram[key]>8'h60)asc=ram[key]-32;
			else if(key==74)asc=63;
			else if(key==22)asc=33;
			else if(key==30)asc=64;
			else if(key==38)asc=35;
			else if(key==37)asc=36;
			else if(key==46)asc=37;
			else if(key==54)asc=94;
			else if(key==61)asc=38;
			else if(key==62)asc=42;
			else if(key==78)asc=95;
			else if(key==14)asc=126;
			else if(key==65)asc=60;
			else if(key==93)asc=124;
			else if(key==73)asc=62;
			else if(key==76)asc=58;
			else if(key==82)asc=34;
			else if(key==85)asc=43;
			else if(key==84)asc=123;
			else if(key==91)asc=125;
			else if(key==74)asc=63;
			else if(key==70)asc=40;
			else if(key==69)asc=41;
			else asc=ram[key];
		end
		else if(caps&&shift)begin
			if(ram[key]>8'h60)asc=ram[key];
			else if(key==74)asc=63;
			else if(key==22)asc=33;
			else if(key==30)asc=64;
			else if(key==38)asc=35;
			else if(key==37)asc=36;
			else if(key==46)asc=37;
			else if(key==54)asc=94;
			else if(key==61)asc=38;
			else if(key==62)asc=42;
			else if(key==78)asc=95;
			else if(key==14)asc=126;
			else if(key==65)asc=60;
			else if(key==93)asc=124;
			else if(key==73)asc=62;
			else if(key==76)asc=58;
			else if(key==82)asc=34;
			else if(key==85)asc=43;
			else if(key==84)asc=123;
			else if(key==91)asc=125;
			else if(key==74)asc=63;
			else if(key==70)asc=40;
			else if(key==69)asc=41;
			else asc=ram[key];
		end
		else asc=ram[key];
		
	end

endmodule




module ps2_keyboard(clk,clrn,ps2_clk,ps2_data,data,
 ready,nextdata_n,overflow);
 input clk,clrn,ps2_clk,ps2_data;
 input nextdata_n;
 output [7:0] data;
 output reg ready;
 output reg overflow; // fifo overflow
 // internal signal, for test
 reg [9:0] buffer; // ps2_data bits
 reg [7:0] fifo[7:0]; // data fifo
 reg [2:0] w_ptr,r_ptr; // fifo write and read pointers
 reg [3:0] count; // count ps2_data bits
 // detect falling edge of ps2_clk
 reg [2:0] ps2_clk_sync;

 always @(posedge clk) begin
 ps2_clk_sync <= {ps2_clk_sync[1:0],ps2_clk};
 end

 wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

 always @(posedge clk) begin
 if (clrn == 0) begin // reset
 count <= 0; w_ptr <= 0; r_ptr <= 0; overflow <= 0; ready<= 0;
 end
 else begin
 if ( ready ) begin // read to output next data
 if(nextdata_n == 1'b0) //read next data
 begin
 r_ptr <= r_ptr + 3'b1;
 if(w_ptr==(r_ptr+1'b1)) //empty
 ready <= 1'b0;
 end
 end
 if (sampling) begin
 if (count == 4'd10) begin
 if ((buffer[0] == 0) && // start bit
 (ps2_data) && // stop bit
 (^buffer[9:1])) begin // odd parity
 fifo[w_ptr] <= buffer[8:1]; // kbd scan code
 w_ptr <= w_ptr+3'b1;
 ready <= 1'b1;
 overflow <= overflow | (r_ptr == (w_ptr + 3'b1));
 end
 count <= 0; // for next
 end else begin
 buffer[count] <= ps2_data; // store ps2_data
 count <= count + 3'b1;
 end
 end
 end
 end
 assign data = fifo[r_ptr]; //always set output data

 endmodule