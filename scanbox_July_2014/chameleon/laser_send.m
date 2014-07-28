function r=laser_send(msg)

global laser

fprintf(laser,msg);
r = fgetl(laser); % wait for reply
