% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : 
% Filename  : gen_golden
% Date      : 2023-09-16 00:33:05
% Last Modified : 2023-09-16 00:33:21
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% ----------------------------------------------------------------------------
  % Padding zeros
g_crc_paddingzeros  = reshape(padded_blk4matlab, 128, []);
g_crc_paddingzeros  = g_crc_paddingzeros';
g_crc_paddingzeros  = fliplr(g_crc_paddingzeros);


%---------------------------------------------------------------------
% Generating golden results
%---------------------------------------------------------------------
fprintf('MAT: Exporting golden results ...\n');          
fid = fopen(fPath_crc_padding_zeros, 'w+');

% Write to hdl_din.txt
for i = 1:size(g_crc_paddingzeros, 1)
    str = sscanf( join( string(g_crc_paddingzeros(i,:)), ''), '%s');
    fprintf(fid, str);
    fprintf(fid, '\n');
end 


% CRC Stream OUT
if crcType == "NO"
    encode = blk;
end

length        = size(encode,1);
padding       = ceil(length/dataWidth)*dataWidth - length;
g_crc_out     = [encode; zeros(padding, 1)];

g_crc_result  = reshape(g_crc_out, 128, []);
g_crc_result  = g_crc_result';
g_crc_result  = fliplr(g_crc_result);


fid = fopen(fPath_crc_result, 'w+');

% Write to hdl_din.txt
for i = 1:size(g_crc_result, 1)
    str = sscanf( join( string(g_crc_result(i,:)), ''), '%s');
    fprintf(fid, str);
    fprintf(fid, '\n');
end 