//SPI Transceiver
//SPI deserializer
//Antonio Sánchez

// FPGA is SPI Slave
// SPI Polarities Mode 0
// CLK idle:low
// CLK edge:rising
// MSb first

`define	IDLE	3'H00;

// NewKey output indicates a new char available
module SPI_Driver(
	input sys_clk,
	//output MISO,
	input MOSI,
	input SPI_CLK,
	input _SS,
	output reg [7:0] Result,
	output reg NewKey);
	
// SPI Sampling prescaler (50MHz->25MHz)
reg int_clk;
always @(posedge sys_clk) int_clk<=int_clk+1'b1;
 	
//	Input pins LowPass filter
reg [1:0] deb_Clk;
reg [1:0] deb_MOSI;
reg [1:0] deb_SS;
reg int_Clk,int_MOSI,int_SS;
always @(posedge sys_clk) begin
	deb_Clk<=deb_Clk+((SPI_CLK)?(deb_Clk<2'h3)?2'h1:2'h0:(deb_Clk>2'h0)?-2'h1:2'h0);
	deb_MOSI<=deb_MOSI+((MOSI)?(deb_MOSI<2'h3)?2'h1:2'h0:(deb_MOSI>2'h0)?-2'h1:2'h0);
	deb_SS<=deb_SS+((_SS)?(deb_SS<2'h3)?2'h1:2'h0:(deb_SS>2'h0)?-2'h1:2'h0);
	int_Clk<=(deb_Clk==2'h3)?1'b1:(deb_Clk==2'h0)?1'b0:int_Clk;
	int_MOSI<=(deb_MOSI==2'h3)?1'b1:(deb_MOSI==2'h0)?1'b0:int_MOSI;
	int_SS<=(deb_SS==2'h3)?1'b1:(deb_SS==2'h0)?1'b0:int_SS;end

// Sample and shift
reg [2:0] State;
reg prev_Clk,sample;
always @(posedge int_clk) begin
	if (int_SS) begin
		State<=`IDLE;
		Result<=8'H00;end
	else begin
	case ({prev_Clk,int_Clk})
		2'b01:	sample<=1'b1;
		2'b11:	if (sample) begin Result<={Result[6:0],int_MOSI};sample<=0;State<=State+3'b1;end
		2'b10:	if (State==3'h7) NewKey<=1'b1;
		2'b00:	NewKey<=1'b0;
	endcase
	prev_Clk<=int_Clk;end;end
endmodule
