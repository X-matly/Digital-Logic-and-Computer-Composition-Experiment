module vga_mem(                                   //与数据处理器几乎一样，有些许改动
	input [12:0]waddr,
	input  [12:0] raddr,
	output reg [31:0] dataout,
	input  [31:0] datain,
	input  rdclk,
	input  wrclk,
	input [2:0] memop,
	input we);
	reg [3:0] bytee;
	wire [31:0] tempout;
	reg [1:0] loc;
	reg [1:0]locc;
	reg [31:0]datainq;
//testdmem A(bytee,datainq,,rdclk,,wrclk,we,tempout);
RAM_VGA my_vga_ram(bytee,datainq,{2'b0,raddr[12:2]},rdclk,{2'b0,waddr[12:2]},wrclk,we,tempout);
initial begin
	bytee=0;
end


always @ (*) begin
	loc=waddr[1:0];
	//locc=raddr[1:0];
	if(memop==0) begin
		dataout=tempout;
		if(loc==0) begin 
		//dataout={{24{tempout[7]}},tempout[7:0]};
		datainq=datain;
		bytee=1;
		end
		else if(loc==1)  begin
		//dataout={{24{tempout[15]}},tempout[15:8]};
		datainq={16'b0,datain[7:0],8'b0};
		bytee=2;
		end
		else if(loc==2) begin
		//dataout={{24{tempout[23]}},tempout[23:16]};
		datainq={8'b0,datain[7:0],16'b0};
		bytee=4;
		end
		else if(loc==3)begin 
		//dataout={{24{tempout[31]}},tempout[31:24]};
		datainq={datain[7:0],24'b0};
		bytee=8;
		end
		/*if(locc==0)dataout={{24{tempout[7]}},tempout[7:0]};
		else if(locc==1)dataout={{24{tempout[15]}},tempout[15:8]};
		else if(locc==2)dataout={{24{tempout[23]}},tempout[23:16]};
		else dataout={{24{tempout[31]}},tempout[31:24]};*/
	end
	else if(memop==1) begin
		if(loc==0) begin 
		//dataout={{16{tempout[15]}},tempout[15:0]};
		dataout=tempout;
		datainq=datain;
		bytee=3;
		end
		else if(loc==2) begin
		//dataout={{16{tempout[31]}},tempout[31:16]};
		dataout=tempout;
		datainq={datain[15:0],16'b0};
		bytee=12;
		end
		/*if(locc==0)dataout={{16{tempout[15]}},tempout[15:0]};
		else if(locc==2)dataout={{16{tempout[31]}},tempout[31:16]};*/
	end
	else if(memop==2) begin
		dataout=tempout;
		datainq=datain;
		bytee=15;
	end
	else if(memop==4) begin
		dataout=tempout;
	end
	else if(memop==5) begin
		dataout=tempout;
	end
end

endmodule

 