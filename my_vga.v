module VGA(memop,rst,CLOCK_50,clock,get_data,waddr,wren,hsync,vsync,valid,vga_r,vga_g,vga_b,VGA_CLK);      
	input [2:0]memop;                                 //vga的主模块，其中例化了变频模块，手册中提供的vga_ctrl模块，显存模块vga_mem
	input rst;
	input [31:0]get_data;
	input [12:0]waddr;
	input CLOCK_50;
	input wren;
	input clock;
	output hsync;
	output vsync;
	output valid;
	output [7:0]vga_r;
	output [7:0]vga_g;
	output [7:0]vga_b;
	output VGA_CLK;
	reg off;
	reg [18:0]addr;
	
	wire [7:0]ascii_key;
	wire [9:0]h_addr;
	wire [9:0]v_addr;
	wire paclk;
	reg [11:0]data;
	reg [12:0]count;
	reg [10:0]lie;
	reg [14:0]locate;
	reg [7:0]word1;
	reg [11:0]word;
	reg [7:0]down;	
	reg we;
	reg re;
	reg [7:0]dataa;
	reg [7:0]temp_key;
	reg [12:0]count_t;
	reg [12:0]rcount;
	wire [31:0] dout0;
	reg [7:0] dout1;
	wire [6:0]h_char;
   wire [4:0] v_char;
   wire [3:0] h_font;
   wire [3:0]v_font;
	reg [12:0]raddr;
	reg [3:0]bytee;
	reg  [7:0] line;
	reg  [7:0] hang;
	clkgen #(25000000) my_vgaclk(CLOCK_50,rst,1'b1,VGA_CLK);
	vga_ctrl maw(VGA_CLK,rst,data,h_addr,v_addr,hsync,vsync,valid,vga_r,vga_g,vga_b,h_char,v_char,h_font,v_font);
	(* ramstyle = "M10K" *)(* ram_init_file = "font.mif" *) reg [11:0] qdata [4095:0];
	//(* ramstyle = "M10K" *)reg [7:0]memory[2594:0];
	vga_mem my_VGA(waddr,raddr,dout0,get_data,VGA_CLK,clock,memop,wren);      //显存模块
	
 initial begin
	 dout1=0;
end
	
	
	always @ (posedge VGA_CLK ) begin                         //该always块用于向显示提供色彩数据
		
		raddr<=v_char*71+h_char;
		if(raddr[1:0]==0)dout1<=dout0[7:0];
		else if(raddr[1:0]==1)dout1<=dout0[15:8];
		else if(raddr[1:0]==2)dout1<=dout0[23:16];
		else dout1<=dout0[31:24];
		//dout1<=dout0[7:0];
		word<=qdata[dout1*16+v_font];
		if(word[h_font-2]==1)data<=12'hfff;
		else data<=12'h000;
	end

	
endmodule



module vga_ctrl(                                           //以下为手册提供的标准函数
 input pclk, //25MHz时钟
 input reset, //置位
 input [11:0] vga_data, // 上 层 模 块 提 供 的 VGA颜色数据
 output [9:0] h_addr, // 提 供 给 上 层 模 块 的 当 前 扫 描 像 素 点 坐 标
 output [9:0] v_addr,
 output hsync, // 行 同 步 和 列 同 步 信 号
 output vsync,
 output valid, //消隐信号
 output [7:0] vga_r, // 红 绿 蓝 颜 色 信 号
 output [7:0] vga_g,
 output [7:0] vga_b,
 output reg [6:0]h_char,
 output [4:0] v_char,
 output reg [3:0] h_font,
 output [3:0]v_font
 );

 //640x480 分辨 率 下的 VGA参数设置
 parameter h_frontporch = 96;
 parameter h_active = 144;
 parameter h_backporch = 784;
 parameter h_total = 800;

 parameter v_frontporch = 2;
 parameter v_active = 35;
 parameter v_backporch = 515;
 parameter v_total = 525;

 // 像素 计 数值
 reg [9:0] x_cnt;
 reg [9:0] y_cnt;
 wire h_valid;
 wire v_valid;
 wire [9:0]v_modi;
 
 always @ (posedge pclk)
	if(h_valid==1'b0)
		begin h_char<=6'b0;h_font<=4'b0;end
	else 
	begin 
		if(h_font>=4'd8)
		begin
			h_char <= h_char + 6'd1;
			h_font <= 4'd0;
		end
		else 
		begin
			h_font <= h_font+4'd1;
		end
	end
	
	assign v_char = v_modi[8:4];
	assign v_font = v_modi[3:0];
	
	assign v_modi = v_valid ? (y_cnt-10'd36) : {10{1'b0}};

 always @(posedge reset or posedge pclk) // 行像 素 计数
 if (reset == 1'b1)

 x_cnt <= 1;
 else
 begin
 if (x_cnt == h_total)
 x_cnt <= 1;
 else
 x_cnt <= x_cnt + 10'd1;
 end

 always @(posedge pclk) // 列像 素 计数
 if (reset == 1'b1)
 y_cnt <= 1;
 else
 begin
 if (y_cnt == v_total & x_cnt == h_total)
 y_cnt <= 1;
 else if (x_cnt == h_total)
 y_cnt <= y_cnt + 10'd1;
 end
 // 生 成 同 步 信 号
 assign hsync = (x_cnt > h_frontporch);
 assign vsync = (y_cnt > v_frontporch);
 // 生 成 消 隐 信 号
 assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
 assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
 assign valid = h_valid & v_valid;
 // 计 算 当 前 有 效 像 素 坐 标
 assign h_addr = h_valid ? (x_cnt - 10'd145) : {10{1'b0}};
 assign v_addr = v_valid ? (y_cnt - 10'd36) : {10{1'b0}};
 // 设 置 输 出 的 颜 色 值
 assign vga_r = {vga_data[11:8],4'b0000};
 assign vga_g = {vga_data[7:4],4'b0000};
 assign vga_b = {vga_data[3:0],4'b0000};
 endmodule

module clkgen(
 input clkin,
 input rst,
 input clken,
 output reg clkout
 );
 parameter clk_freq=1000;
 parameter countlimit=50000000/2/clk_freq; // 自 动 计 算 计 数 次 数

 reg[31:0] clkcount;
 always @ (posedge clkin)
 if(rst)
 begin
 clkcount=0;
 clkout=1'b0;
 end
 else
 begin
 if(clken)
 begin
 clkcount=clkcount+1;
 if(clkcount>=countlimit)
 begin
 clkcount=32'd0;
 clkout=~clkout;
 end
 else
 clkout=clkout;
 end
 else
 begin
 clkcount=clkcount;
 clkout=clkout;
 end
 end
 endmodule