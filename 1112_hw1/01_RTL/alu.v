/***************************************************************************

File Name                                    : alu.v
Author                                       : Rui Tung Lee
Version                                      : 1.0
Module(s) Instantiated in this file          : none
Module(s) which instantiates this module     : none
Project                                      : CVSD NTU ICLAB HW1
Created on                                   : Mar 20, 2023
Last modified on                             : Mar 22, 2023
Last modified by                             :
Description                                  :
I3 need to be debugged but I'm tired QQ
****************************************************************************/
module alu #(
    parameter INT_W  = 4,
    parameter FRAC_W = 6,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,
    input                     i_valid,
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output       [DATA_W-1:0] o_data
); // Do not modify
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg [DATA_W-1:0] o_data_w, o_data_r;
reg              o_valid_w, o_valid_r;
// ---- Add your own wires and registers here if needed ---- //



// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
// ---- Add your own wire data assignments here if needed ---- //

reg [9:0] o_data_t; // out data temp;
// ---------------------------------------------------------------------------
//inst 0
// ---------------------------------------------------------------------------
wire [9 : 0] sum_temp;
assign sum_temp = i_data_a + i_data_b;

// ---------------------------------------------------------------------------
//inst 1
// ---------------------------------------------------------------------------
wire [9 : 0] sub_temp;
assign sub_temp = i_data_a - i_data_b;

// ---------------------------------------------------------------------------
//inst 2
// ---------------------------------------------------------------------------
wire signed [19:0] mult_temp;
wire round;
reg signed [9:0] mult_r;
assign mult_temp = i_data_a * i_data_b;
assign round = (mult_temp[5] == 1'b1)? 1'b1:1'b0;

// ---------------------------------------------------------------------------
//inst 3
// ---------------------------------------------------------------------------
wire signed [19:0] i_data_f;
wire signed [20:0] o_data_f;
wire round_f;
reg signed [9:0] mult_f;
assign i_data_f = {{4{o_data_r[9]}},o_data,6'b0};
assign o_data_f = $signed(i_data_f) + $signed(mult_temp);
assign round_f = (o_data_f[5] == 1'b1)? 1'b1:1'b0;
// ---------------------------------------------------------------------------

always@(*)begin
    case(i_inst)
        4'd0:begin // Signed ADD ,signed add with 4bits int and 6bits fraction
            if((sum_temp[9] == 1'b1) && (i_data_a[9] == 1'b0) && (i_data_b[9] == 1'b0)) o_data_t = 10'b0111_1111_11;
            else if ((sum_temp[9] == 1'b0) && (i_data_a[9] == 1'b1) && (i_data_b[9] == 1'b1)) o_data_t = 10'b1000_0000_00;
            else if (sum_temp == 10'b1000_0000_00) o_data_t = 10'b0000_0000_00;
            else o_data_t = sum_temp;
        end
        4'd1:begin //Signed sub
            if((sub_temp[9] == 1'b1) && (i_data_a[9] == 1'b0 ) && (i_data_b[9] == 1'b1)) o_data_t = 10'b0111_1111_11;
            else if ((sub_temp[9] == 1'b0) && (i_data_a[9] == 1'b1) && (i_data_b[9] == 1'b0)) o_data_t = 10'b1000_0000_00;
            else if (sub_temp == 10'b1000_0000_00) o_data_t = 10'b0000_0000_00;
            else o_data_t = sub_temp;
        end
        4'd2:begin // signed mult
            case(mult_temp[19])
            1'b0:begin
                if (round) mult_r = $signed({1'b0,mult_temp[14:12],mult_temp[11:6]}) + $signed(10'b0000_0000_01);
                else mult_r =  $signed({1'b0,mult_temp[14:12],mult_temp[11:6]});
            end
            default:begin
                if (round) mult_r = $signed({1'b1,mult_temp[14:12],mult_temp[11:6]}) + $signed(10'b0000_0000_01);
                else mult_r =  $signed({1'b1,mult_temp[14:12],mult_temp[11:6]}) ;
            end
            endcase
            case({mult_r[9],i_data_a[9],i_data_b[9]}) // overflow dection
            3'b001: o_data_t = 10'b1000_0000_00;
            3'b010: o_data_t = 10'b1000_0000_00;
            3'b111: o_data_t = 10'b0111_1111_11;
            3'b100: o_data_t = 10'b0111_1111_11;
            default: begin
                if(!mult_r[9] && (mult_temp[19:6] >= 14'b0000_0111_1111_11))  o_data_t = 10'b0111_1111_11;
                else if(mult_r[9] && ($signed(mult_temp[19:6]) <= $signed(14'b1111_1000_0000_00))) o_data_t = 10'b1000_0000_00;
                else o_data_t = mult_r;
            end
            endcase
        end
        
        4'd3:begin //改天想寫再說囉
            case(o_data_f[20])
            1'b0:begin
                if (round_f) mult_f = $signed({1'b0,o_data_f[14:12],o_data_f[11:6]}) + $signed(10'b0000_0000_01);
                else mult_f =  $signed({1'b0,o_data_f[14:12],o_data_f[11:6]});
            end
            default:begin
                if (round_f) mult_f = $signed({1'b1,o_data_f[14:6]}) + $signed(10'b0000_0000_01);
                else mult_f = $signed({1'b1,o_data_f[14:6]});
            end
            endcase
            case({mult_f[9],i_data_f[19],mult_temp[19]}) //overflow dection
            3'b011: o_data_t = 10'b1000_0000_00;
            3'b100: o_data_t = 10'b0111_1111_11;
            default:begin
                if(!mult_f[9] && ((o_data_f[20:6]) >= 15'b00000_0111_1111_11)) o_data_t = 10'b0111_1111_11;
                else if(mult_f[9] && ($signed(mult_f[20:6])) <= $signed(15'b1111_1000_0000_00)) o_data_t = 10'b1000_0000_00;
                else o_data_t = mult_f;
            end
            endcase
            
        end
        4'd4:begin //tanh
            if(!i_data_a[9])begin
                if(i_data_a >= 10'b0001_1000_00) o_data_t = 10'b0001_0000_00;
                else if(i_data_a >= 10'b0000_1000_00)begin
                    if(i_data_a[0]) o_data_t = ((i_data_a - 10'b0000_1000_00)>> 1 ) + 10'b0000_1000_01;
                    else            o_data_t = ((i_data_a - 10'b0000_1000_00)>> 1) + 10'b0000_1000_00;
                end
                else o_data_t = i_data_a;
            end
            else begin
                if(i_data_a >= 10'b1111_100000) o_data_t = i_data_a;
                else if(i_data_a >= 10'b1110_1000_00) 
                    if(i_data_a[0]) o_data_t = ((i_data_a + $signed(10'b0000_1000_00)) >>> 1) - $signed(10'b0000_1000_01) ;
                    else            o_data_t = ((i_data_a + $signed(10'b0000_1000_00)) >>> 1) - $signed(10'b0000_1000_00) ;
                else o_data_t = 10'b1111_0000_00;
            end
        end
        
        4'd5:begin //ORN
            o_data_t = i_data_a | (~i_data_b);
        end
        4'd6:begin //CLZ
            casex(i_data_a)
            10'b1???_????_??: o_data_t = 10'd0;
            10'b01??_????_??: o_data_t = 10'd1;
            10'b001?_????_??: o_data_t = 10'd2;
            10'b0001_????_??: o_data_t = 10'd3;
            10'b0000_1???_??: o_data_t = 10'd4;
            10'b0000_01??_??: o_data_t = 10'd5;
            10'b0000_001?_??: o_data_t = 10'd6;
            10'b0000_0001_??: o_data_t = 10'd7;
            10'b0000_0000_1?: o_data_t = 10'd8;
            10'b0000_0000_01: o_data_t = 10'd9;
            10'd0: o_data_t = 10'd10;
            endcase
        end
        4'd7:begin //ROL
            casex(i_data_a)
            10'd0: o_data_t = 10'd0;
            10'b????_????_?1: o_data_t = 10'd0;
            10'b????_????_10: o_data_t = 10'd1;
            10'b????_???1_00: o_data_t = 10'd2;
            10'b????_??10_00: o_data_t = 10'd3;
            10'b????_?100_00: o_data_t = 10'd4;
            10'b????_1000_00: o_data_t = 10'd5;
            10'b???1_0000_00: o_data_t = 10'd6;
            10'b??10_0000_00: o_data_t = 10'd7;
            10'b?100_0000_00: o_data_t = 10'd8;
            10'b1000_0000_00: o_data_t = 10'd9;
            endcase
        end
        
        4'd8:begin // CPOP
            o_data_t = i_data_a[9] + i_data_a[8] +i_data_a[7] +i_data_a[6] +i_data_a[5] +i_data_a[4] +i_data_a[3] +i_data_a[2] +i_data_a[1] +i_data_a[0];
        end
        4'd9:begin // ROTATE L ,i_data_b as rotate amount;  
            if(i_data_b == 10'd0) o_data_t = i_data_a;
            else if(i_data_b == 10'd1) o_data_t = {i_data_a[8:0],i_data_a[9]};
            else if(i_data_b == 10'd2) o_data_t = {i_data_a[7:0],i_data_a[9:8]};
            else if(i_data_b == 10'd3) o_data_t = {i_data_a[6:0],i_data_a[9:7]};
            else if(i_data_b == 10'd4) o_data_t = {i_data_a[5:0],i_data_a[9:6]};
            else if(i_data_b == 10'd5) o_data_t = {i_data_a[4:0],i_data_a[9:5]};
            else if(i_data_b == 10'd6) o_data_t = {i_data_a[3:0],i_data_a[9:4]};
            else if(i_data_b == 10'd7) o_data_t = {i_data_a[2:0],i_data_a[9:3]};
            else if(i_data_b == 10'd8) o_data_t = {i_data_a[1:0],i_data_a[9:2]};
            else   o_data_t = {i_data_a[0],i_data_a[9:1]};
        end
    endcase
end

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always@(*) begin
    o_data_w = o_data_t;
    o_valid_w = (i_valid == 1'b1)? 1'b1:1'b0;
end



// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_data_r <= 'b0;
        o_valid_r <= 'b0;
    end 
    else begin
        o_data_r <= o_data_w;
        o_valid_r <= o_valid_w;
    end
end
endmodule



