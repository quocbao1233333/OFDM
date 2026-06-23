`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2026 08:37:27 PM
// Design Name: 
// Module Name: ifft8_ip_wrapper
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


module ifft8_ip_wrapper #(
    parameter WIDTH = 16
    // WIDTH = 16 vì m?i thành ph?n I ho?c Q ?ang dùng signed 16-bit
)(
    input  wire                         clk,
    // Clock h? th?ng

    input  wire                         rst_n,
    // Reset tích c?c m?c th?p
    // rst_n = 0 thì reset wrapper và reset IP FFT/IFFT

    input  wire                         freq_valid_in,
    // Tín hi?u báo i_freq_bus và q_freq_bus ??u vào h?p l?
    // Tín hi?u này n?i t? pilot_valid_out c?a kh?i pilot_insertion

    input  wire [8*WIDTH-1:0]           i_freq_bus,
    // Bus ch?a 8 m?u mi?n t?n s? ph?n I
    // i_freq_bus[15:0]     = X_I[0]
    // i_freq_bus[31:16]    = X_I[1]
    // ...
    // i_freq_bus[127:112]  = X_I[7]

    input  wire [8*WIDTH-1:0]           q_freq_bus,
    // Bus ch?a 8 m?u mi?n t?n s? ph?n Q
    // q_freq_bus[15:0]     = X_Q[0]
    // q_freq_bus[31:16]    = X_Q[1]
    // ...
    // q_freq_bus[127:112]  = X_Q[7]

    output reg  [8*WIDTH-1:0]           i_time_bus,
    // Bus ch?a 8 m?u mi?n th?i gian ph?n I sau IFFT
    // i_time_bus[15:0]     = x_I[0]
    // i_time_bus[31:16]    = x_I[1]
    // ...
    // i_time_bus[127:112]  = x_I[7]

    output reg  [8*WIDTH-1:0]           q_time_bus,
    // Bus ch?a 8 m?u mi?n th?i gian ph?n Q sau IFFT

    output reg                          ifft_valid_out,
    // Báo r?ng i_time_bus và q_time_bus ??u ra ?ã h?p l?

    output wire                         event_frame_started,
    // Debug: IP báo b?t ??u x? lý m?t frame

    output wire                         event_tlast_unexpected,
    // Debug: báo TLAST ??n s?m h?n d? ki?n

    output wire                         event_tlast_missing,
    // Debug: báo thi?u TLAST ? cu?i frame

    output wire                         event_status_channel_halt,
    // Debug: status channel b? halt

    output wire                         event_data_in_channel_halt,
    // Debug: input data channel b? halt

    output wire                         event_data_out_channel_halt
    // Debug: output data channel b? halt
);


    // ============================================================
    // 1. Khai báo tr?ng thái FSM
    // ============================================================
    //
    // Wrapper c?n ?i?u khi?n IP theo th? t?:
    //
    // IDLE   : ch? frame t? pilot_insertion
    // CONFIG : g?i c?u hình ch?n IFFT
    // SEND   : g?i 8 m?u X[0] ??n X[7] vào IP
    // RECV   : nh?n 8 m?u x[0] ??n x[7] t? IP
    //

    localparam ST_IDLE   = 2'd0;
    // Tr?ng thái ch? input frame h?p l?

    localparam ST_CONFIG = 2'd1;
    // Tr?ng thái g?i config cho IP

    localparam ST_SEND   = 2'd2;
    // Tr?ng thái stream 8 m?u vào IP

    localparam ST_RECV   = 2'd3;
    // Tr?ng thái nh?n 8 m?u output t? IP


    reg [1:0] state;
    // Thanh ghi l?u tr?ng thái hi?n t?i c?a FSM

    reg [3:0] in_count;
    // ??m s? m?u ?ã g?i vào IP
    // V?i IFFT 8-point, in_count ch?y t? 0 ??n 7

    reg [3:0] out_count;
    // ??m s? m?u ?ã nh?n t? IP
    // V?i IFFT 8-point, out_count ch?y t? 0 ??n 7


    // ============================================================
    // 2. Thanh ghi l?u frame ??u vào
    // ============================================================
    //
    // Khi freq_valid_in = 1, ta ch?t toàn b? frame mi?n t?n s?.
    // Lý do: trong lúc wrapper ?ang g?i t?ng m?u vào IP,
    // input bus bên ngoài có th? thay ??i.
    //

    reg [8*WIDTH-1:0] i_freq_reg;
    // L?u l?i 8 m?u ph?n I c?a frame hi?n t?i

    reg [8*WIDTH-1:0] q_freq_reg;
    // L?u l?i 8 m?u ph?n Q c?a frame hi?n t?i


    // ============================================================
    // 3. Tín hi?u c?u hình cho IP IFFT
    // ============================================================
    //
    // Theo file .veo b?n g?i:
    //
    // .s_axis_config_tdata  là input wire [7:0]
    // .s_axis_config_tvalid là input wire
    // .s_axis_config_tready là output wire
    //
    // Ta ?ang dùng IP này cho IFFT.
    // V?i c?u hình runtime FFT/IFFT, FWD_INV = 0 ngh?a là IFFT.
    //
    // ? ?ây dùng 8'b0000_0000:
    // - ch?n IFFT
    // - scaling schedule ?? m?c ??nh ??n gi?n
    //

    wire [7:0] s_axis_config_tdata;
    // Bus config ?úng 8 bit theo .veo

    wire       s_axis_config_tvalid;
    // Config valid g?i vào IP

    wire       s_axis_config_tready;
    // IP báo s?n sàng nh?n config

    assign s_axis_config_tdata = 8'b0000_0000;
    // Config ch?n IFFT
    // Vì ?ây là wrapper IFFT bên phát

    assign s_axis_config_tvalid = (state == ST_CONFIG);
    // Ch? b?t config valid trong tr?ng thái ST_CONFIG


    // ============================================================
    // 4. Tín hi?u AXI4-Stream input ??a vào IFFT IP
    // ============================================================
    //
    // IP nh?n t?ng m?u complex:
    //
    //      X[k] = I[k] + jQ[k]
    //
    // Theo quy ??c c?a wrapper:
    //
    //      s_axis_data_tdata[15:0]  = I / real
    //      s_axis_data_tdata[31:16] = Q / imag
    //

    wire [2*WIDTH-1:0] s_axis_data_tdata;
    // D? li?u complex ??a vào IP, WIDTH=16 nên t?ng là 32 bit

    wire               s_axis_data_tvalid;
    // Báo input sample hi?n t?i h?p l?

    wire               s_axis_data_tready;
    // IP báo s?n sàng nh?n input sample

    wire               s_axis_data_tlast;
    // Báo m?u cu?i frame
    // V?i IFFT 8-point, TLAST b?t t?i X[7]


    assign s_axis_data_tdata = {
        q_freq_reg[in_count*WIDTH +: WIDTH],
        i_freq_reg[in_count*WIDTH +: WIDTH]
    };
    // ?óng gói sample X[in_count] vào AXI TDATA
    //
    // Ph?n cao [31:16] = Q / imaginary
    // Ph?n th?p [15:0] = I / real

    assign s_axis_data_tvalid = (state == ST_SEND);
    // Ch? g?i data vào IP khi FSM ?ang ? tr?ng thái ST_SEND

    assign s_axis_data_tlast = (state == ST_SEND) && (in_count == 4'd7);
    // TLAST = 1 t?i m?u cu?i cùng X[7]


    // ============================================================
    // 5. Tín hi?u AXI4-Stream output nh?n t? IFFT IP
    // ============================================================

    wire [2*WIDTH-1:0] m_axis_data_tdata;
    // D? li?u complex output t? IP

    wire               m_axis_data_tvalid;
    // IP báo output sample hi?n t?i h?p l?

    wire               m_axis_data_tready;
    // Wrapper báo s?n sàng nh?n output

    wire               m_axis_data_tlast;
    // IP báo output sample cu?i frame

    assign m_axis_data_tready = 1'b1;
    // Wrapper luôn s?n sàng nh?n output t? IFFT IP
    // ?i?u này giúp tránh làm ngh?n output channel


    // ============================================================
    // 6. FSM ?i?u khi?n toàn b? quá trình IFFT
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        // Kh?i tu?n t? ch?y theo c?nh lên clock
        // ho?c c?nh xu?ng reset rst_n

        if (!rst_n) begin
            // Khi reset active-low ???c kích ho?t

            state <= ST_IDLE;
            // ??a FSM v? tr?ng thái ch?

            in_count <= 4'd0;
            // Reset b? ??m input

            out_count <= 4'd0;
            // Reset b? ??m output

            i_freq_reg <= {8*WIDTH{1'b0}};
            // Xóa thanh ghi l?u frame I ??u vào

            q_freq_reg <= {8*WIDTH{1'b0}};
            // Xóa thanh ghi l?u frame Q ??u vào

            i_time_bus <= {8*WIDTH{1'b0}};
            // Xóa bus I ??u ra

            q_time_bus <= {8*WIDTH{1'b0}};
            // Xóa bus Q ??u ra

            ifft_valid_out <= 1'b0;
            // Output ch?a h?p l? khi reset
        end

        else begin
            // Khi không reset, h? th?ng ho?t ??ng bình th??ng

            ifft_valid_out <= 1'b0;
            // M?c ??nh kéo valid xu?ng 0 m?i chu k?
            // Ch? b?t lên 1 khi ?ã nh?n ?? 8 m?u output

            case (state)

                // ------------------------------------------------
                // ST_IDLE: ch? frame mi?n t?n s? t? Pilot Insertion
                // ------------------------------------------------
                ST_IDLE: begin

                    in_count <= 4'd0;
                    // Chu?n b? g?i t? m?u X[0]

                    out_count <= 4'd0;
                    // Chu?n b? nh?n t? m?u x[0]

                    if (freq_valid_in) begin
                        // Khi frame ??u vào h?p l?

                        i_freq_reg <= i_freq_bus;
                        // L?u toàn b? bus I mi?n t?n s?

                        q_freq_reg <= q_freq_bus;
                        // L?u toàn b? bus Q mi?n t?n s?

                        state <= ST_CONFIG;
                        // Chuy?n sang tr?ng thái g?i config cho IP
                    end
                end


                // ------------------------------------------------
                // ST_CONFIG: g?i c?u hình ch?n IFFT cho IP
                // ------------------------------------------------
                ST_CONFIG: begin

                    if (s_axis_config_tready) begin
                        // Khi IP s?n sàng nh?n config
                        //
                        // Vì s_axis_config_tvalid = 1 trong ST_CONFIG,
                        // nên t?i th?i ?i?m tready = 1, config handshake thành công.

                        state <= ST_SEND;
                        // Sau khi g?i config, chuy?n sang g?i data
                    end
                end


                // ------------------------------------------------
                // ST_SEND: g?i 8 m?u X[0] ??n X[7] vào IFFT IP
                // ------------------------------------------------
                ST_SEND: begin

                    if (s_axis_data_tready) begin
                        // M?t m?u ???c truy?n khi:
                        //
                        //      s_axis_data_tvalid = 1
                        //      s_axis_data_tready = 1
                        //
                        // Trong ST_SEND, tvalid luôn b?ng 1.
                        // Vì v?y ch? c?n ki?m tra tready.

                        if (in_count == 4'd7) begin
                            // N?u v?a g?i xong m?u cu?i X[7]

                            in_count <= 4'd0;
                            // Reset b? ??m input

                            state <= ST_RECV;
                            // Chuy?n sang tr?ng thái nh?n output t? IP
                        end

                        else begin
                            // N?u ch?a g?i ?? 8 m?u

                            in_count <= in_count + 4'd1;
                            // T?ng b? ??m ?? g?i m?u ti?p theo
                        end
                    end
                end


                // ------------------------------------------------
                // ST_RECV: nh?n 8 m?u output t? IFFT IP
                // ------------------------------------------------
                ST_RECV: begin

                    if (m_axis_data_tvalid) begin
                        // Khi IP xu?t ra m?t m?u h?p l?
                        //
                        // Vì m_axis_data_tready = 1,
                        // nên output sample ???c nh?n ngay.

                        i_time_bus[out_count*WIDTH +: WIDTH]
                            <= m_axis_data_tdata[0 +: WIDTH];
                        // L?u ph?n real/I c?a output vào i_time_bus
                        //
                        // m_axis_data_tdata[15:0] = I / real

                        q_time_bus[out_count*WIDTH +: WIDTH]
                            <= m_axis_data_tdata[WIDTH +: WIDTH];
                        // L?u ph?n imag/Q c?a output vào q_time_bus
                        //
                        // m_axis_data_tdata[31:16] = Q / imag

                        if (out_count == 4'd7) begin
                            // N?u ?ã nh?n ?? 8 m?u output

                            out_count <= 4'd0;
                            // Reset b? ??m output

                            ifft_valid_out <= 1'b1;
                            // Báo output bus ?ã h?p l?

                            state <= ST_IDLE;
                            // Quay v? IDLE ?? ch? frame ti?p theo
                        end

                        else begin
                            // N?u ch?a nh?n ?? 8 m?u

                            out_count <= out_count + 4'd1;
                            // Chuy?n sang v? trí output ti?p theo
                        end
                    end
                end


                // ------------------------------------------------
                // DEFAULT: tr?ng thái d? phòng
                // ------------------------------------------------
                default: begin

                    state <= ST_IDLE;
                    // N?u FSM r?i vào tr?ng thái l?, ??a v? IDLE
                end

            endcase
        end
    end


    // ============================================================
    // 7. G?i IP Core IFFT do Vivado sinh ra
    // ============================================================
    //
    // ?ây là ?o?n instantiate kh?p ?úng v?i .veo b?n g?i:
    //
    //      xfft_ifft8 your_instance_name ( ... );
    //
    // Ta ??i your_instance_name thành u_ifft8.
    //

    xfft_ifft8 u_ifft8 (
        .aclk(clk),
        // N?i clock h? th?ng vào IP

        .aresetn(rst_n),
        // N?i reset active-low vào IP

        .s_axis_config_tdata(s_axis_config_tdata),
        // Config 8 bit cho IP

        .s_axis_config_tvalid(s_axis_config_tvalid),
        // Config valid

        .s_axis_config_tready(s_axis_config_tready),
        // Config ready t? IP

        .s_axis_data_tdata(s_axis_data_tdata),
        // D? li?u input complex ??a vào IFFT

        .s_axis_data_tvalid(s_axis_data_tvalid),
        // Input data valid

        .s_axis_data_tready(s_axis_data_tready),
        // Input data ready t? IP

        .s_axis_data_tlast(s_axis_data_tlast),
        // TLAST input, b?t ? m?u X[7]

        .m_axis_data_tdata(m_axis_data_tdata),
        // D? li?u output complex t? IFFT

        .m_axis_data_tvalid(m_axis_data_tvalid),
        // Output valid t? IP

        .m_axis_data_tready(m_axis_data_tready),
        // Wrapper luôn ready nh?n output

        .m_axis_data_tlast(m_axis_data_tlast),
        // TLAST output t? IP

        .event_frame_started(event_frame_started),
        // Debug event: frame b?t ??u

        .event_tlast_unexpected(event_tlast_unexpected),
        // Debug event: TLAST ??n sai th?i ?i?m

        .event_tlast_missing(event_tlast_missing),
        // Debug event: thi?u TLAST ? cu?i input frame

        .event_status_channel_halt(event_status_channel_halt),
        // Debug event: status channel halt

        .event_data_in_channel_halt(event_data_in_channel_halt),
        // Debug event: input data channel halt

        .event_data_out_channel_halt(event_data_out_channel_halt)
        // Debug event: output data channel halt
    );

endmodule


