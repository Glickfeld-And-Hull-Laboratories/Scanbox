function quad_close()

global quad;

if ~isempty(quad)
    fclose(quad);
end
