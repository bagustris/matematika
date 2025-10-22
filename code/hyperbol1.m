pkg load geometry
figure(1); clf; 
%drawParabola([0 0 .2 270]);
drawParabola([3 0 .1 270], [-5 5], 'color', 'r', 'linewidth', 2);
hold on;
drawParabola([-3 0 .1 90], [-5 5], 'color', 'r', 'linewidth', 2);
axis("equal");
hold off;

