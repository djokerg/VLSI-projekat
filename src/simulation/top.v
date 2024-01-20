module top;
    reg [3:0] a, b;
    reg [2:0] oc;
    wire [3:0] f;
    reg clk, rst_n, cl, ld, inc, dec, sr, sl, ir, il;
    reg [3:0] in;
    wire [3:0] out;

    alu alu_inst(.a(a),.b(b),.oc(oc),.f(f));
    register register_ins(.clk(clk), .rst_n(rst_n), .cl(cl), .ld(ld), .inc(inc), .dec(dec),
     .sr(sr), .ir(ir), .sl(sl), .il(il), .in(in), .out(out));
    integer i;

    initial begin
        clk = 1'b0;
        for(i = 0; i < 2**(4*2+3);i=i+1) begin
            {oc, b , a} = i;
            #5;
        end 
        $stop;
        rst_n = 1'b0;
        cl = 1'b0;
        ld = 1'b0;
        inc = 1'b0;
        dec = 1'b0;
        sr = 1'b0;
        ir = 1'b0;
        sl = 1'b0;
        il = 1'b0;
        in = 4'b0000;
        #2 rst_n = 1'b1;
        repeat (1000) begin
            #5;
            cl = $urandom % 2;
            ld = $urandom % 2;
            inc = $urandom % 2;
            dec = $urandom % 2;
            sr = $urandom % 2;
            ir = $urandom % 2;
            sl = $urandom % 2;
            il = $urandom % 2;
            in = $urandom % (2**4);
        end
        #10 $finish;
    end

    always begin
        #5 clk = ~clk;
    end

    initial begin
        $monitor("Vreme = %2d, a = %d, b = %d, oc = %b , f = %d", $time,a,b,oc,f);
    end

    always @(out) begin
        $strobe("Vreme = %2d, in = %d, out = %d, cl = %b, ld = %b, inc = %b, dec = %b, sr = %b, ir = %b, sl = %b, il = %b",
        $time, in, out, cl, ld, inc, dec, sr, ir, sl, il);
    end
endmodule