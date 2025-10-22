% plot y=|2x-4|+1;

x=linspace(0,4,100);
y=abs(2*x-4)+1;
plot(x,y, 'linewidth', 2)
axis([0 4 0 4])