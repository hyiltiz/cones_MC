function [ result , X ] = flip_MCMC( result , X , accumulate , trials , update , burn_in )
% Propagate configuration 'X' and accumulated observable 'result' through
% one iteration of MCMC. Trials are generated by 'trial_sampler', which
% also calculates log-likelihoods, and the resulting observables
% accumulated by 'accumulate'. If 'trial_sampler' returns a single trial,
% then the metropolis-hastings rule is used. For more than one trial, the
% symmetric MC rule is used.

if nargin<5 , burn_in = true ; end

% prepend current X to samples
n_trials = length(trials) ;
nomove.ll = X.ll ;
trials   = [{nomove} ; trials] ;

% calculate the log-likelihoods of proposed trials
ll      = zeros(1,n_trials+1) ;
for i=1:n_trials+1
    ll(i) = trials{i}.ll ;
end

% get likelihood vector of trials
L = exp( ll - max(ll) ) ;
L = L/sum(L) ;

% choose next state
% if n_trials>1       

% symmetric rule
trans_prior = zeros(n_trials+1,1) ;
for i=2:n_trials+1
    trans_prior(i) = trials{i}.forward_prob ;
end
trans_prior(1) = sum(trans_prior)/(n_trials+1) ;
p = L./trans_prior' ;
p = cumsum(p) ;
p = p/p(end) ;
i = randiscrete( p ) ;
if i>1 , X = update( X , trials{i} ) ; end

% accumulate acceptance rate statistics
if isfield(trials{1},'stats')
    X.stats.N500 = (1-1/500)*trials{1}.stats.N500 + 1 ;
    X.stats.accepted = (1 - 1/500) * trials{1}.stats.accepted + (i>1) ;
end

% accumulate observable
if ~burn_in
%     result = result + sum( L * cell2mat( map_cell( accumulate , trials )) , 1 ) ;
    result = result + accumulate(X) ;
end
    
% else                % metropolis_hastings
%     i = rand() < ( (L(2) * flip_me{1}.backward_prob) / ...
%                    (L(1) * flip_me{1}.forward_prob ) ) ;
%     X = trials{i+1} ;
%     % accumulate observable
%     result = result + accumulate( y(i+1,:) ) ;
% end

% fprintf('\nn_trials%3d (chose%4d)  at %5f sec/trial',n_trials,i,toc/n_trials)

end