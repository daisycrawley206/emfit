function surrogateDataPlots(Data,models,SurrogateData,bestmodel,fitResults)

nModls = length(models);
Nsj = length(Data);

nfig=get(gcf,'Number');

mkdir figs 

%--------------------------------------------------------------------
% compare with surrogate data 
%--------------------------------------------------------------------
% either generate new data: 
nfig=nfig+1; figure(nfig);clf;

cr = [1 1 2 2];

nSes = length(unique([Data.w]));

ns = zeros(max([Data.Nch])/nSes/4,nSes,4);
as = zeros(max([Data.Nch])/nSes/4,nSes,4,Nsj); % 4-D double
bs = zeros(max([Data.Nch])/nSes/4,4,nSes);
nns = zeros(max([Data.Nch])/nSes/4,4,nSes,nModls);
for sj=1:Nsj
	for ses=1:nSes
		a = Data(sj).a(Data(sj).w==ses); 
		s = Data(sj).s(Data(sj).w==ses); 
		for ss=1:4
			i = s==ss; 
			as(1:sum(i),ses,ss,sj) = a(i)==1;
			ns(1:sum(i),ses,ss) = ns(1:sum(i),ses,ss)+1;

			pc(ss,ses,sj) = sum(a(i)==cr(ss))/sum(i);
		end
	end

	for mdl=1:nModls;
		a = [SurrogateData(sj).(models(mdl).name).a]; 
		nsample = numel(SurrogateData(sj).(models(mdl).name)); 
		a = reshape(a,size(a,2)/nsample,nsample);
		b = mean(a==1,2);
		for ses=1:nSes
			for ss=1:4
				i = Data(sj).w==ses & Data(sj).s==ss; 
				bs(1:sum(i),ss,ses,mdl,sj) = b(i);
				nns(1:sum(i),ss,ses,mdl) = nns(1:sum(i),ss,ses,mdl)+1;

				pcs(ss,ses,mdl,sj) = mean(sum(a(i,:)==cr(ss))/sum(i));
			end
		end
	end
end
mas = sum(as,4)./ns;
mbs = sum(bs,5)./nns;


Ti = {'Go to win','Nogo to win','Go to avoid','Nogo to avoid'};
ssi = [1 2 3 4];

keyboard

for k=1:nModls
subplot(nModls,5,(k-1)*5+1)
	mybar(nanmean(pc(ssi,:,:),3),.7);
   col= colororder; 
	hon
	xx = [1:4]'*ones(1,nSes) + ones(4,1)*linspace(-.3,.3,nSes);
	%for k=1:nModls
		plot(xx,sq(nanmean(pcs(ssi,:,k,:),4)),'.-','markersize',15,'linewidth',1,'color',col(k,:))
	%end
	hof
	xlim([.5 4.5]);
	ylabel('Probability correct');
	set(gca,'xticklabel',Ti(ssi),'xticklabelrotation',30);
	title(models(k).name)
end
		
for ses=1:4
	for ss=1:4
		subplot(4,5,(ses-1)*5+1+ss);
			plot(mas(:,ses,ss),'k','linewidth',3); 
			hon
			plot(sq(mbs(:,ss,ses,:)),'linewidth',2); % this doesn't run still 
			hof
			ylim([0 1]);
			title(Ti{ss});
			xlabel('Trial');
			if ssi(ss)==1; ylabel({sprintf('Session %i',ses),'Probability Go'});end
	end
end

le = {models.name}; 
le = {'Data',le{:}};
legend(le,'location','best'); 

myfig(gcf,sprintf('%s/figs/SurrogateDataPlots',fitResults));

