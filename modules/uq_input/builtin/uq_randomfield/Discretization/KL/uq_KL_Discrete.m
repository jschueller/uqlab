function RF = uq_KL_Discrete(Mesh, Corr, ExpOrder, EnergyRatio)
% UQ_KL_NYSTROM: Solves the Fredholm integral equation for Karhunen-Lo`ve
% using the Nyström method, as described in:
% [1] Press, W. H., S. A. Teukolsky, W. T. Vetterling, and 
% B. P. Flannery (2007). Numerical recipes: The art of scientific 
% computing. Cambridge university press.
% [2] Betz, W., I. Papaioannou, and D. Straub (2014). Numerical methods 
% for the discretization of random fields by means of Karhunen-loeve 
% expansion. Comput. Methos Appl. Mech. Engrg. 271, 109–129.
%
% INPUT:
%   - Domain: Domain of definition of the random field
%   - Mesh: Discretization mesh where the random field is represented (i.e.
%   when sampling from it)
%   - Corr: Options for the correlation matrix (family, length, etc.)
%   - ExpOrder: expansion order (Keep it empty if it is to be estimated
%   here)
%   - Energyratio: Threshold of the energy ratio to derive the expansion
%   order
%   - options: Quadrature options
%
% OUTPUT:
% Struct RF with the followin fields:
%   - Eigs: Eigenvalues of the correlation matrixc
%   - Phi: Corresponding eigenvectors
%   - ExpOrder: Expansion order (when it is calculated within this
%   function)
%   - TraceCorr: Trace of the correlation matrix - used to compute the sum
%   of eigenvalues.
%

% Compute the correlation matrix on the coordinates of the expansion (Gramm Matrix)
RF.KL.Corr = uq_eval_Kernel(Mesh, Mesh, Corr.Length, Corr) ;

% % Compute the cross-correlation matrix
% RF.KL.RhovV = uq_eval_Kernel(Mesh, Coor, Corr.Length, Corr) ;

% % Compute matrix A = W^(1/2) (See [1,2])
% n = size(w,1) ;
% A = spdiags(sqrt(w),0,n,n) ;
% % Compute the matrix to be eigen-decomposed B = A * Cov * A ;
% B = A * RF.KL.Corr * A ;
% B = (B+B')/2 ; % Make B perfectly symmetric

%% Perform spectral decomposition
% Define a starting point for the definition of the eigenvalues
MaxOrder = size(RF.KL.Corr, 1) ;

if ~isempty(ExpOrder)
    
    %  The expansion order is already known
    [V,D,eigflag] = eigs(RF.KL.Corr , ExpOrder, 'lm');
    
    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end
    
else
    
    % The expansion order is not known - Compute it according to the
    % truncation ration
    [Vfull,Dfull,eigflag] = eigs(RF.KL.Corr , MaxOrder, 'lm');
    
    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end
       
    % Calculate the cumulated energy ratio
    cumulated_eigs = cumsum(abs(diag(Dfull)))/sum(abs(diag(Dfull))) ;
    
    % Find the order from which the energy ratio is larger than the
    % threshold
    tmp = find(cumulated_eigs >= EnergyRatio) ;
    if isempty(tmp)
        warning('The eigenvalue ratio threshold of %.2f could not be reached with the current covariance mesh!', EnergyRatio);
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
    
%% Post-processeing : Re-interpolation on the discretization mesh ( See
%% Eq. 18 in [2])

% Get the eigenvalues
eigval = abs(diag(D)) ;

% Get the eigenvector of the original problem ( In [2]: y = W^{-1/2} *
% ystar )
eigvect = V ;

% Normalize here...

% % Apply Nystrom interpolation
% eigvect = (RF.KL.RhovV * (repmat(sqrt(w),1,ExpOrder).*V))./repmat(eigval',size(Mesh,1),1) ;
% 
% % Make sure the eigenvectors are normalized (Not necessary but may help
% % avoid some numerical issues) - In [2] this is the normalization with the
% % integral computed using the data from the previous Gauss quadrature
% normalizing_const = sqrt(sum(repmat(w,1,ExpOrder).*eigvect_original.*eigvect_original,1)) ;
% eigvect = eigvect ./ repmat(normalizing_const,size(eigvect,1),1) ;

% Collect the results for the output of the function
RF.Eigs = eigval ;
RF.Phi = eigvect ;

% Return the trace of the correlation matrix (will be used to display the
% cumulated eigenvalue ratio) ;
RF.TraceCorr = trace(RF.KL.Corr) ;

end