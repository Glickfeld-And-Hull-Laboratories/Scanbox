
function r = ori_tuning(animal,unit,expt)

clear param;

display_param;

open_ovserver   % open connection to the stimulus computer
open_sbserver   % open connnection to the microscope 

send_sbserver(sprintf('A%s',animal)); % tell the microscope the animal name...
send_sbserver(sprintf('U%s',unit));   % the ROI name...
send_sbserver(sprintf('E%s',expt));   % the experient number

th = 0:20:340;

% setup  grating

delete_object(-1);

add_object(0,6);            % creates a grating...
set_field('tper',0,60,1);   % 1Hz
set_field('sper',1,displayWidth/3,1);  % 0.03 at 25cm viewing distance

set_field('sper',1,337,1);  % 0.03 at 25cm viewing distance

set_field('contrast',1,0.7,1);

tag = 1;

send_sbserver(sprintf('G')); % tell microscope to start sampling
pause(10);                   % let it go for ... resonant mirror warm up

nt = 3*length(th);          % total number of trials...

for(rpt=1:5)                % number of repeats...
   
    th = th(randperm(length(th)));    
   
    for(ang = th)
        
        set_field('th',1,ang,1);
        
        param(tag).rpt = rpt;
        param(tag).th = ang;
        
        send_sbserver(sprintf('MTrial %03d Orientation=%3d (%4.1f%%)',tag,ang,100*tag/nt))

        tag = tag+1;
       
        loop(4);            % present the stimulus for 4 sec... at 60hz
        pause(8);           % pause between stimuli
        
    end
end

pause(1);

send_sbserver('S');     % stop the microscope...


close_ovserver    % close communication channels...
close_sbserver

fn = [ animal '_' unit '_' expt '_p.mat'];
save(fn,'param'); % save tags and parameters...


r = param;


