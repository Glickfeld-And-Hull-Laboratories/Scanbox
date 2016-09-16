function sb_current_power_active(x)

global sb;

% set optotune active (1) or inactive (0)

fwrite(sb,uint8([23 x 0]));
