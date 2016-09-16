function sb_deadband(r,l)

% controls the size of left and right deadbands for pockels.

global sb;

fwrite(sb,uint8([9 l r]));