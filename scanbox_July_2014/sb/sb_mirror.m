function sb_mirror(val)

global sb T;

T = uint8([]);              % reset timestamps
if(val)
    fwrite(sb,uint8([5 0 0]));   
else
    fwrite(sb,uint8([5 0 1]));
end


