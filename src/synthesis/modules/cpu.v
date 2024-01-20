module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    clk, rst_n, mem_in, in, mem_we, mem_addr, mem_data, out, pc, sp
);

    input clk, rst_n;
    input [DATA_WIDTH-1:0] mem_in, in;
    //
    output reg mem_we;
    output reg [ADDR_WIDTH-1:0] mem_addr;
    output reg [DATA_WIDTH-1:0] mem_data;
    output [ADDR_WIDTH-1:0] pc;
    output [ADDR_WIDTH-1:0] sp;
    output [DATA_WIDTH-1:0] out;

    //helper variables

    reg [DATA_WIDTH-1:0] out_next,out_reg;

    assign out = out_reg;

    //ALU UNIT

    reg [2:0] alu_oc;
    reg [DATA_WIDTH-1:0] alu_a, alu_b;
    wire [DATA_WIDTH-1:0] alu_f;

    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) alu_inst (
        .oc(alu_oc),
        .a(alu_a),
        .b(alu_b),
        .f(alu_f)
    );


    // REGISTERS

    //pc register
    reg pc_inc,pc_ld;
    reg [ADDR_WIDTH-1:0] pc_in;

    register # (
        .DATA_WIDTH(ADDR_WIDTH)
    ) pc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cl(1'b0),
        .ld(pc_ld),
        .inc(pc_inc),
        .dec(1'b0),
        .sr(1'b0),
        .ir(1'b0),
        .sl(1'b0),
        .il(1'b0),
        .in(pc_in),
        .out(pc)
    );

    //sp register

    reg sp_inc,sp_ld, sp_dec;
    reg [ADDR_WIDTH-1:0] sp_in;

    register # (
        .DATA_WIDTH(ADDR_WIDTH)
    ) sp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cl(1'b0),
        .ld(sp_ld),
        .inc(sp_inc),
        .dec(sp_dec),
        .sr(1'b0),
        .ir(1'b0),
        .sl(1'b0),
        .il(1'b0),
        .in(sp_in),
        .out(sp)
    );

    // ACC register

    reg acc_ld, acc_cl;
    reg [DATA_WIDTH-1:0] acc_in;

    wire [DATA_WIDTH-1:0] acc_out;

    register # (
        .DATA_WIDTH(DATA_WIDTH)
    ) acc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cl(acc_cl),
        .ld(acc_ld),
        .inc(1'b0),
        .dec(1'b0),
        .sr(1'b0),
        .ir(1'b0),
        .sl(1'b0),
        .il(1'b0),
        .in(acc_in),
        .out(acc_out)
    );


    // IR Higher register

    reg ir_h_ld;
    reg [DATA_WIDTH-1:0] ir_h_in;
    wire [DATA_WIDTH-1:0] ir_h_out;
    register # (
        .DATA_WIDTH(DATA_WIDTH)
    ) ir_h_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cl(1'b0),
        .ld(ir_h_ld),
        .inc(1'b0),
        .dec(1'b0),
        .sr(1'b0),
        .ir(1'b0),
        .sl(1'b0),
        .il(1'b0),
        .in(ir_h_in),
        .out(ir_h_out)
    );


    // IR Lower register

    reg ir_l_ld;
    reg [DATA_WIDTH-1:0] ir_l_in;
    wire [DATA_WIDTH-1:0] ir_l_out;
    register # (
        .DATA_WIDTH(DATA_WIDTH)
    ) ir_l_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cl(1'b0),
        .ld(ir_l_ld),
        .inc(1'b0),
        .dec(1'b0),
        .sr(1'b0),
        .ir(1'b0),
        .sl(1'b0),
        .il(1'b0),
        .in(ir_l_in),
        .out(ir_l_out)
    );

    //23 STANJA

    localparam halt = 5'b00000;

    localparam fetch1 = 5'b00001;
    localparam fetch2 = 5'b00010;
    localparam fetch3 = 5'b00011;

    localparam decode = 5'b00100;

    localparam execute_in = 5'b00101;
    localparam execute_out = 5'b00110;
    localparam execute_out_indirect = 5'b00111;
    localparam execute_stop_1 = 5'b01000;
    localparam execute_stop_1_indirect = 5'b01001;
    localparam execute_stop_2 = 5'b01010;
    localparam execute_stop_2_indirect = 5'b01011;
    localparam execute_stop_3 = 5'b01100;
    localparam execute_stop_3_indirect = 5'b01101;
    localparam execute_mov = 5'b01110;
    localparam execute_mov_indirect_2 = 5'b01111;
    localparam execute_mov_indirect_1 = 5'b10000;
    localparam execute_mov_constant = 5'b10001;

    localparam decode_arithmetic_1_indirect = 5'b10010;
    localparam decode_arithmetic_2_indirect = 5'b10011;
    localparam decode_arithmetic_3 = 5'b10100;
    localparam decode_arithmetic_3_indirect = 5'b10101;
    
    localparam execute_arithmetic = 5'b10110;
    localparam prefetch = 5'b10111;

    reg [4:0] state_next, state_reg;
    reg [4:0] prev_state_next, prev_state_reg;

    /* TASKS */

    task load;
        input [ADDR_WIDTH-1:0] addr;
        begin
            mem_we = 0;
            mem_addr = addr;
            mem_data = 0;
        end
    endtask

    task store;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            mem_we = 1;
            mem_addr = addr;
            mem_data = data;
        end
    endtask

    /* SEQUENTIAL LOGIC */

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            //resetuj sve
            //mogu i da dodelim vrednosti registrima PC i SP
            state_reg <= prefetch;
            prev_state_reg <=0;
            out_reg <= 0;
        end
        else begin
            //dodeli signalima iz sekv vr iz komb
            state_reg <= state_next;
            prev_state_reg <= prev_state_next;
            out_reg <= out_next;
        end
    end

    /* COMBINATIONAL LOGIC */

    always @(*) begin
        //kombinaciona logika, definisi sve da ne dodje do latcha
        out_next = out_reg;
        state_next = state_reg;
        prev_state_next = state_reg;
        //staviti ove ostale izlazne promenljive da su 0(SVE)
        mem_we = 0;
        mem_addr = 0;
        mem_data = 0;
        alu_oc = 0;
        alu_a = 0;
        alu_b = 0;
        pc_inc = 0;
        pc_ld = 0;
        pc_in = 0;
        sp_in = 0;
        sp_inc = 0;
        sp_dec = 0;
        sp_ld = 0;
        acc_cl = 0;
        acc_in = 0;
        acc_ld = 0;
        ir_h_in = 0;
        ir_h_ld = 0;
        ir_l_ld = 0;
        ir_l_in = 0;
        case (state_reg)
            halt: begin
                //beskonacna petlja
            end
            prefetch: begin
                pc_in = 8;
                pc_ld = 1;
                sp_in = 63;
                sp_ld = 1;
                state_next = fetch1;
            end
            fetch1: begin
                //fetch from memory into registers IR
                //kako da razdvojim stvari koje radim u jednom taktu, a kako u drugom, vrv mi treba vise stanja
                load(pc);
                pc_inc = 1;
                state_next = fetch2;
            end
            fetch2: begin
                //stavljeno je da se cita, procitaj podatak
                ir_h_in = mem_in;
                ir_h_ld = 1;
                //ovde vec mogu da znam da li idem na citanje drugog bajta ili na decode
                if(mem_in[15:12]== 4'b0000 && mem_in[3:0]==4'b1000) begin
                    //go to fetch another byte but first put signals
                    load(pc);
                    pc_inc = 1;
                    state_next = fetch3;
                end
                else begin
                    state_next = decode;
                end
            end
            fetch3: begin
                //ovde ucitam nizi bajt za mov instrukciju
                ir_l_in = mem_in;
                ir_l_ld = 1;
                state_next = decode;
            end
            decode: begin
                case (ir_h_out[15:12])
                    /* DECODE IN */
                    4'b0111: begin
                        //in instrukcija je u pitanju, podatak sa in se ucitava na adresu prvog operanda
                        //napraviti funkcije koje izdvajaju odredjene bitove
                        if(ir_h_out[11]==1)begin
                            //indirektno adresiranje
                            //mora jedan takt da mi ode da dovucem adresu i da je preusmerim
                            load(ir_h_out[10:8]);
                            state_next = execute_in;
                        end
                        else begin
                            //here it doesnt need execute phase
                            store(ir_h_out[10:8],in);
                            state_next = fetch1;
                        end
                    end
                    /* DECODE OUT */
                    4'b1000: begin
                        //out instrukcija
                        if(ir_h_out[11]==1)begin
                            //indirektno adresiranje
                            load(ir_h_out[10:8]);
                            state_next = execute_out_indirect;
                        end
                        else begin
                            load(ir_h_out[10:8]);
                            state_next = execute_out;
                        end
                    end
                    /* DECODE STOP */
                    4'b1111: begin
                        //this is STOP instruction, it has to write something to out, and go in infinite loop
                        if(ir_h_out[11:8] != 4'b0000) begin
                            //ispisuj ga
                            if(ir_h_out[11] == 1'b1) begin
                                load(ir_h_out[10:8]);
                                state_next = execute_stop_1_indirect;
                            end
                            else begin
                                load(ir_h_out[10:8]);
                                state_next = execute_stop_1;
                            end
                        end
                        else if(ir_h_out[7:4] != 4'b0000) begin
                            //ispisuj ga
                            if(ir_h_out[4] == 1'b1) begin
                                load(ir_h_out[6:4]);
                                state_next = execute_stop_2_indirect;
                            end
                            else begin
                                load(ir_h_out[6:4]);
                                state_next = execute_stop_2;
                            end
                        end
                        else if(ir_h_out[3:0] != 4'b0000) begin
                            //ispisuj ga
                            if(ir_h_out[3] == 1'b1) begin
                                load(ir_h_out[2:0]);
                                state_next = execute_stop_3_indirect;
                            end
                            else begin
                                load(ir_h_out[2:0]);
                                state_next = execute_stop_3;
                            end
                        end
                        else
                            state_next = halt;
                    end
                    /* DECODE MOV */
                    4'b0000: begin
                        //mov instrukcija, trebaju mi oba bajta koja su ucitana
                        if(ir_h_out[3:0]==4'b0000) begin
                            //jednostavno, sa asrese drugog operanda stavim na adresu prvog operanda
                            if(ir_h_out[7]==1) begin
                                // indirektno
                                load(ir_h_out[6:4]);
                                state_next = execute_mov_indirect_2;
                            end
                            else begin
                                //direktno
                                load(ir_h_out[6:4]);
                                state_next = execute_mov;
                            end
                        end
                        else begin
                            //konstanta sa drugog bajta se kopira na adresu prvog operanda
                            //check if it is indirect
                            if(ir_h_out[11]==1) begin
                                //indirect first operand, i have to save second operand in acc
                                acc_in = ir_l_out;
                                acc_ld = 1;
                                load(ir_h_out[10:8]);
                                state_next = execute_mov_indirect_1;
                            end
                            else begin
                                store(ir_h_out[10:8], ir_l_out);
                                state_next = fetch1;
                            end
                        end
                    end

                    /* DECODE ARITHMETIC */
                    //in this section i have to load second operand in acc, then to load thirs operand, then to perform operation
                    //and store result in acc, then to save it to third operand(might be indirect)
                    //i am going to decode first operand immediately
                    4'b0001: begin
                        if(ir_h_out[7]==1) begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_2_indirect;
                        end
                        else begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_3;
                        end
                    end
                    4'b0010: begin
                        if(ir_h_out[7]==1) begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_2_indirect;
                        end
                        else begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_3;
                        end
                    end
                    4'b0011: begin
                        if(ir_h_out[7]==1) begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_2_indirect;
                        end
                        else begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_3;
                        end
                    end
                    4'b0100: begin
                        if(ir_h_out[7]==1) begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_2_indirect;
                        end
                        else begin
                           load(ir_h_out[6:4]);
                           state_next = decode_arithmetic_3;
                        end
                    end
                    default: state_next = halt;//error, go to halt
                endcase
            end

            /* DECODE AND EXECUTE ARITHMETIC */

            decode_arithmetic_2_indirect: begin
                load(mem_in);
                state_next = decode_arithmetic_3;
            end

            decode_arithmetic_3: begin
                //i have second operand in mem_in, store it in acc
                acc_in = mem_in;
                acc_ld = 1;
                if(ir_h_out[3]==1) begin
                    load(ir_h_out[2:0]);
                    state_next = decode_arithmetic_3_indirect;
                end
                else begin
                    load(ir_h_out[2:0]);
                    state_next = execute_arithmetic;
                end
            end

            decode_arithmetic_3_indirect: begin
                load(mem_in);
                state_next = execute_arithmetic;
            end

            /* EXECUTE ARITHMETIC */

            execute_arithmetic: begin
                // now i have second operand in acc and third operand in mem_in, perform operation with alu and save it in the acc
                //just put in oc instr_oc -1
                alu_oc = ir_h_out[15:12] - 1;
                alu_a = acc_out;
                alu_b = mem_in;
                //now save it in acc
                acc_in = alu_f;
                acc_ld = 1;
                //now go to storing part, but first check if it is indirect
                if(ir_h_out[11]==1) begin
                    load(ir_h_out[10:8]);
                    state_next = decode_arithmetic_1_indirect;
                end
                else begin
                    store(ir_h_out[10:8], alu_f);
                    state_next = fetch1;//no need for decode
                end
            end
            
            // THIS IS EXECUTE AT THE SAME TIME

            decode_arithmetic_1_indirect: begin
                store(mem_in, acc_out);
                state_next = fetch1;
            end

            /* EXECUTE IN */

            execute_in: begin
                store(mem_in,in);
                state_next = fetch1;
            end
            /* EXECUTE OUT */
            execute_out_indirect: begin
                load(mem_in);
                state_next = execute_out;
            end
            execute_out: begin
                out_next = mem_in;
                state_next = fetch1;
            end
            /* EXECUTE STOP */
            execute_stop_1: begin
                //na mem_in je podatak koji treba ispisati
                out_next = mem_in;
                //check if there are other operands to print
                if(ir_h_out[7:4] != 4'b0000) begin
                    //ispisuj ga
                    if(ir_h_out[4] == 1'b1) begin
                        load(ir_h_out[6:4]);
                        state_next = execute_stop_2_indirect;
                    end
                    else begin
                        load(ir_h_out[6:4]);
                        state_next = execute_stop_2;
                    end
                end
                else if(ir_h_out[3:0] != 4'b0000) begin
                    //ispisuj ga
                    if(ir_h_out[3] == 1'b1) begin
                        load(ir_h_out[2:0]);
                        state_next = execute_stop_3_indirect;
                    end
                    else begin
                        load(ir_h_out[2:0]);
                        state_next = execute_stop_3;
                    end
                end
                else
                    state_next = halt;
            end
            execute_stop_1_indirect: begin
                load(mem_in);
                state_next = execute_stop_1;
            end
            execute_stop_2: begin
                //na mem_in je podatak koji treba ispisati
                out_next = mem_in;
                //check if there are other operands to print
                if(ir_h_out[3:0] != 4'b0000) begin
                    //ispisuj ga
                    if(ir_h_out[3] == 1'b1) begin
                        load(ir_h_out[2:0]);
                        state_next = execute_stop_3_indirect;
                    end
                    else begin
                        load(ir_h_out[2:0]);
                        state_next = execute_stop_3;
                    end
                end
                else
                    state_next = halt;
            end
            execute_stop_2_indirect: begin
                load(mem_in);
                state_next = execute_stop_2;
            end
            execute_stop_3: begin
                //na mem_in je podatak koji treba ispisati
                out_next = mem_in;
                state_next = halt;
            end
            execute_stop_3_indirect: begin
                load(mem_in);
                state_next = execute_stop_3;
            end

            /* EXECUTE MOV */
            execute_mov: begin
                //check if it is indirect
                if(ir_h_out[11]==1) begin
                    //indirect first operand, i have to save second operand in acc
                    acc_in = mem_in;
                    acc_ld = 1;
                    load(ir_h_out[10:8]);
                    state_next = execute_mov_indirect_1;
                end
                else begin
                    store(ir_h_out[10:8], mem_in);
                    state_next = fetch1;
                end
            end
            execute_mov_indirect_2: begin
                load(mem_in);
                state_next = execute_mov;
            end
            execute_mov_indirect_1: begin
                //in mem_in i have address of first operand, and value of second operand is in acc
                store(mem_in, acc_out);
                state_next = fetch1;
            end
            
        endcase
    end

endmodule