function sb_current_power_active(x)

global sb;

% set the link between current and power active (1) or inactive (0)

fwrite(sb,uint8([20 x 0]));
