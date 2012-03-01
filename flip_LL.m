function X = flip_LL( X , flips , PROB , T )
% X = flip_LL( X , flips , PROB , T )
%
% pardon my appearance, i've been optimized for speed, not prettiness
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

% WC = PROB.cone_params.weight_C ;  % covariance of prior weights
% Wm = PROB.cone_params.weight_m ;  % mean of prior weights

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
        
        keep_GCs = find(PROB.quad_factors .* STA_W_state_j.^2 / X.WW(j,j) + PROB.N_cones_terms > 0) ;
        
        if isfield(X,'invWW')
            invWW      = X.invWW(inds,inds) - ...
                         X.invWW(inds,j)*X.invWW(j,inds)/X.invWW(j,j) ;
            X.invWW    = invWW ;
        end
        
        if isfield(X,'WW')
            X.WW       = X.WW(inds,inds) ;
        end
        
        X.sparse_STA_W_state = X.sparse_STA_W_state(:, inds ) ;
%         X.STA_W_state = X.STA_W_state(:, inds ) ;
        
        keep_cones = sum(X.sparse_STA_W_state(keep_GCs,:),1)>0 ;
        X.contributions(keep_GCs) = ...
                PROB.quad_factors(keep_GCs) .* ...
                sum((X.WW(keep_cones,keep_cones)\X.sparse_STA_W_state(keep_GCs,keep_cones)')' ...
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
        
        if isfield(X,'ds_UW_STA')
            indices = Wkstate>0 ;    %   <----   !!!!  indices must be bigger   !!!!
            if numel(inds)>0
                s_WW = X.WW(indices,indices) ;
                s_w  = Wkstate(indices) ;
                s_s  = - s_WW \ s_w' ;
                s_ss = s_s'*s_WW ;
                if isempty(s_ss)
                    s_q = sqrt(1/Wkkc) ;
                else
                    s_q  = 1/sqrt( s_ss*s_s + 2*s_s'*s_w' + Wkkc ) ;
                end
                s_U  = s_q * s_s ;
            else
                s_q = sqrt(1/Wkkc) ;
                s_U = [] ;
            end
            sU = [s_U ; s_q] ;
            sparse_index = [inds(indices) j] ;
        elseif isfield(X,'dUW_STA')
            U = zeros(X.N_cones,1) ;
            if numel(inds)>0
                WW = X.WW ;
                w  = Wkstate ;
                s  = - WW \ w' ;
                ss = s'*WW ;
                q  = 1/sqrt( ss*s + 2*s'*w' + Wkkc ) ;
                U(inds)     = q * s ;
            else
                q = sqrt(1/Wkkc) ;
            end
            U(j) = q ;        
        end
        
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
            WW            = zeros(X.N_cones) ;
            WW(j,j)       = Wkkc ;
            if numel(inds)>0
                WW(inds,inds) = X.WW ;
                WW(inds,j)    = Wkstate ;
                WW(j,inds)    = Wkstate ;
            end
            X.WW          = WW ;        
        end
        
%         STA_W_state = X.STA_W_state ;
        sparse_STA_W_state = X.sparse_STA_W_state ;
        X.sparse_STA_W_state = sparse([],[],[],PROB.N_GC,X.N_cones) ;
%         X.STA_W_state = zeros(PROB.N_GC,X.N_cones) ;
        if ~isempty(inds)
%             X.STA_W_state(:,inds) = STA_W_state ;
            X.sparse_STA_W_state(:,inds) = sparse_STA_W_state ;
        end
        xi = (x-0.5)/PROB.SS ;
        yi = (y-0.5)/PROB.SS ;

        [filter2,tt,rr,bb,ll] = filter_bounds( xi, yi, PROB.M0,PROB.M1,PROB.gaus_boxed,...
                                       PROB.cone_params.support_radius) ;
        STA_W_state_j = 0 ;
        for cc=1:3
            sta2 = PROB.STA(:,cc,tt:bb,ll:rr) ;
            sta2 = reshape( sta2, PROB.N_GC, []) ;
            STA_W_state_j = STA_W_state_j + PROB.cone_params.colors(c,cc)*(sta2 * filter2(:)) ;
        end
        
%         [filter,index] = filter_index( xi, yi, PROB.M0,PROB.M1,PROB.gaus_boxed,...
%                                        PROB.cone_params.support_radius) ;
%         X.index  = index ;
%         X.filter = filter ;
%         X.xy = {x y} ;
% 
%         filter  = kron(PROB.cone_params.colors(c,:),filter) ;
%         sta = reshape(PROB.STA,PROB.N_GC,[]) ;
%         sta = sta([index index+PROB.M0*PROB.M1 index+2*PROB.M0*PROB.M1],:) ;
%         STA_W_state_j2 = (filter * sta)' ;
%         
%         if norm(STA_W_state_j2 - STA_W_state_j)>1e-15
%             'asdfadfaw'
%         end
        
%         X.STA_W_state_j = STA_W_state_j ;
%         X.STA_W_state_j2 = STA_W_state_j2 ;
        
        keep_GCs = find(PROB.quad_factors .* STA_W_state_j.^2 / X.WW(j,j) + PROB.N_cones_terms > 0) ;

%         X.STA_W_state( :, j ) = STA_W_state_j ;
        X.sparse_STA_W_state( keep_GCs, j ) = STA_W_state_j(keep_GCs) ;
        keep_cones = sum(X.sparse_STA_W_state(keep_GCs,:),1)>0 ;
        
        if ~isfield(X,'contributions')
            X.contributions = zeros(PROB.N_GC,1) ;
        end
        if ~isempty(keep_GCs)
            X.contributions(keep_GCs) = ...
                PROB.quad_factors(keep_GCs) .* ...
                sum((X.WW(keep_cones,keep_cones)\X.sparse_STA_W_state(keep_GCs,keep_cones)')' ...
                            .* X.sparse_STA_W_state(keep_GCs,keep_cones),2) ;
        end
        
        X.keep_cones = keep_cones ;
        X.keep_GCs   = keep_GCs   ;
        
        if exist('U','var')
            X.dUW_STA = U' * X.STA_W_state' ;
        end
        
        if exist('sU','var')
            X.ds_UW_STA = sU' * X.STA_W_state(:,sparse_index)' ;
        end
        
        X.state(x,y)       = c ;
        X.diff = [X.diff ; x y c] ;
    end
end

% recalculate data log-likelihood
ll = calculate_LL( X , PROB , T ) ;
X.T   = T  ;
X.ll  = ll ;

end