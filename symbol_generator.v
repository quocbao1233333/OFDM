`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2026 08:00:18 PM
// Design Name: 
// Module Name: symbol_generator
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


module symbol_generator #(
    parameter WIDTH = 16,                 // ?? r?ng m?i thành ph?n I ho?c Q, ? ?ây là 16 bit
    parameter NUM_SYMBOLS = 4             // S? symbol QAM c?n t?o ra, theo bài toán ta l?p thành 4 symbol
)(
    input  wire                         clk,              // Clock h? th?ng
    input  wire                         rst_n,            // Reset tích c?c m?c th?p, rst_n = 0 thì reset
    input  wire                         symbol_valid_in,  // Báo hi?u i_in và q_in t? QAM Mapper h?p l?

    input  wire signed [WIDTH-1:0]      i_in,             // Thành ph?n I c?a symbol QAM ??u vào
    input  wire signed [WIDTH-1:0]      q_in,             // Thành ph?n Q c?a symbol QAM ??u vào

    output reg  [NUM_SYMBOLS*WIDTH-1:0] i_symbol_bus,     // Bus ch?a 4 symbol I sau khi l?p
    output reg  [NUM_SYMBOLS*WIDTH-1:0] q_symbol_bus,     // Bus ch?a 4 symbol Q sau khi l?p
    output reg                          symbol_valid_out  // Báo hi?u bus symbol ??u ra h?p l?
);

    integer idx;                                           // Bi?n ??m dùng trong vòng l?p for


    always @(posedge clk or negedge rst_n) begin           // Kh?i tu?n t? ch?y theo c?nh lên clock ho?c c?nh xu?ng reset

        if (!rst_n) begin                                  // N?u rst_n = 0 thì h? th?ng reset

            i_symbol_bus <= {NUM_SYMBOLS*WIDTH{1'b0}};     // Reset toàn b? bus I v? 0

            q_symbol_bus <= {NUM_SYMBOLS*WIDTH{1'b0}};     // Reset toàn b? bus Q v? 0

            symbol_valid_out <= 1'b0;                      // Khi reset thì output ch?a h?p l?

        end else begin                                     // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (symbol_valid_in) begin                     // Ch? t?o symbol khi d? li?u ??u vào h?p l?

                for (idx = 0; idx < NUM_SYMBOLS; idx = idx + 1) begin
                // Vòng l?p t?o NUM_SYMBOLS b?n sao c?a symbol QAM ??u vào

                    i_symbol_bus[idx*WIDTH +: WIDTH] <= i_in;
                    // Gán i_in vào t?ng vùng WIDTH bit c?a bus I
                    // Ví d? WIDTH = 16:
                    // idx = 0 ? i_symbol_bus[15:0]
                    // idx = 1 ? i_symbol_bus[31:16]
                    // idx = 2 ? i_symbol_bus[47:32]
                    // idx = 3 ? i_symbol_bus[63:48]

                    q_symbol_bus[idx*WIDTH +: WIDTH] <= q_in;
                    // Gán q_in vào t?ng vùng WIDTH bit c?a bus Q
                    // Cách s?p x?p gi?ng bus I

                end                                        // K?t thúc vòng l?p for

                symbol_valid_out <= 1'b1;                  // Báo r?ng i_symbol_bus và q_symbol_bus ?ã h?p l?

            end else begin                                 // N?u symbol_valid_in = 0 thì không có symbol m?i

                symbol_valid_out <= 1'b0;                  // Output không ???c xem là d? li?u m?i h?p l?

            end                                            // K?t thúc ?i?u ki?n symbol_valid_in

        end                                                // K?t thúc nhánh không reset

    end                                                    // K?t thúc always block

endmodule                                                  // K?t thúc module symbol_generator
