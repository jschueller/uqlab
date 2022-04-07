function RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio, Data)
% UQ_EOLE_METHOD: Carries out spectral decomposition for the EOLE
% (Expansion optimal linear estimation) method.
% INPUT:
%   - Coor: Coordinates/ Points where the correlation matrix is to be
%   computed
%   - Mesh: Discretization mesh where the random field is represented (i.e.
%   when sampling from it)
%   - Corr: Options for the correlation matrix (family, length, etc.)
%   - ExpOrder: expansion order (Keep it empty if it is to be estimated
%   here)
%   - Energyratio: Threshold of the energy ratio to derive the expansion
%   order
%   - Data: Observations (struct: Data.X = locations & Data.Y = Responses)
%
% OUTPUT:
% Struct RF with the followin fields:
%   - Eigs: Eigenvalues of the correlation matrixc
%   - Phi: Corresponding eigenvectors
%   - ExpOrder: Expansion order (when it is calculated within this
%   function)
%   - EOLE: Internal properties of EOLE (Corr_HX: cross-correlation matrix,
%   Corr_XX: Observation correlation matrix, CondWeight: Conditional
%   weight)
%   - TraceCorr: Trace of the correlation matrix - used to compute the sum
%   of eigenvalues.
%


% When called with only 4 inputs, it is assumed that there are no
% conditioning data
if nargin < 6
    Data = [] ;
    if nargin < 5
        error('uq_EOLE: Insufficient number of inputs!');
    end
end

%% Pre-processing: Handle conditional data, if any
% If there are data to condition on, append them to the coordinate and
% mesh vectors
if ~isempty(Data)
    Coor = [Coor; Data.X] ;
    Mesh = [Mesh; Data.X] ;
end

%% Definition of correlation matrices
% Compute the correlation matrix on the coordinates of the expansion (Gramm Matrix)
RF.EOLE.Corr = uq_eval_Kernel(Coor, Coor, Corr.Length, Corr) ;

% Compute the correlation vector between mesh points and
% coordinates of the expansion
if all(size(Mesh) == size(Coor)) & all( Mesh == Coor )
    RF.EOLE.Rho_vV = RF.EOLE.Corr ;
else
    RF.EOLE.Rho_vV = uq_eval_Kernel(Mesh, Coor, Corr.Length, Corr) ;
end

%% Perform spectral decomposition
% Set the maximum expansion order to the size of the correlation matrix
MaxOrder = size(RF.EOLE.Corr,1) ;

if ~isempty(ExpOrder)
    
   %  The expansion order is already known
       [V,D,eigflag] = eigs(RF.EOLE.Corr, ExpOrder, 'lm');
       
       % If eigflag is 0 then the eigendecomposition has converged
       if eigflag ~= 0
           error('Spectral decomposition of the correlation matrix did not converge!');
       end
else
    % The expansion order is not known - Compute it according to the
    % truncation ration
    
    % Eigenvalue decomposition with MaxOrder
    [Vfull,Dfull,eigflag] = eigs(RF.EOLE.Corr, MaxOrder, 'lm');
    
    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end
    
    % Calculate the cumulated energy ratio
    cumulated_eigs = cumsum(diag(Dfull))/sum(diag(Dfull)) ;
   
    % Find the order from which the energy ratio is larger than the
    % threshold
    tmp = find(cumulated_eigs >= EnergyRatio) ;
    if isempty(tmp)
        warning('The energy ratio threshold of %.2f could not be reached with the current covariance mesh!', EnergyRatio);
        fprintf('The expansion order is set at %u!\n', MaxOrder);
        ExpOrder = MaxOrder ;
    else
        ExpOrder = tmp(1) ;
    end
    
    % Get the retained eigenvalues and vectors
    V = Vfull(:,1:ExpOrder) ;
    D = Dfull(1:ExpOrder,1:ExpOrder) ;
    
    % Return also the expansion order in case it is calculated here
    RF.ExpOrder = ExpOrder ;
    
    % Return the full set of eigenvalues
    RF.EigsFull = abs(diag(Dfull)) ;
end

% Save the eigenvalues and eigenvectors of the correlation matrix
RF.Phi = V;                % eigenvectors
RF.Eigs = abs(diag(D));    % eigenvalues


%% Compute the correlation matrices using the observations (to condition on)
if ~isempty(Data)
    % Compute the correlation matrix between observations 
    Corr_XX = uq_eval_Kernel(Data.X , Data.X, Corr.Length, Corr) ;
    
    % Compute the correlation matrix between observations and mesh
    RF.EOLE.Corr_HX = uq_eval_Kernel(Mesh(1:end-size(Data.X,1),:) , Data.X, Corr.Length, Corr) ;
    
    % Get the conditional weights
    RF.EOLE.CondWeight= RF.EOLE.Corr_HX/Corr_XX ;
    RF.EOLE.Corr_XX = Corr_XX ;
end

% Return the trace of the correlation matrix (will be used to display the
% cumulated energy ratio) ;
RF.TraceCorr = trace(RF.EOLE.Corr) ;

end