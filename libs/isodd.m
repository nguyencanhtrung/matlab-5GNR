% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : Matlab libs
% Filename  : isodd
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-15 10:05:45
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%   isodd(number)
%
%   returns 1 if the number is Odd, 0 if it is even.
%
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File created
% ----------------------------------------------------------------------------
function x = isodd (number)
    
a = number/2;
whole = floor(a);
part = a-whole;

if part > 0;
    
    x = 1;
    
else
    
    x = 0;
    
end