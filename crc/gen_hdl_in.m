% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : 
% Filename  : gen_hdl_in
% Date      : 2023-09-16 00:36:46
% Last Modified : 2023-09-18 15:35:24
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% ----------------------------------------------------------------------------
%------------------------------------------
%% IOs
%------------------------------------------
sim_din         = './io/inputs.txt';
sim_cfg         = './io/params.txt';


% Create HDL input
npad        = ceil(dataLen/dataWidth)*dataWidth - dataLen;
pblk_fpga   = [blk; zeros(npad, 1)];

hdl_in  = reshape(pblk_fpga, dataWidth, []);
hdl_in  = hdl_in';

% Generate for XILINX flatform or not
% XLNX:    MSB ... LSB     (first bit is LSB)
% INTEL:   MSB ... LSB     (first bit is MSB)
if strcmp(endianess, 'little') == 1
    hdl_in  = fliplr(hdl_in);
end

% Writing HDL input
fid_din = fopen (sim_din, 'w+');

% Write to hdl_din.txt
for i = 1:size(hdl_in, 1)
    str = sscanf( join( string(hdl_in(i,:)), ''), '%s');
    str_hex = bin2hex(str);
    fprintf(fid_din, str_hex);
    if i ~= size(hdl_in, 1)
        fprintf(fid_din, '\n');
    end
end  

fclose (fid_din);

% Writing HDL config
fid_cfg = fopen (sim_cfg, 'w+');

fprintf(fid_cfg, '%d\n', dataLen);

fclose (fid_cfg);
