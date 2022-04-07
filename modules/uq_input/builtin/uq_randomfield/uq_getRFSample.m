function [SampleRF, xi] = uq_getRFSample( current_input, varargin )
% UQ_GETGRFSAMPLE: gets samples of the random field defined in
% current_input. In case, of translation non-Gaussian RFs, the translation
% is carriedout also within this function (e.g., when using a lognormal
% random field)
% 
% INPUT: 
%   - current_input: Random field object
%   - varargin{1}: Number of samples N (by default 1)
%   - varargin{2}: Sampling method (by default 'MC')
%
% OUTPUT:
%   - SampleRF: Sample trajectories vector of size N x m, where m is the
%   number of points in the discretization mesh
%   - xi: Standard Gaussian random variables vector of size N x M, where M
%   is the expansion order 


%% 1. Initialization

% Number of inputs
nargs = length(varargin);
  
% Get/Define the number of samples to generate
if ~nargs
    fprintf('Number of samples not specified. The default value is 1 ');
    N=1;
else
    N = varargin{1};
end

% Get/Define the sampling strategy
if nargs==2
    Sampling = varargin{2} ;
else
    Sampling = 'MC' ;
end

%% 2. Gaussian random field

% Generate standard Gaussian random samples to build the trajectories
xi = uq_getSample(current_input.UnderlyingGaussian, N, Sampling);

% Transform the standard Gaussian samples into random field trajectories
SampleRF = uq_RF_Xi_to_X(current_input,xi) ;


%% 3. Translation non-Gaussian random field (if any)

% If the user has specified another marginal type carry out
% point-by-point isoprobabilistic transformation with the moments
% maintained.
if ~strcmpi(current_input.Internal.RFType,'gaussian')
    SampleRF = uq_translateRF_FromGaussian(SampleRF,current_input, ...
        current_input.Internal.RFType);    
end

end

