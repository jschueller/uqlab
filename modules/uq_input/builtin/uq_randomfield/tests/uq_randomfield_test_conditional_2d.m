function pass = uq_randomfield_test_conditional_2d( level )
% PASS = uq_RF_exponential_1D: test for 1D gaussian analytical function
% .

eps = 1e-6;
RFMethods = {'KL','EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');

rng(1) ;
%% INPUT
% values taken from the default phimecasoft example
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian'; 
RFInput.Corr.Family='exponential';
RFInput.RFData.X = [-.5,0,0.5;-.5,0,0.5]'; 
RFInput.RFData.Y = [-.5,1.0,1.5]'; 
x = linspace(-1,1,20);
y= linspace(-1,1,20);
[X,Y] = meshgrid(x,x);  
RFInput.Mesh= [X(:) Y(:)]; % 2-D mesh 
RFInput.Corr.Length=[0.2,0.5]; 
RFInput.ExpOrder=10; 
RFInput.Std=1;
RFInput.Mean=1;

%% RF module
for ii = 1 : length(RFMethods)
    switch lower(RFMethods{ii})
            case 'kl' 
                RFInput.DiscScheme=RFMethods{ii};
%                 Cond_eigenValue1 = [25.883156507586989  25.300033584434054  18.436214742725230  16.646887135874092  13.755893189879593]';
                Cond_eigenValue1 = [   0.290069717697139   0.241947157024663   0.187848658550037   0.161990273012734   0.141597370019599] ;

            case 'eole' 
                RFInput.DiscScheme=RFMethods{ii};
                Cond_eigenValue1 = 100*[1.048392434254155   0.836422337513948   0.607075390717444   0.491675203527355   0.419920961502328]';
    end 
                
   evalc('myRF = uq_createInput(RFInput)');
%% Validation: Test the eigenvalues
Cond_eigenValue = myRF.RF.Eigs(1:5); % a test for the eigenvalues
pass = pass & ( max(abs(Cond_eigenValue - Cond_eigenValue1)) < eps ) ;

end