//================================================
// moduel name: special_step +3
// create data: 7.3
// describtion: 1个周期完成
//================================================
module special_step(
    input clk,
    input start,
    input [7:0] in_data,
    output reg [7:0] out_data,
    output reg done
);
    always @(posedge clk) begin
        if (start) begin
            out_data <= in_data + 8'd3;
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
endmodule