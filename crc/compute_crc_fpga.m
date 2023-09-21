% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : 
% Filename  : compute_crc_fpga
% Date      : 2023-09-16 00:13:58
% Last Modified : 2023-09-21 12:38:23
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%   Exact model applied in FPGA
%   Input `data` format:   (matlab idx starts from 1)
%       128 ... ... ... 1
%                     First bit
%
%   CRC value format (based on gen_table algorithm):
%      1 ... ... ... ... 24
%     First bit
%
%   Algorithm:
%      This version is computed based on the following algorithm:
%           CRC(P) where P = A + B
%           - 1st step: Compute P = A + B or P = A xor B
%           - 2nd step: Compute CRC(P)
% 
%   Important notes:
%       - First bit is highest order in the polynomial
%       - LUT which has higher index has higher polynimial order (based on 
%         the `gen_lut` algorithm)
%       - Hence, table LUT mapping
%           LUT1     LUT2  ...  LUT16   |    Table
%           121:128              1:8    |    Input to generate LUT's addresses
%
%            Swapping bit order in each byte is a MUST, since tables are 
%            generated with Matlab toolbox with the MSbit must be the first
%            bit (read `get_lut` description for more details)
%
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-21	NCT	Add description!
% 2023-09-17	NCT	Completed!
% 2023-09-16	NCT	File created!
% ----------------------------------------------------------------------------
function [crcValue] = compute_crc_fpga(data, data_len, crcType, dataWidth, blockLen)

    if strcmp(crcType,"CRC16")
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
    %   A line:         128 ..121 .. 9 8 .. 1     (FPGA data)
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
        %   CRC value: 1 2 .. 24    (1 is the first bit - read `get_lut` description for more details)
        %   Step 1: Need to convert to:    24 23 ... 1 (like the input data)        (**)
        %   Step 2: Segment into 3 8-bit blocks (CRC24) or 2 8-bit blocks (CRC16)   (***)
        %           CRC value:      [24:17] [16:9] [8:1]   or  [16:9] [8:1]
        %   Step 3: Then, reversing the bit order like (*)                          (****)
        %           CRC value:      [17:24] [9:16] [1:8]   or  [9:16] [1:8]
        %   Another solution no need to do Step 1 and Step 3 is to perform the same steps
        %   when generating LUTs
        pre_crc = fliplr(crc);                      % (**)
        pre_crc = reshape(pre_crc, 8, [])';         % (***)
        pre_crc = (bi2de(pre_crc, 'right-msb'))';   % (****)


        % In this version, we compute A+B or (A xor B), then CRC(A+B)
        %       1. XOR CRC value of previous-iteration and first bits of input data
        %       2. Compute CRC of 1st step result
        %  ------
        %  Current FPGA input data          :     [121:128] .... [17:24] [9:16] [1:8]
        %  CRC value of previous FPGA data  :                    [17:24] [9:16] [1:8]
        %  Bitwise xor of the two above (1set step)             ||
        %  Result:                                              \/
        %       data8bitBlock index         :           1   ....    14     15    16
        %                                            --------------------------------
        %       data8bitBlock  = addr   =            |     | ..   |     |     |     |
        %                                            --------------------------------
        %  ------
        %  
        addr1 = bitxor(pre_crc, data8bitBlock(line, end-numBlockPerCRC+1:end)) + 1; % Addresses of high-order LUTs
        addr2 = data8bitBlock(line, 1 : end-numBlockPerCRC) + 1;                    % Addresses of lower-order LUTs
        addr = [addr2, addr1];                                                      % Arrange:    [Low  ... High] = [LUT1 ... LUT16]
        

        % Compute CRC
        %       crc = XOR(LUT1, LUT2, ..., LUT16)
        crc = initialValue;
        for LUT_idx=1:numBlockPerLine
            temp = LUT(addr(1, LUT_idx) ,:, LUT_idx);
            crc = bitxor(crc, temp);
        end
    end
    crcValue = crc;
end