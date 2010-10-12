function cone_map = coalesce( cone_map , folder , instances , ID )

if nargin<1  ,  folder = pwd ; end

here = pwd ;
cd(folder)

filenames = regexp( ls , 'bestX_[0-9]+.mat' , 'match' ) ;

cone_map.X = {} ;

for i=1:length(instances)
    
    bestX = load( filenames{instances{i}} ) ;
    cone_map.X = [cone_map.X bestX] ;
end

cd(here)

cone_map    = rmfield(cone_map,'ROI') ;

cone_map.ID = ID ;
M0          = cone_map.M0 ;
M1          = cone_map.M1 ;
N_instances = length(instances) ;

%% PARAMETERS FOR MCMC
cone_map.N_iterations  = 500 ; %1   * M0 * M1 ; % number of trials
cone_map.start_swap    = 0 ;

% betas         temperatures of independent instances run simultaneously
cone_map.betas         = make_deltas( 0.4, 1, 1, N_instances ) ;

% moves         sequence of moves at each iteration, currently:
%               - a regular MC move for each instance
% cone_map.moves = num2cell([ones(1,N_instances-1) ; 2:N_instances],1) ;  % al
cone_map.moves = [num2cell([1:N_instances-1 ; 2:N_instances],1)] ;    % line

cone_map.N_best = 10 ;

end