function quad_zero()

global quad;

if ~isempty(quad)
    fwrite(quad,1); % zero the counter
    if(quad.BytesAvailable > 0)
        fread(quad,quad.BytesAvailable); % empty the buffer...
    end
end
