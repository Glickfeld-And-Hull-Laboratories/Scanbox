
function ot_close()

global optotune;

if ~isempty(optotune)
    fclose(optotune);
end
