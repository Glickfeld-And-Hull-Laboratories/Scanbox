function sb_callback(obj,event)

global T sb stim_on;
global stim_on;

while(sb.BytesAvailable>0)
    q = fread(sb,5,'uint8')';
    T(end+1,:) = q;
end
