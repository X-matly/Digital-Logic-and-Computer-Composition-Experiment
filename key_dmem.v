module key_dmem(                             //相当于头歌中的数据存储器
	input  [7:0] waddr,
	input  [7:0] raddr,
	output reg [31:0] dataout,
	input  [31:0] datain,
	input  rdclk,
	input  wrclk,
	input [2:0] memop,
	input we
	);
	
	reg [3:0] bytee;
	reg [1:0]locc;
	wire [31:0] tempout;
	reg [1:0] loc;
	reg [31:0]datainq;

RAM_key my_keydmem(bytee,datainq,{2'b0,raddr[7:2]},rdclk,{2'b0,waddr[7:2]},wrclk,we,tempout);   //IP核，地址高位用来确定写哪个32位，地址低两位用来确定写32位中的哪个字节

initial begin
	bytee=0;
end


always @ (*) begin
	loc=raddr[1:0];
	locc=waddr[1:0];
	if(memop==0) begin
		if(loc==0) begin 
		dataout={{24{tempout[7]}},tempout[7:0]};
		end
		else if(loc==1)  begin
		dataout={{24{tempout[15]}},tempout[15:8]};
		end
		else if(loc==2) begin
		dataout={{24{tempout[23]}},tempout[23:16]};
		end
		else if(loc==3)begin 
		dataout={{24{tempout[31]}},tempout[31:24]};
		end
		if(locc==0) begin 
		datainq=datain;
		bytee=1;
		end
		else if(locc==1)  begin
		datainq={16'b0,datain[7:0],8'b0};
		bytee=2;
		end
		else if(locc==2) begin
		datainq={8'b0,datain[7:0],16'b0};
		bytee=4;
		end
		else if(locc==3)begin 
		datainq={datain[7:0],24'b0};
		bytee=8;
		end
	end
	else if(memop==1) begin
		if(loc==0) begin 
		dataout={{16{tempout[15]}},tempout[15:0]};
		end
		else if(loc==2) begin
		dataout={{16{tempout[31]}},tempout[31:16]};
		end
		if(locc==0) begin 
		datainq=datain;
		bytee=3;
		end
		else if(locc==2) begin
		datainq={datain[15:0],16'b0};
		bytee=12;
		end
	end
	else if(memop==2) begin
		dataout=tempout;
		datainq=datain;
		bytee=15;
	end
	else if(memop==4) begin
		if(loc==0) dataout={24'b0,tempout[7:0]};
		else if(loc==1)dataout={24'b0,tempout[15:8]};
		else if(loc==2)dataout={24'b0,tempout[23:16]};
		else if(loc==3)dataout={24'b0,tempout[31:24]};
	end
	else if(memop==5) begin
		if(loc==0)dataout={16'b0,tempout[15:0]};
		else if(loc==2)dataout={16'b0,tempout[31:16]};
	end
end

endmodule

 