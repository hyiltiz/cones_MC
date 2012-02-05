function X = greedy( X , PROB , update_X )

M0 = PROB.M0 * PROB.SS ;
M1 = PROB.M1 * PROB.SS ;

if ~isfield(X,'greedy_ll')
    X.greedy_ll = cell(PROB.N_colors,1) ;
    X.excluded  = cell(PROB.N_colors,1) ;
%     for c=1:PROB.N_colors
%         X.greedy_ll{c} = old_ll * sparse([],[],[],M0,M1) ;
%     end
end

if ~isfield(X,'changed_x')
    X.greedy_ll = PROB.LL ;
    X.excluded  = 0 * PROB.LL ;
else
    n_cones_term = X.ll + 0.5 * PROB.N_cones_term ;
    for i=1:numel(X.changed_x)
        x = X.changed_x(i) ;
        y = X.changed_y(i) ;
        if (x-X.last_x)^2 + (y-X.last_y)^2 > X.D^2
            % propose addition of new cone of each color
            for c=1:PROB.N_colors
                sample = flip_LL( X , [x y c] , PROB , [1 1] ) ;
                X.greedy_ll(x,y,c) = sample.ll - n_cones_term ;
            end
        else
            X.excluded(x,y,:) = -Inf ;
        end
    end
    
%     figure(3)
%     ll = X.greedy_ll{1}(min(X.changed_x)+2:max(X.changed_x)-2,min(X.changed_y)+2:max(X.changed_y)-2) ;
%     imagesc(ll/max(ll(:)))
%     fprintf('changed greedy_ll min %f median %f max %f',min(ll(:)), median(ll(:)), max(ll(:)))
end

% if ~mod( X.N_cones, 20 )
%     LL = zeros([size(X.greedy_ll{1}) PROB.N_colors]) ;
%     for c=1:PROB.N_colors
%         LL(:,:,c) = X.greedy_ll{c} + X.excluded{c} ;
%     end
%     try
%         LL(LL<0) = min(reshape(LL(LL>0),1,[])) ;
%         fprintf('   LL min %f max %f',min(LL(:)), max(LL(:)))
%         figure(1)
%         imagesc(LL/max(LL(:)))
%     end
% 
%     figure(2)
%     plot_cones(X.state,PROB) ;
% end

[mm,I] = max(X.greedy_ll(:) + X.excluded(:)) ;
[mx,my,mc] = ind2sub(size(X.greedy_ll),I) ;

if mm+0.5 * PROB.N_cones_term>0
%     [mx,my] = find(X.greedy_ll{mc} == mm) ;
%     
%     mx = mx(1) ;
%     my = my(1) ;
    
    my = 1+mod(my-1,M1) ;
    
    sx = mod(mx-1,PROB.SS)+1 ;
    sy = mod(my-1,PROB.SS)+1 ;
    [changed_x, changed_y] = find( squeeze(PROB.coneConv(:,:,sx,sy)) > 0 ) ;
    
    changed_x = changed_x + mx - sx - PROB.R ;
    changed_y = changed_y + my - sy - PROB.R ;
    
    keep = logical( (changed_x>0) .* (changed_x<=M0) .* (changed_y>0) .* (changed_y<=M1) ) ;
    
    X.changed_x = changed_x(keep) ;
    X.changed_y = changed_y(keep) ;
    X.last_x    = mx ;
    X.last_y    = my ;
    X.last_c    = mc ;
    
    X = change_cone( X , [mx my mc] , PROB , [1 1]) ;
    X = update_X({X},1,false) ;
else
    X = rmfield(X,{'changed_x','changed_y','last_x','last_y'}) ;
end

end