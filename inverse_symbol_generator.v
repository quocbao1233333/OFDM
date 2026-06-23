`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 09:39:31 PM
// Design Name: 
// Module Name: inverse_symbol_generator
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


module inverse_symbol_generator #(
    parameter WIDTH    = 16,             // ?? r?ng m?i thành ph?n I ho?c Q, h? th?ng ?ang dùng signed 16-bit
    parameter NUM_DATA = 4               // S? symbol data sau equalizer, ? ?ây là 4 symbol
)(
    input  wire                         clk,              // Clock h? th?ng
    input  wire                         rst_n,            // Reset tích c?c m?c th?p, rst_n = 0 thì reset

    input  wire                         eq_valid_in,      // Báo i_eq_data_bus và q_eq_data_bus t? Equalizer h?p l?

    input  wire [NUM_DATA*WIDTH-1:0]    i_eq_data_bus,    // Bus ch?a 4 symbol ph?n I sau equalizer
    input  wire [NUM_DATA*WIDTH-1:0]    q_eq_data_bus,    // Bus ch?a 4 symbol ph?n Q sau equalizer

    output reg  signed [WIDTH-1:0]      symbol_i_out,     // Thành ph?n I c?a symbol QAM ??i di?n
    output reg  signed [WIDTH-1:0]      symbol_q_out,     // Thành ph?n Q c?a symbol QAM ??i di?n

    output reg                          symbol_valid_out  // Báo symbol_i_out và symbol_q_out h?p l?
);


    // ============================================================
    // 1. Khai báo bi?n trung gian
    // ============================================================

    reg signed [31:0] d0_i;
    // Thành ph?n I c?a symbol D0 sau equalizer

    reg signed [31:0] d1_i;
    // Thành ph?n I c?a symbol D1 sau equalizer

    reg signed [31:0] d2_i;
    // Thành ph?n I c?a symbol D2 sau equalizer

    reg signed [31:0] d3_i;
    // Thành ph?n I c?a symbol D3 sau equalizer


    reg signed [31:0] d0_q;
    // Thành ph?n Q c?a symbol D0 sau equalizer

    reg signed [31:0] d1_q;
    // Thành ph?n Q c?a symbol D1 sau equalizer

    reg signed [31:0] d2_q;
    // Thành ph?n Q c?a symbol D2 sau equalizer

    reg signed [31:0] d3_q;
    // Thành ph?n Q c?a symbol D3 sau equalizer


    reg signed [31:0] sum_i_temp;
    // T?ng 4 giá tr? I:
    // sum_i_temp = D0_I + D1_I + D2_I + D3_I

    reg signed [31:0] sum_q_temp;
    // T?ng 4 giá tr? Q:
    // sum_q_temp = D0_Q + D1_Q + D2_Q + D3_Q


    reg signed [31:0] avg_i_temp;
    // Giá tr? trung bình ph?n I tr??c khi ??a v? 16 bit

    reg signed [31:0] avg_q_temp;
    // Giá tr? trung bình ph?n Q tr??c khi ??a v? 16 bit


    // ============================================================
    // 2. Hàm saturation v? signed 16-bit
    // ============================================================
    //
    // Sau khi c?ng và l?y trung bình, k?t qu? th??ng n?m trong 16 bit.
    // Tuy nhiên ?? an toàn, ta v?n gi?i h?n giá tr? v? mi?n:
    //
    //      -32768 ??n +32767
    //
    // N?u k?t qu? v??t quá mi?n này, ta ch?n l?i.
    // ============================================================

    function signed [WIDTH-1:0] sat16;
        // Hàm tr? v? giá tr? signed WIDTH-bit

        input signed [31:0] value;
        // Input là giá tr? 32-bit c?n ??a v? 16-bit

        begin
            // B?t ??u thân hàm

            if (value > 32'sd32767) begin
                // N?u giá tr? l?n h?n gi?i h?n d??ng c?a signed 16-bit

                sat16 = 16'sd32767;
                // Ch?n v? +32767
            end

            else if (value < -32'sd32768) begin
                // N?u giá tr? nh? h?n gi?i h?n âm c?a signed 16-bit

                sat16 = -16'sd32768;
                // Ch?n v? -32768
            end

            else begin
                // N?u giá tr? n?m trong mi?n signed 16-bit

                sat16 = value[WIDTH-1:0];
                // L?y 16 bit th?p làm k?t qu?
            end
        end
    endfunction


    // ============================================================
    // 3. Logic chính c?a Inverse Symbol Generator
    // ============================================================
    //
    // Input t? One-Tap Equalizer:
    //
    //      D0_eq, D1_eq, D2_eq, D3_eq
    //
    // M?i symbol có d?ng:
    //
    //      Dm_eq = Dm_I + jDm_Q
    //
    // Kh?i này l?y trung bình:
    //
    //      symbol_i_out = (D0_I + D1_I + D2_I + D3_I) / 4
    //      symbol_q_out = (D0_Q + D1_Q + D2_Q + D3_Q) / 4
    //
    // Vì chia cho 4 nên trong Verilog dùng d?ch ph?i s? có d?u:
    //
    //      >>> 2
    //
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ho?t ??ng t?i c?nh lên clock
        // ho?c c?nh xu?ng c?a reset rst_n

        if (!rst_n) begin
            // N?u reset ???c kích ho?t, t?c rst_n = 0

            symbol_i_out <= 16'sd0;
            // Reset output I v? 0

            symbol_q_out <= 16'sd0;
            // Reset output Q v? 0

            symbol_valid_out <= 1'b0;
            // Khi reset, output ch?a h?p l?

            d0_i <= 32'sd0;
            // Reset bi?n t?m D0_I

            d1_i <= 32'sd0;
            // Reset bi?n t?m D1_I

            d2_i <= 32'sd0;
            // Reset bi?n t?m D2_I

            d3_i <= 32'sd0;
            // Reset bi?n t?m D3_I

            d0_q <= 32'sd0;
            // Reset bi?n t?m D0_Q

            d1_q <= 32'sd0;
            // Reset bi?n t?m D1_Q

            d2_q <= 32'sd0;
            // Reset bi?n t?m D2_Q

            d3_q <= 32'sd0;
            // Reset bi?n t?m D3_Q

            sum_i_temp <= 32'sd0;
            // Reset t?ng I

            sum_q_temp <= 32'sd0;
            // Reset t?ng Q

            avg_i_temp <= 32'sd0;
            // Reset trung bình I

            avg_q_temp <= 32'sd0;
            // Reset trung bình Q
        end

        else begin
            // N?u không reset, h? th?ng ho?t ??ng bình th??ng

            if (eq_valid_in) begin
                // Ch? x? lý khi d? li?u t? One-Tap Equalizer h?p l?


                // ------------------------------------------------
                // 3.1. Tách 4 symbol ph?n I t? i_eq_data_bus
                // ------------------------------------------------

                d0_i = $signed(i_eq_data_bus[0*WIDTH +: WIDTH]);
                // L?y D0_I t? i_eq_data_bus[15:0]

                d1_i = $signed(i_eq_data_bus[1*WIDTH +: WIDTH]);
                // L?y D1_I t? i_eq_data_bus[31:16]

                d2_i = $signed(i_eq_data_bus[2*WIDTH +: WIDTH]);
                // L?y D2_I t? i_eq_data_bus[47:32]

                d3_i = $signed(i_eq_data_bus[3*WIDTH +: WIDTH]);
                // L?y D3_I t? i_eq_data_bus[63:48]


                // ------------------------------------------------
                // 3.2. Tách 4 symbol ph?n Q t? q_eq_data_bus
                // ------------------------------------------------

                d0_q = $signed(q_eq_data_bus[0*WIDTH +: WIDTH]);
                // L?y D0_Q t? q_eq_data_bus[15:0]

                d1_q = $signed(q_eq_data_bus[1*WIDTH +: WIDTH]);
                // L?y D1_Q t? q_eq_data_bus[31:16]

                d2_q = $signed(q_eq_data_bus[2*WIDTH +: WIDTH]);
                // L?y D2_Q t? q_eq_data_bus[47:32]

                d3_q = $signed(q_eq_data_bus[3*WIDTH +: WIDTH]);
                // L?y D3_Q t? q_eq_data_bus[63:48]


                // ------------------------------------------------
                // 3.3. C?ng 4 symbol trên t?ng nhánh I và Q
                // ------------------------------------------------

                sum_i_temp = d0_i + d1_i + d2_i + d3_i;
                // T?ng ph?n I c?a 4 symbol sau equalizer

                sum_q_temp = d0_q + d1_q + d2_q + d3_q;
                // T?ng ph?n Q c?a 4 symbol sau equalizer


                // ------------------------------------------------
                // 3.4. L?y trung bình b?ng cách chia cho 4
                // ------------------------------------------------

                avg_i_temp = sum_i_temp >>> 2;
                // L?y trung bình ph?n I
                // D?ch ph?i s? có d?u 2 bit t??ng ???ng chia cho 4

                avg_q_temp = sum_q_temp >>> 2;
                // L?y trung bình ph?n Q


                // ------------------------------------------------
                // 3.5. Saturation và xu?t symbol ??i di?n
                // ------------------------------------------------

                symbol_i_out <= sat16(avg_i_temp);
                // ??a k?t qu? trung bình I v? signed 16-bit

                symbol_q_out <= sat16(avg_q_temp);
                // ??a k?t qu? trung bình Q v? signed 16-bit

                symbol_valid_out <= 1'b1;
                // Báo symbol ??u ra ?ã h?p l?
            end

            else begin
                // N?u eq_valid_in = 0 thì ch?a có d? li?u m?i t? Equalizer

                symbol_valid_out <= 1'b0;
                // Output hi?n t?i không ???c xem là symbol m?i h?p l?
            end
        end
    end

endmodule
// K?t thúc module inverse_symbol_generator
