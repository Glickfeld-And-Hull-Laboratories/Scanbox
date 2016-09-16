function sb_optowave_square(m,M,period)

% values between 0 and 4095

global sb otwave;

global sbconfig

vals = m*ones(1,period/2);
vals = [vals M*ones(1,period/2)];
vals = uint16(vals);
otwave = vals;

if(~isempty(sbconfig.optocal))
    for(j=1:length(vals))
        d = abs(double(sbconfig.optolut)-double(vals(j)));
        m = min(d);
        k = find(d==m);
        otwave(j) = round(mean(k));
    end
    otwave = uint16(otwave);
    vals = otwave;
end


sb_optowave_init;  %upload

for(i=0:period-1)
    b = typecast(vals(i+1),'uint8');
    sb_optowave(b(2),b(1));
end

sb_optoperiod(period);

