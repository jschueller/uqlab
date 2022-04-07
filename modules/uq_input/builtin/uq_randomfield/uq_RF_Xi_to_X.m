function X = uq_RF_Xi_to_X(input,xi)
% UQ_RF_XI_TO_X: transforms the random variables xi into random field
% trajectories
% INPUT:
%   - input: Random field input object
%   - xi: random variables of size N x M, where N is the number of
%   realizations and M is the expansion order of the random field defined
%   in input
% OUTPUT:
%   - X: Random field trajectories of size N x m, where m is the size of
%   the discretization size of the mesh defined in the random field input


% Number of samples
N = size(xi,1) ;

% Gather the options of te random field
Options = input.Internal ;

% Update the size of the mean and standard deviation vectors
if ~isempty(Options.RFData)
    % Conditional data
    switch lower(Options.DiscScheme)
        case 'kl'
            UpdateMean=repmat(Options.Mean, 1, size([Options.Mesh; Options.RFData.X],1));
            UpdateStd=repmat(Options.Std, 1, size([Options.Mesh; Options.RFData.X],1));
            
        case 'eole'
            UpdateMean=repmat(Options.Mean, 1, size([Options.Mesh; Options.RFData.X],1));
            UpdateStd=repmat(Options.Std, 1, size([Options.Mesh; Options.RFData.X],1));
            
    end
    
else
    % Non-Conditional data
    UpdateMean = repmat(Options.Mean, 1, size(Options.Mesh,1)) ;
    UpdateStd = repmat(Options.Std, 1, size(Options.Mesh,1)) ;
end


switch lower(Options.DiscScheme)
    case 'kl'
        
        % No conditional data
        if isempty(Options.RFData)
            
            X = repmat(UpdateMean, N, 1) + repmat(UpdateStd, N, 1).* ...
                ( ( Options.RF.Phi * diag( sqrt(Options.RF.Eigs) ) ) * xi' )' ;
            
            
        else
            % Conditional data
            
            SamplecRF = repmat(UpdateMean, N, 1) + repmat(UpdateStd, N, 1).* ...
                ( ( Options.RF.Phi * diag( sqrt(Options.RF.Eigs) ) ) * xi' )' ;
            
            idx = length(Options.Mesh);
            X = SamplecRF(:,1 : idx) +  (repmat(Options.RFData.Y,1,N)' - SamplecRF(:,idx+1:end)) *Options.RF.KL.CondWeight(1:idx,:)';
            
        end
        
    case 'eole'
        
        if isempty(Options.RFData) % Non conditional
            
            Sample = (Options.RF.EOLE.Rho_vV * Options.RF.Phi) ./ repmat(sqrt(Options.RF.Eigs)',size(Options.Mesh,1),1) ;
            X =  xi * Sample' .* repmat(UpdateStd, N, 1) + repmat(UpdateMean, N, 1) ;
            
        else % Conditional
            
            Sample = (Options.RF.EOLE.Rho_vV * Options.RF.Phi) ./ repmat( sqrt(Options.RF.Eigs)', size([Options.Mesh; Options.RFData.X],1), 1 ) ;
            SamplecRF =  xi * Sample'.* repmat(UpdateStd, N, 1) + repmat(UpdateMean, N, 1) ;
            idx = length(Options.Mesh);
            X = SamplecRF(:,1 : idx) +  (repmat(Options.RFData.Y,1,N)' - SamplecRF(:,idx+1:end)) *Options.RF.EOLE.CondWeight';
            
        end
        
    otherwise
        
        error('Undefined discretization scheme!');
        
end
end