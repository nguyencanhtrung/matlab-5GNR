% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : Matlab libs
% Filename  : write2file
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-15 10:06:40
% Modified By   : Nguyen Canh Trung
% 
% Description: 
% 
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File created
% ----------------------------------------------------------------------------
function [] = write2file(fileName, data2write)
fid         = fopen(fileName, 'w+');
data2File   = data2write;
for j = 1:size(data2File, 3)
    fprintf(fid, '{');
    for i = 1:size(data2File, 1)
        str = sscanf( join( string(data2File(i,:,j)), ''), '%s');
        fprintf(fid, str);

        if i == 256
            fprintf(fid, '}');
        end

        fprintf(fid, ',');
        fprintf(fid, '\n');

    end
end
fclose(fid);
end

