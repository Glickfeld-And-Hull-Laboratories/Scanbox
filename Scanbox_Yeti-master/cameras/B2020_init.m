
% init for Imprex camera

global dalsa_src;

dalsa_src = getselectedsource(dalsa);
dalsa_src.BinningHorizontal = 'x4';
dalsa_src.BinningVertical = 'x4';
dalsa_src.ReverseX = 'True';
dalsa_src.ReverseY = 'False';
dalsa_src.ConstantFrameRate = 'True';
dalsa_src.ProgFrameTimeEnable = 'True';
dalsa_src.ProgFrameTimeAbs = 100000;
dalsa_src.ExposureMode = 'Timed';
dalsa_src.ExposureTimeRaw = dalsa_src.MaxExposure;
dalsa_src.ReverseX = 'True';
dalsa_src.DigitalGainAll = 0;
dalsa_src.DigitalOffsetAll = 512;