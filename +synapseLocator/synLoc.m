classdef synLoc < handle & synapseLocator.EventData
    %synLoc class
    %   synLoc class handles data from Synapse Locator GUI
    %
    % MATLAB Version: 9.1.0.441655 (R2016b)
    % MATLAB Version: 9.5.0.944444 (R2018b)
    %
    %
    % drchrisch@gmail.com
    %
    % cs10sep2018
    % cs12dec2018
    %
    
    % General
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        % Files
        synapseLocatorFolder = [];
        
        dataInputPath = [];
        dataOutputPath = [];
        dataFile_1 = [];
        dataFile_2 = [];
        
        initialTransformParametersFile = [];

        elastixDataDir = 'elastix';
        tmpImagesDir = 'tmpImages';
        featureDataBaseDir = 'featureData';
        featureDataDir = [];        
        
        wekaModelsFolder = [];
        
        % Data
        data = struct('G0', [], 'R0', [], 'G1', [], 'R1', [], ...
            'spotModel_model', [], 'spotModel_data', [], ...
            'signalModel_G0', [], 'signalModel_G0_model', [], ...
            'signalModel_generic', [], 'signalModel_generic_model', [], ...
            'spot_classProbs', [], 'spot_classProbsStack', [], 'spot_predicted', [], 'spot_predictedStack', []);

        % Internal stuff
        internalStuff = struct('elastixCheckerTimer', [], 'elastixPID', [], 'cmdPID', [], ...
            'preProParamsChanged', [], 'elastixParamsChanged', [], 'locatorParamsChanged', []);
    end
        
    % Input processing
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        leadingChannel = [];
        loadRegisteredImages = [];
        initialTransform = [];        
        medianFilter = [];
        medianFilterParams = [];
        gaussianSmooth = [];
        gaussianSmoothParams = [];
        bandpassFilter = [];
        bandpassFilterParams = [];
        subtractBackground = [];
        subtractBackgroundParams = [];
        deconvolve = [];
        deconvolveParams = [];
        deconvolveParams_PSF = [];
        
        filterImages = [];
        
        sum2 = [];
        upsampling = [];

        imgSize = [];
        vxlSize = [];
    end
        
    % Output processing
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        dRG0Threshold = []; % Threshold for reporting labels
        excludeSpotsAtEdges = []; % Exclude spots centered at image stack boundary
        
        summaryFields = [];
        summaryTemplate = [];
        summaryTableFields = [];
        summaryTableTemplate = [];
        synapseLocatorSummary = [];
        synapseLocatorSummary_mf = [];
        synapseLocatorSummary_raw = [];
        transformRawData = [];
        resultSaved = 0;
        compositeTif = [];
    end
            
    % elastix
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        data1OtsuThreshold = [];
        data2OtsuThreshold = [];
        data1Threshold = [];
        data2Threshold = [];
        initialTransformParams = [];

        register_CMD = [];
        transformation_CMD = [];
        apparentSimilarity = [];
        markerDensity = [];
    end
    
    % ImageJ
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        IJ_exe = [];
        IJMacrosFolder = [];
        preprocessMacro = [];
        scaleMacro = [];
        featureMakerMacro = []; 
        featureMakerSignalChannelMacro = []; 
        gatherOutputMacro = [];
    end

    % Synapse Locator figure handles
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        sLFigH = []; % synapseLocator figure handles!
        imageAxesH = []; % synapseLocator image axes handles!
        sliderLevelH = []; % slider level handle
        sliderTextH = []; % slider text handle
        statusTextH = []; % Synapse Locator Status text field handle
        displayChannel = [];
        synapseLocatorSummaryTableH = [];
        modelTextH = [];
    end
    
    % Synapse Locator parameters
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        genericSpotModel = []; % Just the name
        
        g0_threshold = [];
        g1_threshold = [];
        
        histogramN = [];
        zRange = [0, 1];
        zLevel = [];
        class1_roi = {};
        class2_roi = {};
        spotSizeMin = [];
        spotSizeMax = [];
        avgSpotSize = [];
        bwconncompValue = [];                        
        spotSpecificity = [];
        signalSpecificity = [];
                                
        preTransformationMatch = [];
        postTransformationMatch = [];
    end
    
    % Synapse Locator feature parameters
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        featureNames = [];
        featureNames_signalChannel = [];
        featureNames_model = [];
    end
    
    % Synapse Locator registration parameters
    properties (GetAccess=public, SetAccess=public, SetObservable=true)
        elastixFolder = [];
        elastixParamsFolder = [];
        elastixParams = [];
        elastixParamsSet = [];
        registrationRunMode = [];
        FGSIV = [];
        FBSIO = [];
        resolutionsN = [];
    end
    
    % Listeners
    properties (GetAccess=private, SetAccess=private)
        load2ChannelTif_listener        
        run_listener
        
        addROI_listener
        deleteROI_listener
        clearROIs_listener
        
        trainClassifier_listener
        loadModel_listener
        saveModel_listener
        clearModel_listener
        modelQuality_listener
        featureStats_listener
        
        saveResults_listener
    end
    
    % Events
    events
        load2ChannelTif        
        run
        
        addROI
        deleteROI
        clearROIs
        
        trainClassifier
        loadModel
        saveModel
        clearModel
        modelQuality
        featureStats

        saveResults
    end
    
    % Object definitions
    methods
        % Start synapseLocator object!
        function obj = synLoc()
            obj.load2ChannelTif_listener = addlistener(obj, 'load2ChannelTif', @(src, evnt) load2ChannelTif_Fcn(src, evnt));
            obj.run_listener = addlistener(obj, 'run', @(src, evnt) run_Fcn(src, evnt));

            obj.addROI_listener = addlistener(obj, 'addROI', @(src, evnt) addROI_Fcn(src, evnt));
            obj.deleteROI_listener = addlistener(obj, 'deleteROI', @(src, evnt) deleteROI_Fcn(src, evnt));
            obj.clearROIs_listener = addlistener(obj, 'clearROIs', @(src, evnt) clearROIs_Fcn(src, evnt));
            
            obj.trainClassifier_listener = addlistener(obj, 'trainClassifier', @(src, evnt) trainClassifier_Fcn(src, evnt));
            obj.loadModel_listener = addlistener(obj, 'loadModel', @(src, evnt) loadModel_Fcn(src, evnt));
            obj.saveModel_listener = addlistener(obj, 'saveModel', @(src, evnt) saveModel_Fcn(src, evnt));
            obj.clearModel_listener = addlistener(obj, 'clearModel', @(src, evnt) clearModel_Fcn(src, evnt));
            obj.modelQuality_listener = addlistener(obj, 'modelQuality', @(src, evnt) modelQuality_Fcn(src, evnt));
            obj.featureStats_listener = addlistener(obj, 'featureStats', @(src, evnt) featureStats_Fcn(src, evnt));
            
            obj.saveResults_listener = addlistener(obj, 'saveResults', @(src, evnt) saveResults_Fcn(src, evnt));
        end
    end
    
    % Methods to perform data handling and processing
    methods
        function load2ChannelTif_Fcn(obj, evnt)
            % Get file name and load tif data! Must be 2-channel interleaved image stack!
            % It is advised to use at least a somewhat filtered input (='MedianFilter' option) but deconvolution is advised (='Deconvolve' option)!
            % A Fiji macro is called to generate both '...mf.tif' and '...deconv.tif' file!
            % Chose 'normal' file as input, Synapse Locator silently uses the 'best' filtered data for
            % processing (preferably 'deconv').
            
            % Check if preprocessing of already loaded data is required!
            if strcmp(evnt.someData, 'elastix')
                % Check image dimensions and filter settings!
                preprocessParamsChecker_Fcn(obj)
                % Clear already calculated features!
                obj.featureNames_signalChannel = [];
                % Start preprocess macro!
                [imagejSettings, ijRunMode] = obj.imageJChecker();
                ijArgs = strjoin({...
                    obj.dataFile_1, obj.dataFile_2, ...
                    fullfile(obj.dataOutputPath, obj.tmpImagesDir), ...
                    ijRunMode, ...
                    num2str(obj.medianFilter), num2str(obj.bandpassFilter), num2str(obj.subtractBackground), num2str(obj.deconvolve), ...
                    num2str(obj.medianFilterParams), num2str(obj.gaussianSmoothParams), num2str(obj.bandpassFilterParams), num2str(obj.subtractBackgroundParams), ...
                    num2str(obj.deconvolveParams_PSF), num2str(obj.deconvolveParams), ...
                    num2str(obj.vxlSize)},',');
                CMD = sprintf('"%s" %s "%s" "%s"', obj.IJ_exe, imagejSettings, fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.preprocessMacro), ijArgs);
                [status, result] = system(CMD); %#ok<ASGLU>
            else
                set(findobj(obj.sLFigH, 'Tag', 'data1Threshold_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'data1ThresholdSuggestion_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'data2Threshold_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'data2ThresholdSuggestion_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'g0_threshold_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'g0_thresholdSuggestion_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'g1_threshold_edit'), 'String', '')
                set(findobj(obj.sLFigH, 'Tag', 'g1_thresholdSuggestion_edit'), 'String', '')
                drawnow

                for idx = 1:2
                    status = getFileName(obj, idx);
                    if ~status
                        errordlg('Error during load file!', 'Data Loading Error Message');
                        return
                    end
                end
                
                % Ask for output directory!
                [status] = setResultPath(obj);
                if ~status
                    errordlg('Error in making output folder!', 'Data Output Directory Error Message');
                    return
                end
                
                % Ask for existing feature folder! Loads features if selected!
                getExistingFeatures(obj);                
                
                obj.statusTextH.String = 'Loading images...';
                drawnow
                
                % Choose between new images (processing needed), already
                % transformed images (no further input processing), and
                % user supplied processed images (must have '*_deconv.tif' filename)!

                % Check if data were already registered!
                if obj.loadRegisteredImages
                    % Great, take files as is! No preprocessing!
                else
                    if ~obj.filterImages
                        % User does not want preprocessing or did it
                        % already. Look for '*_deconv.tif' filename in input folder!
                        tifFiles = inputDirChecker(obj);
                        if all(arrayfun(@(x) ischar(tifFiles(x).deconv), 1:2, 'Uni', 1))
                            % Great, deconvolution preprocessing was done already!
                            % Just copy raw and 'deconv' files to tmpImages directory!
                            for whichOne = ['1', '2']
                                [~, name_, ~] = fileparts(obj.(['dataFile_', whichOne]));
                                [status, msg, msgID] = copyfile(...
                                    obj.(['dataFile_', whichOne]), ...
                                    fullfile(obj.dataOutputPath, obj.tmpImagesDir, [name_, '_raw.tif'])); %#ok<ASGLU>
                                [status, msg, msgID] = copyfile(...
                                    regexprep(obj.(['dataFile_', whichOne]), '.tif$', '_deconv.tif'), ...
                                    fullfile(obj.dataOutputPath, obj.tmpImagesDir, [name_, '_proc.tif'])); %#ok<ASGLU>
                            end
                        else
                            % Ok, skip all preprocessing and copy raw files to tmpImages directory!
                            for whichOne = ['1', '2']
                                [~, name_, ~] = fileparts(obj.(['dataFile_', whichOne]));
                                [status, msg, msgID] = copyfile(obj.(['dataFile_', whichOne]), fullfile(obj.dataOutputPath, obj.tmpImagesDir, [name_, '_raw.tif'])); %#ok<ASGLU>
                            end
                        end
                    else
                        % Check image dimensions and filter settings!
                        preprocessParamsChecker_Fcn(obj)

                        % Start preprocessing!
                        % Either median filtered or deconvolved file is missing! Start preprocess macro!
                        [imagejSettings, ijRunMode] = obj.imageJChecker();
                        ijArgs = strjoin({...
                            obj.dataFile_1, obj.dataFile_2, ...
                            fullfile(obj.dataOutputPath, obj.tmpImagesDir), ...
                            ijRunMode, ...
                            num2str(obj.medianFilter), num2str(obj.bandpassFilter), num2str(obj.subtractBackground), num2str(obj.deconvolve), ...
                            num2str(obj.medianFilterParams), num2str(obj.gaussianSmoothParams), num2str(obj.bandpassFilterParams), num2str(obj.subtractBackgroundParams), ...
                            num2str(obj.deconvolveParams_PSF), num2str(obj.deconvolveParams), ...
                            num2str(obj.vxlSize)},',');
                        CMD = sprintf('"%s" %s "%s" "%s"', obj.IJ_exe, imagejSettings, fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.preprocessMacro), ijArgs);
                        [status, result] = system(CMD); %#ok<ASGLU>
                    end
                end
            end
            obj.statusTextH.String = 'Preprocessing finished...';
            drawnow
            
            % Load tif data!
            for idx = {'1', '2'}
                load2ChannelTifFile(obj, idx{:})
            end

            % Get values for z level slider!
            obj.zRange = [1, size(obj.data.([obj.leadingChannel, '1']), 3)];
            
            % Show image if display selected
            if get(findobj(obj.sLFigH, 'Tag', ['display', upper(obj.displayChannel), '_radiobutton']), 'Value')
                % Deactivate zoom in or zoom out button! Set New display limits!
                zoom(findobj(obj.sLFigH, 'Type', 'Axes'), 'off')
                set(findobj(obj.sLFigH, 'Type', 'Axes'), 'XLim', [1, size(obj.data.(obj.displayChannel), 2)]);
                set(findobj(obj.sLFigH, 'Type', 'Axes'), 'YLim', [1, size(obj.data.(obj.displayChannel), 1)])
                
                obj.zLevel = floor(obj.zRange(2) / 2);
                imagesc(obj.imageAxesH, obj.data.(obj.displayChannel)(:,:,obj.zLevel))
                obj.sliderLevelH.Enable = 'off';
                obj.sliderLevelH.Max = obj.zRange(2);
                obj.sliderLevelH.Min = obj.zRange(1);
                obj.sliderLevelH.Value = obj.zLevel;
                obj.sliderLevelH.SliderStep = [1/(obj.zRange(2)), 10/(obj.zRange(2))];
                obj.sliderLevelH.Enable = 'on';
            end
            
            % Check for intial transformation and get values!
            initialTransform_Fcn(obj)
            
            % Suggest thresholds for registration and spot finding!
            max1 = double(max(obj.data.G0(:)));
            [N, ~] = histcounts(obj.data.G0, max1);
            obj.data1OtsuThreshold = otsuthresh(N) * max1;
            tmpThresh1 = round([0.1, 0.25] .* obj.data1OtsuThreshold);
            max2 = double(max(obj.data.G1(:)));
            [N, ~] = histcounts(obj.data.G1, max2);
            obj.data2OtsuThreshold = otsuthresh(N) * max2;
            tmpThresh2 = round([0.1, 0.25] .* obj.data2OtsuThreshold);
            
            % Suggest threshold for registration step!
            obj.data1Threshold = tmpThresh1(1);
            set(findobj(obj.sLFigH, 'Tag', 'data1Threshold_edit'), 'String', sprintf('%i', tmpThresh1(1)))
            set(findobj(obj.sLFigH, 'Tag', 'data1ThresholdSuggestion_edit'), 'String', sprintf('%i', tmpThresh1(1)))
            obj.data2Threshold = tmpThresh2(1);
            set(findobj(obj.sLFigH, 'Tag', 'data2Threshold_edit'), 'String', sprintf('%i', tmpThresh2(1)))
            set(findobj(obj.sLFigH, 'Tag', 'data2ThresholdSuggestion_edit'), 'String', sprintf('%i', tmpThresh2(1)))
            
            % Suggest threshold for spot finding step!
            obj.g0_threshold = tmpThresh1(2);
            set(findobj(obj.sLFigH, 'Tag', 'g0_threshold_edit'), 'String', sprintf('%i', tmpThresh1(2)))
            set(findobj(obj.sLFigH, 'Tag', 'g0_thresholdSuggestion_edit'), 'String', sprintf('%i', tmpThresh1(2)))
            obj.g1_threshold = round(tmpThresh2(2) * 0.1);
            set(findobj(obj.sLFigH, 'Tag', 'g1_threshold_edit'), 'String', sprintf('%i', min([tmpThresh1(2), obj.g1_threshold])))
            set(findobj(obj.sLFigH, 'Tag', 'g1_thresholdSuggestion_edit'), 'String', sprintf('%i', min([tmpThresh1(2), obj.g1_threshold])))
                        
            obj.statusTextH.String = '';
            drawnow
        end
        
        function run_Fcn(obj, evnt)

            % obj.transformation_CMD = [];

            % Start processing! Orchestrate elastix, transformix, feature calculation, and spot localization!
            if any([isempty(obj.data.G0); isempty(obj.data.R0); isempty(obj.data.G1); isempty(obj.data.R1)])
                obj.statusTextH.String = 'NO DATA!';
                drawnow
                pause(1)
                obj.statusTextH.String = '';
                drawnow
                return
            end
            
            set(findobj(obj.sLFigH, 'Tag', 'parameter_togglebutton'), 'BackgroundColor', [1.0, 0.95, 0.95]);

            % Check if data are already registered!
            if obj.loadRegisteredImages || any(contains({'locator'}, evnt.someData))
                % Start segmentation!
                if any([~isempty(obj.internalStuff.locatorParamsChanged); isempty(obj.synapseLocatorSummary.Spot_ID)])
                    segmentationController_Fcn(obj)
                    return
                end
            end
            
            % Check for changed preprocessing params!
            if obj.internalStuff.preProParamsChanged
                load2ChannelTif_Fcn(obj, evnt)
            end
            
            
            % Check if elastix is called!
            if (isempty(obj.register_CMD) && any(contains({'all', 'elastix'}, evnt.someData)))
                obj.internalStuff.preProParamsChanged = [];
                obj.internalStuff.elastixParamsChanged = [];
                % New data, start elastix!
                elastixController_Fcn(obj, evnt)
                return
            end
            
            % Check for changed elastix params, reload data file 2 and re-start elastix!
            if ~isempty(obj.register_CMD) && (~isempty(obj.internalStuff.elastixParamsChanged) || ~isempty(obj.internalStuff.preProParamsChanged)) && any(contains({'all', 'elastix'}, evnt.someData))
                obj.internalStuff.preProParamsChanged = [];
                obj.internalStuff.elastixParamsChanged = [];
                % New round of registration with already loaded data! Ask for (new) output directory!
                % Data are overwritten if no new output directory is
                % wanted. Otherwise, tmpData and featureData are copyed to
                % new directory.
                ok_ = askForNewDir(obj);
                if ~ok_
                    errordlg('Error in making output folder!', 'Data Output Directory Error Message');
                end
                % Load tif data 2!
                load2ChannelTifFile(obj, '2')
                obj.statusTextH.String = 'Register Data (reloading data #2) ...';
                drawnow
                % Start elastix!
                elastixController_Fcn(obj, evnt)
                return
            end
            
            % Check if newly transformed data should be analyzed!
            if any([~isempty(obj.internalStuff.locatorParamsChanged); isempty(obj.synapseLocatorSummary.Spot_ID)]) && ~isempty(obj.register_CMD) && any(contains({'all', 'locator'}, evnt.someData))
                segmentationController_Fcn(obj)
                return
            end            
        end
                
        function loadModel_Fcn(obj, evnt)
            % Load weka model from file! This command will delete existing model data and roi data!
            % Model dataset is also loaded and checked against feature set!
            if ~isempty(evnt.someData) && strcmp(evnt.someData{1}, 'default')
                % Load data from default model path!
                spotModelName_ = [evnt.someData{2}, '.model'];
                spotModelPath_ = fullfile(obj.synapseLocatorFolder, obj.wekaModelsFolder);
            else
                % Load data from user defined model path! Get path!
                [spotModelName_, spotModelPath_, modelSelectSuccess] = getModelName(obj);
                if ~modelSelectSuccess
                    return
                end
                clear modelSelectSuccess
            end

            
            % Load Model!
            spotModel_ = wekaLoadModel(fullfile(spotModelPath_, spotModelName_));
            % Load dataset! Check if it matches feature set!
            [spotModelName_, ~] = strtok(spotModelName_, '.');
            if exist(fullfile(spotModelPath_, [spotModelName_, '_Data.csv']), 'file')
                success = '1';
                spotModelData_ = importdata(fullfile(spotModelPath_, [spotModelName_, '_Data.csv']));
                %spotModelData_ = wekaLoadData(fullfile(spotModelPath_, [spotModelName_, '_Data.csv'])); % ..._Data.csv'
                %[data,attributes,classIndex,stringVals,relationName] = weka2matlab(spotModelData_, [])
                featureNames_model_ = spotModelData_.colheaders(1:end-1)';
                if isempty(obj.featureNames)
                    success = '2';
                else
                    if eq(numel(obj.featureNames), numel(featureNames_model_))
                        if ~all(strcmp(obj.featureNames, featureNames_model_))
                            success = '3';
                        end
                    else
                        success = '4';
                    end
                end
            else
                success = '0';
            end
            
            switch success
                case {'0'}
                    warndlg('No training data found!', 'Data Error');
                case {'1'; '2'}
                    obj.data.spotModel_model = spotModel_;
                    obj.data.spotModel_data = spotModelData_.data;
                    obj.featureNames_model = featureNames_model_;
                case {'3'}
                    warndlg('Model does not match actual feature set!', 'Data Error');
                case {'4'}
                    warndlg('Model features and actual feature set may be different!', 'Data Error');
            end
                        
            switch success
                case {'1'; '2'}
                    % Set file name in GUI
                    fileNameDisplay = fullfile(spotModelPath_, spotModelName_);
                    if gt(numel(fileNameDisplay), 48)
                        fileNameDisplay = ['...', fileNameDisplay(end-47:end)];
                    end
                    obj.modelTextH.String = fileNameDisplay;
                    obj.modelTextH.FontWeight = 'bold';
                    
                    % Check if model is from wekaModels folder and update model list field!
                    if ~isempty(evnt.someData) && strcmp(evnt.someData{1}, 'default')
%                         if strcmp(evnt.someData{1}, 'default')
                        wekaModels = dir(fullfile(obj.synapseLocatorFolder, obj.wekaModelsFolder, '*.model'));
                        wekaModels = {wekaModels(~[wekaModels.isdir]).name};
                        wekaModels = strrep(wekaModels, '.model', '');
                        wekaModels = wekaModels(~contains(wekaModels, 'signal', 'IgnoreCase', 1));
                        modelList_new = sort(unique([spotModelName_; wekaModels']));
                        set(findobj(obj.sLFigH, 'Tag', 'genericSpotModel_listbox'), 'String', modelList_new);
                        set(findobj(obj.sLFigH, 'Tag', 'genericSpotModel_listbox'), 'Value', find(strcmp(modelList_new, spotModelName_)));
                    end

                    obj.statusTextH.String = 'Model loaded...';
                    drawnow
                    pause(0.1)
                    obj.statusTextH.String = '';
                    drawnow
                otherwise
                    obj.statusTextH.String = 'No model loaded...';
                    drawnow
                    pause(1)
                    obj.statusTextH.String = '';
                    drawnow
            end            
        end
        
        function saveModel_Fcn(obj, ~)
            % Combine existing model data and roi data! Save data and
            % model! Delete rois!
            % Get path to save weka model!

            [spotModelName_, spotModelPath_] = setModelName(obj);
            if ~isempty(spotModelName_)
                % Save Model!
                wekaSaveModel(fullfile(spotModelPath_, spotModelName_), obj.data.spotModel_model);
                % Save dataset!
                [spotModelName_, ~] = strtok(spotModelName_, '.');
                relation = 'spot features';
                attributes = obj.featureNames;
                % Get data from active roi data! Combine with existing model data!
                roiData = roiData_Fcn(obj);
                spotModelData_ = unique([obj.data.spotModel_data; roiData], 'rows');
                obj.data.spotModel_data = spotModelData_;
                
                spotModelData_ = matlab2weka(relation, attributes, spotModelData_(:,1:end-1), spotModelData_(:,end));
                wekaSaveData(fullfile(spotModelPath_, [spotModelName_, '_Data.csv']), spotModelData_, 'CSV');
                % wekaSaveData('test.arff', D, 'ARFF');

                % Set file name in GUI
                fileNameDisplay = fullfile(spotModelPath_, spotModelName_);
                if gt(numel(fileNameDisplay), 50)
                    fileNameDisplay = ['...', fileNameDisplay(end-50:end)];
                end
                obj.modelTextH.String = fileNameDisplay;
                obj.modelTextH.FontWeight = 'bold';
                
                % Update model list field!
                if strcmp(spotModelPath_, fullfile(obj.synapseLocatorFolder, obj.wekaModelsFolder, filesep))
                    modelList_new = sort(unique([spotModelName_; get(findobj(obj.sLFigH, 'Tag', 'genericSpotModel_listbox'), 'String')]));
                    set(findobj(obj.sLFigH, 'Tag', 'genericSpotModel_listbox'), 'String', modelList_new);
                    set(findobj(obj.sLFigH, 'Tag', 'genericSpotModel_listbox'), 'Value', find(strcmp(modelList_new, spotModelName_)));
                else
                end
            end
        end
        
        function clearROIs_Fcn(obj, ~)
            % Clear ROIs from Synapse Locator!

            obj.class1_roi = {};
            obj.class2_roi = {};
            set(findobj(obj.sLFigH, 'Tag', 'class1_listbox'), 'String', []);
            set(findobj(obj.sLFigH, 'Tag', 'class1_listbox'), 'Value', 1);
            set(findobj(obj.sLFigH, 'Tag', 'class2_listbox'), 'String', []);
            set(findobj(obj.sLFigH, 'Tag', 'class2_listbox'), 'Value', 1);
        end
        
        function clearModel_Fcn(obj, ~)
            % Clear model and associated data (from Synapse Locator)!
            obj.data.spotModel_model = [];
            obj.data.spotModel_data = [];
            obj.featureNames_model = [];
            obj.modelTextH.String = ''; 
        end
        
        function addROI_Fcn(obj, evnt)
            % Add ROI to given class!
            roiData = evnt.someData;
            roiN = 1 + numel(obj.(['class', num2str(roiData.Class), '_roi']));
            roiData.ID = roiN;
            obj.(['class', num2str(roiData.Class), '_roi']) = [obj.(['class', num2str(roiData.Class), '_roi']); roiData];
        end
        
        function deleteROI_Fcn(obj, evnt)
            % Delete ROI from given class!
            roi2delete = evnt.someData;
            roiData = obj.(['class', num2str(roi2delete.Class), '_roi']);
            roiData(roi2delete.ID) = [];
            for id = 1:numel(roiData)
                roiData{id}.ID = id;
            end
            obj.(['class', num2str(roi2delete.Class), '_roi']) = roiData;
        end
        
        function getFeatures_Fcn(obj, ~)
            % Set up new set of feature data!
            obj.featureNames = [];
            
            % Check if ImageJ is running!
            [imagejSettings, ijRunMode] = obj.imageJChecker();
            
            % Prepare to use the 'best' filtered input data!
            tifFiles = tmpDirChecker(obj);
            % Load 3D data! Always try to load deconvolved data! (or at least what was name 'deconv' in synLoc 'load2ChannelTif_Fcn' function)!
            if ischar(tifFiles(1).proc)
                % Load 'proc' type data!
                fileName = tifFiles(1).proc;
            elseif ischar(tifFiles(1).mf)
                % Load 'mf' type data!
                fileName = tifFiles(1).mf;
            else
                % Load raw data!
                fileName = tifFiles(1).raw;
            end
            
            if obj.upsampling
                dataFile_1_ = fullfile(obj.dataOutputPath, obj.tmpImagesDir, regexprep(fileName, '.tif$', '_scaled.tif'));
            else
                dataFile_1_ = fullfile(obj.dataOutputPath, obj.tmpImagesDir, fileName);
            end
            
            % Add normalization step!
            oldMin = num2str(min(obj.data.G0(:)));
            oldMax = num2str(max(obj.data.G0(:)));
            newMin = num2str(0);
            newMax = num2str(2^8);
            
            ijArgs = strjoin({dataFile_1_, fullfile(obj.dataOutputPath, obj.featureDataBaseDir), oldMin, oldMax, newMin, newMax, obj.avgSpotSize, ijRunMode},',');
            CMD = sprintf('"%s" %s "%s" "%s"',...
                obj.IJ_exe,...
                imagejSettings,...
                fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.featureMakerMacro),...
                ijArgs);
            [status, result] = system(CMD); %#ok<ASGLU>
            
            % Inspect results and convert from tif to mat!
            d = dir([obj.featureDataDir, '\*.tif']); % in alphabetic order!
            for featureName = {d.name}
                featureName_ = replace(featureName, '.tif', '');
                obj.featureNames = [obj.featureNames; featureName_];
                
                % Load data! Save data as mat file and delete tif file!
                stack = flipud(rot90(ScanImageTiffReader(fullfile(obj.featureDataDir, featureName{:})).data, 1));
                stack = stack(:); 
                save(fullfile(obj.featureDataDir, [featureName_{:}, '.mat']), 'stack', '-v7.3')
                recycleStatus = recycle;
                recycle('off')
                delete(fullfile(obj.featureDataDir, featureName{:}))
                recycle(recycleStatus)
            end
        end
        
        function getFeatures_signalChannel_Fcn(obj, ~)
            % Get feature data from r1 channel!
            [status, msg] = mkdir(fullfile(obj.featureDataDir, 'signalFeatures')); %#ok<ASGLU>
            obj.featureNames_signalChannel = [];

            % Take data from time point 2 (macro expects single channel)!
            oldMin = num2str(min(obj.data.R1(:)));
            oldMax = num2str(max(obj.data.R1(:)));
            newMin = num2str(0);
            newMax = num2str(2^8);
            
            tifFiles = tmpDirChecker(obj);
            if obj.loadRegisteredImages
                dataFile_2_ = fullfile(obj.dataOutputPath, obj.tmpImagesDir, tifFiles(2).proc);
                % Check for upsampling!
                if obj.upsampling
                    dataFile_2_ = regexprep(dataFile_2_, '.tif$', '_scaled.tif');
                end
                channelsN = 'double';
            else
                % Prepare to use the 'best' filtered input data!
                % Load 3D data! Always try to load deconvolved data! (or at least what was name 'deconv' in synLoc 'load2ChannelTif_Fcn' function)!
                if ischar(tifFiles(2).proc)
                    fileName = 'R1_proc_transformed.tif';
                elseif ischar(tifFiles(1).mf)
                    fileName = 'R1_mf_transformed.tif';
                else
                    fileName = 'R1_raw_transformed.tif';
                end                
                dataFile_2_ = fullfile(obj.dataOutputPath, fileName);
                % Check for upsampling!
                if obj.upsampling
                    dataFile_2_tmp = regexprep(dataFile_2_, '.tif$', '_scaled.tif');
                    if ne(exist(dataFile_2_tmp, 'file'), 2)
                        % Call scaleIt macro!
                        [imagejSettings, ijRunMode] = obj.imageJChecker();
                        ijArgs_ = strjoin({...
                            dataFile_2_, ...
                            dataFile_2_tmp, ...
                            'upscale', ...
                            'single', ...
                            ijRunMode},',');
                        CMD = sprintf('"%s" %s "%s" "%s"', obj.IJ_exe, imagejSettings, fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.scaleMacro), ijArgs_);
                        [status, result] = system(CMD); %#ok<ASGLU>
                    end
                    dataFile_2_ = dataFile_2_tmp;
                end
                channelsN = 'single';
            end
            
            % Check if ImageJ is running!
            [imagejSettings, ijRunMode] = obj.imageJChecker();

            ijArgs = strjoin({dataFile_2_, fullfile(obj.featureDataDir, 'signalFeatures'), oldMin, oldMax, newMin, newMax, channelsN, obj.avgSpotSize, ijRunMode},',');

            CMD = sprintf('"%s" %s "%s" "%s"',...
                obj.IJ_exe,...
                imagejSettings,...
                fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.featureMakerSignalChannelMacro),...
                ijArgs);
            % disp(CMD)
            [status, result] = system(CMD); %#ok<ASGLU>
            % disp(result)

            % Inspect results and convert from tif to mat!
            d = dir([fullfile(obj.featureDataDir, 'signalFeatures'), '\*.tif']);
            d = d(cell2mat(cellfun(@(x) eq(contains(x, 'Laplacian_SignalChannel', 'IgnoreCase', 1), 1), {d.name}, 'Uni', 0)));
            for featureName = {d.name}
                featureName_ = replace(featureName, '.tif', '');
                obj.featureNames_signalChannel = [obj.featureNames_signalChannel; featureName_];
                
                % Load data! Save data as mat file and delete tif file!
                stack = flipud(rot90(ScanImageTiffReader(fullfile(obj.featureDataDir, 'signalFeatures', featureName{:})).data, 1));
                stack = stack(:); 
                save(fullfile(obj.featureDataDir, 'signalFeatures', [featureName_{:}, '.mat']), 'stack', '-v7.3')
                recycleStatus = recycle;
                recycle('off')
                delete(fullfile(obj.featureDataDir, 'signalFeatures', featureName{:}))
                recycle(recycleStatus)
            end
            
        end
        
        function trainClassifier_Fcn(obj, ~)
            % Setup training and create model for spot detection!
            % This command overwrites an existing model (model name is reset)!
            
            % Check for feature data!
            if isempty(dir(fullfile(obj.featureDataDir, '*.mat')))
                getFeatures_Fcn(obj)
            end
            
            % Check for training data and assemble class rois and model data!
            if ~any([numel(obj.class1_roi), numel(obj.class2_roi)]) && isempty(obj.data.spotModel_data)
                obj.statusTextH.String = 'NO Training Data...';
                drawnow
                pause(3)
                obj.statusTextH.String = '';
                drawnow
                return
            end
            
            obj.statusTextH.String = 'Training Classifier...';
            drawnow

            roiData = roiData_Fcn(obj);
            spotTrainData_ = unique([obj.data.spotModel_data; roiData], 'rows');
            relation = 'spot features';
            attributes = obj.featureNames;

            % MATLAB2WEKA : Convert numeric data using labels vector
            modelTrainData_ = matlab2weka(relation, attributes, spotTrainData_(:,1:end-1), spotTrainData_(:,end));
            % Train a Random Forest with specific options
            obj.data.spotModel_model = wekaTrainModel(modelTrainData_, 'trees.RandomForest', '-I 1000 -K 0 -S 123 -depth 25 -N 0 -M 1 -V 1e-3 -B -U -O -store-out-of-bag-predictions -output-out-of-bag-complexity-statistics -attribute-importance -output-debug-info');
            % obj.data.spotModel_model = wekaTrainModel(modelTrainData_, 'bayes.NaiveBayes' , '-D');
            
            % Classify data (input data)
            [spotTrainData_predicted, spotTrainData_classProbs, confusionMatrix] = wekaClassify(modelTrainData_, obj.data.spotModel_model); %#ok<ASGLU>
            
            % Show model summary!
            obj.data.spotModel_model
            tabulate(spotTrainData_predicted)
            % confusionMatrix %#ok<NOPRT>
            
            % Indicate that existing model has changed and is not yet saved!
            obj.modelTextH.String = '...(in process)...';
            obj.modelTextH.HorizontalAlignment = 'center';
            obj.modelTextH.FontWeight = 'normal';
            
            obj.statusTextH.String = '';
            drawnow
        end
        
        function modelQuality_Fcn(obj, ~)
            % Show model properties!
            obj.data.spotModel_model
        end
        
        function featureStats_Fcn(obj, ~)
            % Plot feature stats based on active model (plus existing rois)!
            
            if isempty(obj.data.spotModel_data) && ~all([numel(obj.class1_roi), numel(obj.class2_roi)])
                errordlg('No model data!', 'Data Error');
            else
                % Get data from active roi data!
                roiData = roiData_Fcn(obj);
                data_ = unique([obj.data.spotModel_data; roiData], 'rows');

                features_ = data_(:,1:end-1);
                features_ = zscore(features_,1);                
                features_ = reshape(features_, [], 1);
                predicted_ = data_(:,end);
                predicted_ = logical(repmat(predicted_, (size(data_, 2) - 1), 1));
                grps = cellstr(char(cellfun(@(x) repmat(x, size(data_,1),1), obj.featureNames, 'Uni', 0)));
                
                grps(predicted_) = cellfun(@(x) [x, '_bckgrd'], grps(predicted_), 'Uni', 0);
                grps(~predicted_) = cellfun(@(x) [x, '_Spot'], grps(~predicted_), 'Uni', 0);

                % Plot overview of features
                figure('Name', 'Model Feature Overview', 'NumberTitle', 'off', 'Position', [100 200 1400 500], 'Units', 'pixels')
                boxplot(features_, grps, 'PlotStyle', 'compact', 'ColorGroup', repmat([0,1], 1, (size(data_, 2) - 1)), 'FactorSeparator', 1);
                title('Model Features'); ylabel('Feature Values (zscore)'); grid on; grid minor;
            end
        end
                
        function findSpots_Fcn(obj, ~)
            % Classify voxels as 'spot'/'no spot'!
            
            % Check for model!
            if isempty(obj.data.spotModel_model)
                obj.statusTextH.String = 'No Model found!';
                drawnow
                pause(3)
                obj.statusTextH.String = '';
                drawnow
                return
            end
            
            % Check for feature data!
            if isempty(dir(fullfile(obj.featureDataDir, '*.mat')))
                obj.statusTextH.String = 'Calculating Features!';
                drawnow
                getFeatures_Fcn(obj)
                obj.statusTextH.String = '';
                drawnow
            end
            
            % Show progress in GUI!
            obj.statusTextH.String = 'Finding Spots...(step 1)';
            drawnow
            % Reset number of spots in GUI!
            set(findobj(obj.sLFigH, 'Tag', 'spotsN_edit'), 'String', '');
            set(findobj(obj.sLFigH, 'Tag', 'labelsN_edit'), 'String', '');
                        
            %%%%%%%%%%%%%%%%%%
            spotFinding = 1;
            %%%%%%%%%%%%%%%%%%
            switch spotFinding
                case 0
                    % Set up data for classification!
                    spotVoxels_idx = (...
                        ge(obj.data.G0(:), obj.g0_threshold) & ...
                        ge(obj.data.G1(:), obj.g1_threshold));
                    sum(spotVoxels_idx);
                    
                    % spotVoxels_idx, convert from logical to linear indices, use to extract features from file!
                    spotVoxels_idx = find(spotVoxels_idx);
                    % Get feature idx and features from file!
                    features2test = zeros(numel(spotVoxels_idx), numel(obj.featureNames));
                    for featureNameIdx_ = 1:numel(obj.featureNames)
                        tmpF = load(fullfile(obj.featureDataDir, [obj.featureNames{featureNameIdx_}, '.mat']));
                        features2test(:, featureNameIdx_) = tmpF.stack(spotVoxels_idx);
                    end
                    clear 'tmpF'
                    fprintf('%s: %i\n', 'Total number of qualified voxels', numel(spotVoxels_idx))
                    relation = 'spot features';
                    labels = randi([0,1], size(features2test, 1), 1); % Random class labels
                    obj.statusTextH.String = 'Finding Spots...(step 2)';
                    drawnow
                    features2test = matlab2weka(relation, obj.featureNames, features2test, labels);
                    obj.statusTextH.String = 'Finding Spots...(step 3)';
                    drawnow
                    [obj.data.spot_predicted, obj.data.spot_classProbs, ~] = wekaClassify(features2test, obj.data.spotModel_model);
                    clear('features2test', 'labels')
                    tabulate(obj.data.spot_predicted)
                    obj.statusTextH.String = 'Finding Spots...(step 4)';
                    drawnow
                    % Transform classification results into image! Use spotSpecificity!!!
%                     hit_idx = ge(obj.data.spot_classProbs(:, 1), obj.spotSpecificity);
                    % Polish predicted positions to get most likely spots!
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Convert true spot min/max to pixel min/max! Restrict min to 2 pixels!
                    % spotSizeMin_px = max([2,2,2 ; min([2,2,2; round(obj.spotSizeMin ./ obj.vxlSize)])]);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Convert true spot min/max to pixel min/max! Restrict min to 2 pixels!
                    spotSizeMin_px = max([2, 2, 1.5 ; min([2, 2, 1.5; round(obj.spotSizeMin ./ obj.vxlSize)])]);
                    spotSizeMax_px = round(obj.spotSizeMax(1) ./ obj.vxlSize);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    results = spotAnalyzer(obj.data.spot_predictedStack, spotSizeMin_px, spotSizeMax_px, obj.bwconncompValue);
                    % results = spotAnalyzer2(obj.data.spot_classProbsStack, CC, obj.spotSpecificity, spotSizeMin_px, spotSizeMax_px);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % Convert back to true spot min/max to pixel min/max! Restrict min to 2 pixels!
                    spotSize_ = arrayfun(@(x) results(x).spot_diameters_ellipsoid .* obj.vxlSize, 1:numel(results), 'Uni', 0);
                    for sS_idx = 1:numel(results)
                        results(sS_idx).spot_diameters_ellipsoid = spotSize_{sS_idx};
                    end
                    % Gather spot data for output, if no results set to template!
                    obj.synapseLocatorSummary = obj.summaryTemplate;
                    if isempty(results)
                        obj.statusTextH.String = 'No spots found!';
                        drawnow
                        pause(1)
                        obj.statusTextH.String = '';
                        drawnow
                    else
                        spotSummary_Fcn(obj, results);
                        % clear('results')
                        % Blow up for display!
                        % Calculate r intensities of detected spots and suggest r threshold (use r0, r1 should be larger than r0 anyway)!
                        % Show number of spots in GUI!
                        tmpStack = zeros(size(obj.data.([obj.leadingChannel, '1'])));
                        tmpStack(sub2ind(size(obj.data.([obj.leadingChannel, '1'])), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, obj.synapseLocatorSummary.section)) = 1;
                        set(findobj(obj.sLFigH, 'Tag', 'spotsN_edit'), 'String', numel(obj.synapseLocatorSummary.Spot_ID));
                        
                        se = strel('sphere', 3);
                        obj.data.spot_predictedStack = imdilate(tmpStack, se);
                        
                        obj.statusTextH.String = '';
                        drawnow
                    end
                    
                    % Reset label display!
                    tmpH = guihandles(obj.sLFigH);
                    tmpH.label_results_uibuttongroup.SelectedObject = tmpH.label_default_radiobutton;
                    tmpH.label_results_uibuttongroup.SelectionChangedFcn(tmpH.label_results_uibuttongroup, obj.sLFigH)
                                        
                case 1
                    bw = ge(obj.data.G0, obj.g0_threshold) & ge(obj.data.G1, obj.g1_threshold);
                    bwd = bwdist(~bw, 'quasi-euclidean');
                    % bwd = bwdist(~bw, 'euclidean');
                    bwd = -bwd .* obj.rescaler(obj.data.G0, 0, 1023);
%                     bwd = -bwd;
                    bwd(~bw) = Inf;
                    bww = watershed(bwd, obj.bwconncompValue);
                    clear bwd
                    bww(~bw) = 0;
                    clear bw
                    CC = bwconncomp(bww, obj.bwconncompValue);
                    clear bww
                    
                    spotVoxels_idx = (arrayfun(@(x) CC.PixelIdxList{x}, 1:CC.NumObjects, 'Uni', 0));
                    spotVoxels_idx = cat(1, spotVoxels_idx{:});
                    % Gather features keeping the order of feature names from obj.featureNames!
                    % Get feature idx and features from file!
                    features2test = zeros(numel(spotVoxels_idx), numel(obj.featureNames));
                    for featureNameIdx_ = 1:numel(obj.featureNames)
                        tmpF = load(fullfile(obj.featureDataDir, [obj.featureNames{featureNameIdx_}, '.mat']));
                        features2test(:, featureNameIdx_) = tmpF.stack(spotVoxels_idx);
                    end
                    clear 'tmpF'
                    fprintf('%s: %i\n', 'Total number of qualified voxels', numel(spotVoxels_idx))
                    
                    relation = 'spot features';
                    labels = randi([0,1], size(features2test, 1), 1); % Random class labels
                    
                    obj.statusTextH.String = 'Finding Spots...(step 2)';
                    drawnow
                    
                    features2test = matlab2weka(relation, obj.featureNames, features2test, labels);
                    
                    obj.statusTextH.String = 'Finding Spots...(step 3)';
                    drawnow
                    
                    [obj.data.spot_predicted, obj.data.spot_classProbs, ~] = wekaClassify(features2test, obj.data.spotModel_model);
                    clear('features2test', 'labels')
                    % tabulate(obj.data.spot_predicted)
                    
                    obj.statusTextH.String = 'Finding Spots...(step 4)';
                    drawnow
                    
                    % Transform classification results into image! Use spotSpecificity!!!
                    hit_idx = ge(obj.data.spot_classProbs(:, 1), obj.spotSpecificity);
                    obj.data.spot_classProbsStack = zeros(size(obj.data.([obj.leadingChannel, '1'])));
                    obj.data.spot_classProbsStack(spotVoxels_idx(hit_idx)) = obj.data.spot_classProbs(hit_idx, 1);
                    obj.data.spot_predictedStack = zeros(size(obj.data.([obj.leadingChannel, '1'])));
                    obj.data.spot_predictedStack(spotVoxels_idx(hit_idx)) = 1;
                    
                    % Polish predicted positions to get most likely spots!
                    if obj.upsampling
                        spotSizeMin_px = round([1, 1, 2] .* obj.spotSizeMin);
                        spotSizeMax_px = round([1, 1, 2] .* obj.spotSizeMax);
                    else
                        spotSizeMin_px = obj.spotSizeMin;
                        spotSizeMax_px = obj.spotSizeMax;
                    end
                    
                    % Calculate results!
                    results = spotAnalyzer2(obj.data.spot_classProbsStack, CC, obj.spotSpecificity, spotSizeMin_px, spotSizeMax_px);
                    
                    % Convert back in case of upsampling!
                    if obj.upsampling
                        spotSize_ = arrayfun(@(x) results(x).spot_diameters_ellipsoid ./ [1, 1, 2], 1:numel(results), 'Uni', 0);
                        bb_ = arrayfun(@(x) results(x).BoundingBox ./ [1, 1, 2], 1:numel(results), 'Uni', 0);
                    else
                        spotSize_ = arrayfun(@(x) results(x).spot_diameters_ellipsoid, 1:numel(results), 'Uni', 0);
                        bb_ = arrayfun(@(x) results(x).BoundingBox, 1:numel(results), 'Uni', 0);
                    end
                    for sS_idx = 1:numel(results)
                        results(sS_idx).spot_diameters_ellipsoid = spotSize_{sS_idx};
                        results(sS_idx).bb = bb_{sS_idx};
                    end
                    
                    % Gather spot data for output, if no results set to template!
                    obj.synapseLocatorSummary = obj.summaryTemplate;
                    if isempty(results)
                        obj.statusTextH.String = 'No spots found!';
                        drawnow
                        pause(1)
                        obj.statusTextH.String = '';
                        drawnow
                    else
                        obj.spotSummary_Fcn(results);
                        clear('results')
                        % Blow up for display!
                        % Show number of spots in GUI!
                        tmpStack = zeros(size(obj.data.([obj.leadingChannel, '1'])));
                        tmpStack(sub2ind(size(obj.data.([obj.leadingChannel, '1'])), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, obj.synapseLocatorSummary.section)) = 1;
                        set(findobj(obj.sLFigH, 'Tag', 'spotsN_edit'), 'String', numel(obj.synapseLocatorSummary.Spot_ID));
                        
                        se = strel('sphere', 3);
                        obj.data.spot_predictedStack = imdilate(tmpStack, se);
                        
                        obj.statusTextH.String = '';
                        drawnow
                    end
                    
                    % Reset label display!
                    tmpH = guihandles(obj.sLFigH);
                    tmpH.label_results_uibuttongroup.SelectedObject = tmpH.label_default_radiobutton;
                    tmpH.label_results_uibuttongroup.SelectionChangedFcn(tmpH.label_results_uibuttongroup, obj.sLFigH)

                case 2
                    spotVoxels_idx = find(ge(obj.data.G0, obj.g0_threshold) & ge(obj.data.G1, obj.g1_threshold));
                    % Gather features keeping the order of features names from obj.featureNames!
                    % Get feature idx and features from file!
                    features2test = zeros(numel(spotVoxels_idx), numel(obj.featureNames));
                    for featureNameIdx_ = 1:numel(obj.featureNames)
                        tmpF = load(fullfile(obj.featureDataDir, [obj.featureNames{featureNameIdx_}, '.mat']));
                        features2test(:, featureNameIdx_) = tmpF.stack(spotVoxels_idx);
                    end
                    clear 'tmpF'
                    fprintf('%s: %i\n', 'Total number of qualified voxels', numel(spotVoxels_idx))
                    relation = 'spot features';
                    labels = randi([0,1], size(features2test, 1), 1); % Random class labels
                    obj.statusTextH.String = 'Finding Spots...(step 2)';
                    drawnow
                    features2test = matlab2weka(relation, obj.featureNames, features2test, labels);
                    obj.statusTextH.String = 'Finding Spots...(step 3)';
                    drawnow
                    [obj.data.spot_predicted, obj.data.spot_classProbs, ~] = wekaClassify(features2test, obj.data.spotModel_model);
                    clear('features2test', 'labels')
                    tabulate(obj.data.spot_predicted);
                    obj.statusTextH.String = 'Finding Spots...(step 4)';
                    drawnow
                    % Transform classification results into image! Use spotSpecificity!!!
                    hit_idx = ge(obj.data.spot_classProbs(:, 1), obj.spotSpecificity);
                    bw = zeros(size(obj.data.([obj.leadingChannel, '1'])));
                    bw(spotVoxels_idx(hit_idx)) = 1;
                    bwd = bwdist(~bw, 'quasi-euclidean');
                    % bwd = bwdist(~bw, 'euclidean');
                    bwd = -bwd .* obj.rescaler(obj.data.G0, 0, 1023);
                    bwd(~bw) = Inf;
                    bww = watershed(bwd, obj.bwconncompValue);
                    clear bwd
                    bww(~bw) = 0;
                    clear bw
                    CC = bwconncomp(bww, obj.bwconncompValue);
                    clear bww
                    
                    % Polish predicted positions to get most likely spots!
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Convert true spot min/max to pixel min/max! Restrict min to 2 pixels!
                    % spotSizeMin_px = max([2,2,2 ; min([2,2,2; round(obj.spotSizeMin ./ obj.vxlSize)])]);
                    if obj.upsampling
%                         spotSizeMin_px = max([2, 2, 1.5 ; min([2, 2, 1.5; round([1, 1, 2] .* obj.spotSizeMin ./ obj.vxlSize)])]);
                        spotSizeMin_px = max([2, 2, 2 ; round([1, 1, 2] .* obj.spotSizeMin ./ obj.vxlSize)]);
                        spotSizeMax_px = round([1, 1, 2] .* obj.spotSizeMax(1) ./ obj.vxlSize);
                    else
%                         spotSizeMin_px = max([2, 2, 1.5 ; min([2, 2, 1.5; round(obj.spotSizeMin ./ obj.vxlSize)])]);
                        spotSizeMin_px = max([2, 2, 2 ; round(obj.spotSizeMin ./ obj.vxlSize)]);
                        spotSizeMax_px = round(obj.spotSizeMax(1) ./ obj.vxlSize);
                    end
                    
                    results = spotAnalyzer2(obj.data.spot_classProbsStack, CC, obj.spotSpecificity, spotSizeMin_px, spotSizeMax_px);
                    
                    % Convert back to true spot min/max to pixel min/max! Restrict min to 2 pixels!
                    if obj.upsampling
                        spotSize_ = arrayfun(@(x) (results(x).spot_diameters_ellipsoid .* obj.vxlSize) ./ [1, 1, 2], 1:numel(results), 'Uni', 0);
                    else
                        spotSize_ = arrayfun(@(x) results(x).spot_diameters_ellipsoid .* obj.vxlSize, 1:numel(results), 'Uni', 0);
                    end
                    for sS_idx = 1:numel(results)
                        results(sS_idx).spot_diameters_ellipsoid = spotSize_{sS_idx};
                    end
                    
                    % Gather spot data for output, if no results set to template!
                    obj.synapseLocatorSummary = obj.summaryTemplate;
                    if isempty(results)
                        obj.statusTextH.String = 'No spots found!';
                        drawnow
                        pause(1)
                        obj.statusTextH.String = '';
                        drawnow
                    else
                        spotSummary_Fcn(obj, results);
                        % clear('results')
                        % Blow up for display!
                        % Calculate r intensities of detected spots and suggest r threshold (use r0, r1 should be larger than r0 anyway)!
                        % Show number of spots in GUI!
                        tmpStack = zeros(size(obj.data.([obj.leadingChannel, '1'])));
                        tmpStack(sub2ind(size(obj.data.([obj.leadingChannel, '1'])), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, obj.synapseLocatorSummary.section)) = 1;
                        set(findobj(obj.sLFigH, 'Tag', 'spotsN_edit'), 'String', numel(obj.synapseLocatorSummary.Spot_ID));
                        
                        se = strel('sphere', 3);
                        obj.data.spot_predictedStack = imdilate(tmpStack, se);
                        
                        obj.statusTextH.String = '';
                        drawnow
                    end
                    
                    % Reset label display!
                    tmpH = guihandles(obj.sLFigH);
                    tmpH.label_results_uibuttongroup.SelectedObject = tmpH.label_default_radiobutton;
                    tmpH.label_results_uibuttongroup.SelectionChangedFcn(tmpH.label_results_uibuttongroup, obj.sLFigH)
            end            
        end
                
        function findSignals_Fcn(obj, ~)
            % Check spots for their 'signal' quality (r1/r0 ratio & so)!
            % Show progress in GUI!
            obj.statusTextH.String = 'Assigning Labels...';
            drawnow
            
            % Check for spots!
            if isempty(obj.synapseLocatorSummary)
                obj.statusTextH.String = 'No Spots detected!';
                drawnow
                pause(3)
                obj.statusTextH.String = '';
                drawnow
                return
            end
            
            % Get some features from r1 data (=signal channel)! Do so for every start (spot detection may have changed)!
            if isempty(obj.featureNames_signalChannel)
                % Show progress in GUI!
                obj.statusTextH.String = 'Calculating Spot (2nd channel) Features ...';
                drawnow
                getFeatures_signalChannel_Fcn(obj)
                obj.statusTextH.String = '';
                drawnow
            end

            % Simply analyze ALL spots!
            spotVoxelIDs = sub2ind(size(obj.data.G0), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, obj.synapseLocatorSummary.section);
            
            if isempty(spotVoxelIDs)
                obj.statusTextH.String = 'No Spots got ''Active'' Label';
                drawnow
                pause(1)
                obj.statusTextH.String = '';
                drawnow
                return
            end
            
            % Reset number of signals in GUI!
            set(findobj(obj.sLFigH, 'Tag', 'labelsN_edit'), 'String', '');

            % Set up data for classification!
            % Gather signal feature from qualified voxels and submit to signal model!
            features2test = zeros(numel(spotVoxelIDs), numel(obj.featureNames_signalChannel));
            for featureNameIdx = 1:numel(obj.featureNames_signalChannel)
                featureName_ = obj.featureNames_signalChannel{featureNameIdx};
                features_ = load(fullfile(obj.featureDataDir, 'signalFeatures', [featureName_, '.mat']));
                features2test(:, featureNameIdx) = features_.stack(spotVoxelIDs);
            end
            attributes = obj.featureNames_signalChannel;
            relation = 'spot finder signal features';
            labels = randi([0,1], size(features2test, 1), 1); % Random class labels
            features2test = matlab2weka(relation, attributes, features2test, labels);
            
            % Use signal model from g0 (=leading channel) as template for signal 'shape' in r1 to filter qualified spots!
            obj.statusTextH.String = 'Building Model for Label Assignment...';
            drawnow
            
            % Make signal model from real data (use g0 as template for signal 'shape')!
            % Get matching attributes from spot train data set!
            ft_idx = cellfun(@(x) find(strcmp(obj.featureNames, strrep(x, '_SignalChannel', ''))), obj.featureNames_signalChannel, 'Uni', 0);
            ft_idx = cat(1, ft_idx{:})';
            
            modelSource = 'spots';
            switch modelSource
                case 'model'
                    % Include data from active roi data!
                    roiData = roiData_Fcn(obj);
                    signalTrainData_ = unique([obj.data.spotModel_data; roiData], 'rows');
                    signalTrainData_ = signalTrainData_(:,[ft_idx, end]);
                    relation = 'spot features at g0';
                    labels = signalTrainData_(:,end);
                    % MATLAB2WEKA : Convert numeric data using labels vector
                    signalTrainData_ = matlab2weka(relation, attributes, signalTrainData_(:,1:end-1), labels);
                case 'spots'
                    % Gather signal feature from qualified voxels and submit to signal model!
                    signalTrainData_ = zeros(numel(spotVoxelIDs), numel(obj.featureNames_signalChannel));
                    for featureNameIdx = 1:numel(obj.featureNames_signalChannel)
                        featureName_ = obj.featureNames{featureNameIdx};
                        features_ = load(fullfile(obj.featureDataDir, [featureName_, '.mat']));
                        signalTrainData_(:, featureNameIdx) = features_.stack(spotVoxelIDs);
                    end
                    signalTrainData_ = [signalTrainData_, zeros(size(signalTrainData_,1),1)];
                    
                    % Include data from active roi data!
                    roiData = roiData_Fcn(obj);
                    noSignalTrainData_ = unique([obj.data.spotModel_data; roiData], 'rows');
                    noSignalTrainData_ = noSignalTrainData_(:,[ft_idx, end]);
                    noSignalTrainData_ = noSignalTrainData_(eq(noSignalTrainData_(:,end), 1),:);
                    
                    % Combine and convert to weka type!
                    signalTrainData_ = [signalTrainData_; noSignalTrainData_];
                    attributes = obj.featureNames(ft_idx);
                    relation = 'spot finder signal features';
                    labels = signalTrainData_(:,end); % Random class labels
                    signalTrainData_ = matlab2weka(relation, attributes, signalTrainData_(:,1:end-1), labels);
            end
            
                        
            % Train a Random Forest with specific options
            obj.data.signalModel_G0_model = wekaTrainModel(signalTrainData_, 'trees.RandomForest', '-I 1000 -K 0 -S 123 -depth 25 -N 0 -M 0 -V 1e-3 -B -U -O -store-out-of-bag-predictions -output-out-of-bag-complexity-statistics -attribute-importance -output-debug-info');
            % Show model summary!
            % obj.data.signalModel_G0;
            % Classify data (input data)
            % [signal_predicted_, signal_classProbs_, confusionMatrix] = wekaClassify(signalTrainData_, obj.signalModel_G0); %#ok<ASGLU>
            [signal_predicted_, signal_classProbs_, ~] = wekaClassify(features2test, obj.data.signalModel_G0_model); %#ok<ASGLU>
            % tabulate(signal_predicted_);
            % confusionMatrix %#ok<NOPRT>
                     
            % Update spot summary!
            obj.synapseLocatorSummary.spotMatch = gt(signal_classProbs_(:,1), obj.signalSpecificity);
            obj.synapseLocatorSummary.spotMatch_probs = signal_classProbs_(:,1);
            % Add values also to 'raw' and 'mf' type data if available!
            tifFiles = tmpDirChecker(obj);
            if obj.transformRawData && ~obj.loadRegisteredImages
                if ischar(tifFiles(1).mf)
                    obj.synapseLocatorSummary_mf.spotMatch = gt(signal_classProbs_(:,1), obj.signalSpecificity);
                    obj.synapseLocatorSummary_mf.spotMatch_probs = signal_classProbs_(:,1);
                end
                if ischar(tifFiles(1).raw)
                    obj.synapseLocatorSummary_raw.spotMatch = gt(signal_classProbs_(:,1), obj.signalSpecificity);
                    obj.synapseLocatorSummary_raw.spotMatch_probs = signal_classProbs_(:,1);
                end
            end
                        
            % Show found signals in table
            obj.synapseLocatorSummaryTableH = synapseLocatorSummaryTable(obj);
            
            % Reset signal display!
            tmpH = guihandles(obj.sLFigH);
            tmpH.label_results_uibuttongroup.SelectedObject = tmpH.label_default_radiobutton;
            tmpH.label_results_uibuttongroup.SelectionChangedFcn(tmpH.label_results_uibuttongroup, obj.sLFigH)

            % Reset summary table to show 'All'!
            tmpH = guihandles(obj.synapseLocatorSummaryTableH);
            tmpH.dataShowMode_uibuttongroup.SelectedObject = tmpH.dataShowMode_all_radiobutton;
            tmp_.NewValue.String = 'All';
            tmpH.dataShowMode_uibuttongroup.SelectionChangedFcn(tmpH.dataShowMode_uibuttongroup, tmp_)
            tmpH.dataProcessType_uibuttongroup.SelectedObject = tmpH.dataProcessType_processed_radiobutton;
            tmp_.NewValue.String = 'processed';
            tmpH.dataProcessType_uibuttongroup.SelectionChangedFcn(tmpH.dataProcessType_uibuttongroup, tmp_)
            tmpH.dataSortBy_uibuttongroup.SelectedObject = tmpH.dataSortBy_dRG0_radiobutton;
            tmp_.NewValue.String = 'dR/G0';
            tmpH.dataSortBy_uibuttongroup.SelectionChangedFcn(tmpH.dataSortBy_uibuttongroup, tmp_)
            
            % Reset number of signals field in GUI!
            labelsN = sum(ge(obj.synapseLocatorSummary.rDelta_g0, obj.dRG0Threshold));
            set(findobj(obj.sLFigH, 'Tag', 'labelsN_edit'), 'String', sprintf('%i', labelsN));
            
            obj.statusTextH.String = '';
            drawnow
        end
        
        function saveResults_Fcn(obj, ~)
            % Get path to save results (params, elastix params, tifs, spots, signals, ...)!
            % Move important stuff to results dir. Delete tmp files!
            % Save spots and (if available) all qualified signals!
            
            % Check if data were already processed by SynapseLocator or
            % just loaded and preprocessed by ImageJ
            if ~exist(fullfile(obj.dataOutputPath, 'G0_raw.tif'), 'file')
                w = warndlg('Only processed data available! See "tmpImages" directory!');
                pause(1)
                delete(w)
            end
            
            obj.statusTextH.String = 'Saving results...';
            drawnow
            
            % saveastiff_options.color = false; saveastiff_options.big = false; saveastiff_options.overwrite = true;
            saveastiff_options.color = false; saveastiff_options.big = true; saveastiff_options.overwrite = true;
            
            % Prepare to use the 'best' filtered input data!
            tifFiles = tmpDirChecker(obj);

            % Check if a new round of spot/signal finding on already transformed data was run!
            switch get(findobj(obj.sLFigH, 'Tag', 'loadRegisteredImages_radiobutton'), 'Value')
                case 0
                    % 'Standard' case, input data went through all steps.
                    % Keep important elastix params! Keep params (but delete most files)!
                    d = dir(fullfile(obj.dataOutputPath, obj.elastixDataDir));
                    d = d(~[d.isdir]);
                    keepIt = {'elastix.log', 'transformix.log', ...
                        'CMD_R', 'CMD_T', ...
                        'initialTransform_parameters.txt', ...
                        'translation_parameters.txt', 'rotation_parameters.txt', 'affine_parameters.txt', 'elastic_parameters.txt', ...
                        'TransformParameters.0.txt', 'TransformParameters.1.txt', 'TransformParameters.2.txt', 'TransformParameters.3.txt'};
                    idx = cellfun(@(x) strcmp(x, keepIt), {d.name}, 'Uni', 0);
                    idx = logical(sum(cat(1, idx{:}), 2));
                    files2delete = {d(~idx).name};
                    recycleStatus = recycle;
                    recycle('off')
                    cellfun(@(x) delete(fullfile(obj.dataOutputPath, obj.elastixDataDir, x)), files2delete)
                    recycle(recycleStatus)                    
                case 1
                    % 'Non-Standard' case, already aligned images were re-analyzed.                    
            end
            
            % Save detected spots as tif!
            se = strel('sphere', 3);
            if obj.upsampling
                stack_ = zeros(size(obj.data.G0) ./ [1, 1, 2]);
            else
                stack_ = zeros(size(obj.data.G0));
            end
            if isempty(obj.synapseLocatorSummary.Spot_ID)
                saveastiff(stack_, fullfile(obj.dataOutputPath, 'SpotSummary.tif'), saveastiff_options);
            else
                if obj.upsampling
                    idx_ = sub2ind(size(stack_), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, round(obj.synapseLocatorSummary.section / 2));
                else
                    idx_ = sub2ind(size(stack_), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, obj.synapseLocatorSummary.section);
                end
                stack_(idx_) = 1;
                stack_ = imdilate(stack_, se);
                saveastiff(stack_, fullfile(obj.dataOutputPath, 'SpotSummary.tif'), saveastiff_options);
            end
            clear stack_
            
            % Save assigned labels as tif!
            if all(ischar([obj.synapseLocatorSummary.spotMatch]))
                % No labels were assigned! Save stack of zeros as signal summary tif!
                if obj.upsampling
                    stack_ = zeros(size(obj.data.G0) ./ [1, 1, 2]);
                else
                    stack_ = zeros(size(obj.data.G0));
                end
                saveastiff(stack_, fullfile(obj.dataOutputPath, 'SignalSummary.tif'), saveastiff_options);
                clear stack_
            else
                % There are spots and labels! Save values!
                obj.synapseLocatorSummaryLabelTifSaver(saveastiff_options)
            end
            
            if ~isempty(obj.synapseLocatorSummary.Spot_ID)
                synapseLocatorSummarySaver(obj)
            end
            
            % Make composite! Complement transformed data(G0/R0/G1/R1) with spot and label information!
            % Check if a new round of spot/label finding on already transformed data was run!
            switch obj.loadRegisteredImages
                case 1
                    % Skip making composite tif!
                case 0
                    if obj.compositeTif
                        [imagejSettings, ijRunMode] = obj.imageJChecker();
                        dataPath_ = obj.dataOutputPath;
                        dataFile_spotSummary_ = 'SpotSummary.tif';
                        dataFile_labelSummary_ = 'LabelSummary.tif';
                        % Make 'good' output tifs! Check available data!
                        % Load 3D data! Always try to load deconvolved data! (or at least what was name 'deconv' in synLoc 'load2ChannelTif_Fcn' function)!
                        if ischar(tifFiles(1).proc)
                            % Load 'deconv' type data!
                            dataFile_g0_ = 'G0_proc.tif'; dataFile_r0_ = 'R0_proc.tif'; dataFile_g1_ = 'G1_proc_transformed.tif'; dataFile_r1_ = 'R1_proc_transformed.tif';
                        elseif ischar(tifFiles(1).mf)
                            % Load 'mf' type data!
                            dataFile_g0_ = 'G0_mf.tif'; dataFile_r0_ = 'R0_mf.tif'; dataFile_g1_ = 'G1_mf_transformed.tif'; dataFile_r1_ = 'R1_mf_transformed.tif';
                        else
                            % Load raw data!
                            dataFile_g0_ = 'G0_raw.tif'; dataFile_r0_ = 'R0_raw.tif'; dataFile_g1_ = 'G1_raw_transformed.tif'; dataFile_r1_ = 'R1_raw_transformed.tif';
                        end
                        
                        dataOut_ = 'Composite_proc.tif';
                        ijArgs = strjoin({dataPath_, dataOut_, dataFile_g0_, dataFile_r0_, dataFile_g1_, dataFile_r1_, dataFile_spotSummary_, dataFile_labelSummary_, ijRunMode},',');
                        CMD = sprintf('"%s" %s "%s" "%s"', obj.IJ_exe, imagejSettings, fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.gatherOutputMacro), ijArgs);
                        [status, result] = system(CMD); %#ok<ASGLU>
                        if obj.transformRawData && ~obj.loadRegisteredImages
                            % Make composite tif from 'raw' and 'mf' data!
                            if ischar(tifFiles(1).mf)
                                % Load 'mf' type data!
                                dataFile_g0_ = 'G0_mf.tif'; dataFile_r0_ = 'R0_mf.tif'; dataFile_g1_ = 'G1_mf_transformed.tif'; dataFile_r1_ = 'R1_mf_transformed.tif';
                                dataOut_ = 'Composite_mf.tif';
                                ijArgs = strjoin({dataPath_, dataOut_, dataFile_g0_, dataFile_r0_, dataFile_g1_, dataFile_r1_, dataFile_spotSummary_, dataFile_labelSummary_, ijRunMode},',');
                                CMD = sprintf('"%s" %s "%s" "%s"', obj.IJ_exe, imagejSettings, fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.gatherOutputMacro), ijArgs);
                                [status, result] = system(CMD); %#ok<ASGLU>
                            end
                            % Load raw data!
                            dataFile_g0_ = 'G0_raw.tif'; dataFile_r0_ = 'R0_raw.tif'; dataFile_g1_ = 'G1_raw_transformed.tif'; dataFile_r1_ = 'R1_raw_transformed.tif';
                            dataOut_ = 'Composite_raw.tif';
                            ijArgs = strjoin({dataPath_, dataOut_, dataFile_g0_, dataFile_r0_, dataFile_g1_, dataFile_r1_, dataFile_spotSummary_, dataFile_labelSummary_, ijRunMode},',');
                            CMD = sprintf('"%s" %s "%s" "%s"', obj.IJ_exe, imagejSettings, fullfile(obj.synapseLocatorFolder, obj.IJMacrosFolder, obj.gatherOutputMacro), ijArgs);
                            [status, result] = system(CMD); %#ok<ASGLU>
                        end
                    end
            end
            
            % Save SynapseLocatator params!
            allFields = fieldnames(obj);
            fields2save = allFields(~contains(allFields, {...
                'sLFigH'; 'imageAxesH'; 'sliderLevelH'; 'sliderTextH'; 'statusTextH'; ...
                'displayChannel'; 'synapseLocatorSummaryTableH';'modelTextH'; ...
                'Source'; 'EventName'; 'someData'}));
            fields2save = fields2save(~endsWith(fields2save, {'data'; 'internalStuff'}));

            allFields2 = fieldnames(obj.synapseLocatorSummaryTableH.UserData);
            fields2save2 = allFields2(~endsWith(allFields2, {'sLobj'; 'Data'; 'figure1Position'}));
            
            SynapseLocatorParams = struct();
            for field2save = fields2save'
                SynapseLocatorParams.(field2save{:}) = obj.(field2save{:});
            end
            for field2save2 = fields2save2'
                SynapseLocatorParams.(field2save2{:}) = obj.synapseLocatorSummaryTableH.UserData.(field2save2{:});
            end
            save(fullfile(obj.dataOutputPath, 'SynapseLocatorParams.mat'), 'SynapseLocatorParams')
            
            obj.resultSaved = 1;
            obj.statusTextH.String = '';
            drawnow
        end
                
        function elastixCheckerTimer_Fcn(obj, evnt)
            % Add timer to check elastix process!
            if ~isempty(timerfind('Name', 'elastixCheckerTimer'))
                stop(timerfind('Name', 'elastixCheckerTimer'))
                delete(timerfind('Name', 'elastixCheckerTimer'))
            end
            obj.internalStuff.elastixCheckerTimer = timer(...
                'Name', 'elastixCheckerTimer',...
                'BusyMode', 'queue',...
                'ExecutionMode', 'fixedRate',...
                'StartDelay', 0.1,...
                'Period', 5,...
                'StartFcn', @(x,y)elastixCheckerTimer_StartFcn(obj),...
                'StopFcn', @(x, y, z)elastixCheckerTimer_StopFcn(obj, evnt, evnt),...
                'TimerFcn', @(x,y)elastixCheckerTimer_TimerFcn(obj));           
        end
        
        function elastixCheckerTimer_StartFcn(obj)
            % Prepare data for elastix!
            set(findobj(obj.sLFigH, 'Tag', 'spotsN_edit'), 'String', '');
            set(findobj(obj.sLFigH, 'Tag', 'labelsN_edit'), 'String', '');

            obj.statusTextH.String = 'Register Data (prepare registration) ...';
            drawnow
            
            obj.register_CMD = registration_prepare(obj);
            obj.statusTextH.String = 'Command to run elastix is ready!';
            drawnow
            obj.preTransformationMatch = 0;
            obj.postTransformationMatch = 0;
            set(obj.sLFigH.findobj('Tag', 'preTransformationMatch_edit'), 'String', sprintf('%.1f%%', obj.preTransformationMatch))
            set(obj.sLFigH.findobj('Tag', 'postTransformationMatch_edit'), 'String', sprintf('%.1f%%', obj.postTransformationMatch))
            
            % Check for windows console!
            cmdPID_Fcn(obj)
            % Start elastix!
            [status, result] = system([obj.register_CMD, '&']); %#ok<ASGLU>
            elastixP = System.Diagnostics.Process.GetProcessesByName('elastix');
            obj.internalStuff.elastixPID = elastixP(1).Id;
            % Check for windows console!
            cmdPID_Fcn(obj)
            
            % Start terminal and run elastix!
            obj.statusTextH.String = 'Register Data (registration started) ...';
            drawnow
        end
        
        function elastixCheckerTimer_StopFcn(obj, ~, evnt)
            % Close console!
            [status, cmdout] = system(['"C:\Windows\System32\taskkill.exe" /F /pid ', num2str(obj.internalStuff.cmdPID)]); %#ok<ASGLU>
            obj.internalStuff.elastixPID = [];
            
            % Check elastix output!
            elastixLog = dir(fullfile(obj.dataOutputPath, obj.elastixDataDir, '*.log'));
            elastixLog = fullfile(elastixLog.folder, elastixLog.name);
            fileID = fopen(elastixLog);
            fseek(fileID, -1000, 'eof');
            C = textscan(fileID, '%s', 'delimiter', '\n', 'headerlines', 0, 'collectoutput', true);
            fclose(fileID);
            if any([...
                    contains(C{:}, 'Errors occured!'); ...
                    contains(C{:}, 'Errors occured during actual registration!'); ...
                    all(~contains(C{:}, 'Total time'))])
                obj.statusTextH.String = 'Oooops! Elastix error! Please check params and re-start!';
                drawnow
                pause(3)
                obj.statusTextH.String = '';
                drawnow
            elseif any(contains(C{:}, 'Total time'))
                % Start final transformation!
                obj.statusTextH.String = 'Register Data (elastix) ready';
                drawnow
                pause(0.1)
                obj.statusTextH.String = 'Register Data (transforming) ...';
                drawnow
                
                registration_transformation(obj);
                
                obj.statusTextH.String = '';
                drawnow
                
                % Update z level slider!
                obj.zRange = [1, size(obj.data.([obj.leadingChannel, '1']), 3)];
                obj.sliderLevelH.Enable = 'off';
                obj.sliderLevelH.Max = obj.zRange(2);
                obj.sliderLevelH.Min = obj.zRange(1);
                obj.sliderLevelH.Value = obj.zLevel;
                obj.sliderLevelH.SliderStep = [1/(obj.zRange(2)), 10/(obj.zRange(2))];
                obj.sliderLevelH.Enable = 'on';

                % Check if locator should be started!
                if contains(evnt.someData, 'all')
                    segmentationController_Fcn(obj)
                end
            end
        end
        
        function elastixCheckerTimer_TimerFcn(obj)
            elastixP = System.Diagnostics.Process.GetProcessesByName('elastix');
            if elastixP.Length
                elastixPID_ = elastixP(1).Id;
                if eq(obj.internalStuff.elastixPID, elastixPID_)
                    % Process still running
                    obj.statusTextH.String = 'Register Data (registration running) ...';
                    drawnow
                end
            else
                % Process finished, stop timer, close windows console!
                stop(obj.internalStuff.elastixCheckerTimer)
            end
        end
        
        function elastixController_Fcn(obj, evnt)
            
            % Empty transformation command!
            obj.transformation_CMD = [];

            % Timer setup!
            elastixCheckerTimer_Fcn(obj, evnt)
            
            % Check if new round with existing data should be started!
            obj.statusTextH.String = 'Register Data (preparing directory) ...';
            drawnow
            % Delete existing spot finder summary!
            obj.synapseLocatorSummary = obj.summaryTemplate;
            obj.data.spot_classProbs = [];
            obj.data.spot_classProbsStack = [];
            obj.data.spot_predicted = [];
            obj.data.spot_predictedStack = [];

            start(obj.internalStuff.elastixCheckerTimer)
        end
        
        function segmentationController_Fcn(obj)
            obj.internalStuff.locatorParamsChanged = [];
            findSpots_Fcn(obj)
            findSignals_Fcn(obj)
        end
    end
    
    % Extra methods
    methods
        function notify(obj, eventName, varargin)
            % Event notification method that appends supplied varargin to the event's eventData struct, supplied to the event listener(s)
            
            if isempty(varargin)
                notify@handle(obj, eventName);
            else
                EventData_obj = synapseLocator.EventData();
                EventData_obj.someData = varargin{:};
                notify@handle(obj, eventName, EventData_obj);
            end
        end
        
        function tifFiles = inputDirChecker(obj)
            % Check input directory for '_mf.tif' and '_deconv.tif' files!
            
            tifFiles = struct('mf', {NaN, NaN}, 'deconv', {NaN, NaN});            
            for idx = 1:2
                [~, searchName, searchExt] = fileparts(obj.(['dataFile_', num2str(idx)]));
                d = dir(obj.dataInputPath);
                d = d(~[d.isdir]);
                for fileName = {d.name}
                    if strcmp(fileName{:}, [searchName, '_mf', searchExt])
                        tifFiles(idx).mf = fileName{:};
                    end
                    if strcmp(fileName{:}, [searchName, '_deconv', searchExt])
                        tifFiles(idx).deconv = fileName{:};
                    end
                end
            end
        end
        
        function tifFiles = tmpDirChecker(obj)
            % Check tmpImages directory for '_raw', '_mf.tif' and '_proc.tif' files!
            
            tifFiles = struct('raw', {NaN, NaN}, 'mf', {NaN, NaN}, 'proc', {NaN, NaN});            
            for idx = 1:2
                [~, searchName, searchExt] = fileparts(obj.(['dataFile_', num2str(idx)]));
                d = dir(fullfile(obj.dataOutputPath, obj.tmpImagesDir));
                d = d(~[d.isdir]);
                for fileName = {d.name}
                    if strcmp(fileName{:}, [searchName, '_raw', searchExt])
                        tifFiles(idx).raw = fileName{:};
                    end
                    if strcmp(fileName{:}, [searchName, '_mf', searchExt])
                        tifFiles(idx).mf = fileName{:};
                    end
                    if strcmp(fileName{:}, [searchName, '_proc', searchExt])
                        tifFiles(idx).proc = fileName{:};
                    end
                end
            end
        end
        
        function preprocessParamsChecker_Fcn(obj)
            prompt = {...
                'voxel size xy',...
                'voxel size z',...
                'medianFilter xy',...
                'medianFilter z',...
                'GaussianSmooth sigma',...
                'Bandpass Filter min',...
                'Bandpass Filter max',...
                'Subtract Bg radius',...
                'PSF xy',...
                'PSF z',...
                'Deconvolution RF'};
            dlg_title = 'Preprocess params';
            num_lines = [1, 40];
            defaultans = {num2str(obj.vxlSize(1)); num2str(obj.vxlSize(3)); ...
                num2str(obj.medianFilterParams(1)); num2str(obj.medianFilterParams(3)); ...
                num2str(obj.gaussianSmoothParams); ...
                num2str(obj.bandpassFilterParams(1)); num2str(obj.bandpassFilterParams(2)); ...
                num2str(obj.subtractBackgroundParams); ...
                num2str(obj.deconvolveParams_PSF(1)); num2str(obj.deconvolveParams_PSF(3)); ...
                num2str(obj.deconvolveParams)};
            answer = inputdlg(prompt, dlg_title, repmat(num_lines, 11, 1), defaultans);
            obj.vxlSize(1) = str2double(answer{1});
            obj.vxlSize(2) = str2double(answer{1});
            obj.vxlSize(3) = str2double(answer{2});
            obj.medianFilterParams(1) = str2double(answer{3});
            obj.medianFilterParams(2) = str2double(answer{3});
            obj.medianFilterParams(3) = str2double(answer{4});
            obj.gaussianSmoothParams = str2double(answer{5});
            obj.bandpassFilterParams(1) = str2double(answer{6});
            obj.bandpassFilterParams(2) = str2double(answer{7});
            obj.subtractBackgroundParams = str2double(answer{8});
            obj.deconvolveParams_PSF(1) = str2double(answer{9});
            obj.deconvolveParams_PSF(2) = str2double(answer{9});
            obj.deconvolveParams_PSF(3) = str2double(answer{10});
            obj.deconvolveParams = str2double(answer{11});
            tmpData = ScanImageTiffReader(obj.dataFile_1).data;
            obj.imgSize = [obj.vxlSize(1) * size(tmpData, 1); obj.vxlSize(2) * size(tmpData, 2); obj.vxlSize(3) * size(tmpData, 3)];
            obj.imgSize = obj.imgSize ./ [1; 1; 2]; % Correct z (two-channel image stack)!
            
            % Show values!
            set(findobj(obj.sLFigH, 'Tag', 'voxelSize_edit'), 'String', sprintf('%.2fx%.2fx%.2f', obj.vxlSize));
            set(findobj(obj.sLFigH, 'Tag', 'imgSize_edit'), 'String', sprintf('%.1fx%.1fx%.1f', obj.imgSize));
        end
        
        function initialTransform_Fcn(obj)
            if obj.initialTransform
                dftrOptions.gradient = 1;
                dftrOptions.subpixel = 10;
                [coarse, fine, ~] = dftregistration3D(double(obj.data.G0), double(obj.data.G1), dftrOptions);
                obj.initialTransformParams = coarse + fine;
                set(findobj(obj.sLFigH, 'Tag', 'initialOffset_edit'), 'String', sprintf('%.1fx%.1fx%.1f', obj.initialTransformParams));
            else
                obj.initialTransformParams = [];
                set(findobj(obj.sLFigH, 'Tag', 'initialOffset_edit'), 'String', []);
            end
            
            drawnow
        end
        
        function spotSummary_Fcn(obj, results)
            % Gather spot characteristics and intensity values!
%             doPointTransformation = true;
            doPointTransformation = false;
            switch doPointTransformation
                case true
%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VERY SPECIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                    delete(findobj('-regexp', 'Name', 'Voxel Intensity Comparison'))
                    
                    % Get voxel intensities from stack transformed data!
                    G0_t = cell2mat(arrayfun(@(x) obj.data.G0(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0)');
                    G0_t_max = cell2mat(arrayfun(@(x) max(obj.data.G0(results(x).VoxelIdxList)), 1:numel(results), 'Uni', 0)');
                    G1_t = cell2mat(arrayfun(@(x) obj.data.G1(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0)');
                    G1_t_max = cell2mat(arrayfun(@(x) max(obj.data.G1(results(x).VoxelIdxList)), 1:numel(results), 'Uni', 0)');
                    R0_t = cell2mat(arrayfun(@(x) obj.data.R0(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0)');
                    R0_t_max = cell2mat(arrayfun(@(x) max(obj.data.R0(results(x).VoxelIdxList)), 1:numel(results), 'Uni', 0)');
                    R1_t = cell2mat(arrayfun(@(x) obj.data.R1(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0)');
                    R1_t_max = cell2mat(arrayfun(@(x) max(obj.data.R1(results(x).VoxelIdxList)), 1:numel(results), 'Uni', 0)');
                    
                    % Add point transformation data to result!
                    results = point_transformation(obj, results);
                    % Load untransformed 3D data! Always try to load processed data (should have undergone complete preprocessing)!
                    tifFiles = tmpDirChecker(obj);
                    [~, name_, ~] = fileparts(fullfile(obj.dataOutputPath, obj.tmpImagesDir, obj.('dataFile_2')));
                    if ischar(tifFiles(1).proc)
                        % Load 'proc' type data!
                        filename_ = fullfile(obj.dataOutputPath, obj.tmpImagesDir, [name_, '_proc.tif']);
                    elseif ischar(tifFiles(1).mf)
                        % Load 'mf' type data!
                        filename_ = fullfile(obj.dataOutputPath, obj.tmpImagesDir, [name_, '_mf.tif']);
                    elseif ischar(tifFiles(1).raw)
                        % Load raw data!
                        filename_ = fullfile(obj.dataOutputPath, obj.tmpImagesDir, [name_, '_raw.tif']);
                    end
                    G1 = obj.tifLoader(filename_);
                    R1 = G1(:,:,2:2:end);
                    G1 = G1(:,:,1:2:end);
                    tpData.G1 = G1;
                    tpData.R1 = R1;
                    
                    % Get intensities from untransformed G1 image stack!
                    G1_tp_ = cell2mat(arrayfun(@(x) G1(results(x).VoxelIdxList2(~isnan(results(x).VoxelIdxList2))), 1:numel(results), 'Uni', 0)');
                    G1_tp_idx = cell2mat(arrayfun(@(x) ~isnan(results(x).VoxelIdxList2), 1:numel(results), 'Uni', 0)');
                    G1_tp = zeros(size(G1_t));
                    G1_tp(G1_tp_idx) = G1_tp_;
                    R1_tp_ = cell2mat(arrayfun(@(x) R1(results(x).VoxelIdxList2(~isnan(results(x).VoxelIdxList2))), 1:numel(results), 'Uni', 0)');
                    R1_tp = zeros(size(R1_t));
                    R1_tp(G1_tp_idx) = R1_tp_;
                    
                    G1_tp_max = zeros(numel(results), 1);
                    R1_tp_max = zeros(numel(results), 1);
                    for idx = 1:numel(results)
                        if all(isnan(results(idx).VoxelIdxList2))
                            G1_tp_max(idx,1) = 0;
                            R1_tp_max(idx,1) = 0;
                        else
                            G1_tp_max(idx,1) = max(G1(results(idx).VoxelIdxList2(~isnan(results(idx).VoxelIdxList2))));
                            R1_tp_max(idx,1) = max(R1(results(idx).VoxelIdxList2(~isnan(results(idx).VoxelIdxList2))));
                        end
                    end
                    
                    figure('Name', 'Voxel Intensity Comparison', 'NumberTitle', 'off', 'Position', [10 200 1400 520], 'Units', 'pixels')
                    subplot(1,2,1)
                    scatter(G1_t, G1_tp, 35, 'o', 'filled', 'MarkerFaceColor', [0.1, 0.6, 1.0], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 0.8)
                    hold on
                    scatter(G1_t_max, G1_tp_max, 50, 'o', 'filled', 'MarkerFaceColor', [0.8, 0.1, 0.1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 0.8)
                    hold off
                    title('G1 Intensities point vs. stack transformed', 'FontSize', 10, 'FontWeight', 'bold', 'interpreter', 'none')
                    xlabel('G1 stack transformed', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1], 'interpreter', 'none')
                    ylabel('G1 point transformed', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1], 'interpreter', 'none')
                    set(gca, 'FontSize', 10, 'FontWeight', 'bold', 'XLim', [0, max([G1_t_max; G1_tp_max])], 'YLim', [0, max([G1_t_max; G1_tp_max])])
                    grid on; box on
                    legend({'all'; 'max'}, 'Location', 'best')
                    
                    subplot(1,2,2)
                    scatter(R1_t, R1_tp, 35, 'o', 'filled', 'MarkerFaceColor', [0.1, 0.6, 1.0], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 0.8)
                    hold on
                    scatter(R1_t_max, R1_tp_max, 50, 'o', 'filled', 'MarkerFaceColor', [0.8, 0.1, 0.1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 0.8)
                    hold off
                    title('R1 Intensities point vs. stack transformed', 'FontSize', 10, 'FontWeight', 'bold', 'interpreter', 'none')
                    xlabel('R1 stack transformed', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1], 'interpreter', 'none')
                    ylabel('R1 point transformed', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1], 'interpreter', 'none')
                    set(gca, 'FontSize', 10, 'FontWeight', 'bold', 'XLim', [0, max([R1_t_max; R1_tp_max])], 'YLim', [0, max([R1_t_max; R1_tp_max])])
                    grid on; box on
                    legend({'all'; 'max'}, 'Location', 'best')
                    
                    % Get mean of G0 channel for normalization!
                    tmpMedian_ = median(G0_tp_max);
                    
                    channels_text = {'G0', 'R0'}; %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    tmpSums_ = zeros(numel(results), 4);
                    tmpN_ = zeros(numel(results), 4);
                    tmpMean_ = zeros(numel(results), 4);
                    tmpMax_ = zeros(numel(results), 4);
                    for idx = 1:numel(channels_text)
                        tmpValues_ = arrayfun(@(x) obj.data.(channels_text{idx})(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0);
                        tmpN_(:, idx) = cellfun(@numel, tmpValues_);
                        tmpSums_((1 + (idx-1)*numel(results)): (idx*numel(results))) = (cellfun(@(x) (sum(x(:))), tmpValues_))';
                        tmpMean_((1 + (idx-1)*numel(results)): (idx*numel(results))) = (cellfun(@(x) round(sum(x(:))/numel(x)), tmpValues_))';
                        tmpMax_((1 + (idx-1)*numel(results)): (idx*numel(results))) = (cellfun(@(x) max(x(:)), tmpValues_))';
                    end
                    channels_text = {'G1', 'R1'}; %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    for idx = 1:numel(channels_text)
                        tmpValues_ = arrayfun(@(x) tpData.(channels_text{idx})(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0);
                        tmpN_(:, idx+2) = cellfun(@numel, tmpValues_);
                        tmpSums_(:, idx+2) = (cellfun(@(x) (sum(x(:))), tmpValues_))';
                        tmpMean_(:, idx+2) = (cellfun(@(x) round(sum(x(:))/numel(x)), tmpValues_))';
                        tmpMax_(:, idx+2) = (cellfun(@(x) max(x(:)), tmpValues_))';
                    end
                    channels_text = {'G0', 'R0', 'G1', 'R1'}; %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    for idx = 1:numel(channels_text)
                        obj.synapseLocatorSummary.N = tmpN_(:,idx);
                        obj.synapseLocatorSummary.([channels_text{idx}, '_sum']) = tmpSums_(:,idx);
                        obj.synapseLocatorSummary.([channels_text{idx}, '_max']) = tmpMax_(:,idx);
                        obj.synapseLocatorSummary.([channels_text{idx}, '_sumByN']) = tmpMean_(:,idx);
                    end
                    
                    tmpSumsNorm = single(tmpSums_) / single(tmpMedian_);
                    tmpMaxNorm = single(tmpMax_) / single(tmpMedian_);
                    
                    channels_text = {'G0', 'R0', 'G1', 'R1'};
                    for idx = 1:numel(channels_text)
                        obj.synapseLocatorSummary.([channels_text{idx}, '_sum_norm']) = tmpSumsNorm(:,idx);
                        obj.synapseLocatorSummary.([channels_text{idx}, '_max_norm']) = tmpMaxNorm(:,idx);
                    end
                    
                    % Calculate channel ratios!
                    obj.synapseLocatorSummary.r_delta = tmpMax_(:,4) - tmpMax_(:,2); %obj.synapseLocatorSummary.R1_norm - obj.synapseLocatorSummary.R0_norm;
                    obj.synapseLocatorSummary.r_delta_norm = tmpMaxNorm(:,4) - tmpMaxNorm(:,2); % obj.synapseLocatorSummary.R1_norm - obj.synapseLocatorSummary.R0_norm;
                    obj.synapseLocatorSummary.g_sum_norm = tmpMaxNorm(:,1) + tmpMaxNorm(:,3); % obj.synapseLocatorSummary.R1_norm - obj.synapseLocatorSummary.R0_norm;
                    obj.synapseLocatorSummary.r_ratio = (eps + tmpMax_(:,4)) ./ (eps + tmpMax_(:,2));
                    obj.synapseLocatorSummary.g_ratio = (eps + tmpMax_(:,3)) ./ (eps + tmpMax_(:,1));
                    obj.synapseLocatorSummary.rg_pre = (eps + tmpMax_(:,2)) ./ (eps + tmpMax_(:,1));
                    obj.synapseLocatorSummary.rg_post = (eps + tmpMax_(:,4)) ./ (eps + tmpMax_(:,3));
                    obj.synapseLocatorSummary.r_factor = obj.synapseLocatorSummary.r_delta ./ tmpMax_(:,4);
                    
                    obj.synapseLocatorSummary.rDelta_gSum = obj.synapseLocatorSummary.r_delta_norm ./ obj.synapseLocatorSummary.g_sum_norm;
                    obj.synapseLocatorSummary.rDelta_g0 = obj.synapseLocatorSummary.r_delta_norm ./ tmpMaxNorm(:,1);
                    
                    obj.synapseLocatorSummary.VoxelIDs = {results.VoxelIdxList}';
                    obj.synapseLocatorSummary.VoxelIDs2 = {results.VoxelIdxList2}';
                    
                    % Calculate roi intensity similarities!
                    for results_idx = 1:numel(results)
                        tmpValues_ = zeros(numel(results(results_idx).VoxelIdxList), 4);
                        tmpValues_(:,1) = obj.data.G0(results(results_idx).VoxelIdxList);
                        tmpValues_(:,2) = obj.data.R0(results(results_idx).VoxelIdxList);
                        tmp_idx = ~isnan(results(results_idx).VoxelIdxList2);
                        tmpValues_(:,3) = nan(numel(results(results_idx).VoxelIdxList), 1);
                        tmpValues_(tmp_idx,3) = tpData.G1(results(results_idx).VoxelIdxList2(tmp_idx));
                        tmpValues_(tmp_idx,4) = tpData.R1(results(results_idx).VoxelIdxList2(tmp_idx));
                        [obj.synapseLocatorSummary.g0g1_match(results_idx,1), obj.synapseLocatorSummary.pval_g0g1(results_idx,1)] = obj.corrCalc(tmpValues_(:,1), tmpValues_(:,3)); % registration quality
                        [obj.synapseLocatorSummary.g0r1_match(results_idx,1), obj.synapseLocatorSummary.pval_g0r1(results_idx,1)] = obj.corrCalc(tmpValues_(:,1), tmpValues_(:,4)); % registration quality
                        [obj.synapseLocatorSummary.g1r1_match(results_idx,1), obj.synapseLocatorSummary.pval_g1r1(results_idx,1)] = obj.corrCalc(tmpValues_(:,3), tmpValues_(:,4)); % registration quality
                        [obj.synapseLocatorSummary.g0r0_match(results_idx,1), obj.synapseLocatorSummary.pval_g0r0(results_idx,1)] = obj.corrCalc(tmpValues_(:,1), tmpValues_(:,2)); % registration quality
                        [obj.synapseLocatorSummary.r0r1_match(results_idx,1), obj.synapseLocatorSummary.pval_r0r1(results_idx,1)] = obj.corrCalc(tmpValues_(:,2), tmpValues_(:,4)); % registration quality
                        if any(isnan(obj.synapseLocatorSummary.g0r1_match(results_idx,1)))
                            keyboard
                        end
                    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VERY SPECIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%}
                case false
                    % Get intensity values (=channel data) and calculate ratios!
                    obj.spotDataCollector_Fcn(results, 'proc');
                    
                    tifFiles = tmpDirChecker(obj);
                    if obj.transformRawData && ~obj.loadRegisteredImages
                        % Load median filtered data!
                        if ischar(tifFiles(1).mf)
                            % Load 'mf' type data!
                            obj.spotDataCollector_Fcn(results, 'mf');
                        end
                        if ischar(tifFiles(1).raw)
                            % Load raw data!
                            obj.spotDataCollector_Fcn(results, 'raw');
                        end
                    end
            end
        end
        
        function spotDataCollector_Fcn(obj, results, processingType)
            synapseLocatorSummary_ = obj.summaryTemplate;
            
            % Get values that are used for raw, median filtered, and processed data!
            tmpPos_ = round(cat(1,results.spot_center));
            tmpDia_ = round(cat(1,results.spot_diameters_ellipsoid), 1);
            tmpBB_ = round(cat(1,results.bb), 1);
            synapseLocatorSummary_.Spot_ID = [results(:).spot_id]';
            synapseLocatorSummary_.row = tmpPos_(:,1);
            synapseLocatorSummary_.column = tmpPos_(:,2);
            synapseLocatorSummary_.section = tmpPos_(:,3);
            synapseLocatorSummary_.diameter_x = tmpDia_(:,1);
            synapseLocatorSummary_.diameter_y = tmpDia_(:,2);
            synapseLocatorSummary_.diameter_z = tmpDia_(:,3);
            synapseLocatorSummary_.bb_x = tmpBB_(:,1);
            synapseLocatorSummary_.bb_y = tmpBB_(:,2);
            synapseLocatorSummary_.bb_z = tmpBB_(:,3);
            synapseLocatorSummary_.N = [results(:).spotN]';
            synapseLocatorSummary_.VoxelIDs = {results.VoxelIdxList}';
            synapseLocatorSummary_.VoxelIDs2 = {results.VoxelIdxList}';
            synapseLocatorSummary_.edge = ...
                (ceil(synapseLocatorSummary_.bb_x / 2) > synapseLocatorSummary_.column) |...
                (ceil(synapseLocatorSummary_.bb_x / 2) > (double(obj.data.sizeStack0(2)) - synapseLocatorSummary_.column)) |...
                (ceil(synapseLocatorSummary_.bb_y / 2) > synapseLocatorSummary_.row) |...
                (ceil(synapseLocatorSummary_.bb_y / 2) > (double(obj.data.sizeStack0(1)) - synapseLocatorSummary_.row)) |...
                (ceil(synapseLocatorSummary_.bb_z / 2) > synapseLocatorSummary_.section) |...
                (ceil(synapseLocatorSummary_.bb_z / 2) > (double(obj.data.sizeStack0(3)) - synapseLocatorSummary_.section));
            % Check for edges!
            if obj.excludeSpotsAtEdges
                edgeIdx = eq(synapseLocatorSummary_.edge, 1);
            else
                edgeIdx = false(numel(results), 1);
            end

            synapseLocatorSummary_.outlier = false(numel(results), 1);
            
            tmpSums_ = zeros(numel(results), 4);
            tmpMean_ = zeros(numel(results), 4);
            tmpMedian_ = zeros(numel(results), 4);
            tmpMax_ = zeros(numel(results), 4);
            tmpValues_ = cell(numel(results), 4);
            
            % Set slots for label results! Start with NA, set to {0, 1} after running 'find signals'!
            synapseLocatorSummary_.spotMatch = nan(numel(results), 1);
            synapseLocatorSummary_.spotMatch_probs = nan(numel(results), 1);
            
            channels_text = {'G0', 'R0', 'G1', 'R1'};

            switch processingType
                case 'proc'
                    for idx = 1:numel(channels_text)
                        tmpValues_(:, idx) = arrayfun(@(x) obj.data.(channels_text{idx})(results(x).VoxelIdxList), 1:numel(results), 'Uni', 0)';
                        tmpSums_(:, idx) = (cellfun(@(x) (sum(x(:))), tmpValues_(:, idx)))';
                        tmpMean_(:, idx) = (cellfun(@(x) round(mean(x)), tmpValues_(:, idx)))';
                        tmpMedian_(:, idx) = (cellfun(@(x) round(median(x)), tmpValues_(:, idx)))';
                        tmpMax_(:, idx) = (cellfun(@(x) max(x(:)), tmpValues_(:, idx)))';

                        synapseLocatorSummary_.([channels_text{idx}, '_sum']) = tmpSums_(:,idx);
                        synapseLocatorSummary_.([channels_text{idx}, '_max']) = tmpMax_(:,idx);
                        synapseLocatorSummary_.([channels_text{idx}, '_mean']) = tmpMean_(:,idx);
                        synapseLocatorSummary_.([channels_text{idx}, '_median']) = tmpMedian_(:,idx);
                    end
                    
                    % Check for outlier (default, only R0 is considered)!
                    Q = quantile(synapseLocatorSummary_.R0_max(~edgeIdx), [0.25, 0.75], 'method', 'exact');
                    outThresh = Q(2) + 1.5 * (Q(2) - Q(1));
                    synapseLocatorSummary_.outlier = gt(synapseLocatorSummary_.R0_max, outThresh);

                    % Add registration quality measure! Calculate roi intensity similarities!
                    [synapseLocatorSummary_.g0g1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,1), tmpValues_(:,3));
                    [synapseLocatorSummary_.g0r1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,1), tmpValues_(:,4));
                    [synapseLocatorSummary_.g1r1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,3), tmpValues_(:,4));
                    [synapseLocatorSummary_.g0r0_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,1), tmpValues_(:,2));
                    [synapseLocatorSummary_.r0r1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,2), tmpValues_(:,4));
                    
                    % Calculate channel ratios (allways from MAX values!!!!)!
                    means_ = mean(tmpMax_(~synapseLocatorSummary_.outlier & ~edgeIdx,:));
                    synapseLocatorSummary_.r_delta = (tmpMax_(:,4) - tmpMax_(:,2)) / means_(2);
                    synapseLocatorSummary_.r_ratio = tmpMax_(:,4) ./ tmpMax_(:,2);
                    synapseLocatorSummary_.g_ratio = tmpMax_(:,3) ./ tmpMax_(:,1);
                    synapseLocatorSummary_.rg_pre = (tmpMax_(:,2) / means_(2)) ./ (tmpMax_(:,1) / means_(1));
                    synapseLocatorSummary_.rg_post = (tmpMax_(:,4) / means_(2)) ./ (tmpMax_(:,3) / means_(1));
                    synapseLocatorSummary_.r_factor = synapseLocatorSummary_.r_delta ./ (tmpMax_(:,4) / means_(2));                    
                    synapseLocatorSummary_.rDelta_gSum = synapseLocatorSummary_.r_delta ./ (sum(tmpMax_(:, [1,3]), 2) / means_(1));
                    synapseLocatorSummary_.rDelta_g0 = synapseLocatorSummary_.r_delta ./ (tmpMax_(:,1) / means_(1));
                                        
                    obj.synapseLocatorSummary = synapseLocatorSummary_;
                    
                case {'mf', 'raw'}
                    if obj.upsampling
                        VoxelIDs_ = cell(numel(results), 1);
                        for idx = 1:numel(synapseLocatorSummary_.VoxelIDs)
                            [x,y,z] = ind2sub(size(obj.data.G0), synapseLocatorSummary_.VoxelIDs{idx});
                            VoxelIDs_{idx} = sub2ind(size(obj.data.G0) ./ [1, 1, 2], x, y, round(z / 2));
                        end
                    else
                        VoxelIDs_ = synapseLocatorSummary_.VoxelIDs;
                    end

                    if contains(processingType, 'mf')
                        fileNames = {'G0_mf.tif', 'R0_mf.tif', 'G1_mf_transformed.tif', 'R1_mf_transformed.tif'};
                    else
                        fileNames = {'G0_raw.tif', 'R0_raw.tif', 'G1_raw_transformed.tif', 'R1_raw_transformed.tif'};
                    end
                    
                    tmpValues_ = cell(numel(results), 4);
                    for idx = 1:numel(fileNames)
                        fPath = fullfile(obj.dataOutputPath, fileNames{idx});
                        tmpData_ = obj.tifLoader(fPath);
                        tmpValues_(:, idx) = arrayfun(@(x) tmpData_(VoxelIDs_{x}), 1:numel(results), 'Uni', 0)';
                    end
                    clear tmpData_

                    for idx = 1:numel(channels_text)
                        tmpSums_(:, idx) = (cellfun(@(x) (sum(x(:))), tmpValues_(:, idx)))';
                        tmpMean_(:, idx) = (cellfun(@(x) round(mean(x)), tmpValues_(:, idx)))';
                        tmpMedian_(:, idx) = (cellfun(@(x) round(median(x)), tmpValues_(:, idx)))';
                        tmpMax_(:, idx) = (cellfun(@(x) max(x(:)), tmpValues_(:, idx)))';

                        synapseLocatorSummary_.([channels_text{idx}, '_sum']) = tmpSums_(:,idx);
                        synapseLocatorSummary_.([channels_text{idx}, '_max']) = tmpMax_(:,idx);
                        synapseLocatorSummary_.([channels_text{idx}, '_mean']) = tmpMean_(:,idx);
                        synapseLocatorSummary_.([channels_text{idx}, '_median']) = tmpMedian_(:,idx);
                    end

                    % Check for outlier (default, only R0 is considered)!
                    Q = quantile(synapseLocatorSummary_.R0_max(~edgeIdx), [0.25, 0.75], 'method', 'exact');
                    outThresh = Q(2) + 1.5 * (Q(2) - Q(1));
                    synapseLocatorSummary_.outlier = gt(synapseLocatorSummary_.R0_max, outThresh);

                    % Add registration quality measure! Calculate roi intensity similarities!
                    [synapseLocatorSummary_.g0g1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,1), tmpValues_(:,3));
                    [synapseLocatorSummary_.g0r1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,1), tmpValues_(:,4));
                    [synapseLocatorSummary_.g1r1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,3), tmpValues_(:,4));
                    [synapseLocatorSummary_.g0r0_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,1), tmpValues_(:,2));
                    [synapseLocatorSummary_.r0r1_match] = cellfun(@(x,y) obj.corrCalc(x, y), tmpValues_(:,2), tmpValues_(:,4));
                    
                    % Calculate channel ratios (allways from MAX values!!!!)!
                    means_ = mean(tmpMax_(~synapseLocatorSummary_.outlier & ~edgeIdx,:));
                    synapseLocatorSummary_.r_delta = (tmpMax_(:,4) - tmpMax_(:,2)) / means_(2);
                    synapseLocatorSummary_.r_ratio = tmpMax_(:,4) ./ tmpMax_(:,2);
                    synapseLocatorSummary_.g_ratio = tmpMax_(:,3) ./ tmpMax_(:,1);
                    synapseLocatorSummary_.rg_pre = (tmpMax_(:,2) / means_(2)) ./ (tmpMax_(:,1) / means_(1));
                    synapseLocatorSummary_.rg_post = (tmpMax_(:,4) / means_(2)) ./ (tmpMax_(:,3) / means_(1));
                    synapseLocatorSummary_.r_factor = synapseLocatorSummary_.r_delta ./ (tmpMax_(:,4) / means_(2));                    
                    synapseLocatorSummary_.rDelta_gSum = synapseLocatorSummary_.r_delta ./ (sum(tmpMax_(:, [1,3]), 2) / means_(1));
                    synapseLocatorSummary_.rDelta_g0 = synapseLocatorSummary_.r_delta ./ (tmpMax_(:,1) / means_(1));
                    
                    if contains(processingType, 'mf')
                        obj.synapseLocatorSummary_mf = synapseLocatorSummary_;
                    end
                    if contains(processingType, 'raw')
                        obj.synapseLocatorSummary_raw = synapseLocatorSummary_;
                    end
            end
        end
        
        function synapseLocatorSummarySaver(obj)
            
            % Get available data types!
            tifFiles = tmpDirChecker(obj);
            summaries = cell(0);
            if ischar(tifFiles(1).proc)
                summaries = [summaries; '_proc'];
            end
            if ischar(tifFiles(1).mf)
                summaries = [summaries; '_mf'];
            end
            if ischar(tifFiles(1).raw)
                summaries = [summaries; '_raw'];
            end
            
            for summary = summaries(:)'
                if contains(summary, '_proc')
                    Summary = struct2table(obj.synapseLocatorSummary);
                else
                    Summary = struct2table(obj.(['synapseLocatorSummary', summary{:}]));
                end
                if obj.upsampling
                    Summary.section = round(Summary.section ./ 2);
                    
                    for idx = 1:height(Summary)
                        [x,y,z] = ind2sub(size(obj.data.G0), Summary.VoxelIDs{idx});
                        Summary.VoxelIDs{idx} = sub2ind(size(obj.data.G0) ./ [1, 1, 2], x, y, round(z / 2));
                    end
                end
                % Save synapseLocatorSummary as csv!
                Summary{:, 'VoxelIDs'} = cellfun(@(x) mat2str(x), Summary{:, 'VoxelIDs'}, 'Uni', 0);
                Summary{:, 'VoxelIDs2'} = cellfun(@(x) mat2str(x), Summary{:, 'VoxelIDs2'}, 'Uni', 0);
                writetable(Summary, fullfile(obj.dataOutputPath, ['SL_Summary', summary{:}, '.csv']));
                save(fullfile(obj.dataOutputPath, ['SL_Summary', summary{:}, '.mat']), 'Summary');
            end                
        end
        
        function synapseLocatorSummaryLabelTifSaver(obj, saveastiff_options)            
            % Blow up for better visibility in display!
            se = strel('sphere', 3);

            if obj.upsampling
                stack_ = zeros(size(obj.data.G0) ./ [1, 1, 2]);
                idx_ = sub2ind(size(obj.data.G0) ./ [1, 1, 2], obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, round(obj.synapseLocatorSummary.section / 2));
            else
                stack_ = zeros(size(obj.data.G0));
                idx_ = sub2ind(size(obj.data.G0), obj.synapseLocatorSummary.row, obj.synapseLocatorSummary.column, obj.synapseLocatorSummary.section);
            end
            
            % Use calculted dR/G0 values (default params) as 'color'!
            label_tmp = stack_;
            label_tmp(idx_) = obj.synapseLocatorSummary.rDelta_g0;            
            label_tmp = convn(label_tmp, se.Neighborhood, 'same');
            saveastiff(label_tmp, fullfile(obj.dataOutputPath, 'LabelSummary.tif'), saveastiff_options);
        end
        
        function roiData = roiData_Fcn(obj)
            % Gather feature data for active rois!
            % There should be points for both classes, unless a new roi is
            % added to an existing model!
            % Gather features keeping the order of features names from obj.featureNames!
            voxels_1 = arrayfun(@(x) obj.class1_roi{x}.pixels, 1:numel(obj.class1_roi), 'Uni', 0);
            voxels_1 = cat(1, voxels_1{:});
            voxels_2 = arrayfun(@(x) obj.class2_roi{x}.pixels, 1:numel(obj.class2_roi), 'Uni', 0);
            voxels_2 = cat(1, voxels_2{:});
            data_1 = zeros(numel(voxels_1), numel(obj.featureNames));
            data_2 = zeros(numel(voxels_2), numel(obj.featureNames));
            for featureNameIdx_ = 1:numel(obj.featureNames)
                m = matfile(fullfile(obj.featureDataDir, [obj.featureNames{featureNameIdx_}, '.mat']));
                data_1(:, featureNameIdx_) = arrayfun(@(x) m.stack(x, 1), voxels_1);
                data_2(:, featureNameIdx_) = arrayfun(@(x) m.stack(x, 1), voxels_2);
            end
            roiData = [data_1; data_2];
            labels = [zeros(size(data_1,1), 1); ones(size(data_2,1), 1)]; % class 0 is spot
            roiData = unique([roiData, labels], 'rows');
        end
        
        function cmdPID_Fcn(obj)
            cmdPIDs = System.Diagnostics.Process.GetProcessesByName('cmd');
            cmdPIDs = arrayfun(@(x) cmdPIDs(x).Id, 1:cmdPIDs.Length);
            obj.internalStuff.cmdPID = setdiff(cmdPIDs, obj.internalStuff.cmdPID);
        end    
        
        function [out] = uint16Checker(obj, in)
            % Make sure that data are of type uint16!

            % Avoid negative intensities!
            if lt(min(in(:)), 0)
                % fprintf('%s\n', 'OFFSET!')
                in = in - min(in(:));
            end
            if gt(range(in,'all'), intmax('uint16'))
                % fprintf('%s\n', 'RANGE!')
                in = obj.rescaler(in, 0, intmax('uint16'));
            end
            if ~isa(in, 'uint16')
                % fprintf('%s\n', 'CONVERT!')
                out = cast(in, 'uint16');
            else
                out = in;
            end
        end        
    end
    
    % Static methods
    methods(Static)
        function [rho_] = corrCalc(values1, values2)
        % function [rho_, pval_] = corrCalc(values1, values2)
            % Avoid reporting NaN results for uniform input values!
            
            if eq(numel(unique(values1)), 1) || eq(numel(unique(values2)), 1)
                rho_ = zeros(1, 1, 'single');
                % pval_ = ones(1, 1, 'single');
            else
                % [rho_, pval_] = corr(single(values1), single(values2), 'Type', 'Spearman', 'Rows', 'complete');
                [rho_] = fastCorr(single(values1), single(values2));
            end
        end
        
        function [rho] = fastCorr(A, B)
            % Use minimal code to calculate Pearson correlation coefficient! Quite
            % fast in this context (spot intensity values)! Expects no NaNs! Skip
            % calculation of pvalues!
            xy = dot(A, B);
            n = numel(A);
            mx = sum(A) / n;
            my = sum(B) / n;
            x2 = dot(A, A);
            y2 = dot(B, B);
            sx = sqrt(x2 - n .* (mx.^2));  % sx, sy - standard deviations
            sy = sqrt(y2 - n .* (my.^2));
            rho = (xy - n .* mx .* my) ./ (sx .* sy);      % correlation coefficient
            % t = coef .* sqrt((n - 2) ./ (1 - coef.^2));  % t-test statistic
            % p = 2*tcdf(-abs(t), n - 2); % pvalue
        end
        
        function result = tops(x, n)
            % Calculate median and sum from top n entries in vector x!
            
            x = sort(x, 'descend');
            result.medianValue = round(median(x(1:min([n, numel(x)]))));
            result.sumValue = round(sum(x(1:min([n, numel(x)]))));            
        end
        
        function [B] = rescaler(A, new_min, new_max)
            %rescaler Does some scaling of a matrix!
            
            A = double(A);
            new_min = double(new_min);
            new_max = double(new_max);

            current_max = max(A(:));
            current_min = min(A(:));
            
            B =((A-current_min)*(new_max-new_min))/(current_max-current_min) + new_min;
            
        end
        
        function [imagejSettings, ijRunMode] = imageJChecker()
            % Check if ImageJ is running!
            % Aug2018: Headless not working!!!!!!!!!!!!!!!!!!
            imagejSettings = '-macro';
            ijRunMode = 'newStart';
            
            %{
            imagejP = System.Diagnostics.Process.GetProcessesByName('imagej-win64');
            fijiP = System.Diagnostics.Process.GetProcessesByName('fiji-win64');
            if any([gt(imagejP.Length, 0), gt(fijiP.Length, 0)])
                % imagejSettings = '--headless --console --allow-multiple -debug -macro';
                % imagejSettings = '--headless --console --allow-multiple -macro';
                imagejSettings = '--headless --allow-multiple -macro';
                ijRunMode = 'headless';
            else
                % imagejSettings = '--console -debug -macro';
                % imagejSettings = '--console -macro';
                imagejSettings = '-macro';
                ijRunMode = 'newStart';
            end
            %}
        end
        
        function stack = tifLoader(fPath)
            warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffErrorAsWarning')
            tmpTiff = Tiff(fPath);
            pixelsPerLine = tmpTiff.getTag('ImageWidth');
            linesPerFrame = tmpTiff.getTag('ImageLength');
            noImages = numel(imfinfo(fPath));
            stack = zeros(linesPerFrame, pixelsPerLine, noImages, 'double');
            for idx = 1:noImages
                tmpTiff.setDirectory(idx)
                stack(:,:,idx) = (tmpTiff.read());
            end
            tmpTiff.close
            warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffErrorAsWarning')
        end
    end
end

