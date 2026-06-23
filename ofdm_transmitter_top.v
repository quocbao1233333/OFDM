`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 09:43:19 PM
// Design Name: 
// Module Name: ofdm_transmitter_top
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


module ofdm_transmitter_top (
    input  wire         clk,
    // Clock h? th?ng

    input  wire         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? h? th?ng transmitter

    input  wire [3:0]   data_in,
    // 4 bit d? li?u ??u vào
    // Vì h? th?ng dùng 16-QAM nên m?i symbol c?n 4 bit

    input  wire         data_valid_in,
    // Báo data_in hi?n t?i h?p l?

    output wire [159:0] i_tx_cp_bus,
    // Output cu?i transmitter: 10 m?u OFDM ph?n I sau cyclic prefix
    // Vì N = 8, CP_LEN = 2 nên t?ng 10 m?u
    // 10 × 16 bit = 160 bit

    output wire [159:0] q_tx_cp_bus,
    // Output cu?i transmitter: 10 m?u OFDM ph?n Q sau cyclic prefix

    output wire         tx_valid_out,
    // Báo i_tx_cp_bus và q_tx_cp_bus h?p l?

    output wire         ifft_event_frame_started,
    // Debug event t? IFFT IP: b?t ??u frame

    output wire         ifft_event_tlast_unexpected,
    // Debug event t? IFFT IP: TLAST ??n sai th?i ?i?m

    output wire         ifft_event_tlast_missing,
    // Debug event t? IFFT IP: thi?u TLAST

    output wire         ifft_event_status_channel_halt,
    // Debug event t? IFFT IP: status channel b? halt

    output wire         ifft_event_data_in_channel_halt,
    // Debug event t? IFFT IP: input data channel b? halt

    output wire         ifft_event_data_out_channel_halt
    // Debug event t? IFFT IP: output data channel b? halt
);


    // ============================================================
    // 1. Dây n?i gi?a 16-QAM Mapper và Symbol Generator
    // ============================================================

    wire signed [15:0] qam_i;
    // Thành ph?n I c?a symbol 16-QAM sau mapper

    wire signed [15:0] qam_q;
    // Thành ph?n Q c?a symbol 16-QAM sau mapper

    wire qam_symbol_valid;
    // Báo qam_i và qam_q h?p l?


    // ============================================================
    // 2. Dây n?i gi?a Symbol Generator và Pilot Insertion
    // ============================================================

    wire [63:0] symbol_i_bus;
    // Bus ch?a 4 symbol ph?n I t? Symbol Generator
    // 4 × 16 bit = 64 bit

    wire [63:0] symbol_q_bus;
    // Bus ch?a 4 symbol ph?n Q t? Symbol Generator

    wire symbol_bus_valid;
    // Báo symbol_i_bus và symbol_q_bus h?p l?


    // ============================================================
    // 3. Dây n?i gi?a Pilot Insertion và IFFT Wrapper
    // ============================================================

    wire [127:0] freq_i_bus;
    // Bus ch?a 8 subcarrier ph?n I sau khi chèn pilot
    // 8 × 16 bit = 128 bit

    wire [127:0] freq_q_bus;
    // Bus ch?a 8 subcarrier ph?n Q sau khi chèn pilot

    wire freq_valid;
    // Báo freq_i_bus và freq_q_bus h?p l?


    // ============================================================
    // 4. Dây n?i gi?a IFFT Wrapper và Cyclic Prefix Insertion
    // ============================================================

    wire [127:0] time_i_bus;
    // Bus ch?a 8 m?u th?i gian ph?n I sau IFFT

    wire [127:0] time_q_bus;
    // Bus ch?a 8 m?u th?i gian ph?n Q sau IFFT

    wire time_valid;
    // Báo time_i_bus và time_q_bus h?p l?


    // ============================================================
    // 5. Kh?i 16-QAM Mapper
    // ============================================================
    //
    // Ch?c n?ng:
    //      data_in[3:0]
    //      ? qam_i, qam_q
    //
    // Ví d?:
    //      data_in = 1010
    //      ? qam_i = +3072
    //      ? qam_q = +3072
    //

    qam16_mapper u_qam16_mapper (
        .clk          (clk),
        // N?i clock h? th?ng

        .rst_n        (rst_n),
        // N?i reset h? th?ng

        .data_valid   (data_valid_in),
        // data_valid_in báo 4 bit input h?p l?

        .data_in      (data_in),
        // 4 bit d? li?u ??u vào

        .i_out        (qam_i),
        // Thành ph?n I sau mapper

        .q_out        (qam_q),
        // Thành ph?n Q sau mapper

        .symbol_valid (qam_symbol_valid)
        // Báo symbol I/Q sau mapper h?p l?
    );


    // ============================================================
    // 6. Kh?i Symbol Generator
    // ============================================================
    //
    // Ch?c n?ng:
    //      Nh?n 1 symbol QAM
    //      ? t?o 4 symbol data gi?ng nhau
    //
    // Output:
    //      D0, D1, D2, D3
    //

    symbol_generator #(
        .WIDTH       (16),
        // M?i thành ph?n I/Q r?ng 16 bit

        .NUM_SYMBOLS (4)
        // T?o 4 symbol data
    ) u_symbol_generator (
        .clk              (clk),
        // Clock h? th?ng

        .rst_n            (rst_n),
        // Reset h? th?ng

        .symbol_valid_in  (qam_symbol_valid),
        // Valid t? QAM Mapper

        .i_in             (qam_i),
        // Thành ph?n I c?a symbol QAM

        .q_in             (qam_q),
        // Thành ph?n Q c?a symbol QAM

        .i_symbol_bus     (symbol_i_bus),
        // 4 symbol ph?n I

        .q_symbol_bus     (symbol_q_bus),
        // 4 symbol ph?n Q

        .symbol_valid_out (symbol_bus_valid)
        // Báo bus 4 symbol h?p l?
    );


    // ============================================================
    // 7. Kh?i Pilot Insertion
    // ============================================================
    //
    // Ch?c n?ng:
    //      Nh?n 4 data symbol
    //      ? chèn pilot và guard
    //
    // C?u trúc frame:
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
    // V?i:
    //      P0 = P1 = 1024 + j0
    //

    pilot_insertion #(
        .WIDTH (16)
        // I/Q r?ng 16 bit
    ) u_pilot_insertion (
        .clk              (clk),
        // Clock h? th?ng

        .rst_n            (rst_n),
        // Reset h? th?ng

        .symbol_valid_in  (symbol_bus_valid),
        // Valid t? Symbol Generator

        .i_symbol_bus     (symbol_i_bus),
        // 4 data symbol ph?n I

        .q_symbol_bus     (symbol_q_bus),
        // 4 data symbol ph?n Q

        .i_freq_bus       (freq_i_bus),
        // 8 subcarrier ph?n I sau chèn pilot

        .q_freq_bus       (freq_q_bus),
        // 8 subcarrier ph?n Q sau chèn pilot

        .pilot_valid_out  (freq_valid)
        // Báo frame mi?n t?n s? h?p l?
    );


    // ============================================================
    // 8. Kh?i IFFT 8-point IP Wrapper
    // ============================================================
    //
    // Ch?c n?ng:
    //      Chuy?n mi?n t?n s? sang mi?n th?i gian
    //
    // Input:
    //      X[0], X[1], ..., X[7]
    //
    // Output:
    //      x[0], x[1], ..., x[7]
    //
    // Kh?i này g?i IP Vivado:
    //      xfft_ifft8
    //
    // L?u ý:
    //      IP xfft_ifft8 ph?i ???c t?o trong Vivado project.
    //

    ifft8_ip_wrapper #(
        .WIDTH (16)
        // I/Q r?ng 16 bit
    ) u_ifft8_ip_wrapper (
        .clk                         (clk),
        // Clock h? th?ng

        .rst_n                       (rst_n),
        // Reset h? th?ng

        .freq_valid_in               (freq_valid),
        // Valid t? Pilot Insertion

        .i_freq_bus                  (freq_i_bus),
        // 8 subcarrier ph?n I

        .q_freq_bus                  (freq_q_bus),
        // 8 subcarrier ph?n Q

        .i_time_bus                  (time_i_bus),
        // 8 m?u th?i gian ph?n I sau IFFT

        .q_time_bus                  (time_q_bus),
        // 8 m?u th?i gian ph?n Q sau IFFT

        .ifft_valid_out              (time_valid),
        // Báo output IFFT h?p l?

        .event_frame_started         (ifft_event_frame_started),
        // Debug event t? IP

        .event_tlast_unexpected      (ifft_event_tlast_unexpected),
        // Debug event t? IP

        .event_tlast_missing         (ifft_event_tlast_missing),
        // Debug event t? IP

        .event_status_channel_halt   (ifft_event_status_channel_halt),
        // Debug event t? IP

        .event_data_in_channel_halt  (ifft_event_data_in_channel_halt),
        // Debug event t? IP

        .event_data_out_channel_halt (ifft_event_data_out_channel_halt)
        // Debug event t? IP
    );


    // ============================================================
    // 9. Kh?i Cyclic Prefix Insertion
    // ============================================================
    //
    // Ch?c n?ng:
    //      Nh?n 8 m?u th?i gian sau IFFT
    //      ? l?y 2 m?u cu?i ??a lên ??u
    //
    // Input:
    //      x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]
    //
    // Output:
    //      x_cp[0] = x[6]
    //      x_cp[1] = x[7]
    //      x_cp[2] = x[0]
    //      ...
    //      x_cp[9] = x[7]
    //

    cyclic_prefix_insertion #(
        .WIDTH  (16),
        // M?i m?u I/Q r?ng 16 bit

        .N      (8),
        // IFFT 8-point nên có 8 m?u th?i gian

        .CP_LEN (2)
        // ?? dài cyclic prefix b?ng 2 m?u
    ) u_cyclic_prefix_insertion (
        .clk            (clk),
        // Clock h? th?ng

        .rst_n          (rst_n),
        // Reset h? th?ng

        .time_valid_in  (time_valid),
        // Valid t? IFFT Wrapper

        .i_time_bus     (time_i_bus),
        // 8 m?u th?i gian ph?n I

        .q_time_bus     (time_q_bus),
        // 8 m?u th?i gian ph?n Q

        .i_cp_bus       (i_tx_cp_bus),
        // 10 m?u sau CP ph?n I
        // ?ây là output cu?i c?a transmitter

        .q_cp_bus       (q_tx_cp_bus),
        // 10 m?u sau CP ph?n Q
        // ?ây là output cu?i c?a transmitter

        .cp_valid_out   (tx_valid_out)
        // Báo output transmitter h?p l?
    );

endmodule
// K?t thúc module ofdm_transmitter_top

