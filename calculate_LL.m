function ll = calculate_LL( X , PROB , T )

if X.N_cones>0
    invWW = X.invWW ;
    invWW(abs(invWW)<abs(invWW(1,1))*1e-17) = 0 ;
    invWW = sparse(invWW) ;
    
    STA_W_state = (X.STA_W_state-PROB.min_STA_W).^T(2) + PROB.min_STA_W ;
    
    ll  = 0.5 * T(1) * full( X.N_cones * PROB.N_cones_term + ...
        sum( PROB.quad_factor .* ...
        sum( (STA_W_state * invWW) .* STA_W_state ,2) )) ;
else
    ll = 0 ;
end

end