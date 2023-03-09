module SimpleOS(	
	input    clk,	
	input  ps2_data,
	input  ps2_clk,
	input  reset,
	output hsync,
	output vsync,
	output valid,
	output [7:0]vga_r,
	output [7:0]vga_g,
	output [7:0]vga_b,
	output VGA_CLK,
	output [6:0]s1,
	output [6:0]s2
	);
//add your code here
cpu mycpu(
				 .clk(clk),                                  
				 .ps2_data(ps2_data), 
				 .ps2_clk(ps2_clk), 
				 .reset(reset), 
				 .hsync(hsync), 
				 .vsync(vsync), 
				 .valid(dmemwe),
				 .vga_r(vga_r),                                  
				 .vga_g(vga_g), 
				 .vga_b(vga_b), 
				 .reset(reset), 
				 .VGA_CLK(VGA_CLK), 
				 .s1(s1), 
				 .s2(s2)); 
  
endmodule