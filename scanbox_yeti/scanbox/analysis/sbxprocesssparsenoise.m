
function rf = sbxprocesssparsenoise(fn)

z = sbxread(fn,0,1);

load(fn);

global info;

f = info.frame+info.line/512;
f = f(2:end);
t = 0:60:60*(length(f)-1);
t = t';
p = polyfit(f,t,1);

load([fn '.signals'],'-mat')
%spk = sbxextractspikes(sig);

log = load([fn '.log_02']);

L = -20:30;

for(k=8)   
    
    for(q=1:length(L))
        
        q
       % [k L(q) size(spk,2)]
        
        if(~any(isnan(sig(:,k))))
            
            % spikes...
            
                        w = sig(:,k);
                        w = w-median(w(:));
                        w = w/max(w(:));
                        idx = find(diff(w)>prctile(diff(w),92));
            
            % fancy spike
            %  idx = find(spk(:,k)>0.025);
            
            tstim = polyval(p,idx)-L(q);   % stimulus frame we are intersted in
            
            % what stim present at that time?
            
            S = [];  
            for(i=1:length(tstim))
                j = find( (log(:,1)>tstim(i)-log(:,5)) & (log(:,1)-log(:,5)<tstim(i))); % it died AFTER spike-lag and it was born before
                S = [S ; log(j,2:4)];
            end
            
            % fix position indices...
            
            S(:,1) = S(:,1)+1000;
            S(:,2) = S(:,2)+600;
            
            B = zeros(1200,2000);
            D = zeros(size(B));
            
            for(j=1:size(S,1))
                if(S(j,3)>128)
                    B(S(j,2),S(j,1)) = B(S(j,2),S(j,1)) + 1;
                else
                    D(S(j,2),S(j,1)) = D(S(j,2),S(j,1)) + 1;
                end
            end
            rf(k).valid  = 1;
            rf(k).B{q} = B;
            rf(k).D{q} = D;
            rf(k).lag    = L;
        else
            rf(k).valid = 0;
        end 
    end
end
% 
% for(i=14)
%     i
%     if(rf(i).valid)
%         
%         for(j=1:length(1:length(rf(i).B)))
%             s(j) = std(rf(i).B{j}(:));
%         end
%         rf(i).Bstd = s;
%         [~,k] = max(s);
%         rf(i).bmax = k;
%         
%         for(j=1:length(1:length(rf(i).D)))
%             s(j) = std(rf(i).D{j}(:));
%         end
%         rf(i).Dstd = s;
%         [~,k] = max(s);
%         rf(i).dmax = k;
%         
%     end
% end

