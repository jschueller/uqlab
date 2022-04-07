function SUCCESS = uq_removeModule(mname,core_module)
% UQ_REMOVEMODULE(MNAME,COREMODULE) remove the module with identifier MNAME
% from the core module specified in COREMODULE 

%% Copyright notice
% Copyright 2013-2016, Stefano Marelli and Bruno Sudret

% This file is part of UQLab.
% It can not be edited, modified, displayed, distributed or redistributed
% under any circumstances without prior written permission of the copuright
% holder(s). 
% To request special permissions, please contact:
%  - Stefano Marelli (marelli@ibk.baug.ethz.ch)

% Retrieve the core module
UQ = uq_retrieveSession('UQ');

% Remove the specified module
try
    UQ.(core_module).remove_module(mname);
    SUCCESS = 1;
catch me
    SUCCESS = 0;
end
