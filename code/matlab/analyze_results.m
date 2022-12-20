% Stefen Gill
% ME EN 6510
%
% Perform analysis on simulation results from Abaqus. Simultaneously
% produce plots concerning these results.

% Load the CSV data containing differential pressure vs. mirror center
% deflection, as well as the deflection data for the mirror matching the
% target focal length of 1200mm (70.240096Pa applied).
max_deflection_data = readmatrix('pressure_variation_output\max_deflection.csv');
f6_mirror_profile_data = readmatrix('pressure_variation_output\70_240096.rpt', ...
    'FileType', 'text');

% Resolve applied vacuum pressure and max deflection:
P = max_deflection_data(:, 1);
w0 = max_deflection_data(:, 2);

% Resolve the X coordinates and Y deflections of the mirror meeting the
% 1200mm focal length constraint. The values should be sorted to avoid
% strange line plots later.
f6_mirror_profile_data = sortrows(f6_mirror_profile_data, 1);
mirror_x = f6_mirror_profile_data(:, 1);
mirror_y = f6_mirror_profile_data(:, 2);

% Plot the max deflection mirror deflection vs. applied vaccum pressure.
target_w0 = 2.0833;
plot(P, w0, 'LineStyle', 'none', 'Color', 'r', 'Marker', 'o', ...
    'DisplayName', 'Simulation Results')
hold on
plot([65, 105], [target_w0, target_w0], 'LineStyle', '--', ...
    'Color', 'k', 'DisplayName', 'Deflection to Achieve f = 1200mm')
title('Membrane Mirror Center Deflection vs. Applied Pressure')
xlabel('Applied Vacuum Pressure (Pa)')
ylabel('Membrane Center Deflection Magnitude (mm)')
grid
legend('Location', 'northwest')
saveas(gcf, 'newton_raphson_results.svg')

% Plot the membrane deflection corresponding to the 1200mm focal length
% mirror:
figure
plot(mirror_x, mirror_y, 'Color', 'r', 'DisplayName', 'Membrane Mirror')
