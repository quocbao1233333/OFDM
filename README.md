# OFDM Physical Layer Using FPGA

> README này trình bày chi tiết nguyên lý **OFDM – Orthogonal Frequency Division Multiplexing**, chuỗi xử lý phát/thu, vai trò của **IFFT/FFT**, **Cyclic Prefix**, điều chế **QAM**, và cách hiện thực lớp vật lý OFDM trên **FPGA**. Nội dung được biên soạn theo hướng dễ hiểu cho sinh viên/kỹ sư điện tử viễn thông và bám theo bài báo *Implementation of the OFDM Physical Layer Using FPGA*.

---

## 1. OFDM là gì?

**OFDM** là kỹ thuật ghép kênh phân chia theo tần số trực giao. Thay vì truyền một luồng dữ liệu tốc độ cao trên một sóng mang duy nhất, OFDM chia dữ liệu thành nhiều luồng con tốc độ thấp hơn và truyền song song trên nhiều **sóng mang con**.

Ý tưởng chính:

- Dữ liệu tốc độ cao được chia thành nhiều nhánh song song.
- Mỗi nhánh điều chế lên một sóng mang con riêng.
- Các sóng mang con **chồng phổ lên nhau** nhưng vẫn không gây nhiễu lẫn nhau vì chúng **trực giao**.
- IFFT ở phía phát tạo tín hiệu OFDM miền thời gian.
- FFT ở phía thu khôi phục dữ liệu miền tần số.
- Cyclic Prefix giúp giảm nhiễu liên ký hiệu trong môi trường đa đường.

OFDM được dùng rộng rãi trong các hệ thống truyền thông tốc độ cao như Wi-Fi, WiMAX, LTE/4G, DVB, ADSL và nhiều hệ thống vô tuyến băng rộng.

---

## 2. Vì sao cần OFDM?

Trong kênh vô tuyến thực tế, tín hiệu thường bị:

- **Multipath**: tín hiệu đến anten thu theo nhiều đường khác nhau.
- **Frequency selective fading**: mỗi dải tần bị suy hao khác nhau.
- **ISI – Inter-Symbol Interference**: ký hiệu trước chồng lên ký hiệu sau.
- **ICI – Inter-Carrier Interference**: các sóng mang con mất trực giao và gây nhiễu nhau.

OFDM giải quyết vấn đề bằng cách biến một kênh băng rộng khó cân bằng thành nhiều kênh con băng hẹp dễ xử lý hơn.

---

## 3. Nguyên lý trực giao của sóng mang con

Trong OFDM, khoảng cách giữa các sóng mang con thường chọn là:

```math
\Delta f = \frac{1}{T_u}
```

Trong đó:

- `Δf`: khoảng cách tần số giữa hai sóng mang con liền kề.
- `T_u`: thời gian ký hiệu OFDM hữu ích, chưa tính cyclic prefix.

Điều kiện trực giao giữa hai sóng mang con `k` và `m`:

```math
\int_0^{T_u} e^{j2\pi k\Delta f t}\,e^{-j2\pi m\Delta f t}\,dt = 0, \quad k \ne m
```

Hình dưới minh họa các phổ sóng mang con dạng sinc chồng lên nhau. Tại đỉnh của một sóng mang con, các sóng mang con còn lại rơi vào điểm zero nên không gây nhiễu lý tưởng.

![OFDM subcarriers](assets/ofdm_subcarriers.png)

---

## 4. Cấu trúc tín hiệu OFDM

Một ký hiệu OFDM trong miền thời gian gồm hai phần:

1. **Cyclic Prefix – CP**: bản sao của phần cuối ký hiệu OFDM, được đưa lên đầu khung.
2. **Useful OFDM Symbol**: phần dữ liệu chính có độ dài `NFFT` mẫu.

```math
N_{symbol} = N_{CP} + N_{FFT}
```

Hiệu suất do CP gây ra:

```math
\eta_{CP} = \frac{N_{FFT}}{N_{FFT}+N_{CP}}
```

CP càng dài thì chống đa đường càng tốt, nhưng hiệu suất truyền dữ liệu càng giảm. Vì vậy cần chọn `NCP` vừa đủ lớn để lớn hơn hoặc xấp xỉ độ trễ cực đại của kênh.

![Cyclic prefix](assets/cyclic_prefix.png)

---

## 5. Sơ đồ tổng quát OFDM Transceiver

Chuỗi xử lý cơ bản gồm phía phát, kênh truyền và phía thu.

![OFDM Tx Rx flow](assets/ofdm_tx_rx_flow.png)

### 5.1. Phía phát OFDM Transmitter

| Khối | Chức năng | Ghi chú kỹ thuật |
|---|---|---|
| Randomizer / Scrambler | Làm ngẫu nhiên chuỗi bit để tránh chuỗi 0 hoặc 1 quá dài | Thường dùng LFSR |
| FEC Encoder | Thêm bit dư để sửa lỗi | Ví dụ convolutional code, LDPC, Polar |
| Interleaver | Đảo vị trí bit để phân tán lỗi burst | Giúp FEC sửa lỗi tốt hơn |
| QAM Mapper | Gom bit thành symbol phức `I + jQ` | BPSK, QPSK, 16-QAM, 64-QAM |
| Serial-to-Parallel | Chia chuỗi symbol thành nhiều nhánh | Mỗi nhánh tương ứng một subcarrier |
| IFFT | Chuyển miền tần số sang miền thời gian | Khối quan trọng nhất phía phát |
| Parallel-to-Serial | Ghép mẫu thời gian thành chuỗi nối tiếp | Đưa sang khối thêm CP |
| Add Cyclic Prefix | Copy phần cuối ký hiệu lên đầu | Giảm ISI và giữ trực giao |
| DAC/RF | Chuyển số sang tương tự và phát RF | Phụ thuộc phần cứng RF |

### 5.2. Phía thu OFDM Receiver

| Khối | Chức năng | Ghi chú kỹ thuật |
|---|---|---|
| ADC/RF | Thu tín hiệu RF và số hóa | Cần đồng bộ tần số/thời gian |
| Remove Cyclic Prefix | Loại bỏ CP trước khi FFT | Chỉ giữ phần `NFFT` mẫu hữu ích |
| Serial-to-Parallel | Chia mẫu vào FFT | Chuẩn bị xử lý song song |
| FFT | Chuyển miền thời gian về miền tần số | Khôi phục các subcarrier |
| Equalizer | Bù méo kênh | Dựa vào pilot hoặc ước lượng kênh |
| QAM Demapper | Chuyển symbol phức về bit | Có thể hard decision hoặc soft LLR |
| Deinterleaver | Đảo ngược interleaver | Khôi phục thứ tự bit |
| FEC Decoder | Sửa lỗi | Viterbi, LDPC decoder, Polar decoder |
| Descrambler | Khôi phục chuỗi bit ban đầu | Đảo lại randomizer |

---

## 6. Công thức tín hiệu OFDM

Giả sử có `N` sóng mang con. Symbol miền tần số là:

```math
X[0], X[1], ..., X[N-1]
```

Tín hiệu OFDM miền thời gian sau IFFT:

```math
x[n] = \frac{1}{N}\sum_{k=0}^{N-1} X[k]e^{j2\pi kn/N}, \quad n = 0,1,...,N-1
```

Ở phía thu, FFT khôi phục lại symbol miền tần số:

```math
X[k] = \sum_{n=0}^{N-1} x[n]e^{-j2\pi kn/N}, \quad k = 0,1,...,N-1
```

Nếu có kênh truyền `H[k]`, tín hiệu thu ở miền tần số có thể viết:

```math
Y[k] = H[k]X[k] + W[k]
```

Equalizer một tap đơn giản:

```math
\hat{X}[k] = \frac{Y[k]}{H[k]}
```

---

## 7. Ví dụ 16-QAM trong OFDM

Trong 16-QAM, mỗi symbol mang:

```math
\log_2(16) = 4 \text{ bit/symbol}
```

Ví dụ một cụm 4 bit được ánh xạ thành một điểm phức:

```math
b_3b_2b_1b_0 \rightarrow I + jQ
```

![16 QAM constellation](assets/qam16_constellation.png)

Khi SNR thấp, điểm constellation bị tản rộng, dễ quyết định sai bit:

![16 QAM SNR 10](assets/qam16_snr10.png)

Khi SNR cao hơn, các điểm tập trung gần vị trí lý tưởng, BER giảm:

![16 QAM SNR 30](assets/qam16_snr30.png)

---

## 8. Tham số thiết kế quan trọng

| Tham số | Ký hiệu | Ý nghĩa | Ảnh hưởng |
|---|---:|---|---|
| FFT size | `NFFT` | Số điểm FFT/IFFT | Tăng `NFFT` giúp có nhiều subcarrier hơn nhưng tăng tài nguyên FPGA |
| CP length | `NCP` | Số mẫu cyclic prefix | CP dài chống đa đường tốt hơn nhưng giảm hiệu suất |
| Modulation order | `M` | BPSK/QPSK/16-QAM/64-QAM | `M` cao tăng throughput nhưng cần SNR cao hơn |
| Subcarrier spacing | `Δf` | Khoảng cách giữa subcarrier | Quyết định độ dài ký hiệu hữu ích |
| Sampling frequency | `Fs` | Tần số lấy mẫu | Ảnh hưởng băng thông và tốc độ phần cứng |
| Pilot pattern | `P[k]` | Sóng mang con pilot | Dùng để đồng bộ và ước lượng kênh |
| Coding rate | `R` | Tỷ lệ mã hóa | Tăng bảo vệ lỗi nhưng giảm tốc độ dữ liệu |
| Word length | `W` | Số bit fixed-point | Ảnh hưởng độ chính xác và tài nguyên FPGA |

Throughput lý tưởng gần đúng:

```math
R_b \approx \frac{N_{data}\log_2(M)R_{code}}{T_u + T_{CP}}
```

Trong đó:

- `Ndata`: số subcarrier dùng để mang dữ liệu.
- `M`: bậc điều chế.
- `Rcode`: tỷ lệ mã hóa kênh.
- `Tu + TCP`: thời gian một symbol OFDM đầy đủ.

---

## 9. Hiện thực OFDM trên FPGA

Bài toán FPGA không chỉ là hiểu thuật toán mà còn phải chuyển thành kiến trúc phần cứng chạy theo clock.

![FPGA OFDM architecture](assets/fpga_ofdm_architecture.png)

### 9.1. Kiến trúc dữ liệu đề xuất

| Tầng | Khối | Kiểu dữ liệu | Ghi chú |
|---|---|---|---|
| Input | FIFO/BRAM | bit hoặc symbol | Nhận dữ liệu từ UART, AXI Stream, DMA hoặc testbench |
| Mapper | QAM LUT | fixed-point `I/Q` | Tra bảng mapping Gray code |
| Frame builder | Pilot/null insert | complex fixed-point | Chèn pilot, DC null, guard band |
| IFFT | FFT IP hoặc tự viết | complex fixed-point | Có thể dùng Radix-2/Radix-4 hoặc vendor IP |
| CP inserter | RAM buffer | complex sample | Copy `NCP` mẫu cuối lên đầu frame |
| Output | FIFO/DAC interface | complex sample | Đẩy mẫu ra DAC hoặc bộ mô phỏng |
| Receiver | CP remover + FFT | complex sample | Xử lý ngược lại |
| Equalizer | complex divider/multiplier | complex fixed-point | Bù kênh dựa vào pilot |
| Demapper | decision logic | bit/LLR | Quyết định bit theo vùng constellation |

### 9.2. Module RTL gợi ý

```text
rtl/
├── ofdm_top.v
├── ofdm_tx_top.v
├── ofdm_rx_top.v
├── qam_mapper.v
├── qam_demapper.v
├── pilot_insert.v
├── pilot_remove.v
├── ifft_core_wrapper.v
├── fft_core_wrapper.v
├── cyclic_prefix_add.v
├── cyclic_prefix_remove.v
├── complex_mult.v
├── complex_divider.v
├── channel_equalizer.v
├── axi_stream_fifo.v
└── ofdm_controller_fsm.v
```

### 9.3. Giao tiếp khuyến nghị

Dùng chuẩn streaming đơn giản:

```verilog
input  wire              clk;
input  wire              rst_n;
input  wire              s_axis_valid;
output wire              s_axis_ready;
input  wire signed [15:0] s_axis_i;
input  wire signed [15:0] s_axis_q;
output wire              m_axis_valid;
input  wire              m_axis_ready;
output wire signed [15:0] m_axis_i;
output wire signed [15:0] m_axis_q;
```

### 9.4. Fixed-point

Ví dụ dùng Q1.15 hoặc Q4.12:

- Q1.15: phù hợp tín hiệu chuẩn hóa từ `-1` đến gần `+1`.
- Q4.12: phù hợp khi cần biên độ lớn hơn, nhưng độ phân giải nhỏ hơn Q1.15.

Cần kiểm soát:

- Overflow sau IFFT/FFT.
- Scaling sau từng stage FFT.
- Làm tròn hoặc cắt bit.
- Độ rộng twiddle factor.

---

## 10. Độ phức tạp FFT/IFFT

Nếu tính DFT trực tiếp, số phép toán xấp xỉ `O(N^2)`. FFT giảm xuống còn:

```math
O(N\log_2N)
```

Đây là lý do OFDM thực tế dùng FFT/IFFT thay vì tính trực tiếp từng sóng mang con.

![FFT complexity](assets/fft_complexity.png)

Với FPGA, tăng `NFFT` làm tăng:

- Số stage FFT.
- Số RAM/buffer cần dùng.
- Số chu kỳ xử lý một frame.
- Độ rộng địa chỉ.
- Tài nguyên DSP slice nếu dùng nhiều phép nhân song song.

---

## 11. Kết quả mô phỏng cần kiểm tra

Khi mô phỏng OFDM, nên kiểm tra tối thiểu các kết quả sau:

| Kiểm tra | Kết quả mong muốn |
|---|---|
| Phổ OFDM | Các subcarrier phủ đều trong băng thông |
| Tín hiệu sau IFFT | Dạng miền thời gian giống nhiễu, biên độ thay đổi mạnh |
| PAPR | OFDM thường có PAPR cao |
| Constellation sau kênh | SNR thấp thì điểm tản rộng, SNR cao thì cụm điểm rõ |
| BER theo SNR | SNR tăng thì BER giảm |
| CP remove | Sau khi bỏ CP, FFT phải lấy đúng `NFFT` mẫu |
| Equalizer | Sau bù kênh, constellation trở lại gần vị trí lý tưởng |
| FPGA waveform | `valid/ready`, frame counter và CP logic phải đúng chu kỳ |

---

## 12. Ưu điểm và nhược điểm của OFDM

### Ưu điểm

- Sử dụng phổ hiệu quả do các subcarrier chồng lấn nhưng trực giao.
- Chống fading chọn lọc theo tần số tốt hơn truyền một sóng mang.
- Equalizer đơn giản hơn vì mỗi subcarrier chỉ cần bù một hệ số phức.
- Phù hợp truyền dữ liệu tốc độ cao.
- Dễ hiện thực bằng FFT/IFFT.

### Nhược điểm

- PAPR cao, gây khó cho bộ khuếch đại công suất RF.
- Nhạy với sai lệch tần số sóng mang CFO.
- Cần đồng bộ thời gian chính xác.
- CP làm giảm hiệu suất phổ.
- FFT/IFFT cần tài nguyên phần cứng đáng kể khi `NFFT` lớn.

---

## 13. Checklist thiết kế một hệ OFDM hoàn chỉnh

- [ ] Chọn `NFFT`.
- [ ] Chọn `NCP` theo độ trễ kênh.
- [ ] Chọn bậc điều chế: BPSK/QPSK/16-QAM/64-QAM.
- [ ] Xác định số data subcarrier, pilot subcarrier, null subcarrier.
- [ ] Thiết kế mapper/demapper.
- [ ] Thiết kế IFFT/FFT.
- [ ] Thiết kế CP add/remove.
- [ ] Thêm đồng bộ thời gian.
- [ ] Thêm đồng bộ tần số nếu mô phỏng thực tế.
- [ ] Thêm channel estimation bằng pilot.
- [ ] Thêm equalizer.
- [ ] Mô phỏng BER theo SNR.
- [ ] Kiểm tra fixed-point overflow.
- [ ] Kiểm tra waveform RTL.
- [ ] Tổng hợp FPGA và kiểm tra timing.

---

## 14. Cấu trúc thư mục project đề xuất

```text
ofdm-fpga-project/
├── README.md
├── assets/
│   ├── ofdm_subcarriers.png
│   ├── cyclic_prefix.png
│   ├── ofdm_tx_rx_flow.png
│   ├── fpga_ofdm_architecture.png
│   ├── qam16_constellation.png
│   ├── qam16_snr10.png
│   ├── qam16_snr30.png
│   └── fft_complexity.png
├── docs/
│   └── theory_notes.md
├── matlab/
│   ├── ofdm_tx_rx_sim.m
│   └── ber_vs_snr.m
├── python/
│   └── ofdm_reference_model.py
├── rtl/
│   ├── ofdm_top.v
│   ├── ofdm_tx_top.v
│   ├── ofdm_rx_top.v
│   ├── qam_mapper.v
│   ├── qam_demapper.v
│   ├── cyclic_prefix_add.v
│   ├── cyclic_prefix_remove.v
│   ├── fft_core_wrapper.v
│   └── ifft_core_wrapper.v
├── tb/
│   ├── tb_ofdm_tx.v
│   └── tb_ofdm_rx.v
└── constraints/
    └── board.xdc
```

---

## 15. Lộ trình học và triển khai

### Bước 1: Mô phỏng bằng Python/MATLAB

Mục tiêu:

- Tạo bit ngẫu nhiên.
- Map sang QAM.
- Đưa qua IFFT.
- Thêm CP.
- Thêm AWGN.
- Bỏ CP.
- FFT.
- Demap và tính BER.

### Bước 2: Chuyển sang fixed-point

Mục tiêu:

- Chuẩn hóa biên độ symbol.
- Chọn Q-format.
- So sánh sai số giữa floating-point và fixed-point.

### Bước 3: Viết RTL từng khối

Thứ tự nên làm:

1. `qam_mapper.v`
2. `cyclic_prefix_add.v`
3. `cyclic_prefix_remove.v`
4. `fft_core_wrapper.v`
5. `ifft_core_wrapper.v`
6. `ofdm_tx_top.v`
7. `ofdm_rx_top.v`
8. `ofdm_top.v`

### Bước 4: Testbench

Cần test:

- Một frame OFDM không nhiễu.
- Một frame có AWGN.
- Nhiều frame liên tục.
- Reset giữa frame.
- Trường hợp `ready` bị kéo xuống để kiểm tra backpressure.

### Bước 5: Tổng hợp FPGA

Cần kiểm tra:

- LUT, FF, BRAM, DSP.
- Timing slack.
- Clock domain crossing nếu có nhiều clock.
- Độ trễ từ input đến output.

---

## 16. Ghi chú theo bài báo tham khảo

Bài báo *Implementation of the OFDM Physical Layer Using FPGA* trình bày hệ OFDM gồm các khối chính như randomizer, convolutional encoder, interleaver, constellation modulator, S/P, IFFT, P/S, thêm cyclic prefix ở phía phát; phía thu thực hiện các bước ngược lại với remove CP, FFT, P/S, demodulator, deinterleaver và decoder. Bài báo mô phỏng hệ thống bằng MATLAB và hiện thực các khối bằng VHDL trên FPGA Spartan-3A.

Một số nhận xét mô phỏng trong bài:

- Khi tăng độ dài FFT/IFFT, số subcarrier có thể tăng và phổ OFDM biểu diễn thực tế hơn.
- Khi tăng SNR, nhiễu giảm và constellation ít bị phân tán hơn.
- CP là khối quan trọng để giảm ISI trong kênh đa đường.
- FFT/IFFT là lõi tính toán trung tâm của OFDM.

---

## 17. Tài liệu tham khảo

1. M.A. Mohamed, A.S. Samarah, M.I. Fath Allah, **Implementation of the OFDM Physical Layer Using FPGA**, IJCSI International Journal of Computer Science Issues, Vol. 9, Issue 2, No. 2, March 2012.
2. Xilinx, **LogiCORE Fast Fourier Transform**, FFT IP documentation.
3. Các chuẩn truyền thông sử dụng OFDM: IEEE 802.11a/g/n/ac/ax, IEEE 802.16, LTE/4G, DVB-T.

---

## 18. Tóm tắt ngắn gọn

OFDM là kỹ thuật biến một luồng dữ liệu tốc độ cao thành nhiều luồng song song trên các sóng mang con trực giao. IFFT tạo tín hiệu phát trong miền thời gian, FFT khôi phục dữ liệu ở phía thu, còn cyclic prefix giúp chống đa đường. Khi hiện thực trên FPGA, các vấn đề quan trọng nhất là thiết kế FFT/IFFT, quản lý frame, xử lý fixed-point, thêm/bỏ CP và đảm bảo timing phần cứng.
