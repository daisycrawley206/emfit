function [l,dl] = llrw2(x,D,musj,nui,doprior);
% 
% function [l,dl] = llrw(x,D,musj,nui,doprior);
% 
% Likelihood function for simple Rescorla-Wagner Q learning model. It computes
% the probabilities of actions 
%
%       p(D.A(t)) = exp(beta*Q_t(D.A(t),D.S(t))) / sum_a exp(beta*Q_t(a,D.S(t)))
%
% with 
%
%       Q_t(D.A(t),D.S(t)) = Q_{t-1}(D.A(t),D.S(t)) +  epsilon*PE_t
%       PE_t =  D.R(t) - Q_{t-1}(D.A(t),D.S(t))
%   
% It outputs the total log likelihood L of all the choices, in addition to the
% gradient wrt. to the paramters X. Note that the parameters X are transformed
% to lie on the real line.  It applies a Gaussian prior with mean MUSJ and
% inverse variance nui if DOPRIOR=1. 
% 
% Copyright Quentin Huys, 2015 www.quentinhuys.com qhuys@cantab.net


Np = length(x);
beta = exp(x(1));            % sensitivity to reward / noise 
eps = 1./(1+exp(-x(2)));     % learning rate

% apply prior with mean musj and variance nu or not 
if doprior
	 l = -1/2 * (x-musj)'*nui*(x-musj) - 1/2*log(2*pi/det(nui)); %
	dl = - nui*(x-musj) ;
else
	 l=0;
	dl=zeros(Np,1);
end

% initialize some variables 
pa=zeros(2,1);
Q=zeros(2,1); 
dQdb = zeros(2,1);
dQde = zeros(2,1);

% loop over all choices 
for t=1:length(D.A)
	% compute choice likelihood given parameter - softmax of Q 
	l0 = max(Q);
	la = Q - l0 - log(sum(exp(Q-l0)));
	pa = exp(la);
	l = l + la(D.A(t));

	% compute gradients of likelihood wrt parameter 
	dl(1) = dl(1) + dQdb(D.A(t)) - pa'*dQdb;
	dl(2) = dl(2) + dQde(D.A(t)) - pa'*dQde;

	er = beta * D.R(t);

	dQdb(D.A(t)) = (1-eps)*dQdb(D.A(t)) + eps*er;
	dQde(D.A(t)) = (1-eps)*dQde(D.A(t)) + eps*(1-eps)*(er-Q(D.A(t)));

	% update Q values 
	Q(D.A(t)) = Q(D.A(t)) + eps * (er - Q(D.A(t)));  

end
% use f*MIN*unc, so minimize negative log likelihood 
l  = -l; 
dl = -dl; 

return 
