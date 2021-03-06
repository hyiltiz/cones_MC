function make_plots(greed,mcmc,cast,cone_map)

% if nargin<4
%     cone_map = remake_cone_map(mcmc{1}) ;
% end

folder_name = cone_map_string(cone_map);

filename = ['plots_for_' folder_name] ;
mkdir( filename )

here = pwd ;

cd(filename)

% [~,ll] = get_best( cast ) ;
% 
% try load(['../confident_' folder_name])
% catch
%     ['making ../confident_' folder_name]
%     selector = @(n) (n>10000) && (mod(n,20) == 0) ;
%     dX = cast{find(ll==max(ll),1)}.X.dX ;
%     confident = confident_cones( cone_map.initX , dX , cone_map , selector ) ;
% end
% save(['../confident_' folder_name], 'confident') ;
% plot_cone_field( confident , cone_map )
% 
% plot_LL_ncones( greed , mcmc , cast , cone_map )
plot_LL_ncones( {}    , mcmc , cast , cone_map )
% plot_Greedy_MCMC_CAST( greed , mcmc , cast , cone_map )

if strcmp(cone_map.type,'george')
   timeline(greed,mcmc,cast,cone_map.initX, sum(cone_map.N_spikes)) 
end


% % [sta,invww] = denoised_sta( greed.initX , cast{1}.X.dX , cone_map, selector ) ;
% % make_sta_plots( sta , invww, 'denoised' )

cd(here)

end