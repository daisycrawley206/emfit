%% Models to Fit
% clear all; 
% batchRunEMfit(modelClassToFit,pathToData,resultsDir,'key1','val1','key2','val2');

%% example data

% Data=generateExampleDataset(50,'results');

%% or real data

clear all;

T = readtable('gonogo_data_forModel_270323.csv');
T.a = T.action+1;

C = unique(T.subID);

for sj = 1:length(C);
    S(sj).ID = C{(sj),1};
    S(sj).a = T.a(((sj-1)*720+1):(sj)*720)';
    S(sj).r = T.reinforcement(((sj-1)*720+1):(sj)*720)';
    S(sj).s = T.stim(((sj-1)*720+1):(sj)*720)';
    S(sj).w = T.session(((sj-1)*720+1):(sj)*720)';
    S(sj).Nch = length(S(sj).a);
end

Data=S;

%% models

% only models 11 and 12 are set up to accomodate 4 sessions of data
% (Nch=640)
modelsToFit = [13, 11,12]; %% ses change and no change models
models = modelList;
models = models(modelsToFit);

batchRunEMfit('mAffectiveGoNogo', Data, 'results', 'modelstofit', modelsToFit, 'maxit',3 ,'checkGradients',1) 

% emit, you can tell it to only run a set number of loops
