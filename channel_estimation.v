`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 03:53:47 PM
// Design Name: 
// Module Name: channel_estimation
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
// ?? chính xác mô ph?ng là 1ps


module channel_estimation #(
    parameter WIDTH = 16
    // WIDTH là ?? r?ng m?i thành ph?n I ho?c Q
    // Trong h? th?ng OFDM c?a mình, I/Q ?ang dùng signed 16-bit
)(
    input  wire                         clk,
    // Clock h? th?ng

    input  wire                         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? output

    input  wire                         pilot_valid_in,
    // Báo r?ng pilot0 và pilot1 ??u vào ?ang h?p l?
    // Tín hi?u này s? n?i t? extract_valid_out c?a kh?i subcarrier_extraction

    input  wire signed [WIDTH-1:0]      pilot0_i,
    // Thành ph?n I c?a pilot0 nh?n ???c
    // pilot0 = Y[1], ???c tách ra t? Subcarrier Extraction

    input  wire signed [WIDTH-1:0]      pilot0_q,
    // Thành ph?n Q c?a pilot0 nh?n ???c

    input  wire signed [WIDTH-1:0]      pilot1_i,
    // Thành ph?n I c?a pilot1 nh?n ???c
    // pilot1 = Y[6], ???c tách ra t? Subcarrier Extraction

    input  wire signed [WIDTH-1:0]      pilot1_q,
    // Thành ph?n Q c?a pilot1 nh?n ???c

    output reg  signed [WIDTH-1:0]      h_est_i,
    // Thành ph?n th?c c?a h? s? kênh ??c l??ng
    // ?ây là h? s? kênh fixed-point ??a sang Equalizer

    output reg  signed [WIDTH-1:0]      h_est_q,
    // Thành ph?n ?o c?a h? s? kênh ??c l??ng

    output reg                          h_est_valid_out
    // Báo r?ng h_est_i và h_est_q ?ã h?p l?
);


    // ============================================================
    // 1. Khai báo bi?n trung gian
    // ============================================================
    //
    // Khi c?ng hai s? signed 16-bit:
    //
    //      pilot0_i + pilot1_i
    //
    // k?t qu? có th? c?n 17 bit ?? tránh tràn t?m th?i.
    //
    // Ví d?:
    //      32767 + 32767 = 65534
    //
    // Vì v?y ta dùng WIDTH+1 bit cho bi?n sum.
    // ============================================================

    reg signed [WIDTH:0] sum_i_temp;
    // Bi?n t?m ?? l?u t?ng pilot0_i + pilot1_i
    // R?ng h?n output 1 bit ?? tránh overflow khi c?ng

    reg signed [WIDTH:0] sum_q_temp;
    // Bi?n t?m ?? l?u t?ng pilot0_q + pilot1_q


    // ============================================================
    // 2. Logic chính c?a Channel Estimation
    // ============================================================
    //
    // Lý thuy?t:
    //
    //      Y[k] = H[k]X[k] + W[k]
    //
    // T?i v? trí pilot:
    //
    //      H_hat[k] = Y[k] / P[k]
    //
    // Trong thi?t k? này:
    //
    //      P0 = P1 = 1024 + j0
    //
    // ??ng th?i h? s? kênh c?ng ???c gi? ? fixed-point scale 1024.
    //
    // Vì v?y, n?u kênh h = 0.75:
    //
    //      h_fixed = 0.75 * 1024 = 768
    //
    // Pilot nh?n ???c x?p x?:
    //
    //      Y_pilot ? 768
    //
    // Do ?ó ta có th? dùng tr?c ti?p pilot nh?n ???c làm h_est_fixed.
    //
    // ?? gi?m nhi?u, ta l?y trung bình hai pilot:
    //
    //      h_est_i = (pilot0_i + pilot1_i) / 2
    //      h_est_q = (pilot0_q + pilot1_q) / 2
    //
    // Trong Verilog:
    //
    //      chia 2 = d?ch ph?i s? có d?u 1 bit = >>> 1
    //
    // ============================================================


    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên c?a clock
        // ho?c c?nh xu?ng c?a reset rst_n

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset h? th?ng

            h_est_i <= {WIDTH{1'b0}};
            // Reset h? s? kênh ph?n th?c v? 0

            h_est_q <= {WIDTH{1'b0}};
            // Reset h? s? kênh ph?n ?o v? 0

            h_est_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?

            sum_i_temp <= {(WIDTH+1){1'b0}};
            // Reset bi?n t?ng t?m nhánh I v? 0

            sum_q_temp <= {(WIDTH+1){1'b0}};
            // Reset bi?n t?ng t?m nhánh Q v? 0
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (pilot_valid_in) begin
                // Ch? ??c l??ng kênh khi pilot ??u vào h?p l?


                sum_i_temp = $signed(pilot0_i) + $signed(pilot1_i);
                // C?ng hai pilot ph?n I:
                //
                //      sum_i_temp = pilot0_i + pilot1_i
                //
                // $signed giúp Verilog hi?u ?ây là phép c?ng s? có d?u


                sum_q_temp = $signed(pilot0_q) + $signed(pilot1_q);
                // C?ng hai pilot ph?n Q:
                //
                //      sum_q_temp = pilot0_q + pilot1_q


                h_est_i <= sum_i_temp >>> 1;
                // L?y trung bình ph?n I:
                //
                //      h_est_i = (pilot0_i + pilot1_i) / 2
                //
                // Dùng >>> ?? d?ch ph?i s? có d?u


                h_est_q <= sum_q_temp >>> 1;
                // L?y trung bình ph?n Q:
                //
                //      h_est_q = (pilot0_q + pilot1_q) / 2


                h_est_valid_out <= 1'b1;
                // Báo r?ng h? s? kênh ??c l??ng ?ã h?p l?
            end

            else begin
                // N?u pilot_valid_in = 0 thì không có pilot m?i

                h_est_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là h? s? kênh m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module channel_estimation

