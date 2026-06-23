`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 09:50:38 PM
// Design Name: 
// Module Name: ofdm_receiver_top
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


module ofdm_receiver_top (
    input  wire         clk,
    // Clock h? th?ng

    input  wire         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? receiver

    input  wire [159:0] i_rx_cp_bus,
    // Tín hi?u nh?n t? Channel AWGN Model, ph?n I
    // G?m 10 m?u sau cyclic prefix
    // 10 × 16 bit = 160 bit

    input  wire [159:0] q_rx_cp_bus,
    // Tín hi?u nh?n t? Channel AWGN Model, ph?n Q
    // G?m 10 m?u sau cyclic prefix

    input  wire         rx_valid_in,
    // Báo i_rx_cp_bus và q_rx_cp_bus ??u vào h?p l?
    // Tín hi?u này n?i t? rx_valid_out c?a channel_awgn_model

    output wire [3:0]   rx_data,
    // 4 bit d? li?u cu?i cùng receiver khôi ph?c ???c

    output wire         rx_data_valid,
    // Báo rx_data h?p l?

    output wire         fft_event_frame_started,
    // Debug event t? FFT IP: b?t ??u frame

    output wire         fft_event_tlast_unexpected,
    // Debug event t? FFT IP: TLAST ??n sai th?i ?i?m

    output wire         fft_event_tlast_missing,
    // Debug event t? FFT IP: thi?u TLAST

    output wire         fft_event_status_channel_halt,
    // Debug event t? FFT IP: status channel b? halt

    output wire         fft_event_data_in_channel_halt,
    // Debug event t? FFT IP: input data channel b? halt

    output wire         fft_event_data_out_channel_halt
    // Debug event t? FFT IP: output data channel b? halt
);


    // ============================================================
    // 1. Dây n?i gi?a Cyclic Prefix Removal và FFT Wrapper
    // ============================================================

    wire [127:0] i_rx_time_bus;
    // Bus ch?a 8 m?u th?i gian ph?n I sau khi b? cyclic prefix

    wire [127:0] q_rx_time_bus;
    // Bus ch?a 8 m?u th?i gian ph?n Q sau khi b? cyclic prefix

    wire rx_time_valid;
    // Báo i_rx_time_bus và q_rx_time_bus h?p l?


    // ============================================================
    // 2. Dây n?i gi?a FFT Wrapper và Subcarrier Extraction
    // ============================================================

    wire [127:0] i_rx_freq_bus;
    // Bus ch?a 8 subcarrier ph?n I sau FFT

    wire [127:0] q_rx_freq_bus;
    // Bus ch?a 8 subcarrier ph?n Q sau FFT

    wire fft_valid;
    // Báo i_rx_freq_bus và q_rx_freq_bus h?p l?


    // ============================================================
    // 3. Dây n?i gi?a Subcarrier Extraction và Channel Estimation
    // ============================================================

    wire signed [15:0] pilot0_i;
    // Thành ph?n I c?a pilot0 nh?n ???c t?i Y[1]

    wire signed [15:0] pilot0_q;
    // Thành ph?n Q c?a pilot0 nh?n ???c t?i Y[1]

    wire signed [15:0] pilot1_i;
    // Thành ph?n I c?a pilot1 nh?n ???c t?i Y[6]

    wire signed [15:0] pilot1_q;
    // Thành ph?n Q c?a pilot1 nh?n ???c t?i Y[6]

    wire [63:0] i_data_bus;
    // Bus ch?a 4 data subcarrier ph?n I:
    // Y[2], Y[3], Y[4], Y[5]

    wire [63:0] q_data_bus;
    // Bus ch?a 4 data subcarrier ph?n Q

    wire extract_valid;
    // Báo pilot và data sau khi tách h?p l?


    // ============================================================
    // 4. Dây n?i gi?a Channel Estimation và One-Tap Equalizer
    // ============================================================

    wire signed [15:0] h_est_i;
    // Thành ph?n th?c c?a h? s? kênh ??c l??ng

    wire signed [15:0] h_est_q;
    // Thành ph?n ?o c?a h? s? kênh ??c l??ng

    wire h_est_valid;
    // Báo h_est_i và h_est_q h?p l?


    // ============================================================
    // 5. Dây n?i gi?a One-Tap Equalizer và Inverse Symbol Generator
    // ============================================================

    wire [63:0] i_eq_data_bus;
    // Bus ch?a 4 data symbol ph?n I sau equalizer

    wire [63:0] q_eq_data_bus;
    // Bus ch?a 4 data symbol ph?n Q sau equalizer

    wire eq_valid;
    // Báo i_eq_data_bus và q_eq_data_bus h?p l?


    // ============================================================
    // 6. Dây n?i gi?a Inverse Symbol Generator và 16-QAM Demapper
    // ============================================================

    wire signed [15:0] rx_symbol_i;
    // Thành ph?n I c?a symbol QAM ??i di?n sau khi l?y trung bình

    wire signed [15:0] rx_symbol_q;
    // Thành ph?n Q c?a symbol QAM ??i di?n sau khi l?y trung bình

    wire rx_symbol_valid;
    // Báo rx_symbol_i và rx_symbol_q h?p l?


    // ============================================================
    // 7. Dây n?i gi?a 16-QAM Demapper và Receiver Output Module
    // ============================================================

    wire [3:0] demap_data;
    // 4 bit d? li?u sau 16-QAM Demapper

    wire demap_data_valid;
    // Báo demap_data h?p l?


    // ============================================================
    // 8. Kh?i Cyclic Prefix Removal
    // ============================================================
    //
    // Input:
    //      r_CP[0], r_CP[1], ..., r_CP[9]
    //
    // B? 2 m?u CP ??u:
    //      r_CP[0], r_CP[1]
    //
    // Output:
    //      r[0] = r_CP[2]
    //      r[1] = r_CP[3]
    //      ...
    //      r[7] = r_CP[9]
    //

    cyclic_prefix_removal #(
        .WIDTH  (16),
        // M?i m?u I/Q r?ng 16 bit

        .N      (8),
        // FFT 8-point nên gi? l?i 8 m?u chính

        .CP_LEN (2)
        // ?? dài cyclic prefix b?ng 2 m?u
    ) u_cyclic_prefix_removal (
        .clk               (clk),
        // Clock h? th?ng

        .rst_n             (rst_n),
        // Reset h? th?ng

        .rx_valid_in       (rx_valid_in),
        // Valid t? Channel AWGN Model

        .i_rx_cp_bus       (i_rx_cp_bus),
        // 10 m?u I sau kênh, còn CP

        .q_rx_cp_bus       (q_rx_cp_bus),
        // 10 m?u Q sau kênh, còn CP

        .i_rx_time_bus     (i_rx_time_bus),
        // 8 m?u I sau khi b? CP

        .q_rx_time_bus     (q_rx_time_bus),
        // 8 m?u Q sau khi b? CP

        .rx_time_valid_out (rx_time_valid)
        // Báo output sau b? CP h?p l?
    );


    // ============================================================
    // 9. Kh?i FFT 8-point IP Wrapper
    // ============================================================
    //
    // Ch?c n?ng:
    //      Chuy?n tín hi?u t? mi?n th?i gian sang mi?n t?n s?
    //
    // Input:
    //      r[0], r[1], ..., r[7]
    //
    // Output:
    //      Y[0], Y[1], ..., Y[7]
    //
    // Kh?i này g?i Vivado IP:
    //      xfft_fft8
    //

    fft8_ip_wrapper #(
        .WIDTH (16)
        // I/Q r?ng 16 bit
    ) u_fft8_ip_wrapper (
        .clk                         (clk),
        // Clock h? th?ng

        .rst_n                       (rst_n),
        // Reset h? th?ng

        .time_valid_in               (rx_time_valid),
        // Valid t? Cyclic Prefix Removal

        .i_rx_time_bus               (i_rx_time_bus),
        // 8 m?u th?i gian ph?n I

        .q_rx_time_bus               (q_rx_time_bus),
        // 8 m?u th?i gian ph?n Q

        .i_rx_freq_bus               (i_rx_freq_bus),
        // 8 subcarrier ph?n I sau FFT

        .q_rx_freq_bus               (q_rx_freq_bus),
        // 8 subcarrier ph?n Q sau FFT

        .fft_valid_out               (fft_valid),
        // Báo output FFT h?p l?

        .event_frame_started         (fft_event_frame_started),
        // Debug event t? FFT IP

        .event_tlast_unexpected      (fft_event_tlast_unexpected),
        // Debug event t? FFT IP

        .event_tlast_missing         (fft_event_tlast_missing),
        // Debug event t? FFT IP

        .event_status_channel_halt   (fft_event_status_channel_halt),
        // Debug event t? FFT IP

        .event_data_in_channel_halt  (fft_event_data_in_channel_halt),
        // Debug event t? FFT IP

        .event_data_out_channel_halt (fft_event_data_out_channel_halt)
        // Debug event t? FFT IP
    );


    // ============================================================
    // 10. Kh?i Subcarrier Extraction
    // ============================================================
    //
    // Sau FFT, ta có:
    //
    //      Y[0] : guard
    //      Y[1] : pilot0
    //      Y[2] : data0
    //      Y[3] : data1
    //      Y[4] : data2
    //      Y[5] : data3
    //      Y[6] : pilot1
    //      Y[7] : guard
    //
    // Kh?i này tách pilot và data ra riêng.
    //

    subcarrier_extraction #(
        .WIDTH (16)
        // I/Q r?ng 16 bit
    ) u_subcarrier_extraction (
        .clk               (clk),
        // Clock h? th?ng

        .rst_n             (rst_n),
        // Reset h? th?ng

        .fft_valid_in      (fft_valid),
        // Valid t? FFT Wrapper

        .i_rx_freq_bus     (i_rx_freq_bus),
        // 8 subcarrier ph?n I sau FFT

        .q_rx_freq_bus     (q_rx_freq_bus),
        // 8 subcarrier ph?n Q sau FFT

        .pilot0_i          (pilot0_i),
        // Pilot0 ph?n I = Y_I[1]

        .pilot0_q          (pilot0_q),
        // Pilot0 ph?n Q = Y_Q[1]

        .pilot1_i          (pilot1_i),
        // Pilot1 ph?n I = Y_I[6]

        .pilot1_q          (pilot1_q),
        // Pilot1 ph?n Q = Y_Q[6]

        .i_data_bus        (i_data_bus),
        // Data subcarrier ph?n I: Y[2] ??n Y[5]

        .q_data_bus        (q_data_bus),
        // Data subcarrier ph?n Q: Y[2] ??n Y[5]

        .extract_valid_out (extract_valid)
        // Báo output extraction h?p l?
    );


    // ============================================================
    // 11. Kh?i Channel Estimation
    // ============================================================
    //
    // Dùng hai pilot ?ã bi?t tr??c:
    //
    //      P0 = 1024 + j0
    //      P1 = 1024 + j0
    //
    // ??c l??ng kênh:
    //
    //      h_est_i = (pilot0_i + pilot1_i) / 2
    //      h_est_q = (pilot0_q + pilot1_q) / 2
    //

    channel_estimation #(
        .WIDTH (16)
        // I/Q r?ng 16 bit
    ) u_channel_estimation (
        .clk             (clk),
        // Clock h? th?ng

        .rst_n           (rst_n),
        // Reset h? th?ng

        .pilot_valid_in  (extract_valid),
        // Valid t? Subcarrier Extraction

        .pilot0_i        (pilot0_i),
        // Pilot0 ph?n I

        .pilot0_q        (pilot0_q),
        // Pilot0 ph?n Q

        .pilot1_i        (pilot1_i),
        // Pilot1 ph?n I

        .pilot1_q        (pilot1_q),
        // Pilot1 ph?n Q

        .h_est_i         (h_est_i),
        // H? s? kênh ??c l??ng ph?n th?c

        .h_est_q         (h_est_q),
        // H? s? kênh ??c l??ng ph?n ?o

        .h_est_valid_out (h_est_valid)
        // Báo h_est h?p l?
    );


    // ============================================================
    // 12. Kh?i One-Tap Equalizer
    // ============================================================
    //
    // Dùng h_est_i ?? bù kênh cho data:
    //
    //      X_hat_I = (Y_I × 1024) / h_est_i
    //      X_hat_Q = (Y_Q × 1024) / h_est_i
    //
    // Vì Channel AWGN Model hi?n t?i dùng kênh th?c,
    // b?n equalizer này ch? y?u dùng h_est_i.
    //

    one_tap_equalizer #(
        .WIDTH       (16),
        // I/Q r?ng 16 bit

        .NUM_DATA    (4),
        // Có 4 data subcarrier

        .SCALE_SHIFT (10)
        // 1024 = 2^10
    ) u_one_tap_equalizer (
        .clk            (clk),
        // Clock h? th?ng

        .rst_n          (rst_n),
        // Reset h? th?ng

        .h_est_valid_in (h_est_valid),
        // Valid t? Channel Estimation

        .i_data_bus     (i_data_bus),
        // 4 data subcarrier ph?n I

        .q_data_bus     (q_data_bus),
        // 4 data subcarrier ph?n Q

        .h_est_i        (h_est_i),
        // H? s? kênh ph?n th?c

        .h_est_q        (h_est_q),
        // H? s? kênh ph?n ?o, hi?n t?i ch?a dùng trong equalizer ??n gi?n

        .i_eq_data_bus  (i_eq_data_bus),
        // 4 data symbol ph?n I sau equalizer

        .q_eq_data_bus  (q_eq_data_bus),
        // 4 data symbol ph?n Q sau equalizer

        .eq_valid_out   (eq_valid)
        // Báo output equalizer h?p l?
    );


    // ============================================================
    // 13. Kh?i Inverse Symbol Generator
    // ============================================================
    //
    // ? transmitter, Symbol Generator l?p 1 symbol thành 4 symbol.
    //
    // ? receiver, Inverse Symbol Generator l?y trung bình 4 symbol:
    //
    //      S_I = (D0_I + D1_I + D2_I + D3_I) / 4
    //      S_Q = (D0_Q + D1_Q + D2_Q + D3_Q) / 4
    //
    // Output là 1 symbol QAM ??i di?n.
    //

    inverse_symbol_generator #(
        .WIDTH    (16),
        // I/Q r?ng 16 bit

        .NUM_DATA (4)
        // Trung bình 4 data symbol
    ) u_inverse_symbol_generator (
        .clk              (clk),
        // Clock h? th?ng

        .rst_n            (rst_n),
        // Reset h? th?ng

        .eq_valid_in      (eq_valid),
        // Valid t? One-Tap Equalizer

        .i_eq_data_bus    (i_eq_data_bus),
        // 4 symbol I sau equalizer

        .q_eq_data_bus    (q_eq_data_bus),
        // 4 symbol Q sau equalizer

        .symbol_i_out     (rx_symbol_i),
        // Symbol QAM ??i di?n ph?n I

        .symbol_q_out     (rx_symbol_q),
        // Symbol QAM ??i di?n ph?n Q

        .symbol_valid_out (rx_symbol_valid)
        // Báo symbol ??i di?n h?p l?
    );


    // ============================================================
    // 14. Kh?i 16-QAM Demapper
    // ============================================================
    //
    // Nh?n symbol QAM ??i di?n:
    //
    //      rx_symbol_i + j rx_symbol_q
    //
    // Sau ?ó quy?t ??nh v? 4 bit d? li?u.
    //
    // B?ng quy?t ??nh:
    //
    //      v < -2048       ? 00
    //      -2048 <= v < 0  ? 01
    //      0 <= v < 2048   ? 11
    //      v >= 2048       ? 10
    //

    qam16_demapper u_qam16_demapper (
        .clk           (clk),
        // Clock h? th?ng

        .rst_n         (rst_n),
        // Reset h? th?ng

        .symbol_valid  (rx_symbol_valid),
        // Valid t? Inverse Symbol Generator

        .i_in          (rx_symbol_i),
        // Symbol QAM ph?n I

        .q_in          (rx_symbol_q),
        // Symbol QAM ph?n Q

        .data_out      (demap_data),
        // 4 bit d? li?u sau demapper

        .data_valid    (demap_data_valid)
        // Báo data_out h?p l?
    );


    // ============================================================
    // 15. Kh?i Receiver Output Module
    // ============================================================
    //
    // Ch?t d? li?u cu?i cùng c?a receiver.
    //

    receiver_output_module u_receiver_output_module (
        .clk              (clk),
        // Clock h? th?ng

        .rst_n            (rst_n),
        // Reset h? th?ng

        .demap_data_in    (demap_data),
        // D? li?u t? 16-QAM Demapper

        .demap_data_valid (demap_data_valid),
        // Valid t? 16-QAM Demapper

        .rx_data          (rx_data),
        // Output cu?i receiver

        .rx_data_valid    (rx_data_valid)
        // Báo output cu?i h?p l?
    );

endmodule
// K?t thúc module ofdm_receiver_top
