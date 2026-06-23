`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 03:50:35 PM
// Design Name: 
// Module Name: channel_awgn_model
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


module channel_awgn_model #(
    parameter WIDTH       = 16,          // ?? r?ng m?i m?u I ho?c Q, h? th?ng ?ang dùng 16 bit signed
    parameter N           = 8,           // S? m?u OFDM sau IFFT
    parameter CP_LEN      = 2,           // ?? dài cyclic prefix
    parameter SCALE_SHIFT = 10           // Vì scale fixed-point = 1024 = 2^10, nên chia 1024 b?ng d?ch ph?i 10 bit
)(
    input  wire                         clk,              // Clock h? th?ng
    input  wire                         rst_n,            // Reset tích c?c m?c th?p, rst_n = 0 thì reset

    input  wire                         cp_valid_in,      // Báo i_cp_bus và q_cp_bus ??u vào h?p l?

    input  wire [(N+CP_LEN)*WIDTH-1:0]  i_cp_bus,         // Bus ch?a 10 m?u I sau cyclic prefix
    input  wire [(N+CP_LEN)*WIDTH-1:0]  q_cp_bus,         // Bus ch?a 10 m?u Q sau cyclic prefix

    input  wire signed [WIDTH-1:0]      channel_gain,     // H? s? kênh fixed-point, ví d? 1024 = h = 1,0
    input  wire                         noise_enable,     // Cho phép b?t ho?c t?t nhi?u AWGN gi? l?p

    output reg  [(N+CP_LEN)*WIDTH-1:0]  i_rx_cp_bus,      // Bus ch?a 10 m?u I sau kênh
    output reg  [(N+CP_LEN)*WIDTH-1:0]  q_rx_cp_bus,      // Bus ch?a 10 m?u Q sau kênh

    output reg                          rx_valid_out      // Báo output sau kênh ?ã h?p l?
);


    // ============================================================
    // 1. Khai báo bi?n n?i b?
    // ============================================================

    integer idx;
    // Bi?n idx dùng ?? duy?t qua 10 m?u:
    // idx = 0, 1, 2, ..., 9

    reg signed [WIDTH-1:0] sample_i;
    // L?u t?m m?t m?u I l?y ra t? i_cp_bus

    reg signed [WIDTH-1:0] sample_q;
    // L?u t?m m?t m?u Q l?y ra t? q_cp_bus

    reg signed [31:0] gain_i_temp;
    // L?u k?t qu? nhân kênh c?a nhánh I tr??c khi c?t v? 16 bit

    reg signed [31:0] gain_q_temp;
    // L?u k?t qu? nhân kênh c?a nhánh Q tr??c khi c?t v? 16 bit

    reg signed [31:0] rx_i_temp;
    // L?u k?t qu? sau khi c?ng noise nhánh I

    reg signed [31:0] rx_q_temp;
    // L?u k?t qu? sau khi c?ng noise nhánh Q


    // ============================================================
    // 2. Hàm saturation v? signed 16-bit
    // ============================================================
    //
    // Sau phép nhân và c?ng noise, giá tr? có th? v??t quá mi?n 16 bit.
    //
    // signed 16-bit có mi?n:
    //
    //      -32768 ??n +32767
    //
    // N?u v??t quá, ta gi?i h?n l?i ?? tránh tràn s?.
    //

    function signed [WIDTH-1:0] sat16;
        // Hàm tr? v? giá tr? signed WIDTH-bit, ? ?ây WIDTH = 16

        input signed [31:0] value;
        // Input là giá tr? 32 bit sau khi x? lý kênh và noise

        begin
            // B?t ??u thân hàm

            if (value > 32'sd32767) begin
                // N?u giá tr? l?n h?n m?c d??ng t?i ?a c?a signed 16-bit

                sat16 = 16'sd32767;
                // Gi?i h?n v? +32767
            end

            else if (value < -32'sd32768) begin
                // N?u giá tr? nh? h?n m?c âm t?i thi?u c?a signed 16-bit

                sat16 = -16'sd32768;
                // Gi?i h?n v? -32768
            end

            else begin
                // N?u giá tr? v?n n?m trong mi?n signed 16-bit

                sat16 = value[WIDTH-1:0];
                // L?y 16 bit th?p làm output
            end
        end
    endfunction


    // ============================================================
    // 3. Hàm t?o noise gi? l?p cho nhánh I
    // ============================================================
    //
    // AWGN th?t có phân b? Gaussian.
    // Tuy nhiên ?? ?? án Verilog d? mô ph?ng và d? ki?m tra,
    // ta dùng m?t dãy noise nh? c? ??nh ?? mô ph?ng tác ??ng c?a nhi?u.
    //
    // ?ây là pseudo-noise, không ph?i b? t?o Gaussian chu?n.
    //

    function signed [WIDTH-1:0] noise_i;
        // Hàm tr? v? noise cho nhánh I

        input [3:0] n;
        // Ch? s? m?u n, t? 0 ??n 9

        begin
            // B?t ??u thân hàm

            case (n)
                4'd0: noise_i = 16'sd10;     // Noise I t?i m?u 0
                4'd1: noise_i = -16'sd8;     // Noise I t?i m?u 1
                4'd2: noise_i = 16'sd6;      // Noise I t?i m?u 2
                4'd3: noise_i = -16'sd5;     // Noise I t?i m?u 3
                4'd4: noise_i = 16'sd3;      // Noise I t?i m?u 4
                4'd5: noise_i = -16'sd4;     // Noise I t?i m?u 5
                4'd6: noise_i = 16'sd7;      // Noise I t?i m?u 6
                4'd7: noise_i = -16'sd6;     // Noise I t?i m?u 7
                4'd8: noise_i = 16'sd2;      // Noise I t?i m?u 8
                4'd9: noise_i = -16'sd3;     // Noise I t?i m?u 9
                default: noise_i = 16'sd0;   // Tr??ng h?p d? phòng
            endcase
        end
    endfunction


    // ============================================================
    // 4. Hàm t?o noise gi? l?p cho nhánh Q
    // ============================================================

    function signed [WIDTH-1:0] noise_q;
        // Hàm tr? v? noise cho nhánh Q

        input [3:0] n;
        // Ch? s? m?u n, t? 0 ??n 9

        begin
            // B?t ??u thân hàm

            case (n)
                4'd0: noise_q = -16'sd4;     // Noise Q t?i m?u 0
                4'd1: noise_q = 16'sd5;      // Noise Q t?i m?u 1
                4'd2: noise_q = -16'sd7;     // Noise Q t?i m?u 2
                4'd3: noise_q = 16'sd6;      // Noise Q t?i m?u 3
                4'd4: noise_q = -16'sd2;     // Noise Q t?i m?u 4
                4'd5: noise_q = 16'sd3;      // Noise Q t?i m?u 5
                4'd6: noise_q = -16'sd5;     // Noise Q t?i m?u 6
                4'd7: noise_q = 16'sd4;      // Noise Q t?i m?u 7
                4'd8: noise_q = -16'sd1;     // Noise Q t?i m?u 8
                4'd9: noise_q = 16'sd2;      // Noise Q t?i m?u 9
                default: noise_q = 16'sd0;   // Tr??ng h?p d? phòng
            endcase
        end
    endfunction


    // ============================================================
    // 5. Logic chính c?a Channel AWGN Model
    // ============================================================
    //
    // Khi cp_valid_in = 1:
    //
    //      B??c 1: l?y t?ng m?u x_I[n], x_Q[n]
    //      B??c 2: nhân v?i channel_gain
    //      B??c 3: d?ch ph?i SCALE_SHIFT ?? ??a v? scale ban ??u
    //      B??c 4: c?ng noise n?u noise_enable = 1
    //      B??c 5: saturation v? 16 bit
    //      B??c 6: ?óng l?i vào i_rx_cp_bus, q_rx_cp_bus
    //
    // Công th?c:
    //
    //      r_I[n] = ((x_I[n] * channel_gain) >>> 10) + w_I[n]
    //      r_Q[n] = ((x_Q[n] * channel_gain) >>> 10) + w_Q[n]
    //
    // N?u noise_enable = 0:
    //
    //      w_I[n] = 0
    //      w_Q[n] = 0
    //

    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên clock ho?c c?nh xu?ng reset

        if (!rst_n) begin
            // N?u rst_n = 0 thì reset toàn b? output

            i_rx_cp_bus <= {(N+CP_LEN)*WIDTH{1'b0}};
            // Reset bus I sau kênh v? 0

            q_rx_cp_bus <= {(N+CP_LEN)*WIDTH{1'b0}};
            // Reset bus Q sau kênh v? 0

            rx_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?
        end

        else begin
            // N?u không reset thì h? th?ng ho?t ??ng bình th??ng

            if (cp_valid_in) begin
                // Ch? x? lý kênh khi d? li?u sau CP h?p l?

                for (idx = 0; idx < (N+CP_LEN); idx = idx + 1) begin
                    // Vòng l?p x? lý l?n l??t 10 m?u sau cyclic prefix


                    sample_i = $signed(i_cp_bus[idx*WIDTH +: WIDTH]);
                    // L?y m?u I th? idx t? i_cp_bus
                    // $signed giúp Verilog hi?u ?ây là s? có d?u

                    sample_q = $signed(q_cp_bus[idx*WIDTH +: WIDTH]);
                    // L?y m?u Q th? idx t? q_cp_bus
                    // $signed giúp x? lý ?úng giá tr? âm


                    gain_i_temp = (sample_i * channel_gain) >>> SCALE_SHIFT;
                    // Nhân m?u I v?i h? s? kênh fixed-point
                    //
                    // channel_gain = h * 1024
                    // nên sau khi nhân ph?i d?ch ph?i 10 bit ?? chia cho 1024
                    //
                    // Ví d?:
                    // h = 0,75 ? channel_gain = 768
                    // sample_i = 1000
                    // gain_i_temp = (1000 * 768) >>> 10 = 750

                    gain_q_temp = (sample_q * channel_gain) >>> SCALE_SHIFT;
                    // Làm t??ng t? cho nhánh Q


                    if (noise_enable) begin
                        // N?u b?t noise

                        rx_i_temp = gain_i_temp + noise_i(idx[3:0]);
                        // C?ng noise gi? l?p vào nhánh I

                        rx_q_temp = gain_q_temp + noise_q(idx[3:0]);
                        // C?ng noise gi? l?p vào nhánh Q
                    end

                    else begin
                        // N?u t?t noise

                        rx_i_temp = gain_i_temp;
                        // Nhánh I ch? còn tác ??ng c?a channel gain

                        rx_q_temp = gain_q_temp;
                        // Nhánh Q ch? còn tác ??ng c?a channel gain
                    end


                    i_rx_cp_bus[idx*WIDTH +: WIDTH] <= sat16(rx_i_temp);
                    // ??a k?t qu? I sau kênh v? 16 bit và ghi vào output bus

                    q_rx_cp_bus[idx*WIDTH +: WIDTH] <= sat16(rx_q_temp);
                    // ??a k?t qu? Q sau kênh v? 16 bit và ghi vào output bus

                end

                rx_valid_out <= 1'b1;
                // Sau khi x? lý ?? 10 m?u, báo output h?p l?
            end

            else begin
                // N?u cp_valid_in = 0 thì không có frame m?i

                rx_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là frame m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module channel_awgn_model
