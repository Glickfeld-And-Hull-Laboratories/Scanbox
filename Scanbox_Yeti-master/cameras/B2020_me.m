
function B2020_me(x)

% Set exposure to a fraction of the maximum

global dalsa_src;

dalsa_src.ExposureTimeRaw = dalsa_src.MaxExposure * x;