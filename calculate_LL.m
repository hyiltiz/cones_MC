function ll = calculate_LL( X , PROB , T )

% M0 = PROB.M0 * PROB.SS ;
% M1 = PROB.M1 * PROB.SS ;

if X.N_cones>0
%     invWW = X.invWW ;
%     invWW(abs(invWW)<abs(invWW(1,1))*1e-17) = 0 ;
%     invWW = sparse(invWW) ;


%     try
        if isfield(X,'ds_UW_STA') || isfield(X,'dUW_STA')
            if isfield(X,'ds_UW_STA')
                contribution = X.ds_UW_STA.^2 ;
            else
                contribution = X.dUW_STA.^2 ;
            end
            ll = X.ll + 0.5 * T(1) * full( PROB.N_cones_term + ...
                 sum( PROB.quad_factor' .* contribution)) ;

        else
%             STA_W_state = (X.STA_W_state-PROB.min_STA_W).^T(2) + PROB.min_STA_W ;
            
%             if isfield(X,'WW')
%                 contribution = (X.WW\STA_W_state')' .* STA_W_state ;
%             else
%                 contribution = (STA_W_state * X.invWW) .* STA_W_state ;
%             end
            
%             ll0  = 0.5 * T(1) * full( X.N_cones * PROB.N_cones_term + ...
%                     sum( PROB.quad_factor' * contribution )) ;                

%             ll = 0.5 * T(1) * ( X.N_cones * PROB.N_cones_term + sum(X.contributions) ) ;

            ll  = 0.5 * T(1) * (sum( PROB.N_cones_terms .* sum(X.sparse_STA_W_state>0,2)) + ...
                    sum(X.contributions)) ;

%             ll0  = 0.5 * T(1) * full(sum( PROB.N_cones_terms .* sum(X.sparse_STA_W_state>0,2)) + ...
%                     sum(X.contributions0)) ;
% 
%             ll1  = 0.5 * T(1) * full(sum( PROB.N_cones_terms .* sum(X.sparse_STA_W_state>0,2)) + ...
%                     sum(X.contributions1)) ;

        end

%         fprintf('%f,%f,%f\n',ll,ll0,ll-ll0)
%         fprintf('%f,%f,%f,%f,%f\n',ll,ll0,ll1,ll-ll0,ll-ll1)

%     catch
%         'ha'
%     end
else
    ll = 0 ;
end

end