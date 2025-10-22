% triangle demo with signal package
x=0 : 0.01 : 8;
f=@(x) 4 * sawtooth(x , 0.5 );
line(x,f(x),'color','r', 'linewidth',2.5)

% plot spectrum
periodogram(x,[],length(x),Fs,'power')
