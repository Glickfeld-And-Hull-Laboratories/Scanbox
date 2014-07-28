% Hartley processing...

clear all;

% read hartley log

log = sbxreadhartleylog('gc6_001_000.log_07');
log = log{1}; % assuming only one trial

k = max(abs(log));
max_k = k(3);

% load alignment

load -mat gc6_001_000

% load alignment

load -mat gc6_001_000.align

% load signals

load -mat gc6_001_000.signals

sig = zscore(sig);

ncells = size(sig,2);

% arrays

coef = zeros([ncells 2 2*max_k+1 2*max_k+1]);          
nstim = zeros([2 2*max_k+1 2*max_k+1]);

% stimulus events...

idx  = find(info.event_id == 1);
fidx = info.frame(idx);           % frames at which the stimuli arrived

tau = -1;                                % delay between stimulus and response

Z = zeros(ncells,21);

for(i=1:length(fidx))
        
    coef(:, (log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) ...
        = coef(:, (log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) + sig(fidx(i)+tau,:)';
    nstim((log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) ...
        = nstim((log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) + 1;
    
    Z = Z +sig(fidx(i)-10:fidx(i)+10,:)';
end


% normalize 

for(s=1:2)
    for(i=1:(2*max_k+1))
        for(j=1:(2*max_k+1))
            if(nstim(s,i,j)>0)
                coef(:,s,i,j) = coef(:,s,i,j) / nstim(s,i,j);
            end
        end
    end
end


%% compute cell rfs...

[xx,yy] = meshgrid(0:479,0:269);
stim = zeros((2*max_k+1)^2*2,prod(size(xx)));
coef = reshape(coef,[ ncells (2*max_k+1)^2*2]);

% compute stimuli


k=1;
for(j=1:(2*max_k+1))
    for(i=1:(2*max_k+1))
        for(s=-1:2:1)
            h = s *  cas( ((i-(max_k+1)) * xx + (j-(max_k+1)) * yy )/size(yy,1) * 2 * pi);
            stim(k,:) = h(:)';
            k = k+1;
        end
    end
end

% calculate rfs...

rf = coef*stim;
rf = reshape(rf,[ncells size(xx)]);

clf
for(i=1:size(rf,1))
    subplot(7,7,i);
    imagesc(squeeze(rf(i,:,:)));
    axis xy off
end
