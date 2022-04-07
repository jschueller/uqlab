function RF = uq_createRF( current_input )
% UQ_CREATERF: Discretizes a random field using either KL or EOLE methods


% Retrieve the options that were initialized previously
Options = current_input.Internal ;

% Domain of the decomposition
Domain = current_input.Internal.Domain ;

% Mesh used for the representation (sampling) of the RF
Mesh = current_input.Internal.Mesh ;

% Coordinates where the correlation matrix is constructed
Coor = current_input.Internal.CovMesh ;

% Expansion order
ExpOrder = current_input.Internal.ExpOrder ;

% Energy ratio
EnergyRatio = current_input.Internal.EnergyRatio ;

% Properties of the correlation matrix (family, isotropy,
% length)
Corr = current_input.Internal.Corr ;

% Correlation length
CorrLength = Corr.Length ;

% Observations, if any
Data = current_input.Internal.RFData ;
    
if isempty(Data)
    % Unconditional random fields
    
    switch lower( Options.DiscScheme )
        case   'kl'
            switch lower(Options.KL.Method)
                
                case 'analytical'
                    
                    % Compute the eigen-values and -vectors analytically
                    RF  =  uq_KL_analytical(Domain, Mesh, CorrLength, ExpOrder, EnergyRatio);
                    
                case 'nystrom'
                    
                    % Options specific to Nystrom: Quadrature type and
                    % levels (number of samples)
                    opts = current_input.Internal.KL ;
                    
                    RF = uq_KL_Nystrom(Domain, Mesh, Corr, ExpOrder, EnergyRatio, opts) ;
                    
                case {'discrete','pca'}
                    
                    RF = uq_KL_Discrete(Mesh, Corr, ExpOrder, EnergyRatio) ;
                  
            end
            
            % Normalized variance error: Note that this is only valid if
            % the variance of the process is constant over the
            % discretization domain! (which is the case for v2.0)
            RF.VarError = ( ones(1,size(RF.Phi,1)) ...
                - sum( RF.Phi.^2 * diag(RF.Eigs) , 2 )' ) ;
            
        case 'eole'
        
            % Compute the eigenvalues and eigenvectors of the random field
            RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio) ;
            
            % Normalized variance error:
            % Note that:
            % 1. this is only valid if the variance of the process is
            % constant over the discretization domain!
            % 2. this is not equal to Eq. (2.66) of Sudret & Der Kiereghian
            % (2000) as it is normalized by the process variance: In the
            % second part of the equation, the eigenvalues and
            % eigenfunctions are obtained using the correlation matrix and
            % not the covariance matrix so the normalization is already,
            % hence only the first term is divided by sigma^2 (w.r.t. Eq.
            % 2.66 )
            RF.VarError = ones(1,size(Mesh,1)) - ...
                sum( repmat(1./RF.Eigs,1,size(Mesh,1)) ...
                .* (RF.Phi' * RF.EOLE.Rho_vV').^2,1 ) ;
            
    end
    
else
    % Conditional random fields
          
    switch lower(Options.DiscScheme)
        case   'kl'
            
            switch lower(Options.KL.Method)
                
                case 'analytical'

                    % Extend the mesh to account for the location of
                    % the observations
                    Mesh = [Mesh; Data.X] ;
                   
                    % Compute the eigen-values and -vectors analytically
                    RF  =  uq_KL_analytical(Domain, Mesh, CorrLength, ExpOrder, EnergyRatio);
                    
                case 'nystrom'

                    % Extend the mesh to account for the location of
                    % the observations
                    Mesh = [Mesh; Data.X] ;
            
                    % Options specific to Nystrom: Quadrature type and
                    % levels
                    opts = current_input.Internal.KL ;
                    
                    RF = uq_KL_Nystrom(Domain, Mesh, Corr, ExpOrder, EnergyRatio, opts) ;

                case {'discrete','pca'}
                    
                    % Extend the mesh to account for the location of
                    % the observations
                    Mesh = [Mesh; Data.X] ;
                    
                    RF = uq_KL_Discrete(Mesh, Corr, ExpOrder, EnergyRatio) ;
   
            end
            

            %% Compute the correlation matrices using the observations (to condition on)
            % Compute the correlation matrix between samples that are known
            Corr_XX = uq_eval_Kernel(Data.X , Data.X, Corr.Length, Corr) ;
            
            % Compute the correlatio matrix between conditionned samples and mesh
            RF.KL.Corr_HX = uq_eval_Kernel(Mesh , Data.X, Corr.Length, Corr) ;

            % Get the conditional weights
            RF.KL.CondWeight= RF.KL.Corr_HX/Corr_XX ;
            RF.KL.Corr_XX = Corr_XX ;
            
            
            % Normalized variance error: Note that this is only valid if
            % the variance of the process is constant over the
            % discretization domain!!!!
            RF.VarError = ( ones(1,size(RF.Phi,1)) ...
                - sum( RF.Phi.^2 * diag(RF.Eigs) , 2 )' ) ;
            
        case 'eole'
            
            %% Compute the correlation matrix C_{H(x),XGrid} - This should go in initialization

            Coor = current_input.Internal.CovMesh ;
            Mesh = current_input.Internal.Mesh ;
            ExpOrder = current_input.Internal.ExpOrder ;
            Corr = current_input.Internal.Corr ;
            Data = current_input.Internal.RFData ;
            RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio, Data) ;
            
            RF.VarError = current_input.Internal.Std.^2 * ...
                ( ones(1,size(Mesh,1)) - sum( ( ( RF.EOLE.Rho_vV(1:size(Mesh,1),:) * RF.Phi) ./ repmat(sqrt(RF.Eigs)',size(Mesh,1),1)).^2',1 )) ;
            
    end
    
    
end

%%
% Add the expansion order to the RF field, if it was not given
if ~isempty(ExpOrder)
    RF.ExpOrder = ExpOrder ;
end
% Create a unique variable containing the mesh actually used to compute the
% covariance matrix
if ~isempty(current_input.Internal.RFData)
    if strcmpi(Options.DiscScheme,'kl')
        RF.CovMesh = [current_input.Internal.Mesh ; current_input.Internal.RFData.X]  ;
    else % EOLE
        RF.CovMesh = [current_input.Internal.CovMesh;  current_input.Internal.RFData.X] ;
    end  
else
    if strcmpi(Options.DiscScheme,'kl') & strcmpi(Options.KL.Method, 'nystrom')
        % In case of Nystrom, the eigenvectors are interpolated to the actual
        % mesh
        RF.CovMesh = current_input.Internal.Mesh ;
    else
        RF.CovMesh = current_input.Internal.CovMesh ;
    end
end

if ~isempty(current_input.Internal.RFData)
    
    switch lower( Options.DiscScheme )
        case 'kl'
            RF.CondWeight = RF.KL.CondWeight ;
        case 'eole'
            RF.CondWeight = RF.EOLE.CondWeight ;
    end
end
% Build the standard Gaussian input object corresponding to the reduced
% space
for ii = 1:RF.ExpOrder
    InputOpts.Marginals(ii).Type = 'Gaussian' ;
    InputOpts.Marginals(ii).Name = sprintf('X%02u',ii);
    InputOpts.Marginals(ii).Parameters = [0,1] ;
end
current_input.Internal.UnderlyingGaussian = uq_createInput(InputOpts,'-private') ;

end