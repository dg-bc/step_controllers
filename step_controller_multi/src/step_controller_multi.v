
//================================================
// module name: step_controller_multi
// create data: 7.3
// description: 控制4个计算模块工作顺序（带时钟门控）
// 关键变更：为每个计算模块添加独立的时钟门控
//================================================
module step_controller_multi(
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
localparam W_STP = 3'd7;    // 隔离状态
localparam STEP5 = 3'd5;

// ========== 内部寄存器声明 ==========
reg [2:0] state, next_state;
reg [7:0] input_reg;
reg [7:0] intermediate_reg;
reg [7:0] data_out_reg;
reg done_reg;

// ====== 新增：门控使能信号 ======
reg  step1_enable, step2_enable, special_enable, step5_enable;
wire step1_gclk, step2_gclk, special_gclk, step5_gclk;

// ========== 模块实例化和连接 ==========
// 计算模块启动控制
wire step1_start, step2_start, special_step_start, step5_start;

// 计算模块输出
wire [7:0] step1_out, step2_out, special_step_out, step5_out;
wire step1_done, step2_done, special_step_done, step5_done;

// 模块输入选择
wire [7:0] step1_data_in, step2_data_in, special_step_data_in, step5_data_in;

// 实例化时钟门控单元
clock_gate cg_step1 (
    .clk_in(clk),
    .enable(step1_enable),
    .gclk(step1_gclk)
);

clock_gate cg_step2 (
    .clk_in(clk),
    .enable(step2_enable),
    .gclk(step2_gclk)
);

clock_gate cg_special (
    .clk_in(clk),
    .enable(special_enable),
    .gclk(special_gclk)
);

clock_gate cg_step5 (
    .clk_in(clk),
    .enable(step5_enable),
    .gclk(step5_gclk)
);

// 实例化计算模块（连接到门控时钟）
add_step step1_inst(
    .clk(step1_gclk),     // 使用门控时钟
    .start(step1_start),
    .in_data(step1_data_in),
    .out_data(step1_out),
    .done(step1_done)
);

mult_step step2_inst(
    .clk(step2_gclk),     // 使用门控时钟
    .start(step2_start),
    .in_data(step2_data_in),
    .out_data(step2_out),
    .done(step2_done)
);

special_step step3_inst(
    .clk(special_gclk),   // 使用门控时钟（两个special步骤共享）
    .start(special_step_start),
    .in_data(special_step_data_in),
    .out_data(special_step_out),
    .done(special_step_done)
);

end_step step4_inst(
    .clk(step5_gclk),     // 使用门控时钟
    .start(step5_start),
    .in_data(step5_data_in),
    .out_data(step5_out),
    .done(step5_done)
);

// ========== 数据通路控制 ==========
// 模块输入多路选择
assign step1_data_in        = input_reg;
assign step2_data_in        = intermediate_reg;
assign special_step_data_in = intermediate_reg;
assign step5_data_in        = intermediate_reg;

// 启动信号分配
assign step1_start          = (state == STEP1) && !done_reg;
assign step2_start          = (state == STEP2) && !done_reg;
assign special_step_start   = ((state == STEP3)||(state == STEP4)) && !done_reg;
assign step5_start          = (state == STEP5) && !done_reg;

// ========== 状态机实现 (三段式) ==========
// 第一段: 状态寄存器（保持不变）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else state <= next_state;
end

// 第二段: 下一状态逻辑（保持不变）
always @(*) begin
    next_state = state;
    case (state)
        IDLE: if (start) next_state = STEP1;
        STEP1: if (step1_done) next_state = STEP2;
        STEP2: if (step2_done) next_state = STEP3;
        STEP3: if (special_step_done) next_state = W_STP;
        W_STP: next_state = STEP4;
        STEP4: if (special_step_done) next_state = STEP5;
        STEP5: if (step5_done) next_state = IDLE;
    endcase
end

// 第三段: 数据通路控制（添加门控使能逻辑）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_reg <= 8'd0;
        intermediate_reg <= 8'd0;
        data_out_reg <= 8'd0;
        done_reg <= 1'b0;
        
        // 复位门控使能
        step1_enable <= 1'b0;
        step2_enable <= 1'b0;
        special_enable <= 1'b0;
        step5_enable <= 1'b0;
    end else begin
        done_reg <= 1'b0;
        
        // 默认关闭所有时钟门控
        step1_enable <= 1'b0;
        step2_enable <= 1'b0;
        special_enable <= 1'b0;
        step5_enable <= 1'b0;

        case (state)
            IDLE: begin
                if (start) input_reg <= data_in;
            end
            
            STEP1: begin
                step1_enable <= 1'b1;  // 开启STEP1时钟
                if (step1_done) intermediate_reg <= step1_out;
            end
            
            STEP2: begin
                step2_enable <= 1'b1;  // 开启STEP2时钟
                if (step2_done) intermediate_reg <= step2_out;
            end
            
            STEP3: begin
                special_enable <= 1'b1;  // 开启SPECIAL时钟
                if (special_step_done) intermediate_reg <= special_step_out;
            end

            W_STP: begin
                // 空闲状态保持时钟关闭
            end

            STEP4: begin
                special_enable <= 1'b1;  // 开启SPECIAL时钟（复用）
                if (special_step_done) intermediate_reg <= special_step_out;
            end

            STEP5: begin
                step5_enable <= 1'b1;  // 开启STEP5时钟
                if (step5_done) begin
                    data_out_reg <= step5_out;
                    done_reg <= 1'b1;
                end
            end
        endcase
        
        // 特殊处理：状态切换时的保持逻辑
        // if (next_state == STEP1) step1_enable <= 1'b1;
        // if (next_state == STEP2) step2_enable <= 1'b1;
        // if (next_state == STEP3 || next_state == STEP4) special_enable <= 1'b1;
        // if (next_state == STEP5) step5_enable <= 1'b1;
    end
end

// ========== 输出分配 ==========
assign data_out = data_out_reg;
assign done = done_reg;
endmodule