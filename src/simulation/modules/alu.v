module alu (
    input [2:0] oc,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] f
);
    always @(*) begin
        case (oc)
            3'b000: begin
                //add
                f = a + b;
            end
            3'b001: begin
                //sub
                f = a - b;
            end
            3'b010: begin
                //mul
                f = a * b;
            end
            3'b011: begin
                //div
                f = a / b;
            end
            3'b100: begin
                //not
                f = ~a;
            end
            3'b101: begin
                //xor
                f = a^b;
            end
            3'b110: begin
                //or
                f = a | b;
            end
            3'b111: begin
                //and
                f = a & b;
            end
        endcase
    end
endmodule