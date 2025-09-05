`timescale 1ns/1ps

module tb_step_controller();

reg clk, rst_n, start;
reg [7:0] data_in;
wire [7:0] data_out;
wire done;

// 时钟生成 (100MHz)
initial clk = 1;
always #5 clk = ~clk;

// 实例化待测模块
step_controller uut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .start(start),
    .data_out(data_out),
    .done(done)
);

initial begin
    // 初始化
    rst_n = 0;
    start = 0;
    data_in = 0;
    
    // 复位 (20ns)
    #10 rst_n = 1;
    
    // 测试1: 正常流程
    #5;
    test_case(8'd10, 43); // (10+5)*2+3=33
    
    
    $display("All tests passed!");
    $finish;
end

task test_case;
    input [7:0] in_value;
    input [7:0] expected;
    begin
        data_in = in_value;
        start = 1;
        #10;
        start = 0;
        
        // 等待完成
        wait(done);
        @(posedge clk);
        
        // 检查结果
        if (data_out !== expected) begin
            $error("Error! Input=%0d, Output=%0d, Expected=%0d", 
                   in_value, data_out, expected);
            $finish;
        end
        else begin
            $display("Test passed: Input=%0d, Output=%0d", in_value, data_out);
        end
    end
endtask

// 监视关键信号
initial begin
    $monitor("Time=%0t: state=%0d, int_reg=%0d, out=%0d, done=%b",
             $time, uut.state, uut.intermediate_reg, data_out, done);
end

endmodule