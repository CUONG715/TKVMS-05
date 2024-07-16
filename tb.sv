`timescale 1ns / 1ps

module tb;

    parameter CLK_HALF_PERIOD = 1;
    parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

    // Module ports
    logic clk, rst, start, done, load;
    logic [127:0] key, iv, iBlock, oBlock;

    // Instantiate the OFB module
    OFB ofb_inst (
        .clk(clk),
        .rst(rst),
        .load(load),
        .start(start),
        .key(key),
        .iv(iv),
        .iBlock(iBlock),
        .oBlock(oBlock),
        .idle(done)
    );

    logic out;
    // int testNum = 0;  // Kh ng c?n testNum n?a
    // int error = 0;    // Kh ng c?n error n?a

    // Test task
    task automatic test(
        input logic [127:0] in,
        input logic [127:0] expected
    );
        // testNum = testNum + 1; // Kh ng c?n t?ng testNum
        iBlock = in;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        out = 1'b0;
        @(posedge done);
        if (oBlock !== expected) begin
            out = 1'bx;
            // error = error + 1; // Kh ng c?n t?ng error
            $error("[FAILED]");
            $display("\tiBlock \t= %h", in);
            $display("\toBlock \t= %h", oBlock);
            $display("\texpected \t= %h", expected);
        end
        else begin
            out = 1'b1;
            $display("[PASSED]");
            $display("\tiBlock \t= %h", in);
            $display("\toBlock \t= %h", oBlock);
        end
    endtask

    // Load key and iv task
    task automatic loadKeyAndIv(
        input logic [127:0] keyVal,
        input logic [127:0] ivVal
    );
        key = keyVal;
        iv = ivVal;
        @(negedge clk);
        load = 1;
        @(negedge clk);
        load = 0;
        // Wait for key expansion done
        @(posedge done);
    endtask

    // Main simulation block
    initial begin : MAIN
        out = 1'b0;
        rst = 1;
        load = 0;
        start = 0;
        repeat (2) @(negedge clk);
        rst = 0;

        // Test cases for OFB mode
        $display("\n\n===== encrypt iBlock in OFB mode ======");
        loadKeyAndIv(128'h31313131313131313131313131313131, 128'h41414141414141414141414141414141);
        test(128'h30303030303030303030303030303030, 128'h31313131313131313131313131313131);
        test(128'h32323232323232323232323232323232, 128'h33333333333333333333333333333333);
        

        $display("\n\n===== decrypt oBlock in OFB mode ======");
        loadKeyAndIv(128'h31313131313131313131313131313131, 128'h41414141414141414141414141414141);
        test(128'ha64a4fe3fb761df30522c3ff39a07785, 128'h486f616e67204d696e682048756f6e67);
        test(128'h39e56d62efb6d4cc606b0d2c9e4573b0, 128'h37383935383739353436383938373835);
       

        // $display("\n\n%d tests completed with %4d errors\n\n", testNum, error); // Comment d ng n y l?i

        // Stop simulation
        $finish;
    end

    // Clock generator
    always begin : CLK_GEN
        clk = 0;
        #CLK_HALF_PERIOD;
        clk = 1;
        #CLK_HALF_PERIOD;
    end

endmodule