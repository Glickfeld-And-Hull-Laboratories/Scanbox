
function ot_start

global optotune sbconfig;

if(sbconfig.optotune)
    
    fwrite(optotune,'Start');
    
    if(optotune.BytesAvailable>0)
        fread(optotune,optotune.BytesAvailable);
    end
end


