% triangle wave demo
% Define some parameters that define the triangle wave.
elementsPerHalfPeriod = 3; % N-1 of elements in each rising or falling section.
amplitude = 4; % Peak-to-peak amplitude.
verticalOffset = 0; % Also acts as a phase shift.
numberOfPeriods = 4; % How many replicates of the triangle you want.

% Construct one cycle, up and down.
risingSignal = linspace(0, amplitude, elementsPerHalfPeriod);
fallingSignal = linspace(amplitude, 0, elementsPerHalfPeriod);
% Combine rising and falling sections into one single triangle.
oneCycle = [risingSignal, fallingSignal(2:end-1)] + verticalOffset;
x = 0 : length(oneCycle)-1;

% Now replicate this cycle several (numberOfPeriods) times.
triangleWaveform = repmat(oneCycle, [1 numberOfPeriods]);
x = 0 : length(triangleWaveform)-1;

% Now plot the triangle wave.
plot(x, triangleWaveform, 'r', 'linewidth', 2);
axis([0 8])
grid on;