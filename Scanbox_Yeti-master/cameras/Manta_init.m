
% init for Imprex camera

global dalsa_src;

dalsa_src = getselectedsource(dalsa);
dalsa_src.BinningHorizontal = 5;
dalsa_src.BinningVertical = 5;
% dalsa_src.ReverseX = 'True';
% dalsa_src.ReverseY = 'False';
% dalsa_src.ConstantFrameRate = 'True';
% dalsa_src.ProgFrameTimeEnable = 'True';
dalsa_src.AcquisitionFrameRateAbs = 15;
dalsa_src.ExposureMode = 'Timed';
dalsa_src.ExposureTimeAbs = 66000;
% dalsa_src.ReverseX = 'True';
% dalsa_src.DigitalGainAll = 0;
% dalsa_src.DigitalOffsetAll = 5