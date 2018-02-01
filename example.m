% Example script to perform EM inference 
% 
% This is a very basic example script that generates some data from a simple
% Rescorla-Wagner model, and then fits the data. 
% 
% Quentin Huys, 2018 qhuys@cantab.net
% 
%==============================================================

clear all; 
addpath('lib'); 

modelClass = 'mBasicRescorlaWagner';
addpath(genpath(modelClass));
models=modelList; 							% load list of models. There is one such
													% list in each folder for each set of models
try 
	pool = parpool(4) ; 						% try opening matlabpool to speed things up 
end

%--------------------------------------------------------------
% generate some surrogate data 
%--------------------------------------------------------------

NumSubj = 20; 									% number of subjects
T = 120; 											% number of choices per subject 

reg = randn(1,NumSubj); 							% random psychometric regressor 
Etrue(1,:) = randn(1,NumSubj) + 1;			% parameter 1: mean 1, var 1 
Etrue(2,:) = randn(1,NumSubj) - 1 + reg;	% parameter 2: mean -1, correlated with regressor

% generate actual data 
options.generatesurrogatedata=1; 
for sk=1:NumSubj
	D(sk).a = zeros(T,1); % just to set the length of the data simulations 
	[foo,foo,dsurr] = llrw(Etrue(:,sk),D(sk),0,0,0,options);
	Data(sk).a = dsurr.a; 
	Data(sk).r = dsurr.r;
	Data(sk).Nch = T; 
	AA(sk,:) = dsurr.a; 
end

% do standard basic ML fit 
options.generatesurrogatedata=0; 
for sj=1:NumSubj
	mlest(:,sj) = fminunc(@(x)llrw(x,Data(sj),zeros(2,1),zeros(2),0,options),randn(2,1));
end

clf; 
	subplot(121); plot(Etrue(1,:),mlest(1,:),'o'); xlabel('True'); ylabel('ML estimate'); title('Parameter 1'); 
	subplot(122); plot(Etrue(2,:),mlest(2,:),'o'); xlabel('True'); ylabel('ML estimate'); title('Parameter 2');

%--------------------------------------------------------------
% EM inference 
%--------------------------------------------------------------

regressors = cell(2,1); 			% set up regressor cell structure 
regressors{2} = reg;							% put our psychometric regressor into cell structure

% now run the actual inference 
[E,V,alpha,stats,bf,fitparams] = emfit('llrw',Data,2,regressors); 


%--------------------------------------------------------------
% some plots 
%--------------------------------------------------------------

clf; 
subplot(231);
imagesc(AA);
colormap(gray*.3+.7)
hold on
plot(mean(AA==1)*20,'k','linewidth',2);
hold off
yy = linspace(0,NumSubj,6); 
set(gca,'ytick',yy,'yticklabel',1-round(yy/NumSubj*10)/10)
ylabel('Average choice probability')
xlabel('Time')
title('Choice data');

subplot(232);
h=errorbar(Etrue(1,:),E(1,:),sqrt(V(1,:)),'o');
hold on
h(2) = plot(Etrue(1,:),stats.EML(1,:),'k.');
h(3) = plot(Etrue(1,:),stats.EMAP0(1,:),'g+');
m(1) = min(Etrue(1,:));
m(2) = max(Etrue(1,:));
plot(m,m,'r');
hold off
xlabel('True log \beta');
ylabel('Inferred log \beta');
legend(h,'MAP-EM','ML','MAP0');

subplot(233);
errorbar(Etrue(2,:),E(2,:),sqrt(V(2,:)),'o');
hold on
plot(Etrue(2,:),stats.EML(2,:),'k.');
plot(Etrue(2,:),stats.EMAP0(2,:),'g+');
m(1) = min(Etrue(2,:));
m(2) = max(Etrue(2,:));
plot(m,m,'r');
hold off
xlabel('True \sigma^{-1}(\alpha)');
ylabel('Inferred \sigma^{-1}(\alpha)');

subplot(223);
bar([alpha(1:2) ]);
hold on;
errorbar(1:2,alpha(1:2),1.96*stats.groupmeanerr(1:2),'.'); 
plot([.5 1.5],[1 1],'r--','linewidth',2);
plot([1.5 2.5],[-1 -1],'r--','linewidth',2);
hold off;
h=text(.6, 1.2,'True');
set(h,'color','r');
ylabel('Estimated prior group means');
set(gca,'xticklabel',{'E[log \beta]','E[\sigma^{-1}(\alpha)]'});

subplot(224);
if length(alpha)==3
	bar([alpha(3) ]);
	hold on;
	errorbar(1,alpha(3),1.96*stats.groupmeanerr(3)); 
	plot([.5 1.5],[1 1],'r--');
	hold off;
	h=text(.6, .9 ,'True');
else
	bar(corr(E(2,:)',reg'))
	hold on
	plot([.5 1.5],[1 1]*corr(Etrue(2,:)',reg'),'r--','linewidth',2)
	hold off;
	h=text(.6, 1.05*corr(Etrue(2,:)',reg'),'True');
end
set(h,'color','r');
ylabel('Estimated regression coefficient');

