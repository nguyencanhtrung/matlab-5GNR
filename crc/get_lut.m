% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : LUT-based CRC implementation
% Filename  : get_lut
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-21 12:08:09
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%   Generate all LUTs using CRC algorithm of MATLAB toolbox
% 
%  Input arguments:
%       crctype     : "CRC24A", "CRC24B", "CRC24C", "CRC16", "CRC11", "CRC6"
%       blockLen    : 8 bit, 4 bit - number of bit in one block used to 
%                     compute CRC
%       dataWidth   : 128b or 512b - number of bit to compute CRC in 1 cycle
%       modelType   : "FPGA" or not
%
%  Algorithm:
%       `crcgenerator` is MATLAB toolbox CRC generator
%
%       Each LUT is a matrix 256x24bits (CRC24A,B,C) or 256x16bits (CRC16)
%       Each LUT stores 256 checksums (results) of CRC computation of 256 inputs
% 
%       Inputs of LUT1:  [0 .. 255]
%       Inputs of LUT2:  [0 .. 255] << 8
%       Inputs of LUT3:  [0 .. 255] << 16
%       ...  
%       Inputs of LUT16: [0 .. 255] << 120
%
%       Higher Index of LUT(:,:,i) (i is index) = higher order of polynomial
%
%       ---------
%       Explanation:
%       ---------
%       Input stream (a 128-bit vector):   
%           A = a0.a1.a2...a127     (where a0 is the first bit)
%
%       It is considered as a Polynomial:    
%           P = a0*x^127 + a1*x^126 + ... + a127    
%   
%       Compute CRC:    
%           CRC(A) = CRC(P)           
%
%           CRC(P) = CRC(a0*x^127 + a1*x^126 + ... + a127 ) 
%           CRC(P) =  CRC(a0*x^127 + .. + a7*x^120) + 
%                     ... +
%                     CRC(a120*x^7 + ... + a127)
%
%       Where:
%           CRC(a120*x^7+..+ a127)      = CRC( a120..a127 )   
%                                       = LUT1 (a120..a127)
%           ...
%           ...
%           CRC(a0*x^127+..+ a7*x^120)  = CRC( a0..a7 << 120 )
%                                       = LUT16 (a0..a7)
%
%
%       Therefore:
%           CRC(P) =  LUT16(a0...a7) + LUT15(a8..a15) + ... + LUT1(a120...a127)
%       ---------
%
%       Codeword (input):       | << 15*8 | << 15*8 | ... ... | << 0    |
%                                   |          |                   |
%       CRC generator               v          v                   v
%                               -----------------------------------------
%       LUT index:              |   16    |    15   | ... ... |    1    |
%                               -----------------------------------------
%
%
%       Notes:
%          - Bit order of input of LUT:     First bit is the MSbit
%               + LUT16 : a0..a7       (a0 is first bit)
%               + LUT15 : a8..a15      (a8 is first bit)
%               + ...   : ...
%               + LUT1  : a120..a127   (a120 is first bit)
%
%          - Bit order of output (checksum/result) of CRC computation: 
%               + First bit is the MSbit
%               res = crcgenerator( a0..a7 ) = c0..c24     (c0 is first bit)
%
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-21	NCT	Update description
% 2023-09-16	NCT	Update CRC11 and CRC6
% 2023-09-15	NCT	File created
% ----------------------------------------------------------------------------
function [LUT] = get_lut(crcType,blockLen,dataWidth,modelType)

CRC24A = [1,1,0,0,0,0,1,1,0,0,1,0,0,1,1,0,0,1,1,1,1,1,0,1,1];   % 24 CRC bits for LDPC transport block size > 3824
CRC24B = [1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1];   % 24 CRC bits for LDPC code block segments
CRC24C = [1,1,0,1,1,0,0,1,0,1,0,1,1,0,0,0,1,0,0,0,1,0,1,1,1];   % 24 CRC bits for polar downlink (BCH and DCI)
CRC16  = [1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1];                   % 16 CRC bits for LDPC transport block size <= 3824
CRC6   = [1,1,0,0,0,0,1];                                       % 6 CRC bits for polar uplink, 18<=K<=25
CRC11  = [1,1,1,0,0,0,1,0,0,0,0,1];                             % 11 CRC bits for polar uplink, K>30

if crcType == "CRC24A"
    G = CRC24A;
elseif crcType == "CRC24B"
    G = CRC24B;
elseif crcType == "CRC24C"
    G = CRC24C;
elseif crcType == "CRC11"
    G = CRC11;
elseif crcType == "CRC6"
    G = CRC6;
else
    G = CRC16;
end 

crcLen  = length(G) - 1;
maxValue = 2^blockLen - 1;
numBlock = dataWidth/blockLen;

% Matlab model
crcgenerator = comm.CRCGenerator('Polynomial',G,'InitialConditions',0);

% Bit vector to compute CRC in range [0, 255]
codeword = 0:1:maxValue;
codeword = codeword';
codeword = dec2bin(codeword, blockLen);

% LUT storing CRC value | LUT = crc( codeword )
LUT =[];

for i=1:numBlock
    for j=1:maxValue+1
        block = codeword(j,:)-'0';
        block = block';
        
        % Append ZEROS to the end of bitstream (lower polynomial order)
        block = [block; zeros((i-1)*blockLen, 1)];
        
        % Compute CRC
        encoded = crcgenerator(block);

        % Extract CRC value
        crcVal  = encoded(end-crcLen+1:end,1);

        % For FPGA modeling   "FPGA"
        if modelType == "FPGA"
            LUT(j,:,i) = crcVal';
        
        else
        % For C modeling   "C"
            crcValInStr = join(string(crcVal'), '');
            crcValInDec = bin2dec(crcValInStr); 
            LUT(j,:,i) = crcValInDec; 
        end 
    end 
end 
end

