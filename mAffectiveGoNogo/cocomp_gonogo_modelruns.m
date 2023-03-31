%% Models to Fit
clear all; 
% batchRunEMfit(modelClassToFit,pathToData,resultsDir,'key1','val1','key2','val2');

%% example data

% Data=generateExampleDataset(50,'results');

%% or real data

clear all;

T = readtable('gonogo_data_forModel_270323.csv');
% T = readtable('newdf.csv');

T.a = 2-T.action;

C = unique(T.subID);

% %% if running gonogo data for model
% for sj = 1:length(C)
%     S(sj).ID = C{(sj),1};
%     S(sj).a = T.a(((sj-1)*720+1):(sj)*720)';
%     S(sj).r = T.reinforcement(((sj-1)*720+1):(sj)*720)';
%     S(sj).s = T.stim(((sj-1)*720+1):(sj)*720)';
%     S(sj).w = T.session(((sj-1)*720+1):(sj)*720)';
%     S(sj).Nch = length(S(sj).a);
% end

%% if running newdf with complete 3 session data
for sj = 1:length(C)
    S(sj).ID = C{(sj),1};
	 ind = strcmp(S(sj).ID,T.subID);
    S(sj).a = T.a(ind)';
    S(sj).r = T.reinforcement(ind)';
    S(sj).s = T.stim(ind)';
    S(sj).w = T.session(ind)';
    S(sj).Nch = sum(ind);
    %S(sj).a = T.a(((sj-1)*540+1):(sj)*540)';
    %S(sj).r = T.reinforcement(((sj-1)*540+1):(sj)*540)';
    %S(sj).s = T.stim(((sj-1)*540+1):(sj)*540)';
    %S(sj).w = T.session(((sj-1)*540+1):(sj)*540)';
    %S(sj).Nch = length(S(sj).a);
end

Data=S;

% test = structfun(rmmissing,Data);
% test = structfun(rmmissing,Data,'UniformOutput',false);
% A = structfun(func,S);
% Data = structfun(rmmissing(Data));

% dbstop error
% 
% sj=1;
% D = Data(sj);
% np=6;
% 
% x = randn(np,1);
% mu = zeros(np,1);
% nui = eye(np,1);
% doprior = 1;
% options.generatesurrogatedata=0;
% [l,dl,dsurr] = llbaepxbses(x,D,mu,nui,doprior,options);

Nsj = length(Data);
for sj=1:Nsj
	a = Data(sj).a;
	s = Data(sj).s;
	r = Data(sj).r;
	w = Data(sj).w;
	for ses = 1:4
		for ss=1:4
			na(ss,ses,sj) = sum(a(s==ss & w==ses)==1);
			nr(ss,ses,sj) = sum(r(s==ss & w==ses));
			nx(ss,ses,sj) = sum((s==ss & w==ses));
		end
	end
end
mna = nanmean(na./nx,3)
mnr = nanmean(nr./nx,3)


%% models

% only models 11 and 12 are set up to accomodate 4 sessions of data
% (Nch=640)
modelsToFit = [11:13]; %% ses change and no change models
models = modelList;
models = models(modelsToFit);

batchRunEMfit('mAffectiveGoNogo', Data, 'results', 'modelstofit', modelsToFit, 'maxit',40 ,'checkGradients',0) 

% emit, you can tell it to only run a set number of loops
