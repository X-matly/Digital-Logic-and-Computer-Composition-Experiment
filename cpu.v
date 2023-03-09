module cpu(
	input    clk,	
	input  ps2_data,
	input  ps2_clk,
	input 	reset,
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
   wire clock;
	wire sec;
	wire [31:0]get_data;
	wire [12:0]wwaddr;
	wire wren;
	wire [15:0] imemaddr;
	wire [31:0] imemdataout;
	wire 	imemclk;
	wire [14:0] dmemaddr;
	wire [31:0] dmemdataout;
	wire [31:0] dmemdatain;
	wire 	dmemrdclk;
	wire	dmemwrclk;
	wire [2:0] dmemop;
	wire	dmemwe;
	wire [31:0] dbgdata;
	wire  [31:0]PC;
	wire  [31:0]nextPC;
	wire  [6:0]op;
	wire  [4:0]rs1;
	wire  [31:0]rs1_d;
	wire  [31:0]rs2_d;
	wire  [4:0]rs2;
	wire  [4:0]rd;
	wire  [2:0]func3;
	wire  [6:0]func7;
	wire  [2:0]ExtOP;
	wire  RegWr;
	wire  ALUAsrc;
	wire  [1:0]ALUBsrc;
	wire  [3:0]ALUctr;
	wire  [2:0]Branch;
	wire  MemtoReg;
	wire  MemWr;
	wire  [2:0]MemOP;
	wire  [31:0]imm;
	wire  zero;
	wire  less;
	wire  PCAsrc;
	wire  PCBsrc;
	wire  [31:0]dataa;
	wire  [31:0]datab;
	wire  [31:0]aluresult;
	wire  [31:0]data_f;
	wire  [31:0]alldataout;
	wire  [7:0]ascii_key;
	reg   [7:0]temp_key;
	reg   [7:0]locate;
	wire   [31:0]keydataout;
	reg [1:0] loc;
	reg [31:0]tempout;
	reg back;
	reg [31:0]second;
	reg [31:0]minute;
	reg [31:0]hour;
	reg [31:0]timedata;
	reg [7:0]keywaddr;
	wire [7:0]keyraddr;
	reg [31:0]keydatain;
	reg keywe;
clk_human W(clk,clock);//50Mhz降频到10M
clk_second Q(clk,sec);
pc_contral A(clock,reset,PCAsrc,PCBsrc,imm,rs1_d,PC,nextPC);   //CPU组件
opcode_analyse B(imemdataout,op,rs1,rs2,rd,func3,func7);       //cpu
imm_create C(imemdataout,imm,ExtOP);                           //cpu
contral_create D(op,func3,func7,ExtOP,RegWr,Branch,MemtoReg,MemWr,MemOP,ALUAsrc,ALUBsrc,ALUctr);   //cpu
jump_contral E(Branch,zero,less,PCAsrc,PCBsrc);                //cpu
alu F(dataa,datab,ALUctr,less,zero,aluresult);                 //cpu
files myregfile(rs1,rs2,rd,data_f,RegWr,clock,rs1_d,rs2_d);    //cpu
dmem datamem(.addr(dmemaddr),                                  //数据存储器dmem
				 .dataout(dmemdataout), 
				 .datain(dmemdatain), 
				 .rdclk(dmemrdclk), 
				 .wrclk(dmemwrclk), 
				 .memop(dmemop), 
				 .we(dmemwe)); 
				 
imem iimem(imemaddr,imemdataout,imemclk);                      //指令存储器imem
VGA my_vga(MemOP,reset,clk,clock,get_data,wwaddr,wren,hsync,vsync,valid,vga_r,vga_g,vga_b,VGA_CLK);   //vga显示模块
//show A1(k_b_d[locate[7:2]][3:0],s1,reset);                    //测试用七段数码管
//show B1(k_b_d[locate[7:2]][7:4],s2,reset);
keyboard my_keyboard(clk,ps2_clk,!reset,ps2_data,ascii_key);   //键盘模块，按下输出ASCII码，松手输出0
key_dmem my_keydmem(keywaddr,keyraddr,keydataout,keydatain,clock,~clock,MemOP,keywe);
initial begin
	temp_key=0;
	locate=0;
	back=0;
end

always @ (posedge clock) begin            
	if(back==1) begin
		locate<=locate-1;
		back<=2;
	end
	else if(back==2)begin
		if(locate[1:0]==0)k_b_d[locate[15:2]]<={k_b_d[locate[15:2]][31:8],8'b00000000};	
		else if(locate[1:0]==1)k_b_d[locate[15:2]]<={k_b_d[locate[15:2]][31:16],8'b00000000,k_b_d[locate[15:2]][7:0]};
		else if(locate[1:0]==2)k_b_d[locate[15:2]]<={k_b_d[locate[15:2]][31:24],8'b00000000,k_b_d[locate[15:2]][15:0]};	
		else k_b_d[locate[15:2]]<={8'b00000000,k_b_d[locate[15:2]][23:0]};
		locate<=locate-1;
		back<=3;
	end
	else if(back==3) begin
		if(locate[1:0]==0)k_b_d[locate[15:2]]<={k_b_d[locate[15:2]][31:8],8'b00000000};	
		else if(locate[1:0]==1)k_b_d[locate[15:2]]<={k_b_d[locate[15:2]][31:16],8'b00000000,k_b_d[locate[15:2]][7:0]};
		else if(locate[1:0]==2)k_b_d[locate[15:2]]<={k_b_d[locate[15:2]][31:24],8'b00000000,k_b_d[locate[15:2]][15:0]};	
		else k_b_d[locate[15:2]]<={8'b00000000,k_b_d[locate[15:2]][23:0]};
		back<=0;
	end
	if(MemWr==1&&aluresult[31:20]==12'h003)begin
			keywaddr<=aluresult[7:0];
			keydatain<=rs2_d;
			keywe<=1;
	end
	else if(ascii_key!=temp_key&&ascii_key!=0)begin	
		temp_key<=ascii_key;
		keywaddr<=locate;
		keydatain<=ascii_key;
		keywe<=1;	
		locate<=locate+1;
	end
	else if(ascii_key==0) begin
		keywe<=0;
		temp_key<=0;
	end
end

//assign clock=clk;
assign dbgdata=PC;
assign data_f=MemtoReg?alldataout:aluresult;
assign dataa=(ALUAsrc==1)?PC:rs1_d;
assign datab=((ALUBsrc==0)?rs2_d:(ALUBsrc==1?imm:4));
assign imemaddr=nextPC[17:2];
assign imemclk=~clock;
assign dmemaddr=aluresult[14:0];
assign wwaddr=(aluresult[31:20]==12'h002)?aluresult[12:0]:0;
assign keyraddr=(aluresult[31:20]==12'h003)?aluresult[7:0]:0;
assign get_data=(aluresult[31:20]==12'h002)?rs2_d:0;
assign wren=(aluresult[31:20]==12'h002)?MemWr:0;
assign dmemdatain=rs2_d;
assign dmemrdclk=clock;
assign dmemwrclk=~clock;
assign dmemop=MemOP;
assign dmemwe=(aluresult[31:20]==12'h001)?MemWr:0;
assign alldataout=(aluresult[31:20]==12'h003)?keydataout:((aluresult[31:20]==12'h004)?timedata:dmemdataout);

always @ (*) begin                                //该部分为了处理当CPU输出读取地址0x003时，正确地根据memop输出CPU想要的数据，在vga和dmem中都有使用
	if(aluresult[31:20]==12'h004) begin
	loc=aluresult[1:0];
	if(aluresult[3:2]==0)tempout=second;
	else if(aluresult[3:2]==1)tempout=minute;
	else tempout=hour;
	if(MemOP==0) begin
		if(loc==0) begin 
		timedata={{24{tempout[7]}},tempout[7:0]};
		end
		else if(loc==1)  begin
		timedata={{24{tempout[15]}},tempout[15:8]};
		end
		else if(loc==2) begin
		timedata={{24{tempout[23]}},tempout[23:16]};
		end
		else if(loc==3)begin 
		timedata={{24{tempout[31]}},tempout[31:24]};
		end
	end
	else if(MemOP==1) begin
		if(loc==0) begin 
		timedata={{16{tempout[15]}},tempout[15:0]};
		end
		else if(loc==2) begin
		timedata={{16{tempout[31]}},tempout[31:16]};
		end
	end
	else if(MemOP==2) begin
		timedata=tempout;
	end
	else if(MemOP==4) begin
		if(loc==0) timedata={24'b0,tempout[7:0]};
		else if(loc==1)timedata={24'b0,tempout[15:8]};
		else if(loc==2)timedata={24'b0,tempout[23:16]};
		else if(loc==3)timedata={24'b0,tempout[31:24]};
	end
	else if(MemOP==5) begin
		if(loc==0)timedata={16'b0,tempout[15:0]};
		else if(loc==2)timedata={16'b0,tempout[31:16]};
	end
	end
end

always @ (posedge sec) begin
	if(second!=59)begin
		second<=second+1;
	end
	else begin
		second<=0;
		if(minute!=59)begin
			minute<=minute+1;
		end
		else begin
			minute<=0;
			hour<=hour+1;
		end
	end
end


endmodule

module clk_second(clk,clk_h);
	input clk;
	output reg clk_h;
	
	reg [31:0] count_clk;
	
	initial 
		begin
			clk_h=0;
			count_clk=0;
		end
	
	always @ (posedge clk)begin
		if(count_clk==24999999)
		begin 		
				count_clk<=0;
				clk_h<=~clk_h;
		end
		else
				count_clk<=count_clk+1;
		end
endmodule

module clk_human(clk,clk_h);                   //变频（以下模块可以不用看，都是CPU相关）
	input clk;
	output reg clk_h;
	
	reg [31:0] count_clk;
	
	initial 
		begin
			clk_h=0;
			count_clk=0;
		end
	
	always @ (posedge clk)begin
		if(count_clk==4)
		begin 		
				count_clk<=0;
				clk_h<=~clk_h;
		end
		else
				count_clk<=count_clk+1;
		end
endmodule

module jump_contral(Branch,zero,less,PCAsrc,PCBsrc);
	input [2:0]Branch;
	input zero;
	input less;
	output reg PCAsrc;
	output reg PCBsrc;
	
	always @ (*) begin
			if(Branch==0)begin
				PCAsrc=0;
				PCBsrc=0;
			end
			else if(Branch==1)begin
				PCAsrc=1;
				PCBsrc=0;
			end
			else if(Branch==2)begin
				PCAsrc=1;
				PCBsrc=1;
			end
			else if(Branch==4)begin
				if(zero==0) begin
					PCAsrc=0;
					PCBsrc=0;
				end
				else begin
					PCAsrc=1;
					PCBsrc=0;
				end
			end
			else if(Branch==5)begin
				if(zero==0) begin
					PCAsrc=1;
					PCBsrc=0;
				end
				else begin
					PCAsrc=0;
					PCBsrc=0;
				end
			end
			else if(Branch==6)begin
				if(less==0) begin
					PCAsrc=0;
					PCBsrc=0;
				end
				else begin
					PCAsrc=1;
					PCBsrc=0;
				end
			end
			else if(Branch==7)begin
				if(less==0) begin
					PCAsrc=1;
					PCBsrc=0;
				end
				else begin
					PCAsrc=0;
					PCBsrc=0;
				end
			end
	end
endmodule

module files(rs1,rs2,rd,data_f,RegWr,clock,rs1_d,rs2_d);
	input [4:0]rs1;
	input [4:0]rs2;
	input [4:0]rd;
	input [31:0]data_f;
	input RegWr;
	input clock;
	output [31:0]rs1_d;
	output [31:0]rs2_d;

	reg [31:0]regs[127:0];	

	always @ (negedge clock) begin
		if(RegWr) begin
			regs[rd]<=data_f;
		end
	end
	
	assign rs1_d=rs1?regs[rs1]:0;
	assign rs2_d=rs2?regs[rs2]:0;
	
endmodule
	

module contral_create(op,func3,func7,ExtOP,RegWr,Branch,MemtoReg,MemWr,MemOP,ALUAsrc,ALUBsrc,ALUctr);
	input 	[6:0]op;
	input 	[2:0]func3;
	input 	[6:0]func7;
	output 	reg [2:0]ExtOP;
	output  RegWr;
	output  reg [2:0]Branch;
	output  MemtoReg;
	output  MemWr;
	output  [2:0]MemOP;
	output  reg ALUAsrc;
	output  reg [1:0]ALUBsrc;
	output  reg [3:0]ALUctr;

	always @ (*) begin
		if(op[6:2]==13 || op[6:2]==5) ExtOP=1;
		else if(op[6:2]==27) ExtOP=4;
		else if(op[6:2]==24) ExtOP=3;
		else if(op[6:2]==8)  ExtOP=2;
		else ExtOP=0;
		if(op[6]==1)begin
			if(op[6:2]==27) Branch=1;
			else if(op[6:2]==25) Branch=2;
			else if(op[6:2]==24) begin
				if(func3==0) Branch=4;
				else if(func3==1) Branch=5;
				else if(func3==4) Branch=6;
				else if(func3==5) Branch=7;
				else if(func3==6) Branch=6;
				else if(func3==7) Branch=7;
			end
		end
		else begin
			Branch=0;
		end
		if(op[6:2]==5 || op[6:2]==27 || op[6:2]==25) begin
			ALUAsrc=1;
		end
		else ALUAsrc=0;
		if(op[6:2]==24) begin
			if(func3[2:1]==3) begin
				ALUctr=10;
			end	
			else ALUctr=2;
		end
		else if(op[6:2]==12) begin
			if(func3==3) ALUctr=10;
			else ALUctr={func7[5],func3};
		end
		else if(op[6:2]==4) begin
			if(func3==3) ALUctr=10;
			else if(func3==5) ALUctr={func7[5],func3};
			else ALUctr={1'b0,func3};
		end
		else if(op[6:2]==13) ALUctr=3;
		else ALUctr=0;
		if(op[6:2]==12 || op[6:2]==24) begin
			ALUBsrc=0;
		end
		else if(op[6:2]==27 || op[6:2]==25) begin
			ALUBsrc=2;
		end
		else begin
			ALUBsrc=1;
		end
	end

	assign RegWr=(op[6:2]==24 || op[6:2]==8)?0:1;
	assign MemtoReg=(op[6:2]==0)?1:0;
	assign MemWr=(op[6:2]==8)?1:0;
	assign MemOP=(op[6:2]==0 || op[6:2]==8)?func3:0;

endmodule

module pc_contral(clock,reset,PCAsrc,PCBsrc,imm,rs1_d,PC,nextPC);
	input clock;
	input reset;
	input PCAsrc;
	input PCBsrc;
	input [31:0]imm;
	input [31:0]rs1_d;
	output reg [31:0]PC;
	output reg [31:0]nextPC;
	
	initial begin
		PC=0;
		nextPC=0;
	end
	
	always @ (*) begin
		if(reset) begin
			nextPC=0;
		end
		else begin
			if(PCAsrc==0 && PCBsrc==0) begin
				nextPC=PC+4;
			end
			else if(PCAsrc==1 && PCBsrc==0) begin
				nextPC=PC+imm;
			end
			else if(PCAsrc==1 && PCBsrc==1) begin
				nextPC=rs1_d+imm;
			end
		end
	end

	always @ (negedge clock) begin
		if(reset)PC<=0;
		PC<=nextPC;
	end

endmodule

module opcode_analyse(instr,op,rs1,rs2,rd,func3,func7);
	input [31:0]instr;
	output [6:0]op;
	output [4:0]rs1;
	output [4:0]rs2;
	output [4:0]rd;
	output [2:0]func3;
	output [6:0]func7;
	 
	assign op = instr[6:0];
	assign rs1 = instr[19:15];
	assign rs2 = instr[24:20];
	assign rd = instr[11:7];
	assign func3 = instr[14:12];
	assign func7 = instr[31:25];
endmodule

module imm_create(instr,imm,ExtOP);
	input [31:0]instr;
	input [2:0]ExtOP;
	output reg [31:0]imm;
	wire [31:0]immI;
	wire [31:0]immU;
	wire [31:0]immS;
	wire [31:0]immB;
	wire [31:0]immJ;

	assign immI = {{20{instr[31]}}, instr[31:20]};
	assign immU = {instr[31:12], 12'b0};
	assign immS = {{20{instr[31]}}, instr[31:25], instr[11:7]};
	assign immB = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
	assign immJ = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

	always @ (*) begin
		if(ExtOP==0)imm=immI;
		else if(ExtOP==1)imm=immU;
		else if(ExtOP==2)imm=immS;
		else if(ExtOP==3)imm=immB;
		else if(ExtOP==4)imm=immJ;
	end
endmodule

module alu(
	input [31:0] dataa,
	input [31:0] datab,
	input [3:0]  ALUctr,
	output reg less,
	output reg zero,
	output reg [31:0] aluresult);
	reg signed [31:0] temp1;
	reg signed [31:0] temp2;

initial begin
	less=0;
	zero=0;
end

//add your code here
always @ (*)
	if(ALUctr==0)begin
		aluresult=dataa+datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==8)begin
		aluresult=dataa-datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==1)begin
		aluresult=dataa<<datab[4:0];
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==9)begin
		aluresult=dataa<<datab[4:0];
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==2)begin
		temp1=dataa;
		temp2=datab;
		aluresult=temp1<temp2;
		if(dataa==datab)zero=1;
		else zero=0;
		less=aluresult;
	end
	else if(ALUctr==10)begin
		aluresult=dataa<datab;
		if(dataa==datab)zero=1;
		else zero=0;
		less=aluresult;
	end
	else if(ALUctr==3)begin
		aluresult=datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==11)begin
		aluresult=datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==4)begin
		aluresult=dataa^datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==12)begin
		aluresult=dataa^datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==5)begin
		aluresult=dataa>>datab[4:0];
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==13)begin
		aluresult=($signed(dataa))>>>datab[4:0];
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==6)begin
		aluresult=dataa|datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==14)begin
		aluresult=dataa|datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==7)begin
		aluresult=dataa&datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end
	else if(ALUctr==15)begin
		aluresult=dataa&datab;
		if(aluresult==0)zero=1;
		else zero=0;
	end

endmodule