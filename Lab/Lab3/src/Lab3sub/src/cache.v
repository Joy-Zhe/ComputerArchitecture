// | ----------- address 32 ----------- |
// | 31   8 | 7     4 | 3    2 | 1    0 |
// | tag 24 | index 4 | word 2 | byte 2 |

module cache (
	input wire clk,  // clock
	input wire rst,  // reset
	input wire [ADDR_BITS-1:0] addr,  // address
    input wire load,    //  read refreshes recent bit
	input wire replace,  // set valid to 1 and reset dirty to 0
	input wire store,  // set dirty to 1
	input wire invalid,  // reset valid to 0
    input wire [2:0] u_b_h_w, // select signed or not & data width
                              // please refer to definition of LB, LH, LW, LBU, LHU in RV32I Instruction Set  
	input wire [31:0] din,  // data write in
    output hit,  // hit or not
	output [31:0] dout,  // data read out
	output valid,  // valid bit
	output dirty,  // dirty bit
	output [TAG_BITS-1:0] tag  // tag bits
	);

    `include "addr_define.vh"

    wire [31:0] word1, word2, word3, word4;
    wire [15:0] half_word1, half_word2, half_word3, half_word4;
    wire [7:0]  byte1, byte2, byte3, byte4;
    wire recent1, recent2, recent3, recent4, valid1, valid2, valid3, valid4, dirty1, dirty2, dirty3, dirty4;
    wire [TAG_BITS-1:0] tag1, tag2, tag3, tag4;
    wire hit1, hit2, hit3, hit4;

    reg [1:0] inner_recent [ELEMENT_NUM-1:0]; // 2 LRU bits
    reg [ELEMENT_NUM-1:0] inner_valid = 0;
    reg [ELEMENT_NUM-1:0] inner_dirty = 0;
    reg [TAG_BITS-1:0] inner_tag [0:ELEMENT_NUM-1];
    // 64 elements, 4 ways set associative => 16 sets
    reg [31:0] inner_data [0:ELEMENT_NUM*ELEMENT_WORDS-1];

    // initialize tag and data and LRUbits with 0
    integer i;
    initial begin
        for (i = 0; i < ELEMENT_NUM; i = i + 1)
            inner_tag[i] = 24'b0;

        for (i = 0; i < ELEMENT_NUM*ELEMENT_WORDS; i = i + 1)
            inner_data[i] = 32'b0;

        for (i = 0; i < ELEMENT_NUM; i = i + 1)
            inner_recent[i] = 2'b0;
    end

    // the bits in an input address:
    wire [TAG_BITS-1:0] addr_tag;
    wire [SET_INDEX_WIDTH-1:0] addr_index;     // idx of set
    wire [ELEMENT_INDEX_WIDTH-1:0] addr_element1; 
    wire [ELEMENT_INDEX_WIDTH-1:0] addr_element2;     
    wire [ELEMENT_INDEX_WIDTH-1:0] addr_element3;
    wire [ELEMENT_INDEX_WIDTH-1:0] addr_element4;    // idx of element
    wire [ELEMENT_INDEX_WIDTH+ELEMENT_WORDS_WIDTH-1:0] addr_word1;
    wire [ELEMENT_INDEX_WIDTH+ELEMENT_WORDS_WIDTH-1:0] addr_word2; 
    wire [ELEMENT_INDEX_WIDTH+ELEMENT_WORDS_WIDTH-1:0] addr_word3; 
    wire [ELEMENT_INDEX_WIDTH+ELEMENT_WORDS_WIDTH-1:0] addr_word4;    // element index + word index

    assign addr_tag = addr[31:8];  // 31-8 tag bits 23bits         //need to fill in
    assign addr_index = addr[7:4]; // 7-4 index bits 5bits         //need to fill in
    assign addr_element1 = {addr_index, 2'b00};  // way-0
    assign addr_element2 = {addr_index, 2'b01};  // way-1    
    assign addr_element3 = {addr_index, 2'b10};  // way-2    
    assign addr_element4 = {addr_index, 2'b11};  // way-3    //need to fill in
    assign addr_word1 = {addr_element1, addr[ELEMENT_WORDS_WIDTH+WORD_BYTES_WIDTH-1:WORD_BYTES_WIDTH]};
    assign addr_word2 = {addr_element2, addr[ELEMENT_WORDS_WIDTH+WORD_BYTES_WIDTH-1:WORD_BYTES_WIDTH]};
    assign addr_word3 = {addr_element3, addr[ELEMENT_WORDS_WIDTH+WORD_BYTES_WIDTH-1:WORD_BYTES_WIDTH]};
    assign addr_word4 = {addr_element4, addr[ELEMENT_WORDS_WIDTH+WORD_BYTES_WIDTH-1:WORD_BYTES_WIDTH]};
               //need to fill in

    assign word1 = inner_data[addr_word1];
    assign word2 = inner_data[addr_word2];
    assign word3 = inner_data[addr_word3];
    assign word4 = inner_data[addr_word4];

    assign half_word1 = addr[1] ? word1[31:16] : word1[15:0];
    assign half_word2 = addr[1] ? word2[31:16] : word2[15:0]; 
    assign half_word3 = addr[1] ? word3[31:16] : word3[15:0]; 
    assign half_word4 = addr[1] ? word4[31:16] : word4[15:0]; 

    assign byte1 = addr[1] ?
                    addr[0] ? word1[31:24] : word1[23:16] :
                    addr[0] ? word1[15:8] :  word1[7:0]   ;
    assign byte2 = addr[1] ?
                    addr[0] ? word2[31:24] : word2[23:16] :
                    addr[0] ? word2[15:8] :  word2[7:0]   ;
    assign byte3 = addr[1] ?
                    addr[0] ? word3[31:24] : word3[23:16] :
                    addr[0] ? word3[15:8] :  word3[7:0]   ;
    assign byte4 = addr[1] ?
                    addr[0] ? word4[31:24] : word4[23:16] :
                    addr[0] ? word4[15:8] :  word4[7:0]   ;

    assign recent1 = inner_recent[addr_element1];
    assign recent2 = inner_recent[addr_element2];              
    assign recent3 = inner_recent[addr_element3];              
    assign recent4 = inner_recent[addr_element4];              

    assign valid1 = inner_valid[addr_element1];
    assign valid2 = inner_valid[addr_element2];
    assign valid3 = inner_valid[addr_element3];               
    assign valid4 = inner_valid[addr_element4];               
    assign dirty1 = inner_dirty[addr_element1];
    assign dirty2 = inner_dirty[addr_element2]; 
    assign dirty3 = inner_dirty[addr_element3];
    assign dirty4 = inner_dirty[addr_element4];              
    assign tag1 = inner_tag[addr_element1];
    assign tag2 = inner_tag[addr_element2];
    assign tag3 = inner_tag[addr_element3];
    assign tag4 = inner_tag[addr_element4];
    assign hit1 = valid1 & (tag1 == addr_tag);
    assign hit2 = valid2 & (tag2 == addr_tag);
    assign hit3 = valid3 & (tag3 == addr_tag);
    assign hit4 = valid4 & (tag4 == addr_tag);
    assign valid = hit1 ? valid1 : hit2 ? valid2 : hit3 ? valid3 : hit4 ? valid4 : 
        (recent1 == 2'b11) ? valid1 : 
        (recent2 == 2'b11) ? valid2 : 
        (recent3 == 2'b11) ? valid3 :
        (recent4 == 2'b11) ? valid4 : 0;
    assign dirty = hit1 ? dirty1 :
        hit2 ? dirty2 : 
        hit3 ? dirty3 :
        hit4 ? dirty4 :
        (recent1 == 2'b11) ? dirty1 : 
        (recent2 == 2'b11) ? dirty2 : 
        (recent3 == 2'b11) ? dirty3 :
        (recent4 == 2'b11) ? dirty4 : 0;
    assign hit = valid && (hit1 | hit2 | hit3 | hit4);
    assign tag = hit1 ? tag1 :
        hit2 ? tag2 : 
        hit3 ? tag3 :
        hit4 ? tag4 :
        (recent1 == 2'b11) ? tag1 :
        (recent2 == 2'b11) ? tag2 :
        (recent3 == 2'b11) ? tag3 :
        (recent4 == 2'b11) ? tag4 : 0;      

    assign dout = (load && hit1) ? 
    (u_b_h_w[1] ? word1 : 
        (u_b_h_w[0] ? 
            {u_b_h_w[2] ? 16'b0 : {16{half_word1[15]}}, half_word1} :
            {u_b_h_w[2] ? 24'b0 : {24{byte1[7]}}, byte1})) :
    (load && hit2) ? 
    (u_b_h_w[1] ? word2 :
        (u_b_h_w[0] ? 
            {u_b_h_w[2] ? 16'b0 : {16{half_word2[15]}}, half_word2} :
            {u_b_h_w[2] ? 24'b0 : {24{byte2[7]}}, byte2})) : 
    (load && hit3) ?
    (u_b_h_w[1] ? word3 :
        (u_b_h_w[0] ? 
            {u_b_h_w[2] ? 16'b0 : {16{half_word3[15]}}, half_word3} :
            {u_b_h_w[2] ? 24'b0 : {24{byte3[7]}}, byte3})) :
    (load && hit4) ?
    (u_b_h_w[1] ? word4 :
        (u_b_h_w[0] ? 
            {u_b_h_w[2] ? 16'b0 : {16{half_word4[15]}}, half_word4} :
            {u_b_h_w[2] ? 24'b0 : {24{byte4[7]}}, byte4})) :
    (!load) ? inner_data[ recent1 ? addr_word2 : addr_word1 ]
        : 32'b0;

    

    always @ (posedge clk) begin 
        // read $ with load==0 means moving data from $ to mem
        // no need to update recent bit
        // otherwise the refresh process will be affected
        if (load) begin
            if (hit1) begin            
                // inner_recent will be refreshed only on r/w hit
                // (including the r/w hit after miss and replacement)
                // if inner_recent[other] >= inner_recent[hit], then no need to update, because it's still ahead of inner_recent[hit].
                inner_recent[addr_element1] <= 2'b00;
                if (inner_recent[addr_element2] < inner_recent[addr_element1] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element1] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element1] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit2) begin
                inner_recent[addr_element2] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element2] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element2] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element2] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit3) begin
                inner_recent[addr_element3] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element3] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element3] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element3] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit4) begin
                inner_recent[addr_element4] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element4] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element4] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element4] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
            end
        end
        if (store) begin
            if (hit1) begin
                inner_data[addr_word1] <= 
                    u_b_h_w[1] ?        // word?
                        din
                    :
                        u_b_h_w[0] ?    // half word?
                            addr[1] ?       // upper / lower?
                                {din[15:0], word1[15:0]} 
                            :
                                {word1[31:16], din[15:0]} 
                        :   // byte
                            addr[1] ?
                                addr[0] ?
                                    {din[7:0], word1[23:0]}   // 11
                                :
                                    {word1[31:24], din[7:0], word1[15:0]} // 10
                            :
                                addr[0] ?
                                    {word1[31:16], din[7:0], word1[7:0]}   // 01
                                :
                                    {word1[31:8], din[7:0]} // 00
                ;
                inner_dirty[addr_element1] <= 1'b1;
                inner_recent[addr_element1] <= 2'b00;
                if (inner_recent[addr_element2] < inner_recent[addr_element1] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element1] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element1] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit2) begin
                inner_data[addr_word2] <=
                    u_b_h_w[1] ?        // word?
                        din
                    :
                        u_b_h_w[0] ?    // half word?
                            addr[1] ?       // upper / lower?
                                {din[15:0], word2[15:0]} 
                            :
                                {word2[31:16], din[15:0]} 
                        :   // byte
                            addr[1] ?
                                addr[0] ?
                                    {din[7:0], word2[23:0]}   // 11
                                :
                                    {word2[31:24], din[7:0], word2[15:0]} // 10
                            :
                                addr[0] ?
                                    {word2[31:16], din[7:0], word2[7:0]}   // 01
                                :
                                    {word2[31:8], din[7:0]} // 00
                ;
                inner_dirty[addr_element2] <= 1'b1; // set dirty
                inner_recent[addr_element2] <= 2'b00; // set recent
                if (inner_recent[addr_element1] < inner_recent[addr_element2] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element2] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element2] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end 
            else if (hit3) begin
                inner_data[addr_word3] <=
                    u_b_h_w[1] ?        // word?
                        din
                    :
                        u_b_h_w[0] ?    // half word?
                            addr[1] ?       // upper / lower?
                                {din[15:0], word3[15:0]} 
                            :
                                {word3[31:16], din[15:0]} 
                        :   // byte
                            addr[1] ?
                                addr[0] ?
                                    {din[7:0], word3[23:0]}   // 11
                                :
                                    {word3[31:24], din[7:0], word3[15:0]} // 10
                            :
                                addr[0] ?
                                    {word3[31:16], din[7:0], word3[7:0]}   // 01
                                :
                                    {word3[31:8], din[7:0]} // 00
                ;
                inner_dirty[addr_element3] <= 1'b1; // set dirty
                inner_recent[addr_element3] <= 2'b00; // set recent
                if (inner_recent[addr_element1] < inner_recent[addr_element3] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element3] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element3] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit4) begin
                inner_data[addr_word4] <=
                    u_b_h_w[1] ?        // word?
                        din
                    :
                        u_b_h_w[0] ?    // half word?
                            addr[1] ?       // upper / lower?
                                {din[15:0], word4[15:0]} 
                            :
                                {word4[31:16], din[15:0]} 
                        :   // byte
                            addr[1] ?
                                addr[0] ?
                                    {din[7:0], word4[23:0]}   // 11
                                :
                                    {word4[31:24], din[7:0], word4[15:0]} // 10
                            :
                                addr[0] ?
                                    {word4[31:16], din[7:0], word4[7:0]}   // 01
                                :
                                    {word4[31:8], din[7:0]} // 00
                ;
                inner_dirty[addr_element4] <= 1'b1; // set dirty
                inner_recent[addr_element4] <= 2'b00; // set recent
                if (inner_recent[addr_element1] < inner_recent[addr_element4] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element4] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element4] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
            end
        end

        if (replace) begin
            if (hit1) begin
                inner_data[addr_word1] <= din;
                inner_valid[addr_element1] <= 1'b1;
                inner_dirty[addr_element1] <= 1'b0;
                inner_tag[addr_element1] <= addr_tag;
                // update LRU
                inner_recent[addr_element1] <= 2'b00;
                if (inner_recent[addr_element2] < inner_recent[addr_element1] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element1] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element1] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit2) begin
                inner_data[addr_word2] <= din;
                inner_valid[addr_element2] <= 1'b1;
                inner_dirty[addr_element2] <= 1'b0;
                inner_tag[addr_element2] <= addr_tag;
                // update LRU
                inner_recent[addr_element2] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element2] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element2] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element2] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit3) begin
                inner_data[addr_word3] <= din;
                inner_valid[addr_element3] <= 1'b1;
                inner_dirty[addr_element3] <= 1'b0;
                inner_tag[addr_element3] <= addr_tag;
                // update LRU
                inner_recent[addr_element3] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element3] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element3] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element3] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end
            else if (hit4) begin
                inner_data[addr_word4] <= din;
                inner_valid[addr_element4] <= 1'b1;
                inner_dirty[addr_element4] <= 1'b0;
                inner_tag[addr_element4] <= addr_tag;
                // update LRU
                inner_recent[addr_element4] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element4] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element4] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element4] || inner_recent[addr_element3] == 2'b00)  
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
            end
            else if (recent1 == 2'b11 || (recent1 == 2'b00 && recent2 == 2'b00 || recent3 == 2'b00 || recent4 == 2'b00)) begin  // replace 1
                inner_data[addr_word1] <= din;
                inner_valid[addr_element1] <= 1'b1;
                inner_dirty[addr_element1] <= 1'b0;
                inner_tag[addr_element1] <= addr_tag;
                // update LRU
                inner_recent[addr_element1] <= 2'b00;
                if (inner_recent[addr_element2] < inner_recent[addr_element1] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element1] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element1] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end else if (recent2 == 2'b11) begin
                inner_data[addr_word2] <= din;
                inner_valid[addr_element2] <= 1'b1;
                inner_dirty[addr_element2] <= 1'b0;
                inner_tag[addr_element2] <= addr_tag;
                // update LRU
                inner_recent[addr_element2] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element2] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element2] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element2] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end else if (recent3 == 2'b11) begin
                inner_data[addr_word3] <= din;
                inner_valid[addr_element3] <= 1'b1;
                inner_dirty[addr_element3] <= 1'b0;
                inner_tag[addr_element3] <= addr_tag;
                // update LRU
                inner_recent[addr_element3] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element3] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element3] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element4] < inner_recent[addr_element3] || inner_recent[addr_element4] == 2'b00)
                    inner_recent[addr_element4] <= inner_recent[addr_element4] + 2'b01;
            end else if (recent4 == 2'b11) begin
                inner_data[addr_word4] <= din;
                inner_valid[addr_element4] <= 1'b1;
                inner_dirty[addr_element4] <= 1'b0;
                inner_tag[addr_element4] <= addr_tag;
                // update LRU
                inner_recent[addr_element4] <= 2'b00;
                if (inner_recent[addr_element1] < inner_recent[addr_element4] || inner_recent[addr_element1] == 2'b00)
                    inner_recent[addr_element1] <= inner_recent[addr_element1] + 2'b01;
                if (inner_recent[addr_element2] < inner_recent[addr_element4] || inner_recent[addr_element2] == 2'b00)
                    inner_recent[addr_element2] <= inner_recent[addr_element2] + 2'b01;
                if (inner_recent[addr_element3] < inner_recent[addr_element4] || inner_recent[addr_element3] == 2'b00)
                    inner_recent[addr_element3] <= inner_recent[addr_element3] + 2'b01;
            end
        end

        // not used currently, can be used to reset the cache.
        if (invalid) begin
            inner_recent[addr_element1] <= 2'b0;
            inner_recent[addr_element2] <= 2'b0;
            inner_recent[addr_element3] <= 2'b0;
            inner_recent[addr_element4] <= 2'b0;
            inner_valid[addr_element1] <= 1'b0;
            inner_valid[addr_element2] <= 1'b0;
            inner_valid[addr_element3] <= 1'b0;
            inner_valid[addr_element4] <= 1'b0;
            inner_dirty[addr_element1] <= 1'b0;
            inner_dirty[addr_element2] <= 1'b0;
            inner_dirty[addr_element3] <= 1'b0;
            inner_dirty[addr_element4] <= 1'b0;
        end
    end

endmodule
