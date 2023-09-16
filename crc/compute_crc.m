% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : LUT-based CRC implementation
% Filename  : compute_crc
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-17 03:13:07
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%   Input `data` format:
%       127 ... ... ... 0
%    First bit   
%
%   Important notes:
%       - First bit is highest order in the polynomial
%       - LUT which has higher index has higher polynimial order (based on 
%         the `gen_lut` algorithm)
%       - Hence, table LUT mapping
%           LUT16     LUT15  ...  LUT1      |    Table
%           127:120                7:0      |    Input to generate LUT's addresses
%
% Arguments             
%   crctype:  24A, 24B, 24C, 16
%   blockLen: 8 bit, 4 bit - number of bit in one block used to 
%             compute CRC
%   dataWidth: 128b or 512b - number of bit to compute CRC in 1 cycle
%   
%
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File created
% ----------------------------------------------------------------------------
function [crcValue] = compute_crc(data, data_len, crcType, dataWidth, blockLen)

    if crcType == "CRC16"
        CRCLen  = 16;
    else
        CRCLen  = 24;
    end

    numBlockPerCRC  = CRCLen/blockLen;
    numBlockPerLine  = dataWidth/blockLen;

    LUT     = get_lut(crcType, blockLen, dataWidth, "FPGA");

    blkReshape  = [];

    numLines    = data_len/128;
    % Algorithm
    % Formulate into blockLen-bit block
    for i= 1: numLines
        idx             = dataWidth*(i-1)+1;
        dataPerCycle    = data(idx:idx+dataWidth-1,1);
        blockData       = reshape(dataPerCycle, blockLen, []); 
        blockData       = blockData';
        blkReshape      = [blkReshape; blockData];
    end

    initialValue        = zeros(1, CRCLen);
    currentLineXOR      = initialValue;

    for i=1:numLines
        % In this version, we compute CRC(A) + CRC(B)
        %       - 1.Compute CRC of previous-iteration CRC
        %       - 2.Compute first bits of input data
        %       - 3.XOR 2 values
        %
        % In the FPGA-exact version, we compute CRC(A+B)
        %       - 1. XOR CRC value of previous-iteration and first bits of input data
        %       - 2. Compute CRC of 1st step result
        %
        % They are equivalent
        
        previousCRC     = initialValue;
        % Compute Previous CRC result
        currentLineReshape  = reshape(currentLineXOR, blockLen, []);
        currentLineReshape  = currentLineReshape';     % Reshape CRC of previous line into blocks
        currentLineReshape  = num2str(currentLineReshape);

        for z=1:numBlockPerCRC
            addr            = bin2dec(currentLineReshape(z,:))+1;
            idxLUT          = numBlockPerLine-z+1;       % LUT 16, 15,14

            blockCRC         = LUT( addr,:,idxLUT);
            previousCRC      = bitxor(previousCRC, blockCRC);
        end

        % Compute CRC for current data
        currentBlockXOR     = initialValue;
        for j=1:numBlockPerLine
            idx         = numBlockPerLine*(i-1)+j;
            block       = blkReshape(idx,:);

            addr        = bin2dec(num2str(block))+1;
            idxLUT      = numBlockPerLine-j+1;

            blockCRC    = LUT( addr,:,idxLUT);
            currentBlockXOR    = bitxor(currentBlockXOR, blockCRC);
        end

        % XOR Result
        currentLineXOR  = bitxor(currentBlockXOR, previousCRC);
        
    end
    crcValue    = currentLineXOR;
end

