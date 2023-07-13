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

Data = S;

%% throw out any subs who pressed the same stimulus the whole time or performed below chance 

% subsRemoved = sum(Data.a==1,2)==180;
% idx=find(all(~diff(A)))
% out=A(1,idx)

idx = ismember({Data.ID}, 'uEDmL4Uo8AcpbpBBfpXQkxzBxNT2') ; Data(idx) = [] ;
idx = ismember({Data.ID}, 'Rg9EeKHITqP0pMNmuvyDY28FXXk1') ; Data(idx) = [] ;
idx = ismember({Data.ID}, 'gS4tVDEppjaSrqikwKdlU5vSZjj1') ; Data(idx) = [];
idx = ismember({Data.ID}, '0K1wfNeZSEQZZcNzLeqpdLpNif73') ; Data(idx) = [];
idx = ismember({Data.ID}, 'Mjkk62C4j4WPlaI2qARQ2d1tUH42') ; Data(idx) = [];
idx = ismember({Data.ID}, 'zdmF51otguRrUb7LvEiEcvcW6RJ3') ; Data(idx) = [];

Nsj = length(Data);
sk=0; 
for sj=1:Nsj; 
	for w=1:3
		i = Data(sj).w==w; 
		a = Data(sj).a(i); 
		if any(~isnan(a));
			sk=sk+1; 
			DataSeparateSessions(sk).ID  = Data(sj).ID;       
			DataSeparateSessions(sk).sj  = sj;       
			DataSeparateSessions(sk).a   = Data(sj).a(i);     
			DataSeparateSessions(sk).r   = Data(sj).r(i);     
			DataSeparateSessions(sk).s   = Data(sj).s(i);     
			DataSeparateSessions(sk).w   = Data(sj).w(i)*0+1; 
			DataSeparateSessions(sk).ses = unique(Data(sj).w(i));
			DataSeparateSessions(sk).Nch = length(Data(sj).a(i));
		end
	end
end
Nsj = sk; 

modelsToFit = [11 13]; %% ses change and no change models
models = modelList;
models = models(modelsToFit);

batchRunEMfit('mAffectiveGoNogo', DataSeparateSessions, 'results_testretest', 'modelstofit', modelsToFit,'checkGradients',0);%'maxit',15) 

sjind =[DataSeparateSessions.sj];
sesind=[DataSeparateSessions.ses];

nModls = length(models); 
resultsDir = 'results_testretest'; 
for k=1:nModls
	try 
		loadstr = sprintf('%s/%s',resultsDir,models(k).name);
		fprintf('loading model %i %s',k,loadstr);
		R.(models(k).name) = load(loadstr);
		PL(k,:) = R.(models(k).name).stats.PL;
		LL(k,:) = R.(models(k).name).stats.LL;
		iBIC(k) = R.(models(k).name).bf.ibic;
		ilap(k) = R.(models(k).name).bf.ilap;
		fprintf('...ok\n');
	catch 
		fprintf('...ERROR, fit not loaded\n');
		iBIC(k) = NaN;
		ilap(k) = NaN;
		LL(k,:) = NaN;
	end
end

% get best model 
[foo,bestmodel] = min(iBIC);

figure(1);clf;
for mdl=1:2

	E = R.(models(mdl).name).E; 

	clear e12 e13 e23
	n12=0; n13=0; n23=0;
	for sj=unique(sjind);
		i = sjind==sj; 
		if any(sesind(i) == 1) & any(sesind(i)==2); 
			n12 = n12+1; 
			j = i & sesind==1; e12(n12,:,1) = E(:,j);
			j = i & sesind==2; e12(n12,:,2) = E(:,j);
		end
		if any(sesind(i) == 1) & any(sesind(i)==3); 
			n13 = n13+1; 
			j = i & sesind==1; e13(n13,:,1) = E(:,j);
			j = i & sesind==3; e13(n13,:,2) = E(:,j);
		end
		if any(sesind(i) == 2) & any(sesind(i)==3); 
			n23 = n23+1; 
			j = i & sesind==2; e23(n23,:,1) = E(:,j);
			j = i & sesind==3; e23(n23,:,2) = E(:,j);
		end
	end

	clear cr pr 
	for k=1:size(E,1)
		[cr(k,1),pr(k,1)] = corr(e12(:,k,1),e12(:,k,2),'type','spearman');
		[cr(k,2),pr(k,2)] = corr(e13(:,k,1),e13(:,k,2),'type','spearman');
		[cr(k,3),pr(k,3)] = corr(e23(:,k,1),e23(:,k,2),'type','spearman');
	end
		
	subplot(1,nModls,mdl)
		h=bar(cr);
		set(gca,'xticklabel',models(mdl).parnames_untr)
		legend(h,{'Session1 and Session 2','Session1 and Session 3','Session2 and Session 3'})
		ylabel('Spearman correlation')
		xlabel('Parameter');
		title(models(mdl).name)

end
myfig(gcf,'TestRetest','testRetest.m');
