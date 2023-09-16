% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : 
% Filename  : gen_hdl_in
% Date      : 2023-09-16 00:36:46
% Last Modified : 2023-09-16 00:37:15
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% ----------------------------------------------------------------------------

hdl_dwidth      = dataWidth;
hdl_dlen        = dataLen;

if crcType == "CRC24A"
    hdl_crctype  = 0;
elseif crcType == "CRC24B"
    hdl_crctype  = 1;
elseif crcType == "NO"
    hdl_crctype  = 3;
else
    hdl_crctype  = 2;
end  


%     fid_cfg = fopen (hdl_cfg, 'w+');
%     fprintf(fid_cfg, '%d %d %d %d', ...
%                             hdl_dwidth, ...
%                             hdl_crctype, ...
%                             hdl_dlen);
%     fclose (fid_cfg);     


% Writing HDL input
fid_din = fopen (hdl_din, 'w+');

fprintf(fid_din, 'Time,Data\n');

% Write to hdl_din.txt
for i = 1:size(hdl_in, 1)
    str = sscanf( join( string(hdl_in(i,:)), ''), '%s');
    str_hex = bin2hex(str);
    fprintf(fid_din, string(i));
    fprintf(fid_din, ',');
    fprintf(fid_din, str_hex);
    if i ~= size(hdl_in, 1)
        fprintf(fid_din, '\n');
    end
end  

fclose (fid_din);