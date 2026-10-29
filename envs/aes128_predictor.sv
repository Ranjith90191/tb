class aes128_predictor extends uvm_component;
 `uvm_component_utils(aes128_predictor)

function new(string name="aes128_predictor",uvm_component parent);
    super.new(name,parent);
endfunction

bit [7:0] key[4][4];
bit [7:0] state[4][4];
bit [7:0] e_out[4][4];
bit [7:0] d_out[4][4];
        
bit [31:0] word[44];
bit [7:0] rk[11][4][4];

bit [127:0] k;
bit [127:0] s;

function void AddRoundKey(input bit[7:0] s[4][4],input bit[7:0] k[4][4],output bit[7:0] os[4][4]);
    foreach(s[i,j])begin
        os[i][j]=s[i][j]^k[i][j];
    end
endfunction

function void ShiftRows(input bit[7:0] s[4][4],output bit[7:0] os[4][4]);
    os[0] = s[0];
    os[1] = {s[1][1],s[1][2],s[1][3],s[1][0]};
    os[2] = {s[2][2],s[2][3],s[2][0],s[2][1]};
    os[3] = {s[3][3],s[3][0],s[3][1],s[3][2]};
endfunction

function void InvShiftRows(input bit[7:0] s[4][4],output bit[7:0] os[4][4]);
    os[0] = s[0];
    os[1] = {s[1][3],s[1][0],s[1][1],s[1][2]};
    os[2] = {s[2][2],s[2][3],s[2][0],s[2][1]};
    os[3] = {s[3][1],s[3][2],s[3][3],s[3][0]};
endfunction

function bit [7:0] multiplier(input bit [7:0] s);
    if(s[7])begin
        return (s<<1)^8'h1B;
    end
    else begin
        return (s<<1);
    end
endfunction

function void MixColumns(input bit[7:0] s[4][4],output bit[7:0] os[4][4]);
    os[0][0] = multiplier(s[0][0])^(multiplier(s[1][0])^s[1][0])^s[2][0]^s[3][0];
    os[1][0] = s[0][0]^multiplier(s[1][0])^(multiplier(s[2][0])^s[2][0])^s[3][0];
    os[2][0] = s[0][0]^s[1][0]^multiplier(s[2][0])^(multiplier(s[3][0])^s[3][0]);
    os[3][0] = (multiplier(s[0][0])^s[0][0])^s[1][0]^s[2][0]^multiplier(s[3][0]);

    os[0][1] = multiplier(s[0][1])^(multiplier(s[1][1])^s[1][1])^s[2][1]^s[3][1];
    os[1][1] = s[0][1]^multiplier(s[1][1])^(multiplier(s[2][1])^s[2][1])^s[3][1];
    os[2][1] = s[0][1]^s[1][1]^multiplier(s[2][1])^(multiplier(s[3][1])^s[3][1]);
    os[3][1] = (multiplier(s[0][1])^s[0][1])^s[1][1]^s[2][1]^multiplier(s[3][1]);

    os[0][2] = multiplier(s[0][2])^(multiplier(s[1][2])^s[1][2])^s[2][2]^s[3][2];
    os[1][2] = s[0][2]^multiplier(s[1][2])^(multiplier(s[2][2])^s[2][2])^s[3][2];
    os[2][2] = s[0][2]^s[1][2]^multiplier(s[2][2])^(multiplier(s[3][2])^s[3][2]);
    os[3][2] = (multiplier(s[0][2])^s[0][2])^s[1][2]^s[2][2]^multiplier(s[3][2]);

    os[0][3] = multiplier(s[0][3])^(multiplier(s[1][3])^s[1][3])^s[2][3]^s[3][3];
    os[1][3] = s[0][3]^multiplier(s[1][3])^(multiplier(s[2][3])^s[2][3])^s[3][3];
    os[2][3] = s[0][3]^s[1][3]^multiplier(s[2][3])^(multiplier(s[3][3])^s[3][3]);
    os[3][3] = (multiplier(s[0][3])^s[0][3])^s[1][3]^s[2][3]^multiplier(s[3][3]);
endfunction

function bit [7:0] mul9(input bit [7:0] s);
    return multiplier(multiplier(multiplier(s)))^s;
endfunction

function bit [7:0] mul11(input bit [7:0] s);
    return multiplier(multiplier(multiplier(s)))^multiplier(s)^s;
endfunction

function bit [7:0] mul13(input bit [7:0] s);
    return multiplier(multiplier(multiplier(s)))^multiplier(multiplier(s))^s;
endfunction

function bit [7:0] mul14(input bit [7:0] s);
    return multiplier(multiplier(multiplier(s)))^multiplier(multiplier(s))^multiplier(s);
endfunction

function void InvMixColumns(input bit[7:0] s[4][4],output bit[7:0] os[4][4]);
    os[0][0] = mul14(s[0][0])^mul11(s[1][0])^mul13(s[2][0])^mul9(s[3][0]);
    os[1][0] = mul9(s[0][0])^mul14(s[1][0])^mul11(s[2][0])^mul13(s[3][0]);
    os[2][0] = mul13(s[0][0])^mul9(s[1][0])^mul14(s[2][0])^mul11(s[3][0]);
    os[3][0] = mul11(s[0][0])^mul13(s[1][0])^mul9(s[2][0])^mul14(s[3][0]);

    os[0][1] = mul14(s[0][1])^mul11(s[1][1])^mul13(s[2][1])^mul9(s[3][1]);
    os[1][1] = mul9(s[0][1])^mul14(s[1][1])^mul11(s[2][1])^mul13(s[3][1]);
    os[2][1] = mul13(s[0][1])^mul9(s[1][1])^mul14(s[2][1])^mul11(s[3][1]);
    os[3][1] = mul11(s[0][1])^mul13(s[1][1])^mul9(s[2][1])^mul14(s[3][1]);

    os[0][2] = mul14(s[0][2])^mul11(s[1][2])^mul13(s[2][2])^mul9(s[3][2]);
    os[1][2] = mul9(s[0][2])^mul14(s[1][2])^mul11(s[2][2])^mul13(s[3][2]);
    os[2][2] = mul13(s[0][2])^mul9(s[1][2])^mul14(s[2][2])^mul11(s[3][2]);
    os[3][2] = mul11(s[0][2])^mul13(s[1][2])^mul9(s[2][2])^mul14(s[3][2]);

    os[0][3] = mul14(s[0][3])^mul11(s[1][3])^mul13(s[2][3])^mul9(s[3][3]);
    os[1][3] = mul9(s[0][3])^mul14(s[1][3])^mul11(s[2][3])^mul13(s[3][3]);
    os[2][3] = mul13(s[0][3])^mul9(s[1][3])^mul14(s[2][3])^mul11(s[3][3]);
    os[3][3] = mul11(s[0][3])^mul13(s[1][3])^mul9(s[2][3])^mul14(s[3][3]);
endfunction
        
function void SubBytes(input bit[7:0] s[4][4], output bit[7:0] os[4][4]);
    bit [7:0] r[16][16];
    r[0]  = '{8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76};
    r[1]  = '{8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0};
    r[2]  = '{8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15};
    r[3]  = '{8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75};
    r[4]  = '{8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84};
    r[5]  = '{8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf};
    r[6]  = '{8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8};
    r[7]  = '{8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2};
    r[8]  = '{8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73};
    r[9]  = '{8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb};
    r[10] = '{8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79};
    r[11] = '{8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08};
    r[12] = '{8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a};
    r[13] = '{8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e};
    r[14] = '{8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf};
    r[15] = '{8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16};
    for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
            os[i][j] = r[s[i][j][7:4]][s[i][j][3:0]];
        end
    end
endfunction

function void InvSubBytes(input bit[7:0] s[4][4], output bit[7:0] os[4][4]);
    bit [7:0] r[16][16];
    r[0]  = '{8'h52, 8'h09, 8'h6a, 8'hd5, 8'h30, 8'h36, 8'ha5, 8'h38, 8'hbf, 8'h40, 8'ha3, 8'h9e, 8'h81, 8'hf3, 8'hd7, 8'hfb};
    r[1]  = '{8'h7c, 8'he3, 8'h39, 8'h82, 8'h9b, 8'h2f, 8'hff, 8'h87, 8'h34, 8'h8e, 8'h43, 8'h44, 8'hc4, 8'hde, 8'he9, 8'hcb};
    r[2]  = '{8'h54, 8'h7b, 8'h94, 8'h32, 8'ha6, 8'hc2, 8'h23, 8'h3d, 8'hee, 8'h4c, 8'h95, 8'h0b, 8'h42, 8'hfa, 8'hc3, 8'h4e};
    r[3]  = '{8'h08, 8'h2e, 8'ha1, 8'h66, 8'h28, 8'hd9, 8'h24, 8'hb2, 8'h76, 8'h5b, 8'ha2, 8'h49, 8'h6d, 8'h8b, 8'hd1, 8'h25};
    r[4]  = '{8'h72, 8'hf8, 8'hf6, 8'h64, 8'h86, 8'h68, 8'h98, 8'h16, 8'hd4, 8'ha4, 8'h5c, 8'hcc, 8'h5d, 8'h65, 8'hb6, 8'h92};
    r[5]  = '{8'h6c, 8'h70, 8'h48, 8'h50, 8'hfd, 8'hed, 8'hb9, 8'hda, 8'h5e, 8'h15, 8'h46, 8'h57, 8'ha7, 8'h8d, 8'h9d, 8'h84};
    r[6]  = '{8'h90, 8'hd8, 8'hab, 8'h00, 8'h8c, 8'hbc, 8'hd3, 8'h0a, 8'hf7, 8'he4, 8'h58, 8'h05, 8'hb8, 8'hb3, 8'h45, 8'h06};
    r[7]  = '{8'hd0, 8'h2c, 8'h1e, 8'h8f, 8'hca, 8'h3f, 8'h0f, 8'h02, 8'hc1, 8'haf, 8'hbd, 8'h03, 8'h01, 8'h13, 8'h8a, 8'h6b};
    r[8]  = '{8'h3a, 8'h91, 8'h11, 8'h41, 8'h4f, 8'h67, 8'hdc, 8'hea, 8'h97, 8'hf2, 8'hcf, 8'hce, 8'hf0, 8'hb4, 8'he6, 8'h73};
    r[9]  = '{8'h96, 8'hac, 8'h74, 8'h22, 8'he7, 8'had, 8'h35, 8'h85, 8'he2, 8'hf9, 8'h37, 8'he8, 8'h1c, 8'h75, 8'hdf, 8'h6e};
    r[10] = '{8'h47, 8'hf1, 8'h1a, 8'h71, 8'h1d, 8'h29, 8'hc5, 8'h89, 8'h6f, 8'hb7, 8'h62, 8'h0e, 8'haa, 8'h18, 8'hbe, 8'h1b};
    r[11] = '{8'hfc, 8'h56, 8'h3e, 8'h4b, 8'hc6, 8'hd2, 8'h79, 8'h20, 8'h9a, 8'hdb, 8'hc0, 8'hfe, 8'h78, 8'hcd, 8'h5a, 8'hf4};
    r[12] = '{8'h1f, 8'hdd, 8'ha8, 8'h33, 8'h88, 8'h07, 8'hc7, 8'h31, 8'hb1, 8'h12, 8'h10, 8'h59, 8'h27, 8'h80, 8'hec, 8'h5f};
    r[13] = '{8'h60, 8'h51, 8'h7f, 8'ha9, 8'h19, 8'hb5, 8'h4a, 8'h0d, 8'h2d, 8'he5, 8'h7a, 8'h9f, 8'h93, 8'hc9, 8'h9c, 8'hef};
    r[14] = '{8'ha0, 8'he0, 8'h3b, 8'h4d, 8'hae, 8'h2a, 8'hf5, 8'hb0, 8'hc8, 8'heb, 8'hbb, 8'h3c, 8'h83, 8'h53, 8'h99, 8'h61};
    r[15] = '{8'h17, 8'h2b, 8'h04, 8'h7e, 8'hba, 8'h77, 8'hd6, 8'h26, 8'he1, 8'h69, 8'h14, 8'h63, 8'h55, 8'h21, 8'h0c, 8'h7d};
    for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
            os[i][j] = r[s[i][j][7:4]][s[i][j][3:0]];
        end
    end
endfunction

function bit [7:0] SubWord(bit [7:0] w);
     bit [7:0] r[16][16];
    r[0]  = '{8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76};
    r[1]  = '{8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0};
    r[2]  = '{8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15};
    r[3]  = '{8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75};
    r[4]  = '{8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84};
    r[5]  = '{8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf};
    r[6]  = '{8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8};
    r[7]  = '{8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2};
    r[8]  = '{8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73};
    r[9]  = '{8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb};
    r[10] = '{8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79};
    r[11] = '{8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08};
    r[12] = '{8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a};
    r[13] = '{8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e};
    r[14] = '{8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf};
    r[15] = '{8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16};
    return r[w[7:4]][w[3:0]];
endfunction

function bit [31:0] g(bit [31:0] w,bit [31:0] round);
    w = {w[23:0],w[31:24]};
    w[31:24] = SubWord(w[31:24]);
    w[23:16] = SubWord(w[23:16]);
    w[15:8] = SubWord(w[15:8]);
    w[7:0] = SubWord(w[7:0]);
    return w^round;
endfunction

function void word_gen(bit [7:0] k[4][4]);
    automatic int round = 0;
    bit [31:0] round_const[10] = '{32'h01000000,32'h02000000,32'h04000000,32'h08000000,32'h10000000,32'h20000000,32'h40000000,32'h80000000,32'h1b000000,32'h36000000};
    word[0] = {k[0][0],k[1][0],k[2][0],k[3][0]};
    word[1] = {k[0][1],k[1][1],k[2][1],k[3][1]};
    word[2] = {k[0][2],k[1][2],k[2][2],k[3][2]};
    word[3] = {k[0][3],k[1][3],k[2][3],k[3][3]};
    for(int i=4;i<44;i++)begin
        if(i%4==0)begin
            word[i] = word[i-4]^g(word[i-1],round_const[round]);
            round++;
        end
        else begin
            word[i] = word[i-4]^word[i-1];
        end
    end
endfunction

function void round_key_gen();
    automatic int w_idx=0;
    foreach(rk[i])begin
        rk[i][0][0] = word[w_idx][31:24];
        rk[i][1][0] = word[w_idx][23:16];
        rk[i][2][0] = word[w_idx][15:8];
        rk[i][3][0] = word[w_idx][7:0];
        w_idx++;
        rk[i][0][1] = word[w_idx][31:24];
        rk[i][1][1] = word[w_idx][23:16];
        rk[i][2][1] = word[w_idx][15:8];
        rk[i][3][1] = word[w_idx][7:0];
        w_idx++;
        rk[i][0][2] = word[w_idx][31:24];
        rk[i][1][2] = word[w_idx][23:16];
        rk[i][2][2] = word[w_idx][15:8];
        rk[i][3][2] = word[w_idx][7:0];
        w_idx++;
        rk[i][0][3] = word[w_idx][31:24];
        rk[i][1][3] = word[w_idx][23:16];
        rk[i][2][3] = word[w_idx][15:8];
        rk[i][3][3] = word[w_idx][7:0];
        w_idx++;
    end
endfunction

function bit[127:0] Encryption(input bit[7:0] k[4][4],input bit[7:0] s[4][4]);
    bit [7:0] state_in[4][4];
    bit [7:0] state_out[4][4];
    state_in = s;

    word_gen(k);
    round_key_gen();

    AddRoundKey(state_in,rk[0],state_out);state_in=state_out;
    for(int i=1;i<10;i++)begin
        SubBytes(state_in,state_out);state_in=state_out;
        ShiftRows(state_in,state_out);state_in=state_out;
        MixColumns(state_in,state_out);state_in=state_out;
        AddRoundKey(state_in,rk[i],state_out);state_in=state_out;
    end
    SubBytes(state_in,state_out);state_in=state_out;
    ShiftRows(state_in,state_out);state_in=state_out;
    AddRoundKey(state_in,rk[10],state_out);
    return de_matrix_maker(state_out);
endfunction

function bit [127:0] Decryption(input bit[7:0] k[4][4],input bit[7:0] c[4][4]);
    bit [7:0] state_in[4][4];
    bit [7:0] state_out[4][4];
    state_in = c;

    word_gen(k);
    round_key_gen();

    AddRoundKey(state_in,rk[10],state_out);state_in=state_out;
    for(int i=9;i>=1;i--)begin
        InvShiftRows(state_in,state_out);state_in=state_out;
        InvSubBytes(state_in,state_out);state_in=state_out;
        AddRoundKey(state_in,rk[i],state_out);state_in=state_out;
        InvMixColumns(state_in,state_out);state_in=state_out;
    end
    InvShiftRows(state_in,state_out);state_in=state_out;
    InvSubBytes(state_in,state_out);state_in=state_out;
    AddRoundKey(state_in,rk[0],state_out);
    return de_matrix_maker(state_out);
endfunction

function void matrix_maker(input bit [127:0] key,input bit [127:0] state,output bit [7:0] k[4][4],output bit [7:0] s[4][4]);
    k[0][0] = key[127:120];
    k[1][0] = key[119:112];
    k[2][0] = key[111:104];
    k[3][0] = key[103:96];
  
    k[0][1] = key[95:88];
    k[1][1] = key[87:80];
    k[2][1] = key[79:72];
    k[3][1] = key[71:64];

    k[0][2] = key[63:56];
    k[1][2] = key[55:48];
    k[2][2] = key[47:40];
    k[3][2] = key[39:32];

    k[0][3] = key[31:24];
    k[1][3] = key[23:16];
    k[2][3] = key[15:8];
    k[3][3] = key[7:0];

    s[0][0] = state[127:120];
    s[1][0] = state[119:112];
    s[2][0] = state[111:104];
    s[3][0] = state[103:96];
  
    s[0][1] = state[95:88];
    s[1][1] = state[87:80];
    s[2][1] = state[79:72];
    s[3][1] = state[71:64];

    s[0][2] = state[63:56];
    s[1][2] = state[55:48];
    s[2][2] = state[47:40];
    s[3][2] = state[39:32];

    s[0][3] = state[31:24];
    s[1][3] = state[23:16];
    s[2][3] = state[15:8];
    s[3][3] = state[7:0];
endfunction

function bit [127:0] de_matrix_maker(input bit [7:0] s[4][4]);
    bit [127:0] r;
    r[127:120] = s[0][0];
    r[119:112] = s[1][0];
    r[111:104] = s[2][0];
    r[103:96] = s[3][0];
  
    r[95:88] = s[0][1];
    r[87:80] = s[1][1];
    r[79:72] = s[2][1];
    r[71:64] = s[3][1];

    r[63:56] = s[0][2];
    r[55:48] = s[1][2];
    r[47:40] = s[2][2];
    r[39:32] = s[3][2];

    r[31:24] = s[0][3];
    r[23:16] = s[1][3];
    r[15:8] = s[2][3];
    r[7:0] = s[3][3];
    return r;
endfunction

function void printer(bit[7:0] s[4][4],bit stream=0);
    if(!stream)begin
        for(int i=0;i<4;i++)begin
        for(int j=0;j<4;j++)begin
            $write("%h ",s[i][j]);
        end
        $display("");
    end
    end
    else begin
        bit [127:0] temp; 
        temp = de_matrix_maker(s);
        $write("%h",temp[127:96]);$write(" ");$write("%h",temp[95:64]);$write(" ");$write("%h",temp[63:32]);$write(" ");$write("%h",temp[31:0]);
    end
    $display("");
endfunction
endclass