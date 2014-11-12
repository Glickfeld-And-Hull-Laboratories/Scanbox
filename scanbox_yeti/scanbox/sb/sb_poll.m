function sb_poll

global sb T;

T = uint8([]);              % reset timestamps
fwrite(sb,uint8([9 0 0]));   % poll TTL and generate USB message...

