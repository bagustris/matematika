% plot y=|3-x|-1

clear all; close all; clc;
x=[-5:1:5];
y=-x;
plot(x,y, 'linewidth', 2); hold on;
y2=3-x;
plot(x,y2, 'r', 'linewidth', 2); hold on;
y3=abs(3-x);
plot(x,y3, 'g', 'linewidth', 2); hold on;
y4=abs(3-x)-1;
plot(x,y4, 'm', 'linewidth', 2);
legend({'y=-x', 'y=3-x', 'y=|3-x|','y=|3-x|-1'}, 'location', 'north');
axis([0 5 -2 2]);