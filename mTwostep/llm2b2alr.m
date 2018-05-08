function [l,dl,dsurr] = llm2b2alr(x,D,mu,nui,doprior,options);
% 
% [l,dl,dsurr] = llm2b2alr(x,D,mu,nui,doprior,options);
%
% Joint model-based tree search and model-free SARSA(lambda) model with separate
% learning rates and betas to two-step task, as in Daw et al. 2011. 
% 
% X are the parameters for which to evaluate the likelihood D contains the data
% (see dataformat.txt or generate some data using generateExampleDataset.m).  MU
% is the prior mean and NUI is the prior inverse covariance matrix.  The DOPRIOR
% flag defines whether to apply a prior (1) or not (0). The variable
% OPTIONS.generatesurrogatedata defines whether to return the likelihood of data
% D (0) or whether to generate new surrogate data from the given parameters (1). 
% 
% Quentin Huys, 2018 www.quentinhuys.com qhuys@cantab.net

if nargout==2; dodiff=1; else; dodiff=0;end

b  = exp(x(1:2));
al = 1./(1+exp(-x(3:4)));
la = 1./(1+exp(-x(5)));
w  = 1./(1+exp(-x(6)));
rep = x(7)*eye(2);

Q1 = zeros(2,1);
Q2 = zeros(2,2);
dQ1da1= zeros(2,1);
dQ1da2= zeros(2,1);
dQeda1= zeros(2,1);
dQ2da2= zeros(2,2);
dQ1dl = zeros(2,1);
dQedl = zeros(2,1);
dQedw = zeros(2,1);
drep = eye(2);

% add Gaussian prior with mean mu and variance nui^-1 if doprior = 1 
[l,dl] = logGaussianPrior(x,mu,nui,doprior);

if options.generatesurrogatedata==1
	dodiff=0;
	rewprob = D.rewprob; 
	trans = D.trans;
end

% if second-level states are coded as '2' and '3' change to '1' and '2' 
if any(D.S(2,:)==3); D.S(2,:) = D.S(2,:)-1; end

bb=20;
n=zeros(2);
a1old=-1;
for t=1:length(D.A)
	
	s=D.S(1,t); sp=D.S(2,t);
	a=D.A(1,t); ap=D.A(2,t);
	r=D.R(1,t);

	if ~isnan(a) && ~isnan(ap); 

		if n(1,1)+n(2,2) > n(1,2)+n(2,1)
			Tr = .3+.4*eye(2);
		else
			Tr = .3+.4*(1-eye(2));
		end

		pqm = bb*Q2;
		pqm = pqm-ones(2,1)*max(pqm);
		pqm = exp(pqm);
		pqm = pqm*diag(1./sum(pqm));
		Qd = (sum(Q2.*pqm)*Tr)';

		if t>1 && a1old>0
			Qeff= w*Qd + (1-w)*Q1 + rep(:,a1old);
		else
			Qeff= w*Qd + (1-w)*Q1;
		end
		lpa = b(1)*Qeff;
		lpa = lpa - max(lpa);
		lpa = lpa - log(sum(exp(lpa)));
		pa = exp(lpa);
		if options.generatesurrogatedata==1
			[a,sp] = simulateTwostep(pa,s,trans(t));
		else
			l = l + lpa(a);
		end

		lpap = b(2)*Q2(:,sp);
		lpap = lpap - max(lpap);
		lpap = lpap - log(sum(exp(lpap)));
		pap = exp(lpap);
		if options.generatesurrogatedata==1
			[ap,r] = simulateTwostep(pap,sp,trans(t),rewprob(:,:,t));
		else
			l = l + lpap(ap);
		end

		de1 = Q2(ap,sp)-Q1(a);
		de2 = r - Q2(ap,sp);

		if dodiff
			dl(1) = dl(1) + b(1)*(Qeff(a)   - pa'*Qeff);
			dl(2) = dl(2) + b(2)*(Q2(ap,sp) - pap'*Q2(:,sp));
			dl(3) = dl(3) + b(1)*(dQeda1(a) - pa'*dQeda1);
			dl(4) = dl(4) + b(2)*(dQ2da2(ap,sp)- pap'*dQ2da2(:,sp)) + b(1)*(1-w)*(dQ1da2(a) - pa'*dQ1da2);
			dl(5) = dl(5) + b(1)*(dQedl(a)  - pa'*dQedl);

			% grad wrt al(1)
			dQ1da1(a) = dQ1da1(a) + al(1)*(1-al(1))*(de1+la*de2) + al(1)*-dQ1da1(a);
			dQeda1 = (1-w)*dQ1da1;

			% grad wrt al(2)
			dQ1da2(a) = dQ1da2(a) + al(1)*(dQ2da2(ap,sp)-dQ1da2(a) + la*-dQ2da2(ap,sp));
			dQdda2 = ( sum(pqm.* (dQ2da2 + bb*Q2.*(dQ2da2 - ones(2,1)*sum(pqm.*dQ2da2)))) * Tr )';
			dQ2da2(ap,sp) = dQ2da2(ap,sp) + al(2)*(1-al(2))*de2 + al(2)*-dQ2da2(ap,sp);


			% grad wrt la
			dQ1dl(a) = dQ1dl(a) + al(1)*la*(1-la)*de2+ al(1)*-dQ1dl(a);
			dQedl = (1-w)*dQ1dl;

			% grad wrt w 
			dQedw = w*(1-w)*(Qd-Q1);

			dl(4) = dl(4) + b(1)*w*(dQdda2(a)- pa'*dQdda2);
			dl(6) = dl(6) + b(1)*(dQedw(a)  - pa'*dQedw);

			% grad wrt rep 
			if t>1 && a1old>0;
				dl(7) = dl(7) + b(1)*((a==a1old) - pa'*drep(:,a1old));
			end

		end

		Q1(a)     = Q1(a)     + al(1)*(de1 + la*de2);
		Q2(ap,sp) = Q2(ap,sp) + al(2)*de2;

		n(sp,a) = n(sp,a)+1;
		a1old = a; 

		if options.generatesurrogatedata==1
			dsurr.A(1,t)=a; dsurr.A(2,t)=ap;
			dsurr.S(1,t)=s; dsurr.S(2,t)=sp;
			dsurr.R(1,t)=r;
		end
	end

end
l=-l;
dl=-dl;
