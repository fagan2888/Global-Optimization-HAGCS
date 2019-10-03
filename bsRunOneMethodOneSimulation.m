function [xOut, funVal, exitFlag, OUTPUT] = bsRunOneMethodOneSimulation(objFunc, methodName, parameters, ...
    lower, upper, ...
    optimalFunctionTolerance, maxIter, minFVal, maxFevs, ...
    isSaveMiddleRes, isSaveDetailUpdates)
%% optimize the objective function for one method
% this script will be used in 
% testCompareMethodsFinal.m
% testLargeScale.m
% and showAnimation.m

    nDim = length(lower);
    
    % obtain the number of initial population size
    if isa(parameters{1},'function_handle')
        nInitNest = parameters{1}(nDim);
    else
        nInitNest = parameters{1};
    end

    switch methodName
        % test different methods

        case 'CS'
            % Cuckoo search algorithm
            pa = parameters{2};
            alpha = parameters{3};
            initialPopFcn = parameters{4};
            CSObjFunc = @(x)(objFunc(x, 0));    % CS algorithm doesn't need the gradient information

            [xOut, funVal, exitFlag, OUTPUT] = bsCSByYangAndDeb2009(CSObjFunc, lower, upper, ...
                'nNest', nInitNest, ...
                'pa', pa, ...
                'alpha', alpha, ...
                'initialPopulationFcn', initialPopFcn,...
                'optimalFunctionTolerance', optimalFunctionTolerance, ...
                'maxIter', maxIter, ...
                'optimalF', minFVal, ...
                'isSaveMiddleRes', isSaveMiddleRes, ...
                'isSaveDetailUpdates', isSaveDetailUpdates, ...
                'maxFunctionEvaluations', maxFevs);
        case 'GBCS'
            % gradient-based cuckoo search algorithm
            pa = parameters{2};
            alpha = parameters{3};
            initialPopFcn = parameters{4};

            [xOut, funVal, exitFlag, OUTPUT] = bsGBCSByFateen2014(objFunc, lower, upper, ...
                'nNest', nInitNest, ...
                'pa', pa, ...
                'alpha', alpha, ...
                'initialPopulationFcn', initialPopFcn,...
                'optimalFunctionTolerance', optimalFunctionTolerance, ...
                'maxIter', maxIter, ...
                'optimalF', minFVal, ...
                'isSaveMiddleRes', isSaveMiddleRes, ...
                'isSaveDetailUpdates', isSaveDetailUpdates, ...
                'maxFunctionEvaluations', maxFevs);

        case 'AGBCS'
            % advanced gradient-based cuckoo search
            pa = parameters{2};
            alpha = parameters{3};
            initialPopFcn = parameters{4};
            interval = parameters{5};
            innerMaxIter = parameters{6};

            [xOut, funVal, exitFlag, OUTPUT] = bsHGBCSByShe2019(objFunc, lower, upper, ...
                'nNest', nInitNest, ...
                'pa', pa, ...
                'alpha', alpha, ...
                'initialPopulationFcn', initialPopFcn,...
                'interval', interval, ...
                'innerMaxIter', innerMaxIter,...
                'optimalFunctionTolerance', optimalFunctionTolerance, ...
                'maxIter', maxIter, ...
                'optimalF', minFVal, ...
                'isSaveMiddleRes', isSaveMiddleRes, ...
                'isSaveDetailUpdates', isSaveDetailUpdates, ...
                'maxFunctionEvaluations', maxFevs);

        case 'AHSACS'
            % advanced hybrid self-adpatation cuckoo search 
            maxNest = nInitNest;
            minNest = parameters{2};
            
            % obtain the size of history 
            if isa(parameters{1},'function_handle')
                nHistory = parameters{3}(nDim);
            else
                nHistory = parameters{3};
            end
    %                         
            initialPopFcn = parameters{4};
    % 
            [xOut, funVal, exitFlag, OUTPUT] = bsAHSACSByShe2019(objFunc, lower, upper, ...
                'maxNests', maxNest, ...
                'minNests', minNest,...
                'nHistory', nHistory, ...
                'initialPopulationFcn', initialPopFcn,...
                'optimalFunctionTolerance', optimalFunctionTolerance, ...
                'maxIter', maxIter, ...
                'optimalF', minFVal, ...
                'isSaveMiddleRes', isSaveMiddleRes, ...
                'isSaveDetailUpdates', isSaveDetailUpdates, ...
                'maxFunctionEvaluations', maxFevs);

        case 'HAGCS'
            % Our proposed method: hybrid self-adaptation gradient-based cuckoo search algorithm
            minNest = parameters{2};
%             nHistory = parameters{3};
            initialPopFcn = parameters{4};
            interval = parameters{5};
            innerMaxIter = parameters{6};

            % obtain the size of history 
            if isa(parameters{1},'function_handle')
                nHistory = parameters{3}(nDim);
            else
                nHistory = parameters{3};
            end
            
            [xOut, funVal, exitFlag, OUTPUT] = bsHAGCSByShe2019(objFunc, lower, upper, ...
                'maxNests', nInitNest, ...
                'minNests', minNest,...
                'nHistory', nHistory, ...
                'display', 'off', ...
                'initialPopulationFcn', initialPopFcn,...
                'interval', interval, ...
                'innerMaxIter', innerMaxIter,...
                'optimalFunctionTolerance', optimalFunctionTolerance, ...
                'maxIter', maxIter, ...
                'optimalF', minFVal, ...
                'isSaveMiddleRes', isSaveMiddleRes, ...
                'isSaveDetailUpdates', isSaveDetailUpdates, ...
                'maxFunctionEvaluations', maxFevs);


        case 'PSO'
            % particle swarm optimization 
            PSOObjFunc = @(x)(objFunc(x', 0));

            psoOpts = optimoptions('particleswarm', ...
                'MaxIterations', round(maxFevs/nInitNest)+1, ...
                'ObjectiveLimit', minFVal+optimalFunctionTolerance,...
                'FunctionTolerance', 1e-100,...
                'OutputFcn', @(x, y)bsPSOOutFcn(x, y, minFVal, optimalFunctionTolerance),...
                'SwarmSize', nInitNest);

            [xOut, funVal, ~, OUTPUT] = particleswarm(PSOObjFunc, nDim, lower, upper, psoOpts);

            OUTPUT.funcCount = OUTPUT.funccount;

        case 'GA'
            % genetic algorithm
            GAObjFunc = @(x)(objFunc(x', 0));

            gaOpts = optimoptions('ga', 'FitnessLimit', minFVal+optimalFunctionTolerance, ...
                'MaxGenerations', round(maxFevs/nInitNest)+1, ...
                'FunctionTolerance', 1e-100,...
                'OutputFcn', @(x, y, z)bsGAOutFcn(x, y, z, minFVal, optimalFunctionTolerance), ...
                'PopulationSize', nInitNest);

            [xOut, funVal, ~, OUTPUT] = ga(GAObjFunc, nDim, [], [], [], [], lower, upper, [], [], gaOpts);

            OUTPUT.iterations = OUTPUT.generations;
            OUTPUT.funcCount = OUTPUT.funccount;

    %                     case 'MCS'
    %                         pa = parameters{2};
    %                         minNests = parameters{3};
    %                         
    %                         A = parameters{4};
    %                         nesD = parameters{5};
    %                         initialPopFcn = parameters{6};
    %                         
    %                         CSObjFunc = @(x)(objFunc(x, 0));
    %                         
    %                         [xOut, funVal, exitFlag, OUTPUT] = bsMCSByWalton2011(CSObjFunc, lower, upper, ...
    %                             'nNest', nInitNest, ...
    %                             'initialPopulationFcn', initialPopFcn,...
    %                             'minNests', minNests,...
    %                             'nesD', nesD, ...
    %                             'optimalFunctionTolerance', optimalFunctionTolerance, ...
    %                             'maxIter', maxIter, ...
    %                             'optimalF', minFVal, ...
    %                             'isSaveMiddleRes', true, ...
    %                             'maxFunctionEvaluations', maxFevs);

    %                     case 'HSACS_Mlakar'
    %                         minNest = parameters{2};
    %                         nHistory = parameters{3};
    % %                         
    %                         initialPopFcn = parameters{4};
    % % 
    %                         [xOut, funVal, exitFlag, OUTPUT] = bsHSACSByMlakar2016(objFunc, lower, upper, ...
    %                             'maxNests', nInitNest, ...
    %                             'minNests', minNest,...
    %                             'nHistory', nHistory, ...
    %                             'initialPopulationFcn', initialPopFcn,...
    %                             'optimalFunctionTolerance', optimalFunctionTolerance, ...
    %                             'maxIter', maxIter, ...
    %                             'optimalF', minFVal, ...
    %                             'isSaveMiddleRes', true, ...
    %                             'maxFunctionEvaluations', maxFevs);

    end
end