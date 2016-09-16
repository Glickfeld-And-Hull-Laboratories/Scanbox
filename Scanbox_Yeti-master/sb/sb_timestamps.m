function r = sb_timestamps

global T;
% 
% if(~isempty(T))
%     ts = zeros(size(T,1),1);
%     for(i=0:3)
%         ts = ts+ T(:,i+1)*(256^i);
%     end
%     r.timestamps = double(intmax('uint32'))-ts;
%     r.event_id = T(:,5);
%     r.frame_index = T(:,6)+T(:,7)*256;
%     r.timestamps_pc = T(:,end);
% else
%     r = [];
% end


if(~isempty(T))
    r.frame = T(:,1)+T(:,2)*256;
    r.line  = T(:,3)+T(:,4)*256;
    r.event_id = T(:,5);
else
    r = [];
end

