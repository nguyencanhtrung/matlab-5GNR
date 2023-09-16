% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : 
% Filename  : launch_sim
% Date      : 2023-09-16 00:31:44
% Last Modified : 2023-09-16 00:32:26
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% ----------------------------------------------------------------------------

%% run sim
fprintf('ISIM: Launching HDL simulation ...\n');

log_file = 'sim_log.txt';

if strcmp(os, 'win') == 1
    fprintf('ISIM: Running test on Windowns\n');
    status = system(['%SystemRoot%\system32\cmd.exe /c vivado -mode batch -nolog -nojournal -source ', tcl_file, ' > ', log_file]);
else
    fprintf('ISIM: Running test on Linux\n');
    status = system(['vivado -mode batch -nolog -nojournal -source ', tcl_file, ' > ', log_file]);
end

if status
    error('ISIM: Running vivado simulation failed\n');
else
    fprintf('ISIM: Simulation DONE\n');
end