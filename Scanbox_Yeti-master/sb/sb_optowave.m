function sb_optowave(b2,b1)

global sb;

% set current index entry to a given current (current in 0-4095)

fwrite(sb,uint8([21 b2 b1]));
