%% Learning the EMfit output

% The OUTPUT is as follows: 
%     E        is a matrix of size NpxNsj containing the MAP-EM parameters
%     V        is a matrix of size NpxNsj containing the inverse Hessians around 
%              individual subject parameter estimates 
%     alpha    contains the estimated coefficients (both means and regression 
%              coefficients if REG has been included)
%     stats    contains further stats for each estimated prior parameter, in particular
%              standard error estimates (from finite differences), t and p
%              values, and ML estimates as stats.EML. stats.EX is 1 if it
%              converged; 0 if it reached the MAXIT limit, -2 if a saddle point
%              (with some positive group Hessian diagonals) rather than a maximum was
%              reached, and -1 otherwise. 
%     bf       contains estimates of the quantities necessary to compute Bayes
%    			   factors for model comparison. The integrated, group-level BIC
%    			   bf.ibic simply counts the parameters at the group level, while
%    			   bf.ilap uses the finite difference Hessian around the prior mean
%    			   for a Laplacian estimate, which is typically less conservative. 
%     fitparam If asked for, this outputs various parameters used by emfit for
%              fitting - including the data (this might take up a lot of space!)