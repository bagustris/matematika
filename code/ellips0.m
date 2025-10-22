# Draw an ellipse centered in [50 50], with semi major axis length of
# 40, semi minor axis length of 20, and rotated by 30 degrees.
pkg load geometry;
figure(1); clf; hold on;
drawEllipse([0 0 30 20 0], 'r', 'linewidth', 2);
axis equal;
