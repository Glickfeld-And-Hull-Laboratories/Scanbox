close all
figure

imagesc(m),truesize,colormap gray
imcontrast

% coef = reshape(coef,[512 796 2 15^2]);
% z = zeros(size(z));
% for(i=1:size(z,1))
%     i
%     for(j=1:size(z,2))
%         a = corrcoef(squeeze(coef(i,j,1,:)),squeeze(coef(i,j,2,:)));
%         z(i,j) = a(1,2);
%     end
% end


figure(1)
ctr = round(ginput(1));

while(~isempty(ctr))
    figure(2)
    r = zeros(size(coef,3),1);
    for(i=-8:8)
        for(j=-8:8)
            r = r+squeeze(coef(ctr(2)+i,ctr(1)+j,:));
        end
    end
    rf = r'*stim;
    
 %imagesc(fftshift(abs(fft2(r))))
 imagesc(reshape(rf,size(xx)));
 %     figure(3)
%     imagesc(squeeze(coef(ctr(2),ctr(1),:,:)));
    figure(1);
    ctr = round(ginput(1));
end
    