module bcd (
    input [5:0] in,
    output reg [3:0] ones, output reg [3:0] tens
);
    always @(*) begin
        //kodiranje dvocifrenog broja in u binarno kodirane 2 cifre
        ones = in % 10;
        tens = in/10 % 10;
    end
endmodule