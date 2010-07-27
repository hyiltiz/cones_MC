function X = change_cone( X , a , PROB )

% check_X(X)

for i=1:size(a,1)
    x = a(i,1) ;
    y = a(i,2) ;
    c = a(i,3) ;
    free = 1 ;
    
    if c && ~X.state(x,y)  % check exclusion before adding cone
        [mask,indices] = place_mask( X.M0 , X.M1 , x , y , X.masks.exclusion ) ;
        free    = isempty( find( X.state(indices)>0 , 1) ) ;
    end

    if free                % add or delete cone
        X    = flip_LL( X , [x y c] , PROB ) ;
%         check_X(X)
    else
        X.ll = -Inf ;
    end
    
end

end