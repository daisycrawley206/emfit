%% Models to Fit
clear all; 
% batchRunEMfit(modelClassToFit,pathToData,resultsDir,'key1','val1','key2','val2');

%% example data

% Data=generateExampleDataset(50,'results');

%% or real data

clear all;

% drd = '/Users/daisycrawley/GitHub/iapttasks/analyses/gonogo/gonogo_analysis/'; 
drd = '/Users/qhuys/projects/Cocomp/iapttasks/analyses/gonogo/gonogo_analysis/'; 
% T = readtable('gonogo_data_forModel_270323.csv');
% T = readtable('gonogo_data_forModel_200423_1_3.csv')
T = readtable([drd 'gonogo_data_forModel_290623_1_3.csv']); 

% T = readtable('newdf.csv');

T.a = 2-T.action;

C = unique(T.subID);

%% wrangling data into a struct for the models 
for sj = 1:length(C)
    S(sj).ID = C{(sj),1};
	ind = strcmp(S(sj).ID,T.subID);
    S(sj).a = T.a(ind)';
    S(sj).r = T.reinforcement(ind)';
    S(sj).s = T.stim(ind)';
    S(sj).w = T.session(ind)';
    S(sj).Nch = sum(~isnan(S(sj).a));
end

% S(sj).a(S(sj).w>1)=NaN; %% if we want only session 1 data (or use this will full data set to drop ses 4)

Data = S;

%% throw out any subs who pressed the same stimulus the whole time or performed below chance 

% subsRemoved = sum(Data.a==1,2)==180;
% idx=find(all(~diff(A)))
% out=A(1,idx)

idx = ismember({Data.ID}, 'uEDmL4Uo8AcpbpBBfpXQkxzBxNT2') ;
Data(idx) = [] ;

idx = ismember({Data.ID}, 'Rg9EeKHITqP0pMNmuvyDY28FXXk1') ;
Data(idx) = [] ;

idxx = ismember({Data.ID}, 'gS4tVDEppjaSrqikwKdlU5vSZjj1') ;
Data(idxx) = [];

idxx = ismember({Data.ID}, '0K1wfNeZSEQZZcNzLeqpdLpNif73') ;
Data(idxx) = [];

idxx = ismember({Data.ID}, 'Mjkk62C4j4WPlaI2qARQ2d1tUH42') ;
Data(idxx) = [];

idxx = ismember({Data.ID}, 'zdmF51otguRrUb7LvEiEcvcW6RJ3') ;
Data(idxx) = [];

 %% save it for regressor matrix

% save(['results' filesep 'Data_clean.mat'],'Data');


 %% old code
% for sj=1:length(C)
%     Data(sj).subsRemoved = find(all(~diff(Data(sj).a(1:180))));
% end
% disp(sprintf('%d subjects who always picked the same stimulus and were removed',sum(Data.subsRemoved)));
% % the subject: 'uEDmL4Uo8AcpbpBBfpXQkxzBxNT2'

%% old daisy attempts
% 
% if running gonogo data for model

% for sj = 1:length(C)
%     S(sj).ID = C{(sj),1};
%     S(sj).a = T.a(((sj-1)*720+1):(sj)*720)';
%     S(sj).r = T.reinforcement(((sj-1)*720+1):(sj)*720)';
%     S(sj).s = T.stim(((sj-1)*720+1):(sj)*720)';
%     S(sj).w = T.session(((sj-1)*720+1):(sj)*720)';
%     S(sj).Nch = length(S(sj).a);
% end

% if running newdf with complete 3 session data
% for sj = 1:length(C)
%     S(sj).ID = C{(sj),1};
% 	 ind = strcmp(S(sj).ID,T.subID);
%     S(sj).a = T.a(((sj-1)*540+1):(sj)*540)';
%     S(sj).r = T.reinforcement(((sj-1)*540+1):(sj)*540)';
%     S(sj).s = T.stim(((sj-1)*540+1):(sj)*540)';
%     S(sj).w = T.session(((sj-1)*540+1):(sj)*540)';
%     S(sj).Nch = length(S(sj).a);
% end

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

%% compiling for each subject 

Nsj = length(Data);
for sj=1:Nsj
	a = Data(sj).a;
	s = Data(sj).s;
	r = Data(sj).r;
	w = Data(sj).w;
	for ses = 1:3
		for ss=1:3
			na(ss,ses,sj) = sum(a(s==ss & w==ses)==1);
			nr(ss,ses,sj) = sum(r(s==ss & w==ses));
			nx(ss,ses,sj) = sum((s==ss & w==ses));
		end
	end
end
mna = nanmean(na./nx,3)
mnr = nanmean(nr./nx,3)

%% change back to emfit

% cd '/Users/daisycrawley/GitHub/emfit/mAffectiveGoNogo'; 

%% models

% only models 11 and 12 are set up to accomodate 4 sessions of data
% (Nch=640)
modelsToFit = [11]; %% ses change and no change models
%modelsToFit = [15]; %% ses change and no change models
models = modelList;
models = models(modelsToFit);

batchRunEMfit('mAffectiveGoNogo', Data, 'results', 'modelstofit', modelsToFit,'checkGradients',0,'maxit',5) 

% emit / maxit , you can tell it to only run a set number of loops
% 'maxit',10
