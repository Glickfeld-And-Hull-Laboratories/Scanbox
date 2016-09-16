
%% Update knobby firmware...

scanbox_config;
global sbconfig;

if(~isempty(sbconfig.tri_knob))
    d = which('knobby_update.py');  % where is it?
    p = strsplit(d,'\');
    root = strjoin(p(1:end-1),'\');
    cd(root);
    cmd = ['python.exe knobby_update.py ' sbconfig.tri_knob];
    [~,~] = system(cmd,'-echo');
else
    warning('There is no definition of tri_knob in scanbox_config.m');
end
