% ----------------------------------------------------------------------------
% Copyright © 2023 Nguyen Canh Trung
% (nguyencanhtrung 'at' me 'dot' com)
% 
% Project   : Matlab libs
% Filename  : bin2hex
% Date      : 2023-09-15 09:19:30
% Last Modified : 2023-09-15 10:03:59
% Modified By   : Nguyen Canh Trung
% 
% Description: 
%    BIN2HEX (BinStr,...output)
%   
%    Converts binary strings of any length to hexadecimal pairs. Adds leading
%    zeros if there is not an even number of hex bits.
%   
%    Now also supports cell array inputs.
% HISTORY:
% Date      	By	Comments
% ----------	---	---------------------------------------------------------
% 2023-09-15	NCT	File created
% ----------------------------------------------------------------------------
function x = bin2hex(BinStr)

if iscell(BinStr)
    
    NCells = length(BinStr);
    
    for C = 1:NCells
        
        Str = BinStr{C};
        
        x{C} = doconvert(Str);
        
    end
    
elseif ~ischar(BinStr)
    
    error('Input must be a string or character or cell array.')
    
else
    
    x = doconvert(BinStr);
    
end
        
        
%-----------------------------------------------    
function out = doconvert(BinStr)
    

Bits = length(BinStr);
Words = Bits/4;
WholeWords = floor(Words);
PartWords = Words-WholeWords;

while PartWords > 0

    BinStr = ['0' BinStr];   
    Bits = length(BinStr);
    Words = Bits/4;
    WholeWords = floor(Words);
    PartWords = Words-WholeWords;
    
end

% For each WORD (4-bits), convert it to HEX based on the following rules:

Words = length(BinStr)/4;

HEXi = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

HexStr = [];

for W = 1:Words
    
    %For each word, convert it first to decimal:
    
    P = (W*4)-3;
    
    Word = BinStr(P:P+3);
    DEC = bin2dec(Word);
    HEX = HEXi{DEC+1};
    
    HexStr = [HexStr HEX];
   
end

LHex = length(HexStr); %If the Hex String has an odd number of bits, add 0 to the front.

if isodd(LHex)
    
    HexStr = ['0' HexStr];
    
end

out = HexStr;
