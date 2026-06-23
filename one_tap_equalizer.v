`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 04:01:35 PM
// Design Name: 
// Module Name: one_tap_equalizer
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


module one_tap_equalizer #(
    parameter WIDTH       = 16,          // ?? r?ng m?i m?u I ho?c Q, h? th?ng ?ang dùng signed 16-bit
    parameter NUM_DATA    = 4,           // Có 4 data subcarrier: Y[2], Y[3], Y[4], Y[5]
    parameter SCALE_SHIFT = 10           // Vì 1024 = 2^10, dùng làm h? s? fixed-point scale
)(
    input  wire                         clk,
    // Clock h? th?ng

    input  wire                         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset toàn b? output

    input  wire                         h_est_valid_in,
    // Báo r?ng h? s? kênh h_est_i, h_est_q ?ã h?p l?
    // Tín hi?u này n?i t? h_est_valid_out c?a kh?i channel_estimation

    input  wire [NUM_DATA*WIDTH-1:0]    i_data_bus,
    // Bus ch?a 4 data subcarrier ph?n I sau Subcarrier Extraction
    // i_data_bus[15:0]   = Y_I[2]
    // i_data_bus[31:16]  = Y_I[3]
    // i_data_bus[47:32]  = Y_I[4]
    // i_data_bus[63:48]  = Y_I[5]

    input  wire [NUM_DATA*WIDTH-1:0]    q_data_bus,
    // Bus ch?a 4 data subcarrier ph?n Q sau Subcarrier Extraction
    // q_data_bus[15:0]   = Y_Q[2]
    // q_data_bus[31:16]  = Y_Q[3]
    // q_data_bus[47:32]  = Y_Q[4]
    // q_data_bus[63:48]  = Y_Q[5]

    input  wire signed [WIDTH-1:0]      h_est_i,
    // Thành ph?n th?c c?a h? s? kênh ??c l??ng
    // Trong phiên b?n hi?n t?i, ta dùng h_est_i ?? bù biên ??

    input  wire signed [WIDTH-1:0]      h_est_q,
    // Thành ph?n ?o c?a h? s? kênh ??c l??ng
    // ? phiên b?n ??n gi?n này ch?a dùng h_est_q vì Channel AWGN Model ?ang dùng kênh th?c

    output reg  [NUM_DATA*WIDTH-1:0]    i_eq_data_bus,
    // Bus ch?a 4 data subcarrier ph?n I sau equalizer
    // ?ây là d? li?u ?ã ???c bù kênh

    output reg  [NUM_DATA*WIDTH-1:0]    q_eq_data_bus,
    // Bus ch?a 4 data subcarrier ph?n Q sau equalizer

    output reg                          eq_valid_out
    // Báo r?ng i_eq_data_bus và q_eq_data_bus ?ã h?p l?
);


    // ============================================================
    // 1. Khai báo h?ng s? fixed-point scale
    // ============================================================
    //
    // Ta ?ã quy ??c:
    //
    //      h_fixed = h * 1024
    //
    // Vì v?y khi bù kênh:
    //
    //      X_hat = Y / h
    //
    // mà:
    //
    //      h = h_est_i / 1024
    //
    // nên:
    //
    //      X_hat = Y * 1024 / h_est_i
    //
    // ============================================================

    localparam signed [31:0] SCALE_VALUE = 32'sd1024;
    // Giá tr? scale fixed-point b?ng 1024


    // ============================================================
    // 2. Khai báo bi?n n?i b?
    // ============================================================

    integer idx;
    // Bi?n idx dùng ?? duy?t qua 4 data subcarrier

    reg signed [WIDTH-1:0] sample_i;
    // L?u t?m m?t m?u data ph?n I l?y t? i_data_bus

    reg signed [WIDTH-1:0] sample_q;
    // L?u t?m m?t m?u data ph?n Q l?y t? q_data_bus

    reg signed [31:0] scaled_i_temp;
    // L?u k?t qu? sample_i * 1024 tr??c khi chia cho h_est_i

    reg signed [31:0] scaled_q_temp;
    // L?u k?t qu? sample_q * 1024 tr??c khi chia cho h_est_i

    reg signed [31:0] eq_i_temp;
    // L?u k?t qu? equalizer ph?n I tr??c khi saturation v? 16 bit

    reg signed [31:0] eq_q_temp;
    // L?u k?t qu? equalizer ph?n Q tr??c khi saturation v? 16 bit


    // ============================================================
    // 3. Hàm saturation v? signed 16-bit
    // ============================================================
    //
    // Sau phép nhân và chia, k?t qu? có th? v??t quá mi?n 16-bit.
    //
    // signed 16-bit có mi?n:
    //
    //      -32768 ??n +32767
    //
    // N?u v??t quá, ta gi?i h?n l?i ?? tránh tràn s?.
    // ============================================================

    function signed [WIDTH-1:0] sat16;
        // Hàm tr? v? giá tr? signed WIDTH-bit

        input signed [31:0] value;
        // Input là giá tr? 32-bit sau equalizer

        begin
            // B?t ??u thân hàm

            if (value > 32'sd32767) begin
                // N?u giá tr? l?n h?n gi?i h?n d??ng c?a signed 16-bit

                sat16 = 16'sd32767;
                // Gi?i h?n v? +32767
            end

            else if (value < -32'sd32768) begin
                // N?u giá tr? nh? h?n gi?i h?n âm c?a signed 16-bit

                sat16 = -16'sd32768;
                // Gi?i h?n v? -32768
            end

            else begin
                // N?u giá tr? n?m trong mi?n signed 16-bit

                sat16 = value[WIDTH-1:0];
                // L?y 16 bit th?p làm output
            end
        end
    endfunction


    // ============================================================
    // 4. Logic chính c?a One-Tap Equalizer
    // ============================================================
    //
    // Khi h_est_valid_in = 1:
    //
    //      B??c 1: l?y t?ng data subcarrier Y[k]
    //      B??c 2: nhân Y_I[k] và Y_Q[k] v?i 1024
    //      B??c 3: chia cho h_est_i
    //      B??c 4: saturation v? signed 16-bit
    //      B??c 5: ?óng gói l?i thành i_eq_data_bus, q_eq_data_bus
    //
    // Công th?c:
    //
    //      X_hat_I[k] = (Y_I[k] * 1024) / h_est_i
    //      X_hat_Q[k] = (Y_Q[k] * 1024) / h_est_i
    //
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên clock
        // ho?c c?nh xu?ng reset rst_n

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset toàn b? output

            i_eq_data_bus <= {NUM_DATA*WIDTH{1'b0}};
            // Reset bus I sau equalizer v? 0

            q_eq_data_bus <= {NUM_DATA*WIDTH{1'b0}};
            // Reset bus Q sau equalizer v? 0

            eq_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (h_est_valid_in) begin
                // Ch? th?c hi?n equalizer khi h_est_i ?ã h?p l?


                if (h_est_i == 16'sd0) begin
                    // N?u h_est_i = 0 thì không ???c chia
                    // ?ây là b?o v? tránh l?i chia cho 0

                    i_eq_data_bus <= {NUM_DATA*WIDTH{1'b0}};
                    // N?u không ??c l??ng ???c kênh, cho output I = 0

                    q_eq_data_bus <= {NUM_DATA*WIDTH{1'b0}};
                    // N?u không ??c l??ng ???c kênh, cho output Q = 0

                    eq_valid_out <= 1'b1;
                    // V?n báo output h?p l?, nh?ng output là 0 do l?i kênh
                end

                else begin
                    // N?u h_est_i khác 0 thì th?c hi?n equalization bình th??ng

                    for (idx = 0; idx < NUM_DATA; idx = idx + 1) begin
                        // Vòng l?p x? lý 4 data subcarrier:
                        // idx = 0 t??ng ?ng Y[2]
                        // idx = 1 t??ng ?ng Y[3]
                        // idx = 2 t??ng ?ng Y[4]
                        // idx = 3 t??ng ?ng Y[5]


                        sample_i = $signed(i_data_bus[idx*WIDTH +: WIDTH]);
                        // L?y m?u I th? idx t? i_data_bus
                        // $signed giúp Verilog hi?u ?ây là s? có d?u

                        sample_q = $signed(q_data_bus[idx*WIDTH +: WIDTH]);
                        // L?y m?u Q th? idx t? q_data_bus


                        scaled_i_temp = $signed(sample_i) * SCALE_VALUE;
                        // Nhân nhánh I v?i 1024
                        //
                        // ?ây là t? s? c?a công th?c:
                        //      X_hat_I = Y_I * 1024 / h_est_i

                        scaled_q_temp = $signed(sample_q) * SCALE_VALUE;
                        // Nhân nhánh Q v?i 1024
                        //
                        // ?ây là t? s? c?a công th?c:
                        //      X_hat_Q = Y_Q * 1024 / h_est_i


                        eq_i_temp = scaled_i_temp / $signed(h_est_i);
                        // Chia cho h? s? kênh ??c l??ng
                        //
                        // N?u h_est_i = 768, ngh?a là h ? 0.75
                        // thì phép chia này s? bù l?i suy hao 0.75

                        eq_q_temp = scaled_q_temp / $signed(h_est_i);
                        // Làm t??ng t? cho nhánh Q


                        i_eq_data_bus[idx*WIDTH +: WIDTH] <= sat16(eq_i_temp);
                        // Gi?i h?n k?t qu? I v? signed 16-bit
                        // r?i ghi vào bus output

                        q_eq_data_bus[idx*WIDTH +: WIDTH] <= sat16(eq_q_temp);
                        // Gi?i h?n k?t qu? Q v? signed 16-bit
                        // r?i ghi vào bus output

                    end

                    eq_valid_out <= 1'b1;
                    // Sau khi x? lý ?? 4 data subcarrier, báo output h?p l?
                end
            end

            else begin
                // N?u h_est_valid_in = 0 thì ch?a có h? s? kênh h?p l?

                eq_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là d? li?u m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module one_tap_equalizer

