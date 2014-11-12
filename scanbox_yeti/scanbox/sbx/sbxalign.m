function R = sbxalign(fname,idx)

if(length(idx)==1)
    
    A = sbxread(fname,idx(1),1);        % read the frame
    A = double(squeeze(A));
  
    R.m{1} = A;                         % mean
    R.m{2} = zeros(size(A));            % 2nd moment
    R.m{3} = zeros(size(A));            % 3rd moment
    R.m{4} = zeros(size(A));            % 4th moment
 
    R.T = [0 0];                        % no translation (identity)
    R.n = 1;                            % # of frames
    
else
    
    idx0 = idx(1:floor(end/2));         % split into two groups
    idx1 = idx(floor(end/2)+1 : end);   
    
    r = cell(1,2);
    I = {idx0 idx1};
    
    for(j=1:2)
        r{j} = sbxalign(fname,I{j});          % align each group
    end
   
    [u v] = fftalign(r{1}.m{1},r{2}.m{1});  % align their means
    
    for(i=1:4)                          % shift mean image and moments
        r{1}.m{i} = circshift(r{1}.m{i},[u v]);
    end
     
    delta = r{2}.m{1}-r{1}.m{1};            % online update of the moments
    na = r{1}.n;
    nb = r{2}.n;
    nx = na + nb;

    R.m{1} = r{1}.m{1}+delta*nb/nx;       
    R.m{2} = r{1}.m{2} + r{2}.m{2} + delta.^2 * na * nb / nx;
    R.m{3} = r{1}.m{3} + r{2}.m{3} + ...
        delta.^3 * na * nb * (na-nb)/nx^2 + ...
        3 * delta / nx .* (na * r{2}.m{2} - nb * r{1}.m{2});
    R.m{4} = r{1}.m{4} + r{2}.m{4} + delta.^4 * na * nb * (na^2 - na * nb + nb^2) / nx^3 + ...
        6 * delta.^2 .* (na^2 * r{2}.m{2} + nb^2 * r{2}.m{2}) / nx^2 + ...
        4 * delta .* (na * r{2}.m{3} - nb * r{1}.m{3}) / nx;

    R.T = [(ones(size(r{1}.T,1),1)*[u v] + r{1}.T) ; r{2}.T]; % transformations
    R.n = nx;                                           % number of images in A+B               
   
end