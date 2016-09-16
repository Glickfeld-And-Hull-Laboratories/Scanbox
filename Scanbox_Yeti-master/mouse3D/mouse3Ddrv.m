classdef mouse3Ddrv < handle

    properties (SetAccess = private, GetAccess = public)
        SpaceNav
        Sen
        Key
    end

    events (ListenAccess = 'public', NotifyAccess = 'private')
        SenState
        ButState
    end

    methods
        function obj = mouse3Ddrv
            obj.SpaceNav = actxserver('TDxInput.Device');
            obj.Splash;

            % The following lines are a bit strange - events wont link
            % properly if they are nested low down in the COM object, so we
            % use pointers to them :)
            obj.Sen = obj.SpaceNav.Sensor;
            obj.Key = obj.SpaceNav.Keyboard;

            % Setup the device and drivers
            obj.RegisterEvents;
            obj.Reconnect;
            obj.SpaceNav.LoadPreferences('Matlab');
            %obj.monitorHandle = figure('CloseRequestFcn','closereq; disp(''SpaceNavObj still running in background'');');
        end%constructor
        function delete(obj)
            if obj.SpaceNav.IsConnected
                obj.SpaceNav.Disconnect;
            end
            delete(obj.SpaceNav)
        end%destructor

        function Reconnect(obj)
            if obj.SpaceNav.IsConnected
                obj.SpaceNav.Disconnect;
            end
            obj.SpaceNav.Connect;
        end%Reconnect
        function RegisterEvents(obj)
            obj.Sen.registerevent(      {'SensorInput',     @obj.senEvent });
            obj.Key.registerevent(      {'KeyDown',         @obj.keyDownEvent,  'KeyUp',    @obj.keyUpEvent });
            obj.SpaceNav.registerevent( {'DeviceChange',    @obj.connectEvent });
        end%RegisterEvents

        function connectEvent(varargin)
            obj = varargin{1};
            % Type categories are explained in the 3Dconnexions SDK
            switch obj.SpaceNav.Type
                case 0
                    devStr = ['ATTENTION: DEVICE NOT RECOGNISED, CHECK FOLLOWING:\n\t'...
                        'a) Is device connected properly?\n\t'...
                        'b) Is 3Dconnexions control panel running?\n\t'...
                        '\t\t... and then use the ''Reconnect'' method. '];
                case 6
                    devStr = 'SpaceNavigator Connected';
                case 4
                    devStr = 'SpaceExplorer Connected';
                case 25
                    devStr = 'SpaceTraveler Connected';
                case 29
                    devStr = 'SpacePilot Connected';
                otherwise
                    devStr = '3D mouse device recognized';
            end
            fprintf(1,['DeviceID:%i -> ' devStr '\n'],obj.SpaceNav.Type);
        end%connectEvent
        function keyDownEvent(obj,varargin)
            %disp('You just depressed a key')
            notify(obj,'ButState'); % Broadcast notice of event
        end%keyDownEvent
        function keyUpEvent(obj,varargin)
            %disp('You just released a key')
            notify(obj,'ButState'); % Broadcast notice of event
        end%keyUpEvent
        function senEvent(varargin)
            obj = varargin{1};
            notify(obj,'SenState'); % Broadcast notice of event
        end%senEvent
    end %methods

    methods (Static)
        function Splash
        end%Splash
    end%static methods
end
