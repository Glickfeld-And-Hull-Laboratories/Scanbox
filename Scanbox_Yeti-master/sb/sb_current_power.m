function sb_current_power(c,p)

global sb;

% link current c, to power p.

fwrite(sb,uint8([19 c p]));
