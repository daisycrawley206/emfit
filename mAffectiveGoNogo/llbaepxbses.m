function [l,dl,dsurr] = llbaepxb(x,D,mu,nui,doprior,options);
% 
% [l,dl,surrugatedata] = llbaepxb(x,D,mu,nui,doprior,options);
% 
% log likelihood (l) and gradient (dl) of simple RW model with constant bias
% towards one action, irreducible noise and positive Pavlovian bias parameter
% 
% Use this within emfit.m to tit RL type models to a group of subjects using EM. 
% 
% Guitart-Masip M, Huys QJM, Fuentemilla L, Dayan P, Duezel E and Dolan RJ
% (2012): Go and nogo learning in reward and punishment: Interactions between
% affect and effect.  Neuroimage 62(1):154-66 
%
% Quentin Huys 2011-2012 qhuys@gatsby.ucl.ac.uk

% data will have some kind of variable denoting which group and which session it is 

dodiff=nargout==2;
np = length(x);

% add Gaussian prior with mean mu and variance nui^-1 if doprior = 1 
[l,dl] = logGaussianPrior(x,mu,nui,doprior); % l is the likelihood, dl is the dervatives, the gradients

a = D.a; 
r = D.r; 
s = D.s;
% need a variable for session to add to the dataset - discuss structure
% need a grouping variable

if options.generatesurrogatedata==1
	a = zeros(size(a));
	dodiff=0;
end

V=zeros(1,4); 
Q=zeros(2,4); 

dQdb = zeros(2,4,2);
dQde = zeros(2,4);
dVdb = zeros(4,4);
dVde = zeros(4,1);

% if a of t isnan then you just skip it, ML asks which parameter fits
% the data I have best, so it's ok if you have less data

% additional code, include defining parameters within the loop and
% rho - this is separating out the Pavlovian bias as the script is 2ep

for ses = 1:size(a,1) 

    for t=1:size(a,2)

        if t==1
            V=zeros(1,4);
            Q=zeros(2,4);

            dQdb = zeros(2,4,2);
            dQde = zeros(2,4);
            dVdb = zeros(4,4);
            dVde = zeros(4,1);

        end

        if ~isnan(s(ses,t)) & ~isnan(a(ses,t)) % ses is number of sessions

            sesdep = (ses-1)*x(6); 

            beta 		= exp(x(1));				% sensitivity to reward
            alfa 		= 1./(1+exp(-x(2)));		% learning rate
            epsilon 	= exp(x(3)+sesdep);			% 'pavlovian' parameter. Weigth of Vcue into Qgo
            g       	= 1/(1+exp(-x(4)));		    % irreducible noise
            bias 		= x(5);						% constant bias

        	q = Q(:,s(ses,t));
        	q(1) = q(1) + epsilon * V(s(ses,t)) + bias;    % add Pavlovian effect

        	l0 = q - max(q);
        	la = l0 - log(sum(exp(l0)));
        	p0 = exp(la);
        	pg = g*p0 + (1-g)/2;

        	if options.generatesurrogatedata==1
        		[a(ses,t),r(ses,t)] = generatera(pg',s(ses,t));
            end
        	l = l + log(pg(a(ses,t)));

        	er = beta * r(ses,t);

        	if dodiff
        		tmp = (dQdb(:,s(ses,t)) + [epsilon*dVdb(s(ses,t));0]);
        		dl(1) = dl(1) + g*(p0(a(ses,t)) * (tmp(a(ses,t)) - p0'*tmp)) / pg(a(ses,t));
        		dQdb(a(ses,t),s(ses,t)) = (1-alfa)*dQdb(a(ses,t),s(ses,t)) + alfa*er;
        		dVdb(     s(ses,t)) = (1-alfa)*dVdb(     s(ses,t)) + alfa*er;

        		tmp = (dQde(:,s(ses,t)) + [epsilon*dVde(s(ses,t));0]);
        		dl(2) = dl(2) + g*(p0(a(ses,t)) * (tmp(a(ses,t)) - p0'*tmp)) / pg(a(ses,t));
        		dQde(a(ses,t),s(ses,t)) = (1-alfa)*dQde(a(ses,t),s(ses,t)) + (er-Q(a(ses,t),s(ses,t)))*alfa*(1-alfa);
        		dVde(     s(ses,t)) = (1-alfa)*dVde(     s(ses,t)) + (er-V(     s(ses,t)))*alfa*(1-alfa);

        		dl(3) = dl(3) + g*(p0(a(ses,t))*epsilon*V(s(ses,t)) * ((a(ses,t)==1)-p0(1))) / pg(a(ses,t));

        		dl(4) = dl(4) + g*(1-g)*(p0(a(ses,t))-1/2)/pg(a(ses,t));

        		tmp = [1;0];
        		dl(5) = dl(5) + g*(p0(a(ses,t)) * (tmp(a(ses,t)) - p0'*tmp)) / pg(a(ses,t));

                dl(6) = dl(6) + g*(p0(a(ses,t))*(ses-1)*epsilon*V(s(ses,t)) * ((a(ses,t)==1)-p0(1))) / pg(a(ses,t));
            end

        	Q(a(ses,t),s(ses,t)) = Q(a(ses,t),s(ses,t)) + alfa * (er - Q(a(ses,t),s(ses,t)));
        	V(s(ses,t))      = V(s(ses,t))      + alfa * (er - V(s(ses,t)     ));
        end
    end
end

l  = -l; % make sure this is outside the for loop otherwise it turns the l's negative and finds the worst fit not best
dl = -dl; % derivates

if options.generatesurrogatedata==1
    dsurr.a = a;
    dsurr.r = r;
end

%% Debugging code
% use dbup and dbdown to go back a function until you locate the error
% use keyboard to add a stop
% use dbstep to execute each step until you run into an error
% remove the semi colons to list the output and see it run so you can check
% if the variables make sense, e.g. we don't want negative derivates
% use ls to see what's in the data or struct rather than viewing it
% keep a figures panel above the command window so you can view the data
% visually
% keep using clear all so you don't get any hangovers
% push to the git so that Quentin can review my code when it gets bugs
