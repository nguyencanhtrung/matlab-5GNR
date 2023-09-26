% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : LUT-based CRC implementation
% Filename  : gen_table
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-26 17:57:35
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File Created
% ----------------------------------------------------------------------------

blockLen = 8; % 8bit or 4bit
dataWidth = 128;     % 128b or 512b


f_crc24A    = 'crc24A_LUT.dat';
f_crc24B    = 'crc24B_LUT.dat';
f_crc24C    = 'crc24C_LUT.dat';
f_crc16     = 'crc16_LUT.dat';


f_crc24A_hex    = 'crc24A_LUT_hex.dat';
f_crc24B_hex    = 'crc24B_LUT_hex.dat';
f_crc24C_hex    = 'crc24C_LUT_hex.dat';
f_crc16_hex     = 'crc16_LUT_hex.dat';

% Generate LUT
LUT_CRC24A  = get_lut("CRC24A", blockLen, dataWidth, "C");
LUT_CRC24B  = get_lut("CRC24B", blockLen, dataWidth, "C");
LUT_CRC24C  = get_lut("CRC24C", blockLen, dataWidth, "C");
LUT_CRC16   = get_lut("CRC16", blockLen, dataWidth, "C");

% Writing LUTs to file
write2file(f_crc24A, LUT_CRC24A);
write2file(f_crc24B, LUT_CRC24B);
write2file(f_crc24C, LUT_CRC24C);
write2file(f_crc16,  LUT_CRC16);

% write2filehex(f_crc24A_hex, LUT_CRC24A);
% write2filehex(f_crc24B_hex, LUT_CRC24B);
% write2filehex(f_crc24C_hex, LUT_CRC24C);
% write2filehex(f_crc16_hex,  LUT_CRC16);