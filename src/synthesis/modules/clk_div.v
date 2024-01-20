module clk_div #(
    parameter DIVISOR = 50_000_000
) (
    input clk,
    input rst_n,
    output out
);
    reg out_reg, out_next;
    assign out = out_reg;
    integer timer_next, timer_reg;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            timer_reg <=0;
            out_reg <= 0;
        end
        else begin
            timer_reg <= timer_next;
            out_reg <= out_next;
        end
    end

    always @(*) begin
        timer_next = timer_reg;
        out_next = out_reg;
        if(timer_reg == DIVISOR/2) begin
            out_next = ~out_reg;
            timer_next = 0;
        end
        else begin
            timer_next = timer_reg + 1;
        end
    end

endmodule