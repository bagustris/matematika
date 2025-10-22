x=[-10:.1:10];
y=(x.^3)-(2*x)+3;
y2=x/(x.^2-4);
%plot(x, y, 'linewidth', 2)
plot(x, y2, 'linewidth', 2)