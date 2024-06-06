
////////////////////////////////////////////////////////////////////////
module breakout_videogen(
	input clk,
	input [9:0] PaddleX,
	output reg DrawArea, hSync, vSync, 
	output red, green, blue,
	output reg Collision, BrickHit
);

//localparam ballspeed = 2; // ball moves 4 pixels per frame
localparam ballspeed = 3; // ball moves 8 pixels per frame
reg [9:0] ballX = 100;  // initial ball position
reg [8:0] ballY = 300;
reg ball_dirX, ball_dirY;

////////////////////////////////////////////////////////////////////////
parameter hDrawArea = 640;
parameter hSyncPorch = 16;
parameter hSyncLen = 96;
parameter hFrameSize = 800;

parameter vDrawArea = 480;
parameter vSyncPorch = 10;
parameter vSyncLen = 2;
parameter vFrameSize = 525;

reg [9:0] CounterX;
reg [8:0] CounterY;
always @(posedge clk) CounterX <= (CounterX==hFrameSize-1) ? 10'd0 : CounterX+10'd1;
always @(posedge clk) if(CounterX==hFrameSize-1) CounterY <= (CounterY==vFrameSize-1) ? 9'd0 : CounterY+9'd1;
always @(posedge clk) DrawArea <= (CounterX<hDrawArea) & (CounterY<vDrawArea);
always @(posedge clk) hSync <= (CounterX>=hDrawArea+hSyncPorch) & (CounterX<hDrawArea+hSyncPorch+hSyncLen);
always @(posedge clk) vSync <= (CounterY>=vDrawArea+vSyncPorch) & (CounterY<vDrawArea+vSyncPorch+vSyncLen);

////////////////////////////////////////////////////////////////////////
wire DrawBall, DrawBorder, DrawPaddle, DrawBrick, BrickHit_now, BrickHit_acq;
reg RestoreBrickwall = 1'b1;
reg MoveBall;
breakout_playfield #(hDrawArea, vDrawArea) game(
	.clk(clk),
	.PaddleX(PaddleX),
	.CounterX(MoveBall ? ballX + {6'h00, {4{CounterX[0]}}} : CounterX),
	.CounterY(MoveBall ? ballY + {5'h00, {4{CounterX[1]}}} : CounterY),
	.ballX(ballX),
	.ballY(ballY),
	.DrawBall(DrawBall), .DrawBorder(DrawBorder), .DrawPaddle(DrawPaddle), .DrawBrick(DrawBrick),
	.BrickHit_now(BrickHit_now), .BrickHit_acq(BrickHit_acq), .RestoreBrickwall(RestoreBrickwall)
);

// we are going to update the ball position during offscreen timing
wire FrameTick = (CounterX==hFrameSize-1) & (CounterY==vDrawArea-1);
always @(posedge clk) MoveBall <= MoveBall ? ~&CounterX[ballspeed+2:0] : FrameTick;
wire BounceableOject = DrawBorder | DrawPaddle | DrawBrick;
reg [3:0] HBC;  always @(posedge clk) HBC <= {BounceableOject, HBC[3:1]};  // record the ball corners hits in HBC (HotBallCorner)
wire [15:0] updateDirX = 16'b01101101_10110110;  // and update the ball direction if needed
wire [15:0] updateDirY = 16'b01111001_10011110;
always @(posedge clk) if(MoveBall & CounterX[2:0]==3'h5 & updateDirX[HBC]) ball_dirX <= (~HBC[0] &  HBC[1]) | (~HBC[2] & HBC[3]);
always @(posedge clk) if(MoveBall & CounterX[2:0]==3'h5 & updateDirY[HBC]) ball_dirY <= (~HBC[0] & ~HBC[1]) | ( HBC[2] & HBC[3]);
always @(posedge clk) if(MoveBall & CounterX[2:0]==3'h7) ballX <= ballX + {{9{ball_dirX}}, 1'b1};  // and then the ball position
always @(posedge clk) if(MoveBall & CounterX[2:0]==3'h7) ballY <= ballY + {{8{ball_dirY}}, 1'b1};

// then get stats on ball collisions and brick hits
reg [2:0] BHA;  always @(posedge clk) BHA <= {DrawBrick, BHA[2:1]};
assign BrickHit_now = MoveBall & CounterX[2] & BHA[0];
always @(posedge clk) if(FrameTick) BrickHit<=1'b0; else if(BrickHit_now) BrickHit<=1'b1;
reg [7:0] BrickHit_count=0;  always @(posedge clk) BrickHit_count <= RestoreBrickwall ? 8'h00 : BrickHit_count + BrickHit_acq;
always @(posedge clk) RestoreBrickwall <= RestoreBrickwall ? ~FrameTick : (BrickHit_count==19*7) & ballY[8];
always @(posedge clk) if(FrameTick) Collision<=1'b0; else if(MoveBall & CounterX[2] & HBC[1]) Collision<=1'b1;

wire DrawAll = DrawBall | DrawBorder | DrawPaddle | DrawBrick;
assign red = DrawBrick;
assign green = DrawAll;
assign blue = DrawAll;
endmodule
