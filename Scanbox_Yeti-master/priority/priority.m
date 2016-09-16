% Usage:   q = priority(p)
% 
%          Set the priority of the Matlab process to that specified
%          in "p". "p" can be any of the following: "l", "bn", "n",
%          "an" or "h" (low, below-normal, normal, above-normal, high).
%          In addition, "s" can be prefixed to any of these to cause
%          silent behaviour (no message printed). The previous priority
%          is returned in "q", in the same format.
% 
%          q = priority
% 
%          Just return the current priority without changing anything.
% 
% Example: q = priority('l'); % reduce priority
%          ...
%          <do some heavy processing without freezing computer>
%          ...
%          priority(q); % restore priority
% 
%          This is Version 2 (2009-09-18).
				 
%	--- IMPLEMENTED AS A MEX FILE ---

function q = priority(p)

if ispc
	
	% compile
	if nargin && ischar(p) && strcmp(p, 'compile')
		
		c = cd;
		try
			cd(fileparts(which('priority.m')));
			mex priority.cpp
			cd(c);
			disp('Compiled OK!');
		catch err
			cd(c);
			rethrow(err)
		end
		
	else
		
		error(['call ''priority compile'' to compile priority.cpp before use']);
		
	end
	
else
	
	% ignore silently on non-windows systems
	q = [];

end

