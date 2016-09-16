%setup files if they do not exist

global sbconfig tri tri_pos

if(~exist(sbconfig.f_pos,'file'))
    f = fopen(sbconfig.f_pos,'w');
    fwrite(f,zeros(1,5,'int32'),'uint32');
    fclose(f);
end

tri_pos = memmapfile(sbconfig.f_pos,'Writable',true,'Format','int32');

if(~exist(sbconfig.f_cmd,'file'))
    f = fopen(sbconfig.f_cmd,'w');
    fwrite(f,zeros(1,10,'uint8'),'uint8');
    fclose(f);
end

tri = memmapfile(sbconfig.f_cmd,'Writable',true);

