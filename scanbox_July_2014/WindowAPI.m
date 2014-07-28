function WindowAPI(varargin)  %#ok<VANUS>
% Set window state using Windows API
% WindowAPI(FigureHandle, Command, [Value])
% INPUT:
%   FigureHandle:  Matlab Handle of a figure with enabled 'Visible' property.
%                  For all commands except 'FullScreen' and 'Clip' the Windows
%                  handle (e.g. obtained by the 'GetHWnd' command) is accepted
%                  also.
%   Command:       String, not case sensitive, first 3 characters matter:
%     'TopMost':   Keep the window on top of all other windows. This does not
%                  enable the modal state of the window.
%     'NoTopMost': Disable the topmost state.
%     'Front':     Lift the window on top of all others, flash the icon in the
%                  taskbar. The window is not made active. This may interrupt
%                  the current work of the user.
%     'Minimize':  Minimize the window.
%     'Restore':   Restore the original size before minimization or
%                  maximization.
%     'Maximize':  Maximize: Full screen with visible Windows taskbar and
%                  menubar of the figure, but no border around the figure.
%     'XMax', 'YMax': Maximize the window horizontally or vertically.
%     'Position':  Set inner position of the figure realtive to the current
%                  monitor, or to the monitor with index defined as 4th input.
%                  The position value can be:
%                    DOUBLE vector [Left, Top, Right, Bottom]: pixel units
%                            relative to monitor.
%                    'work': Full monitor position without taskbar and sidebar.
%                    'full': Full monitor position. Using this you see only the
%                            figure's contents without title, border and
%                            menubar and without the taskbar.
%     'OuterPosition': As 'Position', but sets the outer position.
%     'ToScreen':  Move window completely to the nearest monitor. See MOVEGUI.
%     'Flash':     Short flashing the window border or the taskbar icon.
%     'Alpha':     WindowAPI(FigH, 'Alpha', A): Set the transparency level of
%                  the complete window from A=0.0 (invisible) to A=1.0 (opaque).
%                  WindowAPI(FigH, 'Alpha', A, [R,G,B]): The pixels with the
%                  color [R,G,B] are not drawn such that the pixels behind the
%                  window are visible. [R,G,B] must be integers in the range
%                  from 0 to 255. See NOTES.
%     'Opaque':    Release memory needed for Alpha blending to save resources.
%     'Clip':      Clip the window border or a specified rectangle. 3rd input:
%                    TRUE:  Clip the figure border, "splash screen".
%                    FALSE: Show the full window.
%                    [X, Y, Width, Height]: Rectangle in coordinates relative
%                           to figure as [X, Y, Width, Height] measured from
%                           bottom left in pixels.
%     'LockCursor': Keep cursor inside a rectangle. 3rd input:
%                    1, TRUE: Limit to figure,
%                    [X, Y, Width, Height]: Rectangle in pixel units relative
%                             to figure, DOUBLE vector.
%                    0, FALSE or omitted: free the cursor.
%                  NOTE: This does not lock the topmost window. You can
%                  activate MATLAB's command window using ALT-TAB and free the
%                  cursor by:  WindowAPI('UnlockCursor').
%     'SetFocus':  Set the keyboard focus to the specified figure. Actually
%                  "figure(FigHandle)" should do this according to Matlab's
%                  documentation, but it doesn't from version 6.5 to 2009a or
%                  higher.
%
% GET INFORMATION:
% Reply = WindowAPI(FigureHandle, Command)
%     'GetStatus': Current window statue: 'maximized', 'minimized', 'restored'.
%     'GetHWnd':   Get the OS handle of the figure as UINT64 value. Most
%                  commands of WindowAPI are faster using this handle, but the
%                  MATLAB handle is needed if the inner figure position is used
%                  e.g. in 'Position', 'Clip' or 'LockCursor'.
%                  NOTE: The HWnd handle changes if the visibility of a figure
%                        is disabled!
%     'Monitor':   Information about monitor with the largest overlap to the
%                  figure. Struct with fields:
%                    FullPosition: [X, Y, W, H] monitor size.
%                    WorkPosition: [X, Y, W, H] size without taskbar / sidebar.
%                    FigureOnScreen: LOGICAL flag, TRUE if any part of the
%                                  figure overlaps with this monitor. Without
%                                  overlap the nearest monitor is replied.
%                    isPrimaryMonitor: This monitor is the primary monitor.
%     'Position', 'OuterPosition': Using these commands with 2 inputs only
%                  reply the size relative to the current monitor as struct
%                  with the fields 'Position' and 'MonitorIndex'.
%
% CONTROL FEATURES:
%   FormerStatus = WindowAPI('topmost', Status): If Status is 'off', the
%      TopMost property is not set in future calls. This keeps Matlab in the
%      background e.g. during a long test, even if a function asks WindowAPI
%      to set a figure as top-most window.
%   WindowAPI('UnlockCursor'): Frees a cursor locked to a rectangle.
%
% NOTES:
%   This function calls Windows-API functions => No Linux, no MacOS - sorry!
%   Suggestions for Unix implementations are very appreciated!
%
%   Enabling the Alpha blending can cause a short black flashing of the
%   figure. It might  be nicer to create the figure outside the visible screen
%   area, enable the Alpha blending and move the window to the desired position
%   afterwards.
%
%   To find the window handle of the OS, the figure title is modified for some
%   milliseconds. This works without Java and for all known Matlab versions.
%   It fails, if two Matlab sessions call this function at the same time for
%   figures with the same title - a very unlikely constellation.
%
%   Alpha blending does not work reliably with the OpenGL renderer on my
%   computer. Setting the FIGURE's WVisual property to '07' ("RGB 16
%   bits(05 06 05 00) zdepth 16, Hardware Accelerated, Opengl, Double Buffered,
%   Window") helps most of the times. I suggest using the Painters or ZBuffer
%   renderer for Alpha blending.
%
%   The StencilRGB value of the command Alpha does not exactly equal the RGB
%   value set by Matlab: The Matlab colors [88/255,0,0] to [95/255,0,0] are
%   matching the StencilRGB=[90,0,0] on my laptop. I suggest to use the RGB
%   colors with either 0 or 255 as components.
%
% EXAMPLES:  (More: demo_WindowAPI.m)
% Maximize the current figure:
%   WindowAPI(gcf, 'maximize')
% Get the whole screen for drawing, remove the border:
%   figure; sphere;
%   uicontrol('Style', 'PushButton', 'Position', [10, 10, 100, 24], ...
%             'String', 'Close', 'Callback', 'delete(gcbf)');
%   WindowAPI(gcf, 'position', 'full')
%   WindowAPI(gcf, 'clip');
%
% A transparent command window (Matlab >= 2008a probably):
%   mainFrame = com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame;
%   HWnd = uint64(mainFrame.getHWnd);
%   WindowAPI(HWnd, 'Alpha', 0.8);
%
% COMPILE:
%   The C-file must be compiled before using. See WindowAPI.c for details.
%   Call the M-file WindowAPI without inputs to start an auto-compilation.
%
% Tested: Matlab 6.5, 7.7, 7.8, 7.13, WinXP/32, Win7/64
% Author: Jan Simon, Heidelberg, (C) 2008-2011 matlab.THISYEAR(a)nMINUSsimon.de
%
% See in the FEX:
% ShowWindow, Matthew Simoneau:
%   http://www.mathworks.com/matlabcentral/fileexchange/3407
% Window Manipulation, Phil Goddard:
%   http://www.mathworks.com/matlabcentral/fileexchange/3434
% api_showwindow, Mihai Moldovan:
%   http://www.mathworks.com/matlabcentral/fileexchange/2041
% maxfig, Mihai Moldovan:
%   http://www.mathworks.com/matlabcentral/fileexchange/6913
% setFigTransparency, Yair Altman:
%   http://www.mathworks.com/matlabcentral/fileexchange/30583
% FigureManagement (multi-monitor setup), Mirko Hrovat:
%   http://www.mathworks.com/matlabcentral/fileexchange/12607

% Useful tricks, which I could not solve in the Windows API yet:
% (inspired by Yair Altman):
%   jFrame = get(handle(gcf), 'JavaFrame');
%   jProx  = jFrame.fFigureClient.getWindow();
%   HWnd   = jProx.getHWnd;
%   jProx.setMinimumSize(java.awt.Dimension(200,200));  % setMaximumSize
%   jProx.setCloseOnEscapeEnabled(1)

% $JRev: R-A V:026 Sum:FA8YujA9Thwk Date:30-Jul-2011 02:58:08 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $File: Tools\GLGui\WindowAPI.m $
% History: See WindowAPI.c

% Initialize: ==================================================================
% Do the work: =================================================================
% This function runs only, if the compiled Mex is not existing!

[mPath, mName] = fileparts(mfilename('fullpath'));
if ~ispc
   error(['JSimon:', mName, ':WindowsOnly'], ...
      'Sorry - this runs under Windows only.');
end
   
fprintf(2, '== %s: Cannot find the compiled mex file\n', mName);

if isempty(which([mName, '.', mexext]))
   try
      fprintf('== Start compilation of %s:\n', mName);
      bakCD = cd;
      cd(mPath);
      mex('-O', 'WindowAPI');
      cd(bakCD);
      fprintf('Compilation successful.\n\n');
      
      fprintf('== Starting unit test:\n');
      uTest_WindowAPI;
      fprintf('\nMore examples in: demo_WindowAPI\n');
      
   catch
      fprintf('Compilation failed:\n  %s\n', lasterr);
      fprintf('MSVC or Intel compiler is needed - not working with LCC!\n');
      fprintf('Perhaps you must setup the compiler at first:\n');
      fprintf('  mex -setup\n');
   end
end

% return;
