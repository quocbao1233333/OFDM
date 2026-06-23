`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 09:52:53 PM
// Design Name: 
// Module Name: ofdm_transceiver_top
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


module ofdm_transceiver_top (
    input  wire         clk,
    // Clock h? th?ng dùng chung cho transmitter, channel và receiver

    input  wire         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? h? th?ng OFDM

    input  wire [3:0]   tx_data_in,
    // 4 bit d? li?u ??u vào ban ??u
    // Vì h? th?ng dùng 16-QAM nên m?i symbol mang 4 bit

    input  wire         tx_data_valid_in,
    // Báo tx_data_in hi?n t?i h?p l?

    input  wire signed [15:0] channel_gain,
    // H? s? kênh fixed-point
    // 1024 = h = 1,0
    // 768  = h = 0,75
    // 512  = h = 0,5

    input  wire         noise_enable,
    // B?t/t?t nhi?u trong Channel AWGN Model
    // noise_enable = 1: có nhi?u
    // noise_enable = 0: không nhi?u

    output wire [3:0]   rx_data_out,
    // 4 bit d? li?u cu?i cùng khôi ph?c ???c ? receiver

    output wire         rx_data_valid_out,
    // Báo rx_data_out h?p l?

    output wire         tx_valid_out,
    // Debug: báo output transmitter sau CP h?p l?

    output wire         channel_valid_out,
    // Debug: báo output channel h?p l?

    output wire         ifft_event_tlast_unexpected,
    // Debug event t? IFFT IP

    output wire         ifft_event_tlast_missing,
    // Debug event t? IFFT IP

    output wire         fft_event_tlast_unexpected,
    // Debug event t? FFT IP

    output wire         fft_event_tlast_missing
    // Debug event t? FFT IP
);


    // ============================================================
    // 1. Dây n?i gi?a OFDM Transmitter Top và Channel AWGN Model
    // ============================================================

    wire [159:0] i_tx_cp_bus;
    // Tín hi?u OFDM bên phát ph?n I sau khi thêm cyclic prefix
    // G?m 10 m?u, m?i m?u 16 bit

    wire [159:0] q_tx_cp_bus;
    // Tín hi?u OFDM bên phát ph?n Q sau khi thêm cyclic prefix

    wire tx_cp_valid;
    // Báo i_tx_cp_bus và q_tx_cp_bus h?p l?


    // ============================================================
    // 2. Dây n?i gi?a Channel AWGN Model và OFDM Receiver Top
    // ============================================================

    wire [159:0] i_rx_cp_bus;
    // Tín hi?u nh?n ph?n I sau khi ?i qua kênh AWGN

    wire [159:0] q_rx_cp_bus;
    // Tín hi?u nh?n ph?n Q sau khi ?i qua kênh AWGN

    wire rx_cp_valid;
    // Báo i_rx_cp_bus và q_rx_cp_bus h?p l?


    // ============================================================
    // 3. Các event debug còn l?i t? IFFT IP
    // ============================================================

    wire ifft_event_frame_started;
    // IFFT IP báo b?t ??u frame

    wire ifft_event_status_channel_halt;
    // IFFT IP báo status channel halt

    wire ifft_event_data_in_channel_halt;
    // IFFT IP báo input channel halt

    wire ifft_event_data_out_channel_halt;
    // IFFT IP báo output channel halt


    // ============================================================
    // 4. Các event debug còn l?i t? FFT IP
    // ============================================================

    wire fft_event_frame_started;
    // FFT IP báo b?t ??u frame

    wire fft_event_status_channel_halt;
    // FFT IP báo status channel halt

    wire fft_event_data_in_channel_halt;
    // FFT IP báo input channel halt

    wire fft_event_data_out_channel_halt;
    // FFT IP báo output channel halt


    // ============================================================
    // 5. Gán debug valid ra ngoài
    // ============================================================

    assign tx_valid_out = tx_cp_valid;
    // Xu?t valid c?a transmitter ra ngoài ?? quan sát waveform

    assign channel_valid_out = rx_cp_valid;
    // Xu?t valid c?a channel ra ngoài ?? quan sát waveform


    // ============================================================
    // 6. OFDM Transmitter Top
    // ============================================================
    //
    // Lu?ng bên trong transmitter:
    //
    // 16-QAM Mapper
    // ? Symbol Generator
    // ? Pilot Insertion
    // ? IFFT 8-point IP Wrapper
    // ? Cyclic Prefix Insertion
    //
    // Input:
    //      tx_data_in[3:0]
    //
    // Output:
    //      i_tx_cp_bus, q_tx_cp_bus
    //

    ofdm_transmitter_top u_ofdm_transmitter_top (
        .clk                            (clk),
        // Clock h? th?ng

        .rst_n                          (rst_n),
        // Reset h? th?ng

        .data_in                        (tx_data_in),
        // 4 bit d? li?u ??u vào

        .data_valid_in                  (tx_data_valid_in),
        // Báo data_in h?p l?

        .i_tx_cp_bus                    (i_tx_cp_bus),
        // Output transmitter ph?n I sau cyclic prefix

        .q_tx_cp_bus                    (q_tx_cp_bus),
        // Output transmitter ph?n Q sau cyclic prefix

        .tx_valid_out                   (tx_cp_valid),
        // Báo output transmitter h?p l?

        .ifft_event_frame_started       (ifft_event_frame_started),
        // Debug event IFFT

        .ifft_event_tlast_unexpected    (ifft_event_tlast_unexpected),
        // Debug event IFFT: TLAST sai th?i ?i?m

        .ifft_event_tlast_missing       (ifft_event_tlast_missing),
        // Debug event IFFT: thi?u TLAST

        .ifft_event_status_channel_halt (ifft_event_status_channel_halt),
        // Debug event IFFT

        .ifft_event_data_in_channel_halt(ifft_event_data_in_channel_halt),
        // Debug event IFFT

        .ifft_event_data_out_channel_halt(ifft_event_data_out_channel_halt)
        // Debug event IFFT
    );


    // ============================================================
    // 7. Channel AWGN Model
    // ============================================================
    //
    // Mô hình kênh:
    //
    //      r[n] = h · x[n] + w[n]
    //
    // V?i fixed-point:
    //
    //      channel_gain = h × 1024
    //
    // Ví d?:
    //      channel_gain = 1024 ? h = 1,0
    //      channel_gain = 768  ? h = 0,75
    //

    channel_awgn_model #(
        .WIDTH       (16),
        // M?i m?u I/Q r?ng 16 bit

        .N           (8),
        // OFDM dùng IFFT/FFT 8-point

        .CP_LEN      (2),
        // Cyclic prefix dài 2 m?u

        .SCALE_SHIFT (10)
        // 1024 = 2^10
    ) u_channel_awgn_model (
        .clk          (clk),
        // Clock h? th?ng

        .rst_n        (rst_n),
        // Reset h? th?ng

        .cp_valid_in  (tx_cp_valid),
        // Valid t? transmitter

        .i_cp_bus     (i_tx_cp_bus),
        // Tín hi?u phát ph?n I sau CP

        .q_cp_bus     (q_tx_cp_bus),
        // Tín hi?u phát ph?n Q sau CP

        .channel_gain (channel_gain),
        // H? s? kênh fixed-point

        .noise_enable (noise_enable),
        // B?t/t?t nhi?u

        .i_rx_cp_bus  (i_rx_cp_bus),
        // Tín hi?u nh?n ph?n I sau kênh

        .q_rx_cp_bus  (q_rx_cp_bus),
        // Tín hi?u nh?n ph?n Q sau kênh

        .rx_valid_out (rx_cp_valid)
        // Báo output channel h?p l?
    );


    // ============================================================
    // 8. OFDM Receiver Top
    // ============================================================
    //
    // Lu?ng bên trong receiver:
    //
    // Cyclic Prefix Removal
    // ? FFT 8-point IP Wrapper
    // ? Subcarrier Extraction
    // ? Channel Estimation
    // ? One-Tap Equalizer
    // ? Inverse Symbol Generator
    // ? 16-QAM Demapper
    // ? Receiver Output Module
    //
    // Input:
    //      i_rx_cp_bus, q_rx_cp_bus
    //
    // Output:
    //      rx_data_out[3:0]
    //

    ofdm_receiver_top u_ofdm_receiver_top (
        .clk                           (clk),
        // Clock h? th?ng

        .rst_n                         (rst_n),
        // Reset h? th?ng

        .i_rx_cp_bus                   (i_rx_cp_bus),
        // Input receiver ph?n I sau kênh

        .q_rx_cp_bus                   (q_rx_cp_bus),
        // Input receiver ph?n Q sau kênh

        .rx_valid_in                   (rx_cp_valid),
        // Valid t? Channel AWGN Model

        .rx_data                       (rx_data_out),
        // 4 bit d? li?u khôi ph?c

        .rx_data_valid                 (rx_data_valid_out),
        // Báo d? li?u khôi ph?c h?p l?

        .fft_event_frame_started       (fft_event_frame_started),
        // Debug event FFT

        .fft_event_tlast_unexpected    (fft_event_tlast_unexpected),
        // Debug event FFT: TLAST sai th?i ?i?m

        .fft_event_tlast_missing       (fft_event_tlast_missing),
        // Debug event FFT: thi?u TLAST

        .fft_event_status_channel_halt (fft_event_status_channel_halt),
        // Debug event FFT

        .fft_event_data_in_channel_halt(fft_event_data_in_channel_halt),
        // Debug event FFT

        .fft_event_data_out_channel_halt(fft_event_data_out_channel_halt)
        // Debug event FFT
    );

endmodule
// K?t thúc module ofdm_transceiver_top

