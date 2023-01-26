function Data=generateExampleDataset(Nsj,resultsDir)
% 
% Data = generateExampleDataset(Nsj)
% 
% Generate example dataset containing Nsj subjects for affective Go/Nogo task using the
% standard model llbaepqx.m
% new therapy change model % update

% Quentin Huys 2018 www.quentinhuys.com 


fprintf('Generating example dataset for affective Go/Nogo task\n')

options.generatesurrogatedata=1; 

T = 160; 
for sj=1:Nsj; 
    
	Data(sj).ID = sprintf('Subj %i',sj);
    %ses = [1:4]';
    %Data(sj).n = (1:4)';
    Data(sj).a = zeros(4,T);
    Data(sj).r = zeros(4,T);        
    rs = randperm(T);							% randomise stimuli 
	s = [1:4]'*ones(1,T/4);
    s2 = s(rs);
	Data(sj).s = repmat(s2,4,1);	
	Data(sj).Nch = T; 							% length 

	% realistic random parameters 
	Data(sj).trueParam = [1.5 -.5 -1 1 1 1]'+randn(6,1);

	% generate choices A, state transitions S and rewards R 
	[foo,foo,dsurr] = llbaepxbses(Data(sj).trueParam,Data(sj),0,0,0,options); 
	Data(sj).a = dsurr.a;
	Data(sj).r = dsurr.r;
	Data(sj).trueModel='llbaepxbses';

end

fprintf('Saved example dataset as Data.mat\n');
save([resultsDir filesep 'Data.mat'],'Data');
