function sb_open()

global sb sbconfig;

try
    if ~isempty(sb)
        fclose(sb);
    end
catch
end


sb = serial(sbconfig.scanbox_com ,...
    'BytesAvailableFcn','', ...
    'BytesAvailableFcnMode','byte', ...
    'InputBufferSize',100000, ...
    'OutputBufferSize',512, ...
    'Tag','sb', ...
    'BytesAvailableFcnCount',7);

fopen(sb);    % open it

