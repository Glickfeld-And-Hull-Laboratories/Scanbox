function tri_close()

[~,~] = system('taskkill /F /IM python.exe');   % kill any running stuff from previous runs
[~,~] = system('taskkill /F /IM cmd.exe');