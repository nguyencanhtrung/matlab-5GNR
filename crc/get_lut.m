% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : LUT-based CRC implementation
% Filename  : get_lut
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-15 15:13:47
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%   Generate all LUTs with predifined configuration
%   crctype     : "CRC24A", "CRC24B", "CRC24C", "CRC16"
%   blockLen    : 8 bit, 4 bit - number of bit in one block used to 
%                 compute CRC
%   dataWidth   : 128b or 512b - number of bit to compute CRC in 1 cycle
%   modelType   : "FPGA" or not
%   
%   Higher Index of LUT(:,:,i) (i is index) = higher order of polynomial
%
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File created
% ----------------------------------------------------------------------------
function [LUT] = get_lut(crcType,blockLen,dataWidth,modelType)

CRC24A = [1,1,0,0,0,0,1,1,0,0,1,0,0,1,1,0,0,1,1,1,1,1,0,1,1];
CRC24B = [1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1];
CRC24C = [1,1,0,1,1,0,0,1,0,1,0,1,1,0,0,0,1,0,0,0,1,0,1,1,1];
CRC16  = [1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1];

maxValue = 2^blockLen - 1;
numBlock = dataWidth/blockLen;

if crcType == "CRC24A"
    G = CRC24A;
elseif crcType == "CRC24B"
    G = CRC24B;
elseif crcType == "CRC24C"
    G = CRC24C;
else
    G = CRC16;
end 

crcLen  = length(G) - 1;

% Matlab model
crcgenerator = comm.CRCGenerator('Polynomial',G,'InitialConditions',0);

% Bit vector to compute CRC in range [0, 255]
codeword = 0:1:maxValue;
codeword = codeword';
codeword = dec2bin(codeword, blockLen);

% LUT storing CRC value
% LUT = crc( codeword )
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

