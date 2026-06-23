`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2026 09:40:28 PM
// Design Name: 
// Module Name: receiver_output_module
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


module receiver_output_module (
    input  wire        clk,
    // Clock h? th?ng

    input  wire        rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset output v? 0

    input  wire [3:0]  demap_data_in,
    // 4 bit d? li?u nh?n t? kh?i 16-QAM Demapper
    // ?ây là d? li?u ?ã ???c khôi ph?c sau toàn b? chu?i OFDM receiver

    input  wire        demap_data_valid,
    // Tín hi?u báo demap_data_in hi?n t?i h?p l?
    // Tín hi?u này n?i t? data_valid c?a qam16_demapper

    output reg  [3:0]  rx_data,
    // 4 bit d? li?u ??u ra cu?i cùng c?a receiver

    output reg         rx_data_valid
    // Báo r?ng rx_data hi?n t?i h?p l?
);


    // ============================================================
    // 1. Logic chính c?a Receiver Output Module
    // ============================================================
    //
    // Khi demap_data_valid = 1:
    //
    //      rx_data       = demap_data_in
    //      rx_data_valid = 1
    //
    // Khi demap_data_valid = 0:
    //
    //      rx_data_valid = 0
    //
    // Kh?i này ?óng vai trò ch?t d? li?u cu?i cùng c?a receiver.
    // ============================================================


    always @(posedge clk or negedge rst_n) begin
        // Kh?i always ch?y t?i c?nh lên clock
        // ho?c c?nh xu?ng reset rst_n

        if (!rst_n) begin
            // N?u reset ???c kích ho?t, t?c rst_n = 0

            rx_data <= 4'b0000;
            // Reset d? li?u ??u ra v? 0

            rx_data_valid <= 1'b0;
            // Khi reset, d? li?u ??u ra ch?a h?p l?
        end

        else begin
            // N?u không reset, h? th?ng ho?t ??ng bình th??ng

            if (demap_data_valid) begin
                // Khi d? li?u t? 16-QAM Demapper h?p l?

                rx_data <= demap_data_in;
                // Ch?t 4 bit d? li?u khôi ph?c vào output receiver

                rx_data_valid <= 1'b1;
                // Báo r?ng rx_data hi?n t?i h?p l?
            end

            else begin
                // Khi ch?a có d? li?u m?i t? Demapper

                rx_data_valid <= 1'b0;
                // Output hi?n t?i không ???c xem là d? li?u m?i h?p l?

                rx_data <= rx_data;
                // Gi? nguyên d? li?u c?
                // Dòng này có th? b?, vì register t? gi? giá tr? n?u không gán m?i
            end
        end
    end

endmodule
// K?t thúc module receiver_output_module

