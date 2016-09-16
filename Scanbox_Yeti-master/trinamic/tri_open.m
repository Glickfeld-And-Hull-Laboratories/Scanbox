function tri_open()

global tri tri_pos sbconfig scanbox_h;

fn = which('scanbox');
fn = strsplit(fn,'\');
fn{end-1} = 'mmap';
fn{end} = 'scanknob.pos';
sbconfig.f_pos = strjoin(fn,'\');
fn{end} = 'scanknob.cmd';
sbconfig.f_cmd = strjoin(fn,'\');

scanknob_setup;                                 % setup memory mapped communication

[~,~] = system('taskkill /F /IM python.exe');   % kill any running stuff from previous runs
[~,~] = system('taskkill /F /IM cmd.exe');

tri.Data = uint8([1 ; zeros(9,1)]);

if(isempty(sbconfig.tri_knob))
    cmd = sprintf('%s %s %s %s %s &',  ...
    'python.exe',   ...
    which('scanknob_sa.py'), ...
    sbconfig.f_pos, ...
    sbconfig.f_cmd, ...
    sbconfig.tri_com);
    [~,~] = system(cmd);
else
    cmd = sprintf('%s %s %s %s %s %s &',  ...
    'python.exe',   ...
    which('scanknob_only.py'), ...
    sbconfig.f_pos, ...
    sbconfig.f_cmd, ...
    sbconfig.tri_com, ...
    sbconfig.tri_knob);
    [~,~] = system(cmd);    
end

tic
while(tri.Data(1)~=0)   % wait for python to start...   
    if(toc>5)
            uiwait(errordlg('Cannot communicate with Knobby! Please fix and restart!'));
            return;
    end
end





