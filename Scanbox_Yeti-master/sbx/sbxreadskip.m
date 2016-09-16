function z = sbxreadskip(fname,N,skip,varargin)

% read a set of N images skip frames apart

global info;

z = sbxread(fname,1,1);
z = zeros([size(z,2) size(z,3) N]);

idx = (1:N)*skip;

h = waitbar(0,'Reading frames...');
for(j=1:length(idx))
    waitbar(j/length(idx),h);
    q = sbxread(fname,idx(j),1);
    z(:,:,j) = circshift(squeeze(q(1,:,:)),info.aligned.T(idx(j),:));
   % z(:,:,j) = filter2(fspecial('gauss',5,1),z(:,:,j),'same'); % filter too!
end
delete(h);
