% Stefen Gill
% ME EN 6510
%
% This script analyses the surface of the membrane mirror, a parabolic
% mirror, and a spherical mirror, and then makes plots to show how they
% compare in terms of abberations present. The parabolic mirror is meant as
% a reference to an absolutely perfect mirror. The spherical mirror is
% acceptable for some amateur astronomers, but anything more extreme than
% the spherical aberration exhibited by the membrane mirror is
% unacceptable. For this reason, the membrane mirror will be deemed of an
% acceptable shape if its distribution of reflected light destinations on
% the optical axis lies between those of the parabolic and spherical
% mirrors.
close all

% Start by loading the membrane mirror data:
w0 = 2.0833; % Center deflection of the membrane/parabolic mirror to achieve 1200mm focal length.
f6_mirror_profile_data = readmatrix('pressure_variation_output\70_240096.rpt', ...
    'FileType', 'text');
f6_mirror_profile_data = sortrows(f6_mirror_profile_data, 1);
x = f6_mirror_profile_data(:, 1);
y_membrane = f6_mirror_profile_data(:, 2) + w0;

% Trim the data down to not include the clamped part of the mirror (up to
% the 100mm radius mark):
mirror_radius = 100; % (mm)
edge_index = find(x == mirror_radius);
x = x(1:edge_index);
y_membrane = y_membrane(1:edge_index);

% Create the parabolic mirror. The x coordinates for all three mirrors
% considered will be the same.
f = 1200; % (mm) Focal length.
y_parabola_func = @(x) (1/(4*f))*x.^2;
y_parabola_deriv_func = @(x) (1/(2*f))*x;
y_parabola = y_parabola_func(x);

% Create the spherical mirror. The focal length of a spherical mirror is
% half its radius. So the sphere's radius must be 2*f to make a mirror that
% can be compared to the other two.
R = 2*f; % (mm) Spherical mirror radius.
y_sphere_func = @(x) -sqrt(R^2 - x.^2) + 2*f;
y_sphere_deriv_func = @(x) (1/2)*sqrt(R^2 - x.^2)*2.*x;
y_sphere = y_sphere_func(x);

% Plot the three mirror surfaces together as a sanity check:
plot(x, y_membrane, 'Color', 'k', 'DisplayName', 'Membrane')
hold on
plot(x, y_parabola, 'Color', 'b', 'DisplayName', 'Parabolic', ...
    'LineStyle', '--')
plot(x, y_sphere, 'Color', 'r', 'DisplayName', 'Spherical', ...
    'LineStyle', ':')
xlabel('x (mm)')
ylabel('y (mm)')
title('Mirror Surface Comparison (200mm Diameter, 1200mm Focal Length)')
grid
legend
saveas(gcf, 'mirror_shapes.svg')

% Calculate the distribution of light reflected onto the optical axis for
% each mirror, this can be used characterize the aberrations of each
% mirror.
y_membrane_reflected = ray_trace_mirror_surface(x, y_membrane);
y_parabola_reflected = ray_trace_mirror_surface(x, y_parabola);
y_sphere_reflected = ray_trace_mirror_surface(x, y_sphere);

% The strange membrane mirror shape causes several reflected rays to end
% up on the order of 10^16 mm from the surface, and this causes problems
% when trying to plot a histogram. Since I will limit showing the histogram
% to within a few mm of the target focal length anyway, I am scrubbing
% those extremely high points from the data.
membrane_focal_points_are_within_2000 = y_membrane_reflected <= 2000;
y_membrane_reflected = y_membrane_reflected(membrane_focal_points_are_within_2000);

% Plot histograms showing the distibution of light that is reflected back
% to the optical axis. The tighter these distributions, the better. The
% parabolic mirror should be a perfect point at 1200mm.
figure
histogram(y_parabola_reflected, 10000, 'FaceColor', 'r', 'DisplayName', ...
    'Parabolic Mirror')
hold on
histogram(y_sphere_reflected, 10000, 'FaceColor', 'g', 'DisplayName', ...
    'Spherical Mirror')
histogram(y_membrane_reflected, 10000, 'FaceColor', 'b', 'DisplayName', ...
    'Membrane Mirror')
title('Mirror Focal Distributions')
xlabel('Point of Focus Along the Optical Axis (mm)')
ylabel('Reflected Light Ray Frequency')
xlim([1198, 1202])
legend
set(gcf, 'position', [10, 10, 550, 1200])
saveas(gcf, 'focal_dist_1.svg')

% Plot a second histogram that highlights how poor the membrane mirror
% shape is compared to the other two.
figure
histogram(y_parabola_reflected, 1000, 'FaceColor', 'r', 'DisplayName', ...
    'Parabolic Mirror')
hold on
histogram(y_sphere_reflected, 1000, 'FaceColor', 'g', 'DisplayName', ...
    'Spherical Mirror')
histogram(y_membrane_reflected, 1000, 'FaceColor', 'b', 'DisplayName', ...
    'Membrane Mirror')
title('Mirror Focal Distributions')
xlabel('Point of Focus Along the Optical Axis (mm)')
ylabel('Reflected Light Ray Frequency')
xlim([1198, 1330])
legend
set(gcf, 'position', [10, 10, 550, 1200])
saveas(gcf, 'focal_dist_2.svg')

% Plot a histogram of the parabolic mirror focal distribution when using
% the true derivative of a parabola (instead of finite difference
% estimates). The histogram for the parabolic mirror should be a single bin
% at 1200mm, but it is not in the histograms previously generated because
% of the estimated derivative. The following plot is meant to test the
% algorithm for finding the focal distribution in the ideal case where we
% know the slope exactly at each point on the mirror surface.
y_parabola_reflected_true = ray_trace_mirror_surface_true(x, y_parabola, y_parabola_deriv_func);
y_sphere_reflected_true = ray_trace_mirror_surface_true(x, y_sphere, y_sphere_deriv_func);
considered_range = [400, 2000];
mask = y_sphere_reflected_true <= considered_range(2) & y_parabola_reflected_true >= considered_range(1);
y_sphere_reflected_true = y_sphere_reflected_true(mask);
figure
histogram(y_parabola_reflected_true, 10000, 'FaceColor', 'r', 'DisplayName', ...
    'Parabolic Mirror')
hold on
title('True Parabolic Mirror Focal Distributions (Calculated Using True Mirror Slopes)')
xlabel('Point of Focus Along the Optical Axis (mm)')
ylabel('Reflected Light Ray Frequency')
xlim([1198, 1202])
legend
set(gcf, 'position', [10, 10, 550, 1200])
saveas(gcf, 'focal_dist_1.svg')

% This function returns a distribution of y coordinates where reflected
% parallel rays of light end up on the optical axis, essentially applying
% Snell's law to many parallel rays of light approaching a mirror's
% surface. For a parabolic mirror, these y_reflected will be on the same
% place on the mirror, because parabolic mirrors have no optical
% aberration. For the sperical mirror, they will be spread out a bit due to
% spherical aberration. surface_x and surface_y are the x and y coordinates
% of the mirror's surface, passed as vectors.
function y_reflected = ray_trace_mirror_surface(surface_x, surface_y)
% The set of coordinates where parallel rays of light reflect off the
% mirror surface are simply the x and y coordinates of the mirror surface,
% excluding the point in the very center because the light will not be
% reflected at all (incidence angle of pi/2rad):
x_incidence = surface_x(2:end);
y_incidence = surface_y(2:end);

% The mirror surface's angle at each of these incidence points, phi, is
% necessary. It is calculated from a finite difference estimation of the
% surface's derivative with respect to x.
delta_x = diff(surface_x);
delta_y = diff(surface_y);
phi = atan(delta_y./delta_x);

% Using the mirror surface coordinates, solve for the y intercept of the
% equation describing the reflected ray of light from the mirror. Beta is
% the angle from the positive x axis to a reflected ray of light.
beta = pi/2 - 2*phi;
y_reflected = y_incidence + x_incidence.*tan(beta);
end

% Derivative estimates result in focal distribution histograms that don't
% match what is expected for the parabolic mirror. The focal distribution
% should be a single bin concentrated at 1200mm (the focal length) for the
% parabolic mirror, since it is the ideal surface. The derivative estimate
% on discrete data causes this to not be the case. This function shows this
% by performing the same ray tracing operation as the function above, but
% requires passing an anonymous function that is the mirror surface's
% derivative.
function y_reflected = ray_trace_mirror_surface_true(surface_x, surface_y, ...
    surface_deriv_func)
% The set of coordinates where parallel rays of light reflect off the
% mirror surface are simply the x and y coordinates of the mirror surface,
% excluding the point in the very center because the light will not be
% reflected at all (incidence angle of pi/2rad):
x_incidence = surface_x(2:end);
y_incidence = surface_y(2:end);

% The mirror surface's angle at each of these incidence points, phi, is
% necessary. It is related to the mirror surface's slope.
phi = atan(surface_deriv_func(x_incidence));

% Using the mirror surface coordinates, solve for the y intercept of the
% equation describing the reflected ray of light from the mirror. Beta is
% the angle from the positive x axis to a reflected ray of light.
beta = pi/2 - 2*phi;
y_reflected = y_incidence + x_incidence.*tan(beta);
end