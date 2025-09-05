// 添加锁存型时钟门控模块（标准ASIC单元实现）
module clock_gate (
    input  clk_in,     // 主时钟
    input  enable,      // 门控使能信号
    output gclk         // 门控时钟输出
);
    reg en_latch;

    // 在时钟下降沿锁存使能信号
    always @(negedge clk_in) begin
        en_latch <= enable;
    end

    // 生成门控时钟（无毛刺）
    assign gclk = clk_in & en_latch;
endmodule
