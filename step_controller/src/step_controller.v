//================================================
// moduel name: step_controller
// create data: 7.3
// describtion: 控制4个计算模块以add，mul，special，end的顺序工作，
//================================================
module step_controller(
    input        clk,
    input        rst_n,
    input  [7:0] data_in,
    input        start,
    output [7:0] data_out,
    output       done
);

// ========== 状态定义 ==========
localparam IDLE  = 3'd0;
localparam STEP1 = 3'd1;
localparam STEP2 = 3'd2;
localparam STEP3 = 3'd3;
localparam STEP4 = 3'd4;

// ========== 内部寄存器声明 ==========
reg [2:0] state, next_state;
reg [7:0] input_reg;           // 输入寄存器
reg [7:0] intermediate_reg;    // 中间结果寄存器
reg [7:0] data_out_reg;        // 输出寄存器 
reg done_reg;                  // 完成标志寄存

// ========== 模块实例化和连接 ==========
// 计算模块启动控制
wire step1_start, step2_start, step3_start, step4_start;

// 计算模块输出
wire [7:0] step1_out, step2_out, step3_out, step4_out;
wire step1_done, step2_done, step3_done, step4_done;

// 模块输入选择
wire [7:0] step1_data_in, step2_data_in, step3_data_in, step4_data_in;

// 实例化计算模块
add_step step1_inst(
    .clk(clk),
    .start(step1_start),
    .in_data(step1_data_in),
    .out_data(step1_out),
    .done(step1_done)
);

mult_step step2_inst(
    .clk(clk),
    .start(step2_start),
    .in_data(step2_data_in),
    .out_data(step2_out),
    .done(step2_done)
);

special_step step3_inst(
    .clk(clk),
    .start(step3_start),
    .in_data(step3_data_in),
    .out_data(step3_out),
    .done(step3_done)
);

end_step step4_inst(
    .clk(clk),
    .start(step4_start),
    .in_data(step4_data_in),
    .out_data(step4_out),
    .done(step4_done)
);

// ========== 数据通路控制 ==========
// 模块输入多路选择
assign step1_data_in = input_reg;
assign step2_data_in = intermediate_reg;
assign step3_data_in = intermediate_reg;
assign step4_data_in = intermediate_reg;

// 启动信号分配
assign step1_start = (state == STEP1) && !done_reg;
assign step2_start = (state == STEP2) && !done_reg;
assign step3_start = (state == STEP3) && !done_reg;
assign step4_start = (state == STEP4) && !done_reg;

// ========== 状态机实现 (三段式) ==========
// 第一段: 状态跳转
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else state <= next_state;
end

// 第二段: 次态逻辑
always @(*) begin
    case (state)
        IDLE:  next_state = (start) ? STEP1 : IDLE;
        
        STEP1: next_state = (step1_done) ? STEP2 : STEP1;
            
        STEP2: next_state = (step2_done) ? STEP3 : STEP2;
            
        STEP3: next_state = (step3_done) ? STEP4 : STEP3;

        STEP4: next_state = (step4_done) ? IDLE  : STEP4;

        default: next_state = IDLE; // 其他状态回到IDLE
    endcase
end

// 第三段: 数据通路控制
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_reg <= 8'd0;
        intermediate_reg <= 8'd0;
        data_out_reg <= 8'd0;
        done_reg <= 1'b0;

    end else begin
        // 默认值设置
        done_reg <= 1'b0;
        
        // 基于当前状态执行操作
        case (state)
            IDLE: begin
                if (start) begin
                    // 在IDLE状态锁存输入
                    input_reg <= data_in;  // 使用中间寄存器暂存输入
                end
            end
            
            STEP1: begin
                if (step1_done) begin
                    // 在STEP1状态结束时锁存第一步结果
                    intermediate_reg <= step1_out;
                end
            end
            
            STEP2: begin
                if (step2_done) begin
                    // 在STEP2状态结束时锁存第二步结果
                    intermediate_reg <= step2_out;
                end
            end
            
            STEP3: begin
                if (step3_done) begin
                    // 在STEP3状态结束时锁存第三步结果
                    intermediate_reg <= step3_out;  
                end
            end

            STEP4: begin
                if (step4_done) begin
                    // 在STEP3状态结束时锁存最终结果并设置完成标志
                    data_out_reg <= step4_out;  // 直接更新输出寄存器
                    done_reg <= 1'b1;
                end
            end
            
            default: ; // 其他状态不执行操作
        endcase
    end
end

// ========== 输出分配 ==========
assign data_out = data_out_reg;
assign done = done_reg;

endmodule