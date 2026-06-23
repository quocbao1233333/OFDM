`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2026 07:44:29 PM
// Design Name: 
// Module Name: qam16_mapper
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
// Khai báo ??n v? th?i gian mô ph?ng là 1ns, ?? chính xác mô ph?ng là 1ps

module qam16_mapper (
    input  wire              clk,          // Clock h? th?ng
    input  wire              rst_n,        // Reset tích c?c m?c th?p, rst_n = 0 thì reset
    input  wire              data_valid,   // Báo hi?u data_in hi?n t?i h?p l?
    input  wire [3:0]        data_in,      // 4 bit d? li?u ??u vào cho 16-QAM

    output reg  signed [15:0] i_out,       // Thành ph?n In-phase I, có d?u, 16 bit
    output reg  signed [15:0] q_out,       // Thành ph?n Quadrature Q, có d?u, 16 bit
    output reg               symbol_valid  // Báo hi?u i_out và q_out h?p l?
);

    // ------------------------------------------------------------
    // 1. Khai báo các m?c biên ?? cho 16-QAM
    // ------------------------------------------------------------

    localparam signed [15:0] LEVEL_NEG_3 = -16'sd3072;
    // M?c -3A, v?i A = 1024, nên -3A = -3072

    localparam signed [15:0] LEVEL_NEG_1 = -16'sd1024;
    // M?c -A, v?i A = 1024

    localparam signed [15:0] LEVEL_POS_1 =  16'sd1024;
    // M?c +A, v?i A = 1024

    localparam signed [15:0] LEVEL_POS_3 =  16'sd3072;
    // M?c +3A, v?i A = 1024, nên +3A = +3072


    // ------------------------------------------------------------
    // 2. Hàm ánh x? 2 bit sang m?c biên ?? 4-PAM theo Gray code
    // ------------------------------------------------------------

    function signed [15:0] gray_2bit_to_level;
    // Hàm tr? v? m?t giá tr? signed 16 bit

        input [1:0] bits;
        // Input c?a hàm là 2 bit, ??i di?n cho m?t tr?c I ho?c Q

        begin
            // B?t ??u ph?n x? lý c?a hàm

            case (bits)
                // Xét t?ng t? h?p 2 bit

                2'b00: gray_2bit_to_level = LEVEL_NEG_3;
                // Gray code: 00 ánh x? thành -3A

                2'b01: gray_2bit_to_level = LEVEL_NEG_1;
                // Gray code: 01 ánh x? thành -A

                2'b11: gray_2bit_to_level = LEVEL_POS_1;
                // Gray code: 11 ánh x? thành +A

                2'b10: gray_2bit_to_level = LEVEL_POS_3;
                // Gray code: 10 ánh x? thành +3A

                default: gray_2bit_to_level = 16'sd0;
                // Tr??ng h?p d? phòng, g?n nh? không x?y ra v?i input 2 bit
            endcase

        end
        // K?t thúc ph?n x? lý c?a hàm

    endfunction
    // K?t thúc hàm ánh x? Gray code


    // ------------------------------------------------------------
    // 3. Logic chính c?a kh?i 16-QAM Mapper
    // ------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
    // Kh?i always ch?y khi có c?nh lên clock ho?c c?nh xu?ng reset

        if (!rst_n) begin
        // N?u reset ???c kích ho?t, t?c rst_n = 0

            i_out <= 16'sd0;
            // Reset thành ph?n I v? 0

            q_out <= 16'sd0;
            // Reset thành ph?n Q v? 0

            symbol_valid <= 1'b0;
            // Reset tín hi?u báo output h?p l? v? 0

        end else begin
        // N?u không reset thì x? lý d? li?u bình th??ng

            if (data_valid) begin
            // Ch? ánh x? khi d? li?u ??u vào h?p l?

                i_out <= gray_2bit_to_level(data_in[3:2]);
                // L?y 2 bit cao data_in[3:2] ?? ánh x? thành thành ph?n I

                q_out <= gray_2bit_to_level(data_in[1:0]);
                // L?y 2 bit th?p data_in[1:0] ?? ánh x? thành thành ph?n Q

                symbol_valid <= 1'b1;
                // Báo r?ng symbol I/Q ??u ra h?p l?

            end else begin
            // N?u data_valid = 0 thì không nh?n d? li?u m?i

                symbol_valid <= 1'b0;
                // Output hi?n t?i không ???c xem là symbol m?i h?p l?

            end
        end
    end

endmodule
// K?t thúc module qam16_mapper
