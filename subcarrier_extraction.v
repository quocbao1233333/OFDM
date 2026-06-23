`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 10:03:14 PM
// Design Name: 
// Module Name: subcarrier_extraction
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


module subcarrier_extraction #(
    parameter WIDTH = 16
    // WIDTH là ?? r?ng m?i thành ph?n I ho?c Q
    // Trong h? th?ng c?a mình, I/Q ?ang dùng 16 bit signed
)(
    input  wire                         clk,
    // Clock h? th?ng

    input  wire                         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? output v? 0

    input  wire                         fft_valid_in,
    // Tín hi?u báo i_rx_freq_bus và q_rx_freq_bus t? FFT ?ã h?p l?

    input  wire [8*WIDTH-1:0]           i_rx_freq_bus,
    // Bus ch?a 8 subcarrier ph?n I sau FFT
    // i_rx_freq_bus[15:0]     = Y_I[0]
    // i_rx_freq_bus[31:16]    = Y_I[1]
    // i_rx_freq_bus[47:32]    = Y_I[2]
    // i_rx_freq_bus[63:48]    = Y_I[3]
    // i_rx_freq_bus[79:64]    = Y_I[4]
    // i_rx_freq_bus[95:80]    = Y_I[5]
    // i_rx_freq_bus[111:96]   = Y_I[6]
    // i_rx_freq_bus[127:112]  = Y_I[7]

    input  wire [8*WIDTH-1:0]           q_rx_freq_bus,
    // Bus ch?a 8 subcarrier ph?n Q sau FFT
    // q_rx_freq_bus[15:0]     = Y_Q[0]
    // q_rx_freq_bus[31:16]    = Y_Q[1]
    // q_rx_freq_bus[47:32]    = Y_Q[2]
    // q_rx_freq_bus[63:48]    = Y_Q[3]
    // q_rx_freq_bus[79:64]    = Y_Q[4]
    // q_rx_freq_bus[95:80]    = Y_Q[5]
    // q_rx_freq_bus[111:96]   = Y_Q[6]
    // q_rx_freq_bus[127:112]  = Y_Q[7]

    output reg signed [WIDTH-1:0]       pilot0_i,
    // Thành ph?n I c?a pilot 0 nh?n ???c
    // pilot0 = Y[1]

    output reg signed [WIDTH-1:0]       pilot0_q,
    // Thành ph?n Q c?a pilot 0 nh?n ???c

    output reg signed [WIDTH-1:0]       pilot1_i,
    // Thành ph?n I c?a pilot 1 nh?n ???c
    // pilot1 = Y[6]

    output reg signed [WIDTH-1:0]       pilot1_q,
    // Thành ph?n Q c?a pilot 1 nh?n ???c

    output reg [4*WIDTH-1:0]            i_data_bus,
    // Bus ch?a 4 data subcarrier ph?n I
    // i_data_bus[15:0]   = D0_I_rx = Y_I[2]
    // i_data_bus[31:16]  = D1_I_rx = Y_I[3]
    // i_data_bus[47:32]  = D2_I_rx = Y_I[4]
    // i_data_bus[63:48]  = D3_I_rx = Y_I[5]

    output reg [4*WIDTH-1:0]            q_data_bus,
    // Bus ch?a 4 data subcarrier ph?n Q
    // q_data_bus[15:0]   = D0_Q_rx = Y_Q[2]
    // q_data_bus[31:16]  = D1_Q_rx = Y_Q[3]
    // q_data_bus[47:32]  = D2_Q_rx = Y_Q[4]
    // q_data_bus[63:48]  = D3_Q_rx = Y_Q[5]

    output reg                          extract_valid_out
    // Báo r?ng pilot và data sau khi tách ?ã h?p l?
);


    // ============================================================
    // 1. Logic chính c?a Subcarrier Extraction
    // ============================================================
    //
    // Sau FFT, ta có vector mi?n t?n s?:
    //
    //      Y = [Y0, Y1, Y2, Y3, Y4, Y5, Y6, Y7]
    //
    // Theo c?u trúc frame ?ã thi?t k? ? phía phát:
    //
    //      Y[0] : guard / zero
    //      Y[1] : pilot 0
    //      Y[2] : data 0
    //      Y[3] : data 1
    //      Y[4] : data 2
    //      Y[5] : data 3
    //      Y[6] : pilot 1
    //      Y[7] : guard / zero
    //
    // Kh?i này s?:
    //
    //      - B? qua Y[0] và Y[7]
    //      - Tách Y[1] làm pilot0
    //      - Tách Y[6] làm pilot1
    //      - Tách Y[2] ??n Y[5] làm data
    //
    // ============================================================


    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên clock
        // ho?c c?nh xu?ng c?a reset rst_n

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset toàn b? output

            pilot0_i <= {WIDTH{1'b0}};
            // Reset pilot0_i v? 0

            pilot0_q <= {WIDTH{1'b0}};
            // Reset pilot0_q v? 0

            pilot1_i <= {WIDTH{1'b0}};
            // Reset pilot1_i v? 0

            pilot1_q <= {WIDTH{1'b0}};
            // Reset pilot1_q v? 0

            i_data_bus <= {4*WIDTH{1'b0}};
            // Reset toàn b? bus data I v? 0

            q_data_bus <= {4*WIDTH{1'b0}};
            // Reset toàn b? bus data Q v? 0

            extract_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (fft_valid_in) begin
                // Ch? tách subcarrier khi output t? FFT h?p l?


                // ------------------------------------------------
                // 2. Tách pilot 0 t?i v? trí Y[1]
                // ------------------------------------------------

                pilot0_i <= $signed(i_rx_freq_bus[1*WIDTH +: WIDTH]);
                // L?y Y_I[1] làm thành ph?n I c?a pilot0
                // ?ây là pilot P0 sau khi ?i qua kênh và FFT

                pilot0_q <= $signed(q_rx_freq_bus[1*WIDTH +: WIDTH]);
                // L?y Y_Q[1] làm thành ph?n Q c?a pilot0


                // ------------------------------------------------
                // 3. Tách pilot 1 t?i v? trí Y[6]
                // ------------------------------------------------

                pilot1_i <= $signed(i_rx_freq_bus[6*WIDTH +: WIDTH]);
                // L?y Y_I[6] làm thành ph?n I c?a pilot1
                // ?ây là pilot P1 sau khi ?i qua kênh và FFT

                pilot1_q <= $signed(q_rx_freq_bus[6*WIDTH +: WIDTH]);
                // L?y Y_Q[6] làm thành ph?n Q c?a pilot1


                // ------------------------------------------------
                // 4. Tách data subcarrier Y[2], Y[3], Y[4], Y[5]
                // ------------------------------------------------

                i_data_bus[0*WIDTH +: WIDTH] <= i_rx_freq_bus[2*WIDTH +: WIDTH];
                // D0_I_rx = Y_I[2]
                // Data subcarrier ??u tiên

                q_data_bus[0*WIDTH +: WIDTH] <= q_rx_freq_bus[2*WIDTH +: WIDTH];
                // D0_Q_rx = Y_Q[2]


                i_data_bus[1*WIDTH +: WIDTH] <= i_rx_freq_bus[3*WIDTH +: WIDTH];
                // D1_I_rx = Y_I[3]
                // Data subcarrier th? hai

                q_data_bus[1*WIDTH +: WIDTH] <= q_rx_freq_bus[3*WIDTH +: WIDTH];
                // D1_Q_rx = Y_Q[3]


                i_data_bus[2*WIDTH +: WIDTH] <= i_rx_freq_bus[4*WIDTH +: WIDTH];
                // D2_I_rx = Y_I[4]
                // Data subcarrier th? ba

                q_data_bus[2*WIDTH +: WIDTH] <= q_rx_freq_bus[4*WIDTH +: WIDTH];
                // D2_Q_rx = Y_Q[4]


                i_data_bus[3*WIDTH +: WIDTH] <= i_rx_freq_bus[5*WIDTH +: WIDTH];
                // D3_I_rx = Y_I[5]
                // Data subcarrier th? t?

                q_data_bus[3*WIDTH +: WIDTH] <= q_rx_freq_bus[5*WIDTH +: WIDTH];
                // D3_Q_rx = Y_Q[5]


                // ------------------------------------------------
                // 5. B? qua guard subcarriers Y[0] và Y[7]
                // ------------------------------------------------
                //
                // Y[0] và Y[7] không ???c gán ra output.
                // ?ây là guard / zero subcarrier ?ã ??t ? phía phát.
                // Chúng không ??a vào Channel Estimation hay Demapper.
                // ------------------------------------------------


                extract_valid_out <= 1'b1;
                // Báo r?ng pilot và data sau khi tách ?ã h?p l?
            end

            else begin
                // N?u fft_valid_in = 0 thì không có frame FFT m?i

                extract_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là d? li?u m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module subcarrier_extraction
