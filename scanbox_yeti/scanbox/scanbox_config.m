global sbconfig;

% User dependent settings

sbconfig.scanbox_com    = 'COM4';      % scanbox communication port 26
sbconfig.laser_com      = 'COM3';      % laser serial communication
sbconfig.laser_type     = 'CHAMELEON';  % laser type (CHAMELEON or MAITAI or '' if controlling with manufacturer's GUI) 
sbconfig.tri_com        = 'COM1';       % motor controller communication
sbconfig.tri_baud       = 57600;        % baud rate to motor controller
sbconfig.dinterval      = 2;            % microscope display interval

% Please do not change these settings unless you understand what your are doing --

sbconfig.qmotion        = 0;            % quadrature motion controller 
sbconfig.qmotion_com    = 'COM32';      % comm port for quad controller
sbconfig.ot_open        = 'COMX';       % opto tune lens serial communication port
sbconfig.balltracker = 1;               % enable ball tracker (0 - disabled, 1- enabled)
sbconfig.eyetracker = 1;                % enable eye tracker  (0 - disabled, 1- enabled)
sbconfig.optotune = 0;                  % enable optotune     (0 - disabled, 1- enabled)
sbconfig.dalsa = 0;                     % enable dalsa genie on camera path (0 - disabled, 1- enabled)
sbconfig.nbuffer = 16;                  % number of buffers in ring (depends on your memory)
sbconfig.resfreq = 7919;                % resonant freq for your mirror 
sbconfig.lasfreq = 80180000;            % laser freq at 920nm
sbconfig.imask = 3;                     % interrupt masks (3 TTL event lines are availabe)
sbconfig.imaqmem = 6e9;                 % image acquisition memmory
sbconfig.obj_length = 98000;            % objective length from center of rotation to focal point [um] 
sbconfig.stream_host = '';
sbconfig.stream_port = 7001;            % where to stream data to...
sbconfig.analog = '';           
sbconfig.analog_chan = 0;
sbconfig.rtmax = 30000;                 % maximum real time data points
sbconfig.gpu_pages = 200;                 % max number of gpu pages (make it zero if no GPU desired)
sbconfig.gpu_interval = 5;              % delta frames between gpu-logged frames
sbconfig.gpu_dev = 1;                   % gpu device #
sbconfig.gpu = 0;                       % enable GPU processing?
sbconfig.nroi_auto = 4;                 % number of ROIs to track in auto alignment
sbconfig.nroi_auto_size = 64;           % size of auto ROIs regioins
sbconfig.nroi_parallel = 0;             % use parallel for alignment? 
sbconfig.stream_host = 'localhost';     % stream to this host name
sbconfig.stream_port = 30000;           % and port...
sbconfig.sim_mode = 0;                  % simulation mode 
sbconfig.sim_file = 'd:\2pdata\gg8\gg8_000_004'; % data to play back
sbconfig.sim_nframes = 300;             % loop length for simulation mode in frames