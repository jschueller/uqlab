function pass = uq_Dispatcher_testObject(DispatcherObj)

%% Initialize the test
if nargin < 1
    DispatcherObj = uq_getDispatcher;
end

pass = false;

DispatcherObj.Internal.Display = 0;
DispatcherObj.LocalStagingLocation = fullfile(...
    uq_rootPath, 'modules', 'uq_dispatcher', 'builtin',...
    'uq_default_dispatcher', 'tests');

%% Define the test names
TestNames = {...
    'uq_Dispatcher_tests_usage_cancelJob',...
    'uq_Dispatcher_tests_usage_deleteJob',...
    'uq_Dispatcher_tests_usage_Basic',...
    'uq_Dispatcher_tests_usage_MapBasic',...
    'uq_Dispatcher_tests_usage_MapCustomFun',...
    'uq_Dispatcher_tests_usage_MapUQLabFun',...
    'uq_Dispatcher_tests_usage_MapAnonFun',...
    'uq_Dispatcher_tests_usage_MapMultiOutFun',...
    'uq_Dispatcher_tests_usage_MapParams',...
    'uq_Dispatcher_tests_usage_MapSeqGen',...
    'uq_Dispatcher_tests_usage_MapUQLabSavedSession',...
    'uq_Dispatcher_tests_usage_UQLinkBasicWithMATLAB',...
    'uq_Dispatcher_tests_usage_UQLinkBasicWithoutMATLAB',...
    'uq_Dispatcher_tests_usage_DefModelMultiOutArgs',...
    'uq_Dispatcher_tests_usage_PCEMultiOutArgs',...
    'uq_Dispatcher_tests_usage_KrigingMultiOutArgs',...
    'uq_Dispatcher_tests_usage_PCKMultiOutArgs',...
    'uq_Dispatcher_tests_usage_SVCMultiOutArgs',...
    'uq_Dispatcher_tests_usage_UQLinkMultiOutArgs',...
    'uq_Dispatcher_tests_usage_UQLinkCommandOpts',...
    'uq_Dispatcher_tests_usage_UQLinkImpOut',...
    'uq_Dispatcher_tests_usage_UQLinkInpOut',...
    'uq_Dispatcher_tests_usage_UQLinkMultiInp',...
    'uq_Dispatcher_tests_usage_UQLinkMultiInpOpts',...
    'uq_Dispatcher_tests_usage_UQLinkMultiOutFiles'};

%% Execute each test
success = zeros(length(TestNames),1);
Times = zeros(length(TestNames),1);
TestTimer = tic;
Tprev = 0;
for iTest = 1 : length(TestNames)
    % obtain the function handle of current test from its name
    testFuncHandle = str2func(TestNames{iTest});
    % run test
    success(iTest) = testFuncHandle(DispatcherObj);
    % calculate the time required from the current test to execute
    Times(iTest) = toc(TestTimer) - Tprev;
    Tprev = Tprev + Times(iTest);
end

%% Print out the results in a table
Result = {'ERROR','OK'};
ResultChar = 60; % Character where the result of test is displayed
MinusLine(1:ResultChar+7) = deal('-');

fprintf('\n%s\n',MinusLine);
fprintf('UQ_TESTOBJECT_UQ_DISPATCHER RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:length(success)
    points(1:max(2,ResultChar-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',...
        TestNames{ii}, points, Result{success(ii)+1}, Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);

%% Print the results of all tests
if all(success)
    pass = true;
    fprintf('\nSUCCESS: Dispatcher module usage tests were successful.\n');
end

end
