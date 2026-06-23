`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2026 08:16:53 PM
// Design Name: 
// Module Name: pilot_insertion
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
// Khai báo ??n v? th?i gian mô ph?ng là 1ns
// Khai báo ?? chính xác th?i gian mô ph?ng là 1ps


module pilot_insertion #(
    parameter WIDTH = 16
    // WIDTH là ?? r?ng bit c?a m?i thành ph?n I ho?c Q
    // Trong thi?t k? này ta dùng signed 16-bit cho I và Q
)(
    input  wire                         clk,
    // Clock h? th?ng

    input  wire                         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? output v? 0

    input  wire                         symbol_valid_in,
    // Tín hi?u báo r?ng i_symbol_bus và q_symbol_bus ??u vào ?ang h?p l?

    input  wire [4*WIDTH-1:0]           i_symbol_bus,
    // Bus ch?a 4 symbol d? li?u thành ph?n I t? Symbol Generator
    // T?ng ?? r?ng = 4 * WIDTH = 64 bit n?u WIDTH = 16

    input  wire [4*WIDTH-1:0]           q_symbol_bus,
    // Bus ch?a 4 symbol d? li?u thành ph?n Q t? Symbol Generator
    // T?ng ?? r?ng = 4 * WIDTH = 64 bit n?u WIDTH = 16

    output reg  [8*WIDTH-1:0]           i_freq_bus,
    // Bus ??u ra ch?a 8 subcarrier thành ph?n I sau khi chèn pilot
    // T?ng ?? r?ng = 8 * WIDTH = 128 bit n?u WIDTH = 16

    output reg  [8*WIDTH-1:0]           q_freq_bus,
    // Bus ??u ra ch?a 8 subcarrier thành ph?n Q sau khi chèn pilot
    // T?ng ?? r?ng = 8 * WIDTH = 128 bit n?u WIDTH = 16

    output reg                          pilot_valid_out
    // Tín hi?u báo r?ng i_freq_bus và q_freq_bus ??u ra ?ã h?p l?
);


    // ============================================================
    // 1. Khai báo giá tr? pilot
    // ============================================================
    //
    // Ta ?ã ch?t pilot:
    //
    //      P0 = 1024 + j0
    //      P1 = 1024 + j0
    //
    // Vì v?y:
    //
    //      Pilot ph?n I = 1024
    //      Pilot ph?n Q = 0
    //

    localparam signed [WIDTH-1:0] PILOT_I = 16'sd1024;
    // Thành ph?n I c?a pilot
    // Giá tr? này b?ng A = 1024 trong h? 16-QAM ?ã ch?n

    localparam signed [WIDTH-1:0] PILOT_Q = 16'sd0;
    // Thành ph?n Q c?a pilot
    // Ta ch?n pilot n?m hoàn toàn trên tr?c I ?? ??n gi?n hóa ??c l??ng kênh


    // ============================================================
    // 2. Tách 4 symbol d? li?u t? Symbol Generator
    // ============================================================
    //
    // Symbol Generator ?ã ?óng gói bus nh? sau:
    //
    //      i_symbol_bus[15:0]   = D0_I
    //      i_symbol_bus[31:16]  = D1_I
    //      i_symbol_bus[47:32]  = D2_I
    //      i_symbol_bus[63:48]  = D3_I
    //
    // T??ng t? cho q_symbol_bus.
    //

    wire signed [WIDTH-1:0] d0_i;
    // Thành ph?n I c?a data symbol D0

    wire signed [WIDTH-1:0] d1_i;
    // Thành ph?n I c?a data symbol D1

    wire signed [WIDTH-1:0] d2_i;
    // Thành ph?n I c?a data symbol D2

    wire signed [WIDTH-1:0] d3_i;
    // Thành ph?n I c?a data symbol D3

    wire signed [WIDTH-1:0] d0_q;
    // Thành ph?n Q c?a data symbol D0

    wire signed [WIDTH-1:0] d1_q;
    // Thành ph?n Q c?a data symbol D1

    wire signed [WIDTH-1:0] d2_q;
    // Thành ph?n Q c?a data symbol D2

    wire signed [WIDTH-1:0] d3_q;
    // Thành ph?n Q c?a data symbol D3


    assign d0_i = i_symbol_bus[0*WIDTH +: WIDTH];
    // L?y D0_I t? i_symbol_bus[15:0]

    assign d1_i = i_symbol_bus[1*WIDTH +: WIDTH];
    // L?y D1_I t? i_symbol_bus[31:16]

    assign d2_i = i_symbol_bus[2*WIDTH +: WIDTH];
    // L?y D2_I t? i_symbol_bus[47:32]

    assign d3_i = i_symbol_bus[3*WIDTH +: WIDTH];
    // L?y D3_I t? i_symbol_bus[63:48]


    assign d0_q = q_symbol_bus[0*WIDTH +: WIDTH];
    // L?y D0_Q t? q_symbol_bus[15:0]

    assign d1_q = q_symbol_bus[1*WIDTH +: WIDTH];
    // L?y D1_Q t? q_symbol_bus[31:16]

    assign d2_q = q_symbol_bus[2*WIDTH +: WIDTH];
    // L?y D2_Q t? q_symbol_bus[47:32]

    assign d3_q = q_symbol_bus[3*WIDTH +: WIDTH];
    // L?y D3_Q t? q_symbol_bus[63:48]


    // ============================================================
    // 3. Logic chính c?a kh?i Pilot Insertion
    // ============================================================
    //
    // Khi symbol_valid_in = 1:
    //
    //      X[0] = 0
    //      X[1] = P0
    //      X[2] = D0
    //      X[3] = D1
    //      X[4] = D2
    //      X[5] = D3
    //      X[6] = P1
    //      X[7] = 0
    //
    // Trong ?ó:
    //
    //      P0 = 1024 + j0
    //      P1 = 1024 + j0
    //

    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên c?a clock
        // ho?c t?i c?nh xu?ng c?a reset rst_n

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset h? th?ng

            i_freq_bus <= {8*WIDTH{1'b0}};
            // Reset toàn b? bus I ??u ra v? 0

            q_freq_bus <= {8*WIDTH{1'b0}};
            // Reset toàn b? bus Q ??u ra v? 0

            pilot_valid_out <= 1'b0;
            // Khi reset thì output ch?a h?p l?
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (symbol_valid_in) begin
                // Ch? chèn pilot khi d? li?u t? Symbol Generator h?p l?

                i_freq_bus[0*WIDTH +: WIDTH] <= {WIDTH{1'b0}};
                // X_I[0] = 0
                // ?ây là subcarrier guard bên trái

                q_freq_bus[0*WIDTH +: WIDTH] <= {WIDTH{1'b0}};
                // X_Q[0] = 0
                // Vì X[0] = 0 + j0


                i_freq_bus[1*WIDTH +: WIDTH] <= PILOT_I;
                // X_I[1] = P0_I = 1024
                // ?ây là pilot th? nh?t

                q_freq_bus[1*WIDTH +: WIDTH] <= PILOT_Q;
                // X_Q[1] = P0_Q = 0
                // Pilot P0 = 1024 + j0


                i_freq_bus[2*WIDTH +: WIDTH] <= d0_i;
                // X_I[2] = D0_I
                // Subcarrier s? 2 ch?a data symbol D0

                q_freq_bus[2*WIDTH +: WIDTH] <= d0_q;
                // X_Q[2] = D0_Q
                // Ph?n Q c?a data symbol D0


                i_freq_bus[3*WIDTH +: WIDTH] <= d1_i;
                // X_I[3] = D1_I
                // Subcarrier s? 3 ch?a data symbol D1

                q_freq_bus[3*WIDTH +: WIDTH] <= d1_q;
                // X_Q[3] = D1_Q
                // Ph?n Q c?a data symbol D1


                i_freq_bus[4*WIDTH +: WIDTH] <= d2_i;
                // X_I[4] = D2_I
                // Subcarrier s? 4 ch?a data symbol D2

                q_freq_bus[4*WIDTH +: WIDTH] <= d2_q;
                // X_Q[4] = D2_Q
                // Ph?n Q c?a data symbol D2


                i_freq_bus[5*WIDTH +: WIDTH] <= d3_i;
                // X_I[5] = D3_I
                // Subcarrier s? 5 ch?a data symbol D3

                q_freq_bus[5*WIDTH +: WIDTH] <= d3_q;
                // X_Q[5] = D3_Q
                // Ph?n Q c?a data symbol D3


                i_freq_bus[6*WIDTH +: WIDTH] <= PILOT_I;
                // X_I[6] = P1_I = 1024
                // ?ây là pilot th? hai

                q_freq_bus[6*WIDTH +: WIDTH] <= PILOT_Q;
                // X_Q[6] = P1_Q = 0
                // Pilot P1 = 1024 + j0


                i_freq_bus[7*WIDTH +: WIDTH] <= {WIDTH{1'b0}};
                // X_I[7] = 0
                // ?ây là subcarrier guard bên ph?i

                q_freq_bus[7*WIDTH +: WIDTH] <= {WIDTH{1'b0}};
                // X_Q[7] = 0
                // Vì X[7] = 0 + j0


                pilot_valid_out <= 1'b1;
                // Báo r?ng frame t?n s? sau khi chèn pilot ?ã h?p l?
            end

            else begin
                // N?u symbol_valid_in = 0 thì không có symbol m?i c?n x? lý

                pilot_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là frame m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module pilot_insertion
