`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 03:49:46 PM
// Design Name: 
// Module Name: cyclic_prefix_insertion
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
// Khai báo ?? chính xác mô ph?ng là 1ps


module cyclic_prefix_insertion #(
    parameter WIDTH  = 16,              // ?? r?ng m?i m?u I ho?c Q, h? th?ng ?ang dùng 16 bit
    parameter N      = 8,               // S? m?u OFDM sau IFFT, ? ?ây IFFT 8-point nên N = 8
    parameter CP_LEN = 2                // ?? dài cyclic prefix, ta ch?n 2 m?u
)(
    input  wire                         clk,             // Clock h? th?ng
    input  wire                         rst_n,           // Reset tích c?c m?c th?p, rst_n = 0 thì reset
    input  wire                         time_valid_in,   // Báo i_time_bus và q_time_bus t? IFFT ?ã h?p l?

    input  wire [N*WIDTH-1:0]           i_time_bus,      // Bus ch?a 8 m?u th?i gian ph?n I sau IFFT
    input  wire [N*WIDTH-1:0]           q_time_bus,      // Bus ch?a 8 m?u th?i gian ph?n Q sau IFFT

    output reg  [(N+CP_LEN)*WIDTH-1:0]  i_cp_bus,        // Bus ch?a 10 m?u ph?n I sau khi thêm cyclic prefix
    output reg  [(N+CP_LEN)*WIDTH-1:0]  q_cp_bus,        // Bus ch?a 10 m?u ph?n Q sau khi thêm cyclic prefix
    output reg                          cp_valid_out     // Báo i_cp_bus và q_cp_bus ??u ra ?ã h?p l?
);


    // ============================================================
    // 1. Logic chính c?a kh?i Cyclic Prefix Insertion
    // ============================================================
    //
    // Input t? IFFT:
    //
    //      x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]
    //
    // Output sau khi thêm CP:
    //
    //      x_cp[0] = x[6]
    //      x_cp[1] = x[7]
    //      x_cp[2] = x[0]
    //      x_cp[3] = x[1]
    //      x_cp[4] = x[2]
    //      x_cp[5] = x[3]
    //      x_cp[6] = x[4]
    //      x_cp[7] = x[5]
    //      x_cp[8] = x[6]
    //      x_cp[9] = x[7]
    //
    // Vì m?i m?u có hai ph?n I và Q, ta ph?i thêm CP cho c? hai bus.
    // ============================================================


    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên c?a clock ho?c c?nh xu?ng c?a reset

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset toàn b? output

            i_cp_bus <= {(N+CP_LEN)*WIDTH{1'b0}};
            // Reset toàn b? bus I sau CP v? 0

            q_cp_bus <= {(N+CP_LEN)*WIDTH{1'b0}};
            // Reset toàn b? bus Q sau CP v? 0

            cp_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (time_valid_in) begin
                // Ch? thêm cyclic prefix khi d? li?u sau IFFT h?p l?


                // ------------------------------------------------
                // 2. Thêm CP cho nhánh I
                // ------------------------------------------------

                i_cp_bus[0*WIDTH +: WIDTH] <= i_time_bus[6*WIDTH +: WIDTH];
                // x_cp_I[0] = x_I[6]
                // L?y m?u cu?i g?n cu?i c?a symbol OFDM ??a lên ??u

                i_cp_bus[1*WIDTH +: WIDTH] <= i_time_bus[7*WIDTH +: WIDTH];
                // x_cp_I[1] = x_I[7]
                // L?y m?u cu?i cùng c?a symbol OFDM ??a lên ??u

                i_cp_bus[2*WIDTH +: WIDTH] <= i_time_bus[0*WIDTH +: WIDTH];
                // x_cp_I[2] = x_I[0]
                // Sau ph?n CP, b?t ??u chép l?i symbol OFDM g?c t? x[0]

                i_cp_bus[3*WIDTH +: WIDTH] <= i_time_bus[1*WIDTH +: WIDTH];
                // x_cp_I[3] = x_I[1]

                i_cp_bus[4*WIDTH +: WIDTH] <= i_time_bus[2*WIDTH +: WIDTH];
                // x_cp_I[4] = x_I[2]

                i_cp_bus[5*WIDTH +: WIDTH] <= i_time_bus[3*WIDTH +: WIDTH];
                // x_cp_I[5] = x_I[3]

                i_cp_bus[6*WIDTH +: WIDTH] <= i_time_bus[4*WIDTH +: WIDTH];
                // x_cp_I[6] = x_I[4]

                i_cp_bus[7*WIDTH +: WIDTH] <= i_time_bus[5*WIDTH +: WIDTH];
                // x_cp_I[7] = x_I[5]

                i_cp_bus[8*WIDTH +: WIDTH] <= i_time_bus[6*WIDTH +: WIDTH];
                // x_cp_I[8] = x_I[6]

                i_cp_bus[9*WIDTH +: WIDTH] <= i_time_bus[7*WIDTH +: WIDTH];
                // x_cp_I[9] = x_I[7]
                // K?t thúc ph?n symbol OFDM g?c


                // ------------------------------------------------
                // 3. Thêm CP cho nhánh Q
                // ------------------------------------------------

                q_cp_bus[0*WIDTH +: WIDTH] <= q_time_bus[6*WIDTH +: WIDTH];
                // x_cp_Q[0] = x_Q[6]
                // CP c?a nhánh Q c?ng ph?i l?y t? hai m?u cu?i

                q_cp_bus[1*WIDTH +: WIDTH] <= q_time_bus[7*WIDTH +: WIDTH];
                // x_cp_Q[1] = x_Q[7]

                q_cp_bus[2*WIDTH +: WIDTH] <= q_time_bus[0*WIDTH +: WIDTH];
                // x_cp_Q[2] = x_Q[0]
                // Sau CP, chép l?i symbol OFDM g?c t? m?u ??u

                q_cp_bus[3*WIDTH +: WIDTH] <= q_time_bus[1*WIDTH +: WIDTH];
                // x_cp_Q[3] = x_Q[1]

                q_cp_bus[4*WIDTH +: WIDTH] <= q_time_bus[2*WIDTH +: WIDTH];
                // x_cp_Q[4] = x_Q[2]

                q_cp_bus[5*WIDTH +: WIDTH] <= q_time_bus[3*WIDTH +: WIDTH];
                // x_cp_Q[5] = x_Q[3]

                q_cp_bus[6*WIDTH +: WIDTH] <= q_time_bus[4*WIDTH +: WIDTH];
                // x_cp_Q[6] = x_Q[4]

                q_cp_bus[7*WIDTH +: WIDTH] <= q_time_bus[5*WIDTH +: WIDTH];
                // x_cp_Q[7] = x_Q[5]

                q_cp_bus[8*WIDTH +: WIDTH] <= q_time_bus[6*WIDTH +: WIDTH];
                // x_cp_Q[8] = x_Q[6]

                q_cp_bus[9*WIDTH +: WIDTH] <= q_time_bus[7*WIDTH +: WIDTH];
                // x_cp_Q[9] = x_Q[7]


                cp_valid_out <= 1'b1;
                // Báo r?ng bus sau cyclic prefix ?ã h?p l?
            end

            else begin
                // N?u time_valid_in = 0 thì không có frame m?i t? IFFT

                cp_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là frame m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module cyclic_prefix_insertion

