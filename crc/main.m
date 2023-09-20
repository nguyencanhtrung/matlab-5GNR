% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : LUT-based CRC implementation
% Filename  : main
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-18 15:14:11
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File Created
% ----------------------------------------------------------------------------
clc; clear;

%------------------------------------------
%% Libraries
%------------------------------------------
addpath(genpath('./../libs'));

%------------------------------------------
%% FLAGS
%------------------------------------------
is_golden_creation      = 0;
is_gen_hdl_in           = 0;
is_launch_isim          = 0;
is_hdl_check            = 0;
os                      = 'linux';
endianess               = 'little';
SIMPLETEST              = 0;

%------------------------------------------
%% Main
%------------------------------------------
% crcType     = "CRC24A";
blockLen    = 8;      % 4 bit or 8bit
dataWidth   = 128;    % 128bit or 512 bit
% dataLen     = randi(5000);
A     = 4096;

% if (A > 3824)
%     crcType     = "CRC24A";
% else
%     crcType     = "CRC16";
% end
crcType     = "CRC24B";
dataLen     = A;

%Polynomials and CRC lengths
CRC24A = [1,1,0,0,0,0,1,1,0,0,1,0,0,1,1,0,0,1,1,1,1,1,0,1,1];   % 24 CRC bits for LDPC transport block size > 3824
CRC24B = [1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1];   % 24 CRC bits for LDPC code block segments
CRC16  = [1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1];                   % 16 CRC bits for LDPC transport block size <= 3824
CRC24C = [1,1,0,1,1,0,0,1,0,1,0,1,1,0,0,0,1,0,0,0,1,0,1,1,1];   % 24 CRC bits for polar downlink (BCH and DCI)
CRC6   = [1,1,0,0,0,0,1];                                       % 6 CRC bits for polar uplink, 18<=K<=25
CRC11  = [1,1,1,0,0,0,1,0,0,0,0,1];                             % 11 CRC bits for polar uplink, K>30

if crcType == "CRC24A"
    G = CRC24A;
    CRCLen  = 24;
elseif crcType == "CRC24B"
    G = CRC24B;
    CRCLen  = 24;
elseif crcType == "CRC24C"
    G = CRC24C;
    CRCLen  = 24;
elseif crcType == "CRC11"
    G = CRC11;
    CRCLen = 11;
else
    G = CRC16;
    CRCLen  = 16;
end 

% Keep random vector the same in every run (with fixed seed)
s       = rng();
seed    = 1;
rng(seed);
blk     = randi([0 1], dataLen, 1);

% Simple test for Catapult
if SIMPLETEST == 1
    simInput = [1804289383, 846930886, 1681692777, 1714636915];
%     simInputHex = [ "0x40554DC4EDD210B27E4BE5D4D6DCDE0F", "0x3AB8199730DB8A5CF3F3D1617D956CD7", "0xDFA0B1E7F82F0B0949D67F7B2B3F84E6", "0x2537D41EB0142AAF1F84AA6D74B1E0AA"];
%     simInput = hex2dec(simInputHex);
    simInputBin = dec2bin(simInput, dataWidth);
    simInputBitstream = reshape(simInputBin', [], 1);
    blk = str2num(simInputBitstream);
    dataLen = size(simInput,2) * dataWidth;
end

% Zeros padding to make sure the data length is a multiple of dataWidth
% Padding at the beginning of the input stream based on the LUT-based CRC Algorithm
npad   = ceil(dataLen/dataWidth)*dataWidth - dataLen;
pblk   = [zeros(npad, 1); blk];
% hdl_str = join(string(hdl_in), '');

fprintf('Compute %s - Input length %d \n', crcType, dataLen);

%% MATLAB model CRC LUT-Based
crcValue        = compute_crc(pblk, size(pblk,1), crcType, dataWidth, blockLen);
crcValueFPGA    = compute_crc_fpga(pblk, size(pblk,1), crcType, dataWidth, blockLen);
%% End MATLaB model


% Golden result
crcgenerator = comm.CRCGenerator('Polynomial',G,'InitialConditions',0);
encode  = crcgenerator(blk);
crcValueGold = encode(end-CRCLen+1:end,1)';

if crcType ~= "NO"
    fprintf('\tGolden(HEX):\tCRC value - 0x%s \n' ,dec2hex(bin2dec(join(string(crcValueGold), ''))));
    fprintf('\tGolden(DEC):\tCRC value - %d \n' ,bin2dec(join(string(crcValueGold), '')));
    fprintf('\tFPGA(HEX): \tCRC value - 0x%s \n' ,dec2hex(bin2dec(join(string(crcValueFPGA), ''))));
else
    fprintf('\tCRC value: ____ \n');   
end
if (~isequal(crcValueGold, crcValue)) & (crcType ~= "NO")
   error("MATLAB model mismatch!!!\n");
else 
    fprintf ("MAT: Functional model PASSED\n");
end
if (~isequal(crcValueGold, crcValueFPGA)) & (crcType ~= "NO")
   error("MATLAB FPGA model mismatch!!!\n");
else 
    fprintf ("MAT: Functional FPGA model PASSED\n");
end

%% HDL generator
% 1. HDL input generation
if is_gen_hdl_in
    gen_hdl_in;
end  
    
% 2. Golden generation
if is_golden_creation == 1
    gen_golden;
end

% 3. Launching ISIM
if is_launch_isim == 1
    launch_sim;
end


% 4. HDL check
if is_hdl_check==1
    fprintf('MAT: Launching verification\n');
        % sim output
         %% CHECK LDPC FE
        fid = fopen( hdl_dout );
        hdl_res = textscan(fid, '%s');
        hdl_res = hdl_res{1};
        fclose(fid);

        fid = fopen( fPath_crc_result );
        golden = textscan(fid, '%s');
        golden = golden{1};
        fclose(fid);


        if isequal(golden, hdl_res)
            fprintf('[HDL] CRC Passed\n');
            testResult  = 'PASSED';
        else
            for aa=1:size(hdl_res,1)
                if sum(golden{aa} ~= hdl_res{aa}) ~= 0
                    fprintf(2, '[HDL] error in line %d\n', aa);
%                   break
                end
            end
            error(2,'[HDL] LDPC FE Failed\n');
            testResult  = 'FAILED';
        end
end



