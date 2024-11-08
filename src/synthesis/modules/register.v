module register #(
    parameter DATA_WIDTH = 16
) (
    clk, rst_n, cl, ld, in, inc, dec, sr, ir, sl, il, out
);
    input clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    input [DATA_WIDTH-1:0] in;
    output [DATA_WIDTH-1:0] out;

    reg [DATA_WIDTH-1:0] out_next, out_reg;
    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            out_reg <= {(DATA_WIDTH-1){1'b0}};
        end
        else begin
            out_reg <= out_next;
        end
    end

    always @(*) begin
        out_next = out_reg;
        if(cl) begin
            out_next = {(DATA_WIDTH-1){1'b0}};;
        end
        else if(ld) begin
            out_next = in;
        end
        else if(inc) begin
            out_next = out_reg + 1'b1;
        end
        else if(dec) begin
            out_next = out_reg - 1'b1;
        end
        else if(sr) begin
            out_next = ((out_reg >> 1) | {ir,{(DATA_WIDTH-1){1'b0}}});
        end
        else if(sl) begin
            out_next = (out_reg << 1) | il;
        end
    end
endmodule