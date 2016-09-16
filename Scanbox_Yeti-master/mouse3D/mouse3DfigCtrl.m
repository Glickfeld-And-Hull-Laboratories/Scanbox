classdef mouse3DfigCtrl  < handle
%MOUSE3DFIGCTRL Dynamic control of camera position
%   Allows use of 3Dconnexions controller to control camera position in
%   figure in real time.

% mouse3DfigCtrl.m


   properties (SetAccess = private)
       hAxis
       lhSen
       lhBut
   end
   
   properties (SetAccess = public)
       resetPoint
   end

   methods
       function obj = mouse3DfigCtrl(drvObj,varargin)
           if ~isa(drvObj, 'mouse3D.mouse3Ddrv')
               error('First argument must be 3D mouse driver object')
           end
           if nargin >1
               obj.hAxis = varargin{1};
           else
               obj.hAxis = gca;
           end

           axis(obj.hAxis,'vis3d')
           obj.resetPoint.VA  = camva(obj.hAxis);
           obj.resetPoint.POS = campos(obj.hAxis);
           [obj.resetPoint.AZ,obj.resetPoint.EL] = view;
           
           obj.lhSen = addlistener(drvObj,'SenState',@obj.updateMon);
           obj.lhBut = addlistener(drvObj,'ButState',@obj.buttonMon);
       end
       function updateMon(obj,src,varargin)
           camorbit(obj.hAxis,-src.Sen.Rotation.Y,-src.Sen.Rotation.X);
           camroll(obj.hAxis,-src.Sen.Rotation.Z*2);
           campan(obj.hAxis,src.Sen.Translation.X/3200,src.Sen.Translation.Y/3200,'camera');
           camva(obj.hAxis, camva(obj.hAxis) + src.Sen.Translation.Z/1600)
       end
       function buttonMon(obj,src,varargin)
           if src.Key.IsKeyDown(1)
               camva(obj.hAxis,obj.resetPoint.VA);
               campos(obj.hAxis,obj.resetPoint.POS);
               view(obj.hAxis, [obj.resetPoint.AZ obj.resetPoint.EL]);
           end
       end
   end
end 
