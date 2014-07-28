function r = sbxalign(fname,idx)

if(length(idx)==1)
    
    A = sbxread(fname,idx(1),1);        % read the frame
    S = sparseint;                      % sparse interpolant for...
    A = squeeze(A(1,:,:))*S;            % ... spatial correction
    
    r.m{1} = A;                         % mean
    r.m{2} = zeros(size(A));            % 2nd moment
    r.m{3} = zeros(size(A));            % 3rd moment
    r.m{4} = zeros(size(A));            % 4th moment
 
    r.T = [0 0];                        % no translation (identity)
    r.n = 1;                            % # of frames
    
else
    
    idx0 = idx(1:floor(end/2));         % split into two groups
    idx1 = idx(floor(end/2)+1 : end);   
        
    r0 = sbxalign(fname,idx0);          % align each group
    r1 = sbxalign(fname,idx1);
   
    [u v] = fftalign(r0.m{1},r1.m{1});  % align their means
    
    for(i=1:4)                          % shift mean image and moments
        r0.m{i} = circshift(r0.m{i},[u v]);
    end
     
    delta = r1.m{1}-r0.m{1};            % online update of the moments
    na = r0.n;
    nb = r1.n;
    nx = na + nb;

    r.m{1} = r0.m{1}+delta*nb/nx;       
    r.m{2} = r0.m{2} + r1.m{2} + delta.^2 * na * nb / nx;
    r.m{3} = r0.m{3} + r1.m{3} + ...
        delta.^3 * na * nb * (na-nb)/nx^2 + ...
        3 * delta / nx .* (na * r1.m{2} - nb * r0.m{2});
    r.m{4} = r0.m{4} + r1.m{4} + delta.^4 * na * nb * (na^2 - na * nb + nb^2) / nx^3 + ...
        6 * delta.^2 .* (na^2 * r1.m{2} + nb^2 * r1.m{2}) / nx^2 + ...
        4 * delta .* (na * r1.m{3} - nb * r0.m{3}) / nx;

    r.T = [(ones(size(r0.T,1),1)*[u v] + r0.T) ; r1.T]; % transformations
    r.n = nx;                                           % number of images in A+B               
   
end