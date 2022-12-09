%% Models to Fit
clear all; 
% batchRunEMfit(modelClassToFit,pathToData,resultsDir,'key1','val1','key2','val2');

Data=generateExampleDataset(50,'results_0912');


modelsToFit = [11]; %% this is currently (llbaexpb and) therapy change models
models = modelList;
models = models(modelsToFit);

batchRunEMfit('mAffectiveGoNogo', Data, 'results_0912', 'modelstofit', modelsToFit,'checkGradients',1,'emit',2)