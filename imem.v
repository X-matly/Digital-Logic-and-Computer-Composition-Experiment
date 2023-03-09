module imem(imemaddr,imemdataout,imemclk);
	input [15:0] imemaddr;
	output  [31:0] imemdataout;
	input 	     imemclk;
	
	ram_imem my_rom(.address(imemaddr),
						 .clock(imemclk),
						 .q(imemdataout));
	
endmodule