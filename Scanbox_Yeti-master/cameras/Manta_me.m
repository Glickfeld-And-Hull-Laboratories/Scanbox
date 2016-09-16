function Manta_me(x)

% Set exposure to a fraction of the maximum

global dalsa_src;
dalsa_src.ExposureTimeAbs = round(66000 * x);