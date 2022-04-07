function varargout = uq_evalModel(varargin)
% UQ_CREATEINPUT   create a UQLab INPUT object 
%    myInput = UQ_CREATEINPUT(INPUTOPTS) creates and stores in the current
%    UQLab session an object of type INPUT based on the configuration
%    options given in the INPUTOPTS structure. 
%
%    myInput = UQ_CREATEINPUT(INPUTOPTS, '-private') creates an object of
%    type INPUT based on the configuration options given in the INPUTOPTS
%    structure, without saving it in the UQLab session. This is useful,
%    e.g., in case of parametric studies which create a large number of
%    temporary INPUT objects that do not need to be stored in memory.
%
%    Example 1 (representation): create a 2-dimensional INPUT object with independent
%    uniform random variables in [-1,1]:
%       INPUTOPTS.Marginals(1).Type = 'Uniform';
%       INPUTOPTS.Marginals(1).Parameters = [-1 1];
%       INPUTOPTS.Marginals(2).Type = 'Uniform';
%       INPUTOPTS.Marginals(2).Parameters = [-1 1];
%       myInput = UQ_CREATEINPUT(INPUTOPTS);
%
%    To draw N samples from the resulting object use:
%       X = uq_getSample(N)
%
%    Example 2 (statistical inference): infer the marginals and copula of an
%    input from data X among supported parametric models.
%       INPUTOPTS.Inference.Data = X;
%       myInput = UQ_CREATEINPUT(INPUTOPTS);
%
%    For additional information about the available INPUTOPTS configuration
%    fields type: 
%       help <a href="matlab:uq_InputOptions">uq_InputOptions</a>
%
%    To open the INPUT User Manual or the INFERENCE User Manual, type:
%       uq_doc('Input')
%       uq_doc('Inference')
%
%    See also: uq_getInput, uq_listInputs, uq_selectInput, uq_getSample,
%              uq_createModel, uq_createAnalysis 
%

% step 1: figure out whether the first argument is of type uq_model. If it
% is, define a 'module' argument to be used in the rest
if nargin && isa(varargin{1}, 'uq_model')
    module = varargin{1};
    varargin = varargin(2:end);
end

% HPC initialization
HPCflag = 0;


if exist('module', 'var') && ~isempty(module)
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end

if isempty(current_model)
    error('No model defined!');
end

% enable parallelization if specified in the model
if isfield(current_model.Internal, 'HPC') && isfield(current_model.Internal.HPC, 'enable_HPC') && current_model.Internal.HPC.enable_HPC
    HPCflag = 1;
end

% override the previous setting if specified in the command line
if any(strcmpi(varargin, 'HPC'))
    varargin = varargin(~strcmpi(varargin, 'HPC'));
    HPCflag = 1;
end


%% we can now distribute the model evaluations if configured
% program the dispatcher if not under execution

if HPCflag 
    if ~exist('UQ_dispatcher', 'var')
        UQ_dispatcher = uq_getDispatcher;
    end
    if ~strcmp(UQ_dispatcher.Type, 'empty') 
        if ~UQ_dispatcher.isExecuting  % don't do anything if it is executing or if we specify not to parallelize it
            UQ_dispatcher.Internal.Data.X = varargin{1};
            UQ_dispatcher.Internal.Data.current_model = current_model;
            UQ_dispatcher.Internal.current_model = current_model;
            UQ_dispatcher.Internal.Data.Nargout = nargout;
            % now remotely execute the model evaluation
            [varargout{1:nargout}] = UQ_dispatcher.run;
            %varargout{1} = Y;
            % and, once done, return
            return;
        else % if we are running, retrieve the important information and run!
            % retrieve the execution status
            cpuID = UQ_dispatcher.Runtime.cpuID;
            ncpu = UQ_dispatcher.Runtime.ncpu;
            % needs to be fixed absolutely!!
            X = varargin{1};
            chunksize = floor(size(X, 1)/ncpu);
        
            % now resize X to the correct chunk
            minidx = (cpuID-1)*chunksize + 1;
            maxidx = (minidx - 1) + chunksize;
            if cpuID == ncpu
                maxidx = size(X,1);
            end
            
            dispidx = minidx:maxidx;
            fprintf('Distributed model evaluation.\n')
            fprintf('Calculating node %d of %d\n', cpuID, ncpu);
            fprintf('Elements %d to %d\n', minidx, maxidx);
            which uqlab
            % and trim the X
            varargin{1} = X(dispidx,:);
            
        end
    end
end

% Eval the current model (with error handling)
try
    [varargout{1:nargout}]  = current_model.eval(current_model,varargin{:});
catch uqException
    uq_error(uqException);
end

