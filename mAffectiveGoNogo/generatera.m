function [a,r] = generatera(pa,s);

p = 0.9; 
c = 1;
ago = 1; 

a = sum(rand>cumsum([0 pa]));

rn = rand<p; 

if s==1	% go to win 
	if a == ago; 	r = c*rn; 
	else 				r = c*(1-rn);
	end
elseif s==2		% nogo to win 
	if a == ago; 	r = c*(1-rn);
	else 				r = c*rn;
	end
elseif s==3; 	% go to avoid 
	if a == ago; 	r = -c*(1-rn);
	else 				r = -c*rn;
	end
elseif s==4; 	% nogo to avoid 
	if a == ago; 	r = -c*rn;
	else 				r = -c*(1-rn);
	end
end
