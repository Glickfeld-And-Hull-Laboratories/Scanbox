global sbconfig;

% User dependent settings

sbconfig.scanbox_com    = 'COM22';      % scanbox communication port
sbconfig.laser_com      = 'COM1';       % laser serial communication
sbconfig.laser_type     = 'CHAMELEON';  % laser type (CHAMELEON or '' if controlling with manufacturer's GUI) 
sbconfig.tri_knob       = 'COM6';      % serial for scanknob (empty if not present)
sbconfig.tri_com        = 'COM3';       % motor controller communication
sbconfig.tri_baud       = 57600;        % baud rate to motor controller
sbconfig.quad_com       = 'COM38';      % monitor quadrature encoder of rotating platform 
sbconfig.quad_cal       = 20*pi/1440;   % cm/count (r=10cm platform)
sbconfig.idisplay       = 2;            % take care of serial/ethernet callbacks every idisplay frames
sbconfig.deadband       = [22 10];      % size of laser deadband at margins
sbconfig.datadir        = 'd:\';        % default data directory
sbconfig.autoinc        = 1;            % auto-increment experiment # field
sbconfig.freewheel      = 1;            % enable freewheeling of motors (power will be turned off upon reaching position)
sbconfig.balltracker    = 0;            % enable ball tracker (0 - disabled, 1- enabled)
sbconfig.ballcamera     = '640';        % model of ball camera
sbconfig.eyetracker     = 1;            % enable eye tracker  (0 - disabled, 1- enabled)
sbconfig.eyecamera      = '1280';       % model of eye camera
sbconfig.portcamera     = 1;            % enable path camera (0 - disabled, 1- enabled)
sbconfig.pathcamera     = 'Manta';
sbconfig.pathlr         = 0;            % switch camera image lr? (Use camera hardware option if availabe!)
sbconfig.imask          = 3;            % interrupt masks (3 TTL event lines are availabe)
sbconfig.pockels_lut    = uint8([]);    % your look up table (must have exactly 256 entries)
sbconfig.mmap           = 0;            % enable/disable memory mapped file stream
sbconfig.optocal = [6.3176e-05 0.0732 1.3162]; % optotune calibration or []

 % PLEASE do not change these settings unless you understand what your are doing!

sbconfig.trig_level     = 160;          % trigger level
sbconfig.trig_slope     = 0;            % trigger slope (0 - positive, 1 - negative)
sbconfig.nbuffer = 16;                  % number of buffers in ring (depends on your memory)
sbconfig.resfreq = 7930;                % resonant freq for your mirror 
sbconfig.lasfreq = 80180000;            % laser freq at 920nm
sbconfig.ncolbi = [1222 1223 1226];     % bidirectional scanning even/odd alignment
sbconfig.margin = 40;                   % margin removed in bidirectional scannning
sbconfig.imaqmem = 6e9;                 % image acquisition memmory
sbconfig.stream_host = '';
sbconfig.stream_port = 7001;            % where to stream data to...
sbconfig.rtmax = 30000;                 % maximum real time data points
sbconfig.gpu_pages = 250;               % max number of gpu pages (make it zero if no GPU desired)
sbconfig.gpu_interval = 10;             % delta frames between gpu-logged frames
sbconfig.gpu_dev = 1;                   % gpu device #
sbconfig.nroi_auto = 4;                 % number of ROIs to track in auto alignment
sbconfig.nroi_auto_size = [64 96 128];  % size of auto ROIs regions for x1 x2 and x4
sbconfig.nroi_parallel = 0;             % use parallel for alignment? 
sbconfig.stream_host = 'localhost';     % stream to this host name
sbconfig.stream_port = 30000;           % and port...

sbconfig.obj_length = 98000;            % objective length from center of rotation to focal point [um] 
sbconfig.qmotion        = 0;            % quadrature motion controller 
sbconfig.qmotion_com    = 'COM32';      % comm port for quad controller
sbconfig.ephys = 0;                     % enable ephys data acquisition
sbconfig.ephysRate = 32000;             % sampling rate (samples/sec)

sbconfig.hsync_sign    = 1;             % 0-normal, 1-flip horizontal axis
sbconfig.gain_override = 1;             % override default gain settings?
sbconfig.gain_resonant = [1.4 2.9 5.7]; % gains for x1, x2 and x4 (x)
sbconfig.gain_galvo    = [1.0 2.0 4.0]; % same for galvo (y)
sbconfig.dv_galvo      = 64;            % dv per line (64 is the maximum)

% SLM

sbconfig.slm    = 0;                    % SLM option 
sbconfig.slmdev = 'Dev1';               % SLM daq device used
sbconfig.slmcal = 'slmcalx2';           % SLM calibration file