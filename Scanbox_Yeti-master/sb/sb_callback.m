function sb_callback(obj,event)

global T sb;

% while(sb.BytesAvailable>0)
%     q = fread(sb,5,'uint8')';
%     T(end+1,:) = q;
% end

n = floor(sb.BytesAvailable/5);

if(n>0)
    q = fread(sb,[5 n],'uint8');
    T = [T; q'];
end
