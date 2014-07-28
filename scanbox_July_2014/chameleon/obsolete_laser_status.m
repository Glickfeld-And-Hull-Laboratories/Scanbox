function msg = laser_status


'kuku'

msg = [];

r = laser_send('PRINT LASER');

switch(r(end))
    case '0'
        msg = [msg 'Laser is in standby'];
    case '1'
        msg = [msg 'Laser in on'];
    case '2'
        msg = [msg 'Laser of due to fault!'];
end


r = laser_send('PRINT KEYSWITCH');
switch(r(end))
    case '0'
        msg = [msg ' - ' 'Key is off'];
    case '1'
        msg = [msg ' - ' 'Key is on'];
end

r = laser_send('PRINT SHUTTER');
switch(r(end))
    case '0'
        msg = [msg sprintf('\n') 'Shutter is closed'];
    case '1'
        msg = [msg sprintf('\n') 'Shutter is open'];
end


r = laser_send('PRINT TUNING STATUS');
switch(r(end))
    case '0'
        msg = [msg sprintf('\n') 'Tuning is ready'];
    case '1'
        msg = [msg sprintf('\n') 'Tuning in progress'];
    case '2'
        msg = [msg sprintf('\n') 'Search for modelock in progress'];
    case '3'
        msg = [msg sprintf('\n') 'Recovery in progress'];
end


r = laser_send('PRINT MODELOCKED');
switch(r(end))
    case '0'
        msg = [msg sprintf('\n') 'Standby...'];
    case '1'
        msg = [msg sprintf('\n') 'Modelocked!'];
    case '2'
        msg = [msg sprintf('\n') 'CW'];
end
    



       