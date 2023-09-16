% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : 
% Filename  : compute_crc_fpga
% Date      : 2023-09-16 00:13:58
% Last Modified : 2023-09-17 03:07:38
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%   Exact model applied in FPGA
%   Input `data` format:
%       127 ... ... ... 0
%                     First bit
%
%   Important notes:
%       - First bit is highest order in the polynomial
%       - LUT which has higher index has higher polynimial order (based on 
%         the `gen_lut` algorithm)
%       - Hence, table LUT mapping
%           LUT1     LUT2  ...  LUT16   |    Table
%           120:127              0:7    |    Input to generate LUT's addresses
%
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-17	NCT	Completed!
% 2023-09-16	NCT	File created!
% ----------------------------------------------------------------------------
function [crcValue] = compute_crc_fpga(data, data_len, crcType, dataWidth, blockLen)

    if crcType == "CRC16"
        CRCLen  = 16;
    else
        CRCLen  = 24;
    end

    numBlockPerCRC = CRCLen/blockLen;
    numBlockPerLine = dataWidth/blockLen;
    numLines = data_len/128;

    % LUT generation
    % Higher index LUT is for higher polynomial order
    LUT = get_lut(crcType, blockLen, dataWidth, "FPGA");

    % Convert matlab input to fpga input
    %   To little endian
    %   Matlab data: matrix(data_len, 1)
    %   FPGA data  : matrix(numLines, dataWidth)
    %   ------------
    %   Matlab data:    1                   (1 is the first  bit)
    %                   2  
    %                   .
    %                   .
    %                   .  
    %                   128 
    %                   .
    %                   .
    %
    %   FPGA data  :    128 127 ... 1        (1 is the first bit)
    %                   256 ...     129
    %                   ...
    %                   
    din_fpga  = reshape(data, dataWidth, []);
    din_fpga  = din_fpga';
    din_fpga  = fliplr(din_fpga);

    % Segment input data into 8-bit blocks
    %   Important note:
    %   A line:         128 ..121 .. 9 8 .. 1
    %   Blocks:         [128:121] .... [8:1]
    %   Convert to addr [121:128] .... [1:8]      (*)
    %   LUT mapping     LUT1   ....... LUT16
    data8bitBlock = zeros(numLines, numBlockPerLine);
    
    for line= 1: numLines
        dataOnLine = din_fpga(line, :);
        data8bitOnLine = (reshape(dataOnLine, 8, []))';
        data8bitOnLine = (bi2de(data8bitOnLine, 'right-msb'))';   % Reverse the bit order in (*)
        data8bitBlock(line, :) = data8bitOnLine;
    end

    initialValue  = zeros(1, CRCLen);
    crc = initialValue;
    
    for line=1:numLines
        % XOR previous CRC and the first bytes to get the address of high-order LUT
        %   Important notes:
        %   CRC value: 1 2 .. 24    (1 is the first bit)
        %   Step 1: Need to convert to:    24 23 ... 1 (like the input data)        (**)
        %   Step 2: Segment into 3 8-bit blocks (CRC24) or 2 8-bit blocks (CRC16)   (***)
        %   Step 3: Then, reversing the bit order like (*)                          (****)
        %   Another solution no need to do Step 1 and Step 3 is to perform the same steps
        %   when generating LUTs
        pre_crc = fliplr(crc);  % (**)
        pre_crc = reshape(pre_crc, 8, [])'; % (***)
        pre_crc = (bi2de(pre_crc, 'right-msb'))'; % (****)

        addr1 = bitxor(pre_crc, data8bitBlock(line, end-numBlockPerCRC+1:end)) + 1; % Addresses of high-order LUTs
        addr2 = data8bitBlock(line, 1 : end-numBlockPerCRC) + 1;                    % Addresses of lower-order LUTs
        addr = [addr2, addr1];                                                      % Arrange:    [Low  ... High] = [LUT1 ... LUT16]
        
        crc = initialValue;
        for LUT_idx=1:numBlockPerLine
            temp = LUT(addr(1, LUT_idx) ,:, LUT_idx);
            crc = bitxor(crc, temp);
        end
    end
    crcValue = crc;
end