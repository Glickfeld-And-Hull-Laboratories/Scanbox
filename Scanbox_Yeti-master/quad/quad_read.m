function r = quad_read()

global quad;

if ~isempty(quad)
    fwrite(quad,0);
    r=fread(quad,1,'int32'); % read counter
end
