function quad_open()

global quad sbconfig;

if ~isempty(quad)
    try,
        fclose(quad);
    catch
    end
end

quad = serial(sbconfig.quad_com ,'Terminator','','BaudRate',1000000); 
fopen(quad);    % open it

