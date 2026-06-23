`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2026 07:57:18 PM
// Design Name: 
// Module Name: qam16_demapper
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
// ??n v? th?i gian mô ph?ng là 1ns
// ?? chính xác th?i gian mô ph?ng là 1ps


module qam16_demapper (
    input  wire               clk,           // Clock h? th?ng
    input  wire               rst_n,         // Reset tích c?c m?c th?p, rst_n = 0 thì reset
    input  wire               symbol_valid,  // Báo hi?u i_in và q_in hi?n t?i h?p l?

    input  wire signed [15:0] i_in,          // Thành ph?n I nh?n ???c sau equalizer
    input  wire signed [15:0] q_in,          // Thành ph?n Q nh?n ???c sau equalizer

    output reg  [3:0]         data_out,      // 4 bit d? li?u sau khi gi?i ?i?u ch?
    output reg                data_valid     // Báo hi?u data_out hi?n t?i h?p l?
);

    // ============================================================
    // 1. Khai báo các ng??ng quy?t ??nh
    // ============================================================
    //
    // ? kh?i 16-QAM Mapper, ta ?ã ch?n:
    //
    //      A = 1024
    //
    // Các m?c biên ?? trên m?i tr?c là:
    //
    //      -3A = -3072
    //      -A  = -1024
    //      +A  = +1024
    //      +3A = +3072
    //
    // Ng??ng quy?t ??nh n?m gi?a các m?c k? nhau:
    //
    //      T1 = (-3072 + -1024) / 2 = -2048
    //      T2 = (-1024 +  1024) / 2 = 0
    //      T3 = ( 1024 +  3072) / 2 = 2048
    //
    // Vì v?y Demapper s? so sánh i_in, q_in v?i:
    //
    //      -2048, 0, +2048
    //

    localparam signed [15:0] TH_NEG_2A = -16'sd2048;
    // Ng??ng -2A, dùng ?? phân bi?t vùng -3A và -A

    localparam signed [15:0] TH_ZERO   =  16'sd0;
    // Ng??ng 0, dùng ?? phân bi?t vùng âm và vùng d??ng

    localparam signed [15:0] TH_POS_2A =  16'sd2048;
    // Ng??ng +2A, dùng ?? phân bi?t vùng +A và +3A


    // ============================================================
    // 2. Hàm quy?t ??nh m?t tr?c I ho?c Q
    // ============================================================
    //
    // Hàm này nh?n vào m?t giá tr? signed 16 bit:
    //
    //      value = i_in ho?c q_in
    //
    // Sau ?ó tr? v? 2 bit theo ?úng b?ng Gray code ?ã dùng ? Mapper:
    //
    //      value < -2048        ? 00
    //      -2048 <= value < 0   ? 01
    //      0 <= value < 2048    ? 11
    //      value >= 2048        ? 10
    //
    // B?ng này chính là ánh x? ng??c c?a Mapper:
    //
    //      00 ? -3072
    //      01 ? -1024
    //      11 ? +1024
    //      10 ? +3072
    //

    function [1:0] decision_1d;
        // Hàm tr? v? 2 bit sau khi quy?t ??nh trên m?t tr?c

        input signed [15:0] value;
        // Giá tr? ??u vào c?n quy?t ??nh, có th? là i_in ho?c q_in

        begin
            // N?u value nh? h?n -2048
            // thì nó g?n m?c -3072 nh?t
            // Gray code t??ng ?ng là 00
            if (value < TH_NEG_2A) begin
                decision_1d = 2'b00;
            end

            // N?u value n?m trong kho?ng [-2048, 0)
            // thì nó g?n m?c -1024 nh?t
            // Gray code t??ng ?ng là 01
            else if (value < TH_ZERO) begin
                decision_1d = 2'b01;
            end

            // N?u value n?m trong kho?ng [0, 2048)
            // thì nó g?n m?c +1024 nh?t
            // Gray code t??ng ?ng là 11
            else if (value < TH_POS_2A) begin
                decision_1d = 2'b11;
            end

            // N?u value l?n h?n ho?c b?ng 2048
            // thì nó g?n m?c +3072 nh?t
            // Gray code t??ng ?ng là 10
            else begin
                decision_1d = 2'b10;
            end
        end
    endfunction


    // ============================================================
    // 3. Logic chính c?a kh?i 16-QAM Demapper
    // ============================================================
    //
    // Kh?i này ho?t ??ng ??ng b? theo clock.
    //
    // Khi symbol_valid = 1:
    //
    //      i_in ???c quy?t ??nh thành 2 bit cao data_out[3:2]
    //      q_in ???c quy?t ??nh thành 2 bit th?p data_out[1:0]
    //
    // Khi symbol_valid = 0:
    //
    //      data_valid = 0
    //      data_out gi? nguyên giá tr? c?
    //

    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ch?y t?i c?nh lên c?a clock
        // ho?c c?nh xu?ng c?a reset rst_n

        if (!rst_n) begin
            // N?u reset ???c kích ho?t, t?c rst_n = 0

            data_out <= 4'b0000;
            // Reset d? li?u ??u ra v? 0

            data_valid <= 1'b0;
            // Reset tín hi?u báo d? li?u h?p l? v? 0
        end

        else begin
            // N?u không reset, h? th?ng ho?t ??ng bình th??ng

            if (symbol_valid) begin
                // Ch? th?c hi?n demapping khi symbol ??u vào h?p l?

                data_out[3:2] <= decision_1d(i_in);
                // Thành ph?n I quy?t ??nh 2 bit cao b3b2

                data_out[1:0] <= decision_1d(q_in);
                // Thành ph?n Q quy?t ??nh 2 bit th?p b1b0

                data_valid <= 1'b1;
                // Báo r?ng data_out hi?n t?i ?ã h?p l?
            end

            else begin
                // N?u symbol_valid = 0 thì không x? lý symbol m?i

                data_valid <= 1'b0;
                // data_out không ???c xem là d? li?u m?i h?p l?

                data_out <= data_out;
                // Gi? nguyên data_out c?
                // Dòng này có th? b? vì thanh ghi t? gi? giá tr? n?u không gán m?i
            end
        end
    end

endmodule

