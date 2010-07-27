function [results,X] = update_swap(results,trials,i)

% check_X(XLL,X.X)
% check_X(OLL,X.with)

% accumulate acceptance rate statistics
if isfield(results,'N500')
    results.N500     = (1-1/500)*results.N500     + 1 ;
    results.accepted = (1-1/500)*results.accepted + (i>1) ;
%     fprintf('\tX.i=%d,%d:%d,%d:%d',X.X.i,X.with.i,...
%               floor(results.N500),floor(results.accepted),changed)
end

if i>1

%     check_X(trials{1}.X)
%     check_X(trials{1}.with)

    X.X         = trials{1}.X ;
    X.X.state   = trials{i}.X.state ;
    X.X.invWW   = trials{i}.X.invWW ;
    X.X.N_cones = trials{i}.X.N_cones ;
    X.X.ll      = trials{i}.X.ll ;
    X.X.diff    = trials{i}.X.diff ;
    X.X.beta    = trials{i}.X.beta ;
    
    X.with         = trials{1}.with ;
    X.with.state   = trials{i}.with.state ;
    X.with.invWW   = trials{i}.with.invWW ;
    X.with.N_cones = trials{i}.with.N_cones ;
    X.with.ll      = trials{i}.with.ll ;
    X.with.diff    = trials{i}.with.diff ;
    X.with.beta    = trials{i}.with.beta ;
    
%     check_X(X.X)
%     check_X(X.with)
    
    if i>1
        X.X.version     = X.X.version    + 1 ;
        X.with.version  = X.with.version + 1 ;
    end
else
    X = trials{1} ;
end

% update both X
ii = 2*(i>1) + (i==1) ;
[results.results{1},X.X   ]  = update_X(results.results{1},{trials{1}.X    X.X   },ii) ;
[results.results{2},X.with]  = update_X(results.results{2},{trials{1}.with X.with},ii) ;    

results.results{1}.swap(results.results{1}.iteration) = true ;
results.results{2}.swap(results.results{2}.iteration) = true ;

results.trials = trials ;
results.version = [X.X.version X.with.version] ;

% fprintf('\t swapped ')

% check_X(XLL,X.X)
% check_X(OLL,X.with)

end