module step_controller(
    input        clk,
    input        rst_n,
    input  [7:0] data_in,
    input        start,
    output [7:0] data_out,
    output       done
);

// ========== 状态定义 ==========
localparam IDLE       = 3'd0;
localparam STEP1      = 3'd1;
localparam STEP2_FIR  = 3'd2; // 第一步乘法
localparam STEP2_SEC  = 3'd3; // 第二步乘法
localparam STEP3      = 3'd4;

// ========== 内部寄存器声明 ==========
reg [2:0] state, next_state;   // 状态寄存器宽度扩展到3位
reg [7:0] input_reg;          
reg [7:0] intermediate_reg;   // 中间结果寄存器
reg [7:0] data_out_reg;       
reg done_reg;                 

// ========== 模块实例化和连接 ==========
// 计算模块启动控制
wire step1_start, step2_start, step3_start;

// 计算模块输出
wire [7:0] step1_out, step2_out, step3_out;
wire step1_done, step2_done, step3_done;

// 模块输入选择
wire [7:0] step1_data_in, step2_data_in, step3_data_in;

// 实例化计算模块
add_step step1_inst(
    .clk(clk),
    .start(step1_start),
    .in_data(step1_data_in),
    .out_data(step1_out),
    .done(step1_done)
);

// 单个乘法模块实例 (用于两个乘法步骤)
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

// ========== 数据通路控制 ==========
// 模块输入多路选择
assign step1_data_in = input_reg;             // STEP1使用输入
assign step2_data_in = intermediate_reg;      // 乘法模块输入始终来自中间寄存器
assign step3_data_in = intermediate_reg;      // STEP3使用中间结果

// 启动信号分配 (每个状态执行一次)
assign step1_start = (state == STEP1) && !done_reg;
assign step2_start = ((state == STEP2_FIR) || (state == STEP2_SEC)) && !done_reg;
assign step3_start = (state == STEP3) && !done_reg;

// ========== 状态机实现 (三段式) ==========
// 第一段: 状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else state <= next_state;
end

// 第二段: 下一状态逻辑
always @(*) begin
    next_state = state;  // 默认保持当前状态
    
    case (state)
        IDLE:      if (start) next_state = STEP1;
        
        STEP1:     if (step1_done) next_state = STEP2_FIR;
        
        STEP2_FIR: if (step2_done) next_state = STEP2_SEC;
        
        STEP2_SEC: if (step2_done) next_state = STEP3;
        
        STEP3:     if (step3_done) next_state = IDLE;
        
        default:   next_state = IDLE; // 安全处理
    endcase
end

// 第三段: 数据通路控制
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_reg         <= 8'd0;
        intermediate_reg  <= 8'd0;
        data_out_reg      <= 8'd0;
        done_reg          <= 1'b0;
    end else begin
        // 默认值设置
        done_reg <= 1'b0;
        
        // 基于当前状态执行操作
        case (state)
            IDLE: begin
                // 启动时锁存输入
                if (start) begin
                    input_reg <= data_in;
                end
            end
            
            STEP1: begin
                // STEP1完成后锁存结果
                if (step1_done) begin
                    intermediate_reg <= step1_out;
                end
            end
            
            STEP2_FIR: begin
                // STEP2_FIR完成后锁存结果
                if (step2_done) begin
                    intermediate_reg <= step2_out;
                end
            end
            
            STEP2_SEC: begin
                // STEP2_SEC完成后锁存结果
                if (step2_done) begin
                    intermediate_reg <= step2_out;
                end
            end
            
            STEP3: begin
                // STEP3完成后输出结果并设置完成标志
                if (step3_done) begin
                    data_out_reg <= step3_out;
                    done_reg <= 1'b1;
                end
            end
            
            default: ; // 其他状态不执行操作
        endcase
    end
end

// ========== 输出分配 ==========
assign data_out = data_out_reg;
assign done     = done_reg;

endmodule