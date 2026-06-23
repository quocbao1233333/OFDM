`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 03:51:27 PM
// Design Name: 
// Module Name: cyclic_prefix_removal
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


module cyclic_prefix_removal #(
    parameter WIDTH  = 16,              // ?? r?ng m?i m?u I ho?c Q, h? th?ng ?ang dùng 16 bit
    parameter N      = 8,               // S? m?u OFDM chính, vì FFT/IFFT c?a ta là 8-point
    parameter CP_LEN = 2                // ?? dài cyclic prefix, ta ?ã ch?n 2 m?u
)(
    input  wire                         clk,              // Clock h? th?ng
    input  wire                         rst_n,            // Reset tích c?c m?c th?p, rst_n = 0 thì reset

    input  wire                         rx_valid_in,      // Báo i_rx_cp_bus và q_rx_cp_bus t? Channel AWGN h?p l?

    input  wire [(N+CP_LEN)*WIDTH-1:0]  i_rx_cp_bus,      // Bus ch?a 10 m?u I sau kênh, còn cyclic prefix
    input  wire [(N+CP_LEN)*WIDTH-1:0]  q_rx_cp_bus,      // Bus ch?a 10 m?u Q sau kênh, còn cyclic prefix

    output reg  [N*WIDTH-1:0]           i_rx_time_bus,    // Bus ch?a 8 m?u I sau khi b? cyclic prefix
    output reg  [N*WIDTH-1:0]           q_rx_time_bus,    // Bus ch?a 8 m?u Q sau khi b? cyclic prefix

    output reg                          rx_time_valid_out // Báo i_rx_time_bus và q_rx_time_bus ??u ra h?p l?
);


    // ============================================================
    // 1. Khai báo bi?n ??m
    // ============================================================

    integer idx;
    // Bi?n idx dùng ?? duy?t qua 8 m?u chính sau khi b? CP
    // idx = 0, 1, 2, ..., 7


    // ============================================================
    // 2. Logic chính c?a Cyclic Prefix Removal
    // ============================================================
    //
    // Input t? Channel AWGN Model:
    //
    //      r_CP[0], r_CP[1], r_CP[2], r_CP[3], ..., r_CP[9]
    //
    // Trong ?ó:
    //
    //      r_CP[0], r_CP[1] là cyclic prefix
    //      r_CP[2] ??n r_CP[9] là 8 m?u OFDM chính
    //
    // Output sau khi b? CP:
    //
    //      r[0] = r_CP[2]
    //      r[1] = r_CP[3]
    //      r[2] = r_CP[4]
    //      r[3] = r_CP[5]
    //      r[4] = r_CP[6]
    //      r[5] = r_CP[7]
    //      r[6] = r_CP[8]
    //      r[7] = r_CP[9]
    //
    // Công th?c t?ng quát:
    //
    //      r[n] = r_CP[n + CP_LEN]
    //
    // V?i:
    //
    //      n = 0, 1, ..., N-1
    //      CP_LEN = 2
    //
    // ============================================================


    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên c?a clock
        // ho?c c?nh xu?ng c?a reset rst_n

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset toàn b? output

            i_rx_time_bus <= {N*WIDTH{1'b0}};
            // Reset bus I sau khi b? CP v? 0

            q_rx_time_bus <= {N*WIDTH{1'b0}};
            // Reset bus Q sau khi b? CP v? 0

            rx_time_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (rx_valid_in) begin
                // Ch? th?c hi?n b? CP khi d? li?u sau kênh h?p l?

                for (idx = 0; idx < N; idx = idx + 1) begin
                    // Vòng l?p l?y 8 m?u chính t? frame 10 m?u

                    i_rx_time_bus[idx*WIDTH +: WIDTH]
                        <= i_rx_cp_bus[(idx + CP_LEN)*WIDTH +: WIDTH];
                    // L?y m?u I sau CP:
                    //
                    // idx = 0 ? l?y i_rx_cp_bus[2] ??a vào i_rx_time_bus[0]
                    // idx = 1 ? l?y i_rx_cp_bus[3] ??a vào i_rx_time_bus[1]
                    // ...
                    // idx = 7 ? l?y i_rx_cp_bus[9] ??a vào i_rx_time_bus[7]

                    q_rx_time_bus[idx*WIDTH +: WIDTH]
                        <= q_rx_cp_bus[(idx + CP_LEN)*WIDTH +: WIDTH];
                    // L?y m?u Q sau CP theo cách t??ng t? nhánh I

                end

                rx_time_valid_out <= 1'b1;
                // Báo r?ng 8 m?u sau khi b? CP ?ã h?p l?
            end

            else begin
                // N?u rx_valid_in = 0 thì không có frame m?i t? Channel AWGN

                rx_time_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là d? li?u m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module cyclic_prefix_removal

