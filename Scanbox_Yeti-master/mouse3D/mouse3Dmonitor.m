classdef mouse3Dmonitor < handle
    %SPNAVMON Monitor window showing 3D mouse parameters
    %   Object must be initialised with a valid 3d mouse driver object from
    %   which to read input data. Window opens and displays all data
    %   incoming from 3d device.

    % mouse3Dmonitor.m


    properties (SetAccess = private, GetAccess = public)
        lhSen
        lhBut
        fh
        th
        tlh
        bth
        tith
    end

    methods
        function obj = mouse3Dmonitor(drvObj)
            if ~isa(drvObj, 'mouse3D.mouse3Ddrv')
                error('First argument must be 3D mouse driver object handle')
            end
            obj.lhSen = addlistener(drvObj,'SenState',@obj.updateMon);
            obj.lhBut = addlistener(drvObj,'ButState',@obj.buttonMon);
            makeMonWin(obj);
        end
        function delete(obj)
            delete(obj.fh)
        end
        function updateMon(obj,src,varargin)
            set(obj.th(1), 'String',  num2str(src.Sen.Translation.X,'%.2f') );
            set(obj.th(2), 'String',  num2str(src.Sen.Translation.Y,'%.2f') );
            set(obj.th(3), 'String',  num2str(src.Sen.Translation.Z,'%.2f') );
            set(obj.th(4), 'String',  num2str(src.Sen.Translation.Length,'%.2f') );
            set(obj.th(5), 'String',  num2str(src.Sen.Rotation.X,'%.2f') );
            set(obj.th(6), 'String',  num2str(src.Sen.Rotation.Y,'%.2f') );
            set(obj.th(7), 'String',  num2str(src.Sen.Rotation.Z,'%.2f') );
            set(obj.th(8), 'String',  num2str(src.Sen.Rotation.Angle,'%.2f') );
        end
        function buttonMon(obj,src,varargin)
            set(obj.bth(3), 'String',  num2str(src.Key.IsKeyDown(1),'%i') );
            set(obj.bth(4), 'String',  num2str(src.Key.IsKeyDown(2),'%i') );
        end
        function makeMonWin(obj,varargin)
            screenSize = get(0,'ScreenSize');
            fDepth = 300;
            fWidth = 200;
            obj.fh = figure(...
                'Units',         'Pixels',...
                'Position',      [10 screenSize(4)-50-fDepth fWidth fDepth],...
                'ToolBar',       'none',...
                'Name',          'nrcWare 3Dconnexions monitor tool',...
                'NumberTitle',   'off',...
                'MenuBar',       'none',...
                'DockControls',  'on');
            axis off
            for n = 1:4
                yCoOrd = 1-((n+1)/12);
                obj.th(n)  = text( 'Position',      [.7 yCoOrd]);
                obj.tlh(n) = text( 'Position',      [.1 yCoOrd]);
            end
            obj.tlh(9) = text(...
                'Position',      [-.05  yCoOrd],...
                'String',        'Translation');
            for n = 5:8
                yCoOrd = 1-((n+2)/12);
                obj.th(n)  = text( 'Position',      [.7 yCoOrd]);
                obj.tlh(n) = text( 'Position',      [.1 yCoOrd]);
            end
            obj.tlh(10) = text(...
                'Position',      [-.05  yCoOrd],...
                'String',        'Rotation');
            set(obj.th,...
                'Units',         'normalized',...
                'String',        'x.xx');
            set(obj.tlh,...
                'Units',         'normalized');
            set(obj.tlh(1), 'String',  'X' );
            set(obj.tlh(2), 'String',  'Y' );
            set(obj.tlh(3), 'String',  'Z' );
            set(obj.tlh(4), 'String',  'Length' );
            set(obj.tlh(5), 'String',  'X' );
            set(obj.tlh(6), 'String',  'Y' );
            set(obj.tlh(7), 'String',  'Z' );
            set(obj.tlh(8), 'String',  'Angle' );

            for n = 1:2
                yCoOrd = 1-((n+11)/12);
                obj.bth(n)    = text( 'Position',      [.1 yCoOrd]);
                obj.bth(n+2)  = text( 'Position',      [.7 yCoOrd]);
            end
            set(obj.bth(1), 'String',  'Button 1' );
            set(obj.bth(2), 'String',  'Button 2' );
            set(obj.bth(3:4), 'String',  'xXx' );

            set(obj.tlh(9:10),...
                'Rotation',      90,...
                'FontWeight',    'bold');

            obj.tith = text(...
                'String',        '3D Mouse Monitor',...
                'Position',      [-0.1 12/12],...
                'FontWeight',    'bold',...
                'FontSize',      14,...
                'Color',         [0 0 1]);
            set(obj.tlh, 'Color', [0 0 1]);
            set(obj.th,  'Color', [1 1 1]);
            set(obj.tlh(9:10),  'Color', [1 1 1]);
            set(obj.th([4 8]),  'Color', [1 0 0]);
            set(obj.tlh([4 8]),  'Color', [1 0 0]);
            set(obj.bth(1:2),  'Color', [0 0 1]);
            set(obj.bth(3:4),  'Color', [1 1 1]);
            set(obj.fh,  'Color', [0 0 0]);
        end
    end
end
