function laser_close()

global laser;

if ~isempty(laser)
    fclose(laser);
end

