function X = flip_LL( X , flips , PROB , T )
% X = flip_LL( X , flips , PROB , T )
%
% This is where most cpu time is spent,
% pardon my appearance, i've been optimized for speed, not prettiness.
%
% Apply flips to configuration X, and update log-likelihood of X.
% Bits in X.state are flipped, and the inverse X.invWW of WW is updated.
% Some other book-keeping variables are stored in X, for speed.
% The matrix inverse is not recalculated each time:
% block matrix inverse update formulas are used to update X.invWW 
% incrementally, for speed.
% 
% Only updates X.WW if X.invWW is not present in input X.

M0 = PROB.M0 * PROB.SS ;

for i=1:size(flips,1)
    
    x = flips(i,1) ;
    y = flips(i,2) ;
    c = flips(i,3) ;
    
    [posX,posY,colors] = find(X.state) ;

    if ~c && ~X.state(x,y)
        error('deleting nonexistent cone...')
    else        % cone deletion
        k = x + M0*(y-1) ;
    end
    j = sum( posX + M0*(posY-1) <= k ) ;
    
    % block matrix inverse update
    if ~c       % update inverse by deleting jth row/column
        inds       = [1:j-1 j+1:X.N_cones] ;
        X.N_cones  = X.N_cones - 1 ;
        
        STA_W_state_j = X.sparse_STA_W_state(:, j) ;
        
        keep_GCs = find(PROB.quad_factors .* STA_W_state_j.^2 / double(X.WW(j,j)) ...
                        + PROB.N_cones_terms > 0) ;

        if isfield(X,'invWW')
            invWW      = X.invWW(inds,inds) - ...
                         X.invWW(inds,j)*X.invWW(j,inds)/X.invWW(j,j) ;
            X.invWW    = invWW ;
        end
        
        if isfield(X,'WW')
            X.WW       = X.WW(inds,inds) ;
        end
        
        X.sparse_STA_W_state = X.sparse_STA_W_state(:, inds ) ;
        
        keep_cones = sum(X.sparse_STA_W_state(keep_GCs,:),1)>0 ;
        X.contributions(keep_GCs) = ...
             sum((double(X.WW(keep_cones,keep_cones))\...
                            X.sparse_STA_W_state(keep_GCs,keep_cones)')' ...
                            .* X.sparse_STA_W_state(keep_GCs,keep_cones),2) ;

        X.state(x,y)= 0 ;
        
        X.diff = [X.diff ; x y 0] ;

    else        % update inverse by adding row/column
        j           = j + 1 ;
        X.N_cones   = X.N_cones + 1 ;
        inds        = [1:j-1 j+1:X.N_cones] ;
        
        Wkinds  = [posX'-x ; posY'-y] ;
        ssx     = 1+mod(x-1,PROB.SS) ;
        ssy     = 1+mod(y-1,PROB.SS) ;
        
        Wkstate = zeros(1,X.N_cones-1) ;
        where   = find( max(abs(Wkinds),[],1) <= PROB.R ) ;
        if ~isempty(where)
            xx = Wkinds(1,where)+PROB.R+ssx ;
            yy = Wkinds(2,where)+PROB.R+ssy ;
            for kk=1:length(where)
                Wkstate(where(kk)) = PROB.coneConv(xx(kk),yy(kk),ssx,ssy) ...
                    .* PROB.colorDot(c,colors(where(kk))) ;
            end
        end
        
        Wkkc = PROB.coneConv(PROB.R+ssx,PROB.R+ssy,ssx,ssy) * PROB.colorDot(c,c) ;
        
        if isfield(X,'invWW')
            invWW   = X.invWW ;
            r       = Wkstate * invWW ;

            X.invWW = zeros(X.N_cones) ;
            if ~isempty(r)
                q                  = 1/( Wkkc - r*Wkstate' ) ;
                cc                 = invWW * Wkstate' * q ;
                X.invWW(inds,inds) = invWW+cc*r  ;
                X.invWW(inds,j)    = -cc         ;
                X.invWW(j,inds)    = -r*q        ;
            else
                q = 1/Wkkc ;
            end
            X.invWW(j,j)       = q ;
        else
            if ~issparse(X.WW) ;
                X.WW = sparse(double(X.WW)) ;
            end 
            [wwx,wwy,wwv] = find(X.WW) ;
            wwx = [inds(wwx) j*ones(1,numel(Wkstate)+1) inds] ;
            wwy = [inds(wwy) inds j*ones(1,numel(Wkstate)+1)] ;
            wwv = [wwv' Wkstate Wkkc Wkstate] ;
            X.WW            = sparse(wwx,wwy,wwv,X.N_cones,X.N_cones) ;            
        end
        
        sparse_STA_W_state = X.sparse_STA_W_state ;
        X.sparse_STA_W_state = sparse([],[],[],PROB.N_GC,X.N_cones) ;
        if ~isempty(inds)
            X.sparse_STA_W_state(:,inds) = sparse_STA_W_state ;
        end
        xi = (x-0.5)/PROB.SS ;
        yi = (y-0.5)/PROB.SS ;

        [filter,tt,rr,bb,ll] = filter_bounds( xi, yi, PROB.M0,PROB.M1,PROB.gaus_boxed,...
                                       PROB.cone_params.support_radius) ;
        keep_GCs = PROB.sparse_struct{x,y,c} ;

        if ~isfield(X,'contributions')
            X.contributions = zeros(PROB.N_GC,1) ;
        end

        if ~isempty(keep_GCs)
            sta = PROB.STA(:,tt:bb,ll:rr,keep_GCs) ;
            sta = reshape( sta, [], numel(keep_GCs) ) ;
            STA_W_state_j = sta' * kron(filter(:),PROB.cone_params.colors(c,:)') ;
            X.sparse_STA_W_state( keep_GCs, j ) = STA_W_state_j ;
            keep_cones = sum(abs(X.sparse_STA_W_state(keep_GCs,:)),1)>0 ;

            if ~isempty(keep_GCs)
                X.contributions(keep_GCs) = ...
                    sum((double(X.WW(keep_cones,keep_cones))\...
                    X.sparse_STA_W_state(keep_GCs,keep_cones)')'...
                                .* X.sparse_STA_W_state(keep_GCs,keep_cones),2) ;
            end
            X.keep_cones = keep_cones ;
        end        
        X.keep_GCs   = keep_GCs   ;
        
        X.state(x,y)       = c ;
        X.diff = [X.diff ; x y c] ;
    end
end

% recalculate data log-likelihood
ll = calculate_LL( X , PROB , T ) ;
X.T   = T  ;
X.ll  = ll ;

end