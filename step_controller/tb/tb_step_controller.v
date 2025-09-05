`timescale 1ns/1ps

module tb_step_controller();

reg clk, rst_n, start;
reg [7:0] data_in;
wire [7:0] data_out;
wire done;

// ʱ������ (100MHz)
initial clk = 1;
always #5 clk = ~clk;

// ʵ��������ģ��
step_controller uut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .start(start),
    .data_out(data_out),
    .done(done)
);

initial begin
    // ��ʼ��
    rst_n = 0;
    start = 0;
    data_in = 0;
    
    // ��λ (20ns)
    #10 rst_n = 1;
    
    // ����1: ��������
    #5;
    test_case(8'd10, 43); // (10+5)*2+3+10=33
    
    
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
        
        // �ȴ����
        wait(done);
        @(posedge clk);
        
        // �����
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

// ���ӹؼ��ź�
initial begin
    $monitor("Time=%0t: state=%0d, int_reg=%0d, out=%0d, done=%b",
             $time, uut.state, uut.intermediate_reg, data_out, done);
end

endmodule