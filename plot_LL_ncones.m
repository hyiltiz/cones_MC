function svg = plot_LL_ncones( greedy , dir1 , pattern1 , dir2 , pattern2 )

phase1 = load_bestX( dir1 , pattern1 ) ;
phase2 = load_bestX( dir2 , pattern2 ) ;

[x,y] = get_N_ll( [phase1 ; phase2 ; {greedy}] ) ;
id = [ones(numel(phase1),1) ; 2*ones(numel(phase2),1) ; 0] ;

minx =  99 ;
maxx = 119 ;
inds = (x>minx) & (x<maxx) & (y>31000) ;

id  = id(inds) ;
y   = y(inds) ;
x   = x(inds) ;

mx = min(x) ;
Mx = max(x) ;

m  = min(y) ;
M  = max(y) ;

id3 = find( y == max(y(id == 1)) ) ;
id( id3 ) = 3 ;

id4 = find( y == max(y(id == 2)) ) ;
id( id4 ) = 4 ;

inds = [1:id3-1 id3+1:id4-1 id4+1:numel(x)-1 id3 id4 numel(x)] ;
x  = x(inds) ;
y  = y(inds) ;
id = id(inds) ;

M1 = max(y(id==1)) ;
M1i= y == M1 ;

mxi = y == max(y) ;

g_ncone = x(end) ;
g_ll = y(end) ;

y = y - m ;
y = 200 * (1-y/(M-m)) ;
x = 200 * (x-minx)/(max(x)-minx) ;

svg = sprints('<use xlink:href="#%d" transform="translate(%f %f)"/>\n',id,x,y) ;

% svg = svg_xcoord( x(end) , y(end) , 200 ) ;
% svg = svg_ycoord( x(end) , y(end) , 200 ) ;

% svg = svg_ycoord( x(end) , y(end) , 200 ) ;

svg = [sprintf('<line x1="0" x2="%f" y1="%f" y2="%f" text-anchor="middle" stroke="black" opacity="0.3"/>\n',x(end),y(end),y(end)) ...
       sprintf('<text x="-5" y="%f" font-size="12" text-anchor="end" baseline-shift="-45%%">%d</text>\n',y(end),ceil(g_ll)) ...
       sprintf('<line x1="%f" x2="%f" y1="%f" y2="200" text-anchor="middle" stroke="black" opacity="0.3"/>\n',x(end),x(end),y(end)) ...
       sprintf('<text x="%f" y="200" font-size="12" text-anchor="middle" baseline-shift="-100%%">%d</text>\n',x(end),g_ncone) ...
       sprintf('<line x1="0" x2="%f" y1="0" y2="0" text-anchor="middle" stroke="black" opacity="0.3"/>\n',x(mxi)) ...
       sprintf('<text x="-5" y="0" font-size="12" text-anchor="end" baseline-shift="-45%%">%d</text>\n',ceil(M)) ...
       sprintf('<line x1="200" x2="200" y1="%f" y2="200" text-anchor="middle" stroke="black" opacity="0.3"/>\n',y(x==max(x))) ...
       sprintf('<text x="200" y="200" font-size="12" text-anchor="middle" baseline-shift="-110%%">%d</text>\n',ceil(Mx)) ...
       sprintf('<line x1="%f" x2="0" y1="%f" y2="%f" text-anchor="middle" stroke="black" opacity="0.3"/>\n',x(end-2),y(end-2),y(end-2)) ...
       sprintf('<text x="-5" y="%f" font-size="12" text-anchor="middle" baseline-shift="-110%%">%d</text>\n',y(end-2),ceil(M1)) ...
       sprintf('<text x="100" y="220" font-size="15" text-anchor="middle" baseline-shift="-100%%">     number of cones</text>\n') ...
       sprintf('<g transform="translate(-10 55)rotate(-90)"><text font-size="15" text-anchor="end">log posterior</text></g>\n') ...
       sprintf('<text x="100" y="-25" font-size="18" text-anchor="middle"><tspan fill="green">Greedy</tspan>, <tspan fill="blue">MCMC</tspan> and <tspan fill="red">Parallel tempering</tspan></text>\n') ...
       svg] ;

svg = insert_string(svg,'plot_LL_ncones_stub.svg',-40) ;

fid = fopen('LL_ncones.svg','w') ;
fwrite(fid,svg) ; fclose(fid) ;

end


function [x,y] = get_N_ll( Xs )

x = zeros(numel(Xs),1) ;
y = zeros(numel(Xs),1) ;
for i=1:numel(Xs)
    x(i) = Xs{i}.N_cones ;
    y(i) = Xs{i}.ll ;
end

end