

////////////////////////////////////////////////////////////////////////
module breakout(
	input clk,
	output VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B,
	output [1:0] LED,
	output audioR, audioL
);

wire [9:0] PaddleX;  // paddle position

// if you have a way to control the paddle, make sure to update PaddleX here
assign PaddleX = 10'd900;  // othersise this line puts the paddle off-screen to run the game in demo mode

wire DrawArea, hSync, vSync, red, green, blue, Collision, BrickHit;
breakout_videogen myVideoGen(
	.clk(clk),
	.PaddleX(PaddleX),
	.DrawArea(DrawArea), .hSync(hSync), .vSync(vSync), .red(red), .green(green), .blue(blue),
	.Collision(Collision), .BrickHit(BrickHit)
);

assign VGA_R = DrawArea & red;
assign VGA_G = DrawArea & green;
assign VGA_B = DrawArea & blue;
assign VGA_HS = ~hSync;
assign VGA_VS = ~vSync;
assign LED = {BrickHit, Collision & ~BrickHit};

reg [15:0] audio;  always @(posedge clk)  audio <= audio + Collision + BrickHit;
assign audioR = audio[15];
assign audioL = audio[15];
endmodule
