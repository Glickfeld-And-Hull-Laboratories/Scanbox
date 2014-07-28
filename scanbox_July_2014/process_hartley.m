%% Hartley processing...

clear all;

% read hartley log

log = sbxreadhartleylog('gc6_001_000.log_07');
log = log{1}; % assuming only one trial

k = max(abs(log));
max_k = k(3);

% load alignment

load -mat gc6_001_000.align

% load basic image info

z = sbxread('gc6_001_000',1,1);
global info;

z = squeeze(z(1,:,:))*info.S;

% arrays

coef = zeros([size(z) 2 2*max_k+1 2*max_k+1]);          
nstim = zeros([2 2*max_k+1 2*max_k+1]);

% stimulus events...

idx  = find(info.event_id == 1);
fidx = info.frame(idx);           % frames at which the stimuli arrived

tau = 1;                           % delay between stimulus and response

h = waitbar(0,'Progress...');

for(i=1:length(fidx))
    waitbar(i/length(fidx),h);
    z = sbxread('gc6_001_000',fidx(i)+tau,1);   % read the frame
    z = squeeze(z(1,:,:)) * info.S;             % spatial correction
    z = circshift(z,info.aligned.T(fidx(i)+tau+1)); % alignment
    
    z = z -m;                                   % remove mean
    
    coef(:,:, (log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) ...
        = coef(:,:, (log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) + z;
    
    nstim((log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) ...
        = nstim((log(i,2)+3)/2 , log(i,3)+max_k+1 , log(i,4)+max_k+1 ) + 1;
end

close(h);
drawnow;


% normalize 

for(s=1:2)
    for(i=1:(2*max_k+1))
        for(j=1:(2*max_k+1))
            if(nstim(s,i,j)>0)
                coef(:,:,s,i,j) = coef(:,:,s,i,j) / nstim(s,i,j);
            end
        end
    end
end

%% reshape coef

coef = reshape(coef,[prod(size(z)) (2*max_k+1)^2*2]);


% compute stimuli

[xx,yy] = meshgrid(0:479,0:269);
stim = zeros((2*max_k+1)^2*2,prod(size(xx)));

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
% 
% % calculate rfs...
% 
% rf = coef*stim;
% rf = reshape(rf,size(xx));
% 
% imagesc(rf);
% axis xy
% truesize



