function serialcb(obj,event)

global T;

T(end+1,:) = fread(obj,5,'uint8')';
