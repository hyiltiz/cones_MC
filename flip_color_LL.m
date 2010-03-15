function X = flip_color_LL( ...
    X , flips , prior_ll , cell_consts , STA_W , coneConv , colorDot , sizes , beta )
% X = flip_color_LL( X , flips , prior_ll , cell_consts , ...
%                    STA_W , coneConv , colorDot , sizes , beta )
% Apply flips to configuration X, and update log-likelihood of X.
% Bits in X.state are flipped, and the inverse X.invWW of WW is updated.
% The matrix inverse is not recalculated each time:
% block matrix inverse update formulas are used to update X.invWW 
% incrementally, for speed.

% default inverse temperature is 1
if nargin<9
    beta = 1 ;
end

% center of cone RF convolution
Nconv   = ceil(size(coneConv,1)/2) ;

% number of colors
Ncolors = size(colorDot,1) ;

% number of pixels without color
NBW     = length(X.state)/Ncolors ;
if NBW ~= floor(NBW)
    error('number of pixels must be multiple of number of colors!')
end

% initialize inverse if necessary
if ~isfield(X,'invWW') || ~isfield(X,'overlaps')
    temp_X.state     = false(1,size(STA_W,2)) ;
    temp_X.invWW     = [] ;
    temp_X.overlaps  = [] ;
    temp_X.WW        = [] ;
    temp_X.positions = [] ;
    temp_X.colors    = [] ;
    X = flip_color_LL( temp_X , find(X.state) , prior_ll , cell_consts , ...
                      STA_W , coneConv , colorDot , sizes , beta ) ;
end

% % initialize best 10 configurations encountered to zero
% if ~isfield(X,'best')
%     X.best = zeros(10,size(STA_W,2)+1) ;
%     X.best(1:10) = -Inf ;
% end

% apply all the bit flips to X
for i=1:length(flips)
    k = flips(i) ;
    n = size(X.invWW,1) ;
    j = cumsum(X.state) ;
    
    % block matrix inverse update
    if X.state(k)     % update inverse by deleting jth row/column
        j = j(k) ;
        inds = [1:j-1 j+1:n] ;
        X.overlaps = X.overlaps(inds,inds) ;
        X.invWW = X.invWW(inds,inds) - ...
                  X.invWW(inds,j   )*X.invWW(j,inds)/X.invWW(j,j) ;
        X.positions = X.positions(:,inds) ;
        X.colors    = X.colors(inds) ;
    else                % update inverse by adding row/column
        j = j(k) + 1 ;
        inds = [1:j-1 j+1:n+1] ;
        A = X.invWW ;
        
        % reconstruct W(k,X.state) using coneConv
        Wkk     = coneConv(Nconv,Nconv) ;
        
%         [kI,kJ] = ind2sub(sizes,mod(k     -1,NBW)+1) ;
        k_position = 1 + mod( k-1 , NBW      ) ;
        kI         = 1 + mod( k-1 , sizes(1) ) ;
        kJ         = 1 + floor( (k_position-1) / sizes(1)) ;
        
        k_color    = 1 + floor( (k-1)          / NBW     ) ;

        positions   = X.positions ;
        X.positions = zeros(2,n + 1) ;
        if ~isempty(positions)
            X.positions(:,inds) = positions ;
            Wkinds  = [positions(1,:)-kI ; positions(2,:)-kJ] ;
        else
            Wkinds  = [] ;
        end
        X.positions(:,j)    = [kI;kJ] ;
        
        colors      = X.colors ;
        X.colors    = zeros(1,n + 1) ;
        X.colors(inds) = colors ;
        X.colors(j)    = k_color  ;
        
%         colors  = find( X.state ) ;
% [sI,sJ] = ind2sub(sizes,mod(colors-1,NBW)+1) ;
% [kI,kJ] = ind2sub(sizes,mod(k     -1,NBW)+1) ;
%         colors  = 1 + floor( (colors-1)/NBW ) ;

        overlap = zeros(1,n) ;
        Wkstate = overlap ;
        where   = max(abs(Wkinds),[],1)<Nconv ;
        if sum(where)
            Nc   = size(coneConv,1) ;
            here = (Nconv+Wkinds(2,where) - 1)*Nc + Nconv+Wkinds(1,where) ;
            
%             here = sub2ind(size(coneConv),Nconv+Wkinds(1,where),Nconv+Wkinds(2,where)) ;
            overlap(where) = coneConv(here) ;
            
%             where
%             overlap(where) .* colorDot(k_color,colors(where))
%             Wkstate(where)
            
            Wkstate(where) = overlap(where) .* colorDot(k_color,colors(where)) ;
        end
        
%         WW                  = X.WW ;
%         X.WW                = zeros(n+1) ;
%         X.WW(inds,inds)     = WW ;
%         X.WW(inds,j)        = Wkstate ;
%         X.WW(j,inds)        = Wkstate ;
%         X.WW(j,j)           = Wkk ;

        O                     = X.overlaps ;
        X.overlaps            = zeros(n+1) ;
        X.overlaps(inds,inds) = O ;
        X.overlaps(inds,j)    = overlap ;
        X.overlaps(j,inds)    = overlap ;
        X.overlaps(j,j)       = Wkk ;
        
        r = Wkstate * A ;
        q = 1/( Wkk - r*Wkstate' ) ;
        c = A * Wkstate' * q ;
        X.invWW = zeros(n+1) ;
        X.invWW(inds,inds) = A+c*r ;
        X.invWW(inds,j)    = -c    ;
        X.invWW(j,inds)    = -r*q  ;
        X.invWW(j,j)       = q     ;
        
    end
    X.state(flips(i)) = ~X.state(flips(i)) ;    
end
X.state = logical(X.state) ;

% recalculate data log-likelihood
Ncones = sum(X.state) ;
if Ncones>0
    ldet = log( det(X.invWW) ) ;
    X.data_ll = + Ncones * (length(cell_consts) * log(2*pi) + sum(log(cell_consts))) * ldet + ...
        sum( cell_consts .* sum( (STA_W(:,X.state) * X.invWW) .* STA_W(:,X.state) ,2) )/2 ;
%     X.data_ll = ( - length(cell_consts) * log( det(2.*pi.*X.invWW) ) + ...
%         sum( cell_consts .* sum( (STA_W(:,X.state) * X.invWW) .* STA_W(:,X.state) ,2) ) ...
%         )/2 ;
else
    X.data_ll = 0 ;
end

% update log-likelihood
X.ll = beta * (X.data_ll + prior_ll(X)) ;

% % update best 10 configurations encountered so far
% i = 1 ;
% while 1    
%     if i>10
%         X.best = [ X.best(2:end,:) ; X.ll X.state ] ;
%         break
%     elseif sum(X.state ~= X.best(i,2:end))>0
%         if X.ll > X.best(i)
%             i = i + 1 ;
%         else
%             X.best = [X.best(1:i-1,:) ; X.ll X.state ; X.best(i:10,:)] ;
%             X.best = X.best(2:end,:) ;
%             break
%         end
%     else
%         break
%     end
% end

end