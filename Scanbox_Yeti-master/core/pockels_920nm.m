% Pockels calibration

power_920 = [
    0           1.2;
    0.048       6.8;
    0.090       20.2;
    0.131       40.3;
    0.181       74;
    0.224       111;
    0.316       203.5;
    0.386       290.6;
    0.513       469.9;
    0.625       655;
    0.714       797;
    0.81        951;
    0.95        1153;
    1.135       1366;
    1.256       1454;
    1.363       1486;
    1.48        1519;
    1.566       1493;
    1.752       1360;
    1.822       1282;
    1.9         1196];

clf
f = @(x,xdata) x(1).*sin(xdata*x(2)).^2
pp = lsqcurvefit(f,[1500 1],power_920(:,1),power_920(:,2))
plot(power_920(:,1),power_920(:,2),'o')
hold on
xx = linspace(0,2,512);
plot(xx,f(pp,xx))

% generate lookup table for linearization

pint = linspace(0,pp(1),256);
Vint = asin(sqrt(pint/pp(1)))/pp(2);
lut = round(256*Vint/2.040); % max PSoC value

% generate values for hardware LUT

t = linspace(0,pi,17);
t = t(1:end-1);
t = t+pi/32;
v = dec2hex(lut(round(255*abs(sin(t)))));


    