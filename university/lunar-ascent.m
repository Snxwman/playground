%% Script setup

clc; clear all; close all;
format compact; format shortG;

global current_altitude;
global current_velocity;
global current_acceleration;
global current_mass;

%% Given and intial parameters

% https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html
moon_radius = 1737 * 1000;  % Meters
moon_mass = 0.07346e+24;    % Kilograms
grav_const = 6.67e-11;      % Newton Meters^2

thrust = 15568;   % Newtons
burn_time = 438;  % Seconds
Isp = 311;        % Seconds

u_eq = Isp * 9.81;  % Meters/Second

M_0 = 4682;       % Kilograms
M_p = 2384;       % Kilograms
M_b = M_0 - M_p;  % Kilograms

target_altitude = 55000;   % Meters
target_velocity = sqrt((grav_const*moon_mass) / (moon_radius+target_altitude));  % Meters/Second^2

current_range = 0;         % Meters
current_altitude = 0;      % Meters
current_velocity = 0;      % Meters/Second
current_acceleration = 0;  % Meters/Second^2

mass_flow = M_p / burn_time;  % Kilograms/Second

vertical_time = 10;  % Seconds
step = .01;          % Seconds

% Both vertical_profile and roll_profile have the following makeup:
% [t, altitude, velocity, accceleration, mass, theta, range]
vertical_profile = zeros(vertical_time/step, 7);
roll_profile = zeros((burn_time - vertical_time)/step, 7);
log_index = 0;

% Range and step to search for optimal kick angle (degrees)
kick_range_low = 5;  
kick_range_high = 10;
kick_range_step = 1e-2;

%% Numerically integrate for velocity and altitude during vertical ascent profile

for t = 0:step:vertical_time
   local_gravity = (grav_const * moon_mass)/(moon_radius + current_altitude)^2;
   
   current_mass = M_0 - (mass_flow * t);
   current_acceleration = (thrust - current_mass * local_gravity) / current_mass;
   
   current_altitude = current_altitude + (current_velocity * step);
   current_velocity = current_velocity + (current_acceleration * step);
   
   % Log results of step
   log_index = log_index + 1;
   vertical_profile(log_index, :) = [t, current_altitude, current_velocity, current_acceleration, ...
                                     current_mass, 0, 0];
end

fprintf('Altitude at top of vertical profile: %.2f m \n', vertical_profile(end, 2));
fprintf('Velocity at top of vertical profile: %.2f m/s^2 \n\n', vertical_profile(end, 3));

%% Determine kick angle and numerically integrate roll profile

kick_angle = 0;  % Optimal kick angle
last_altitude_delta = Inf;

w = waitbar(0, 'Determining Kick Angle...');
for kick_angle_guess = kick_range_low:kick_range_step:kick_range_high
    theta = deg2rad(kick_angle_guess);
    
    resetTopOfVerticalConditions(vertical_profile);
    t = vertical_time;
    
    % Drive theta_dot to ~0 to find the final altitude for a given kick angle
    % This block of code is only for determining the optimal kick angle
    while (theta < deg2rad(90)) && (t < burn_time)
        local_gravity = (grav_const * moon_mass)/(moon_radius + current_altitude)^2;
        
        current_mass = M_0 - (mass_flow * t);
        current_acceleration = (mass_flow * u_eq / current_mass) - (local_gravity * cos(theta));
        
        current_altitude = current_altitude + (current_velocity * cos(theta) * step);
        current_velocity = current_velocity + (current_acceleration * step);
 
        theta_dot = local_gravity / current_velocity * sin(theta);
        theta = theta + (theta_dot * step);
        
        t = t + step;
    end
    
    % Check if kick angle was better than previous and store value accordingly
    this_altitude_delta = abs(target_altitude - current_altitude);
    if this_altitude_delta < last_altitude_delta
        last_altitude_delta = this_altitude_delta;
        kick_angle = kick_angle_guess;
    else
        break;  % Stop trying new kick angles when the altitude_deltas start increasing
    end
    
    waitbar((kick_angle_guess - kick_range_low) / kick_range_high, w);
end; close(w);


% While almost the same code as the block above, this is intentionally seperated 
% since logging the step data takes the most time and is useless all but one time in the block above.
% Additionally, this block calculates the range of the rocket at every step.
log_index = 0;
resetTopOfVerticalConditions(vertical_profile);
theta = deg2rad(kick_angle);
t = vertical_time;

while (theta < deg2rad(90)) && (t < burn_time)  % While rocket is ascending and there is fuel remaining
    local_gravity = (grav_const * moon_mass)/(moon_radius + current_altitude)^2;

    current_mass = M_0 - (mass_flow * t);
    current_acceleration = (mass_flow * u_eq / current_mass) - (local_gravity * cos(theta));

    current_altitude = current_altitude + (current_velocity * cos(theta) * step);
    current_range = current_range + (current_velocity * sin(theta) * step);

    current_velocity = current_velocity + (current_acceleration * step);

    theta_dot = local_gravity / current_velocity * sin(theta);
    theta = theta + (theta_dot * step);

    % Log results of step
    log_index = log_index + 1;
    roll_profile(log_index, :) = [t, current_altitude, current_velocity, current_acceleration, ...
                                  current_mass, theta, current_range];
                              
    t = t + step;
end

fprintf('Optimal Kick Angle: %.2f° \n\n', kick_angle);

%% Final analysis of ascent profile

mission_profile = [vertical_profile; roll_profile];
mission_profile = mission_profile(any(mission_profile, 2), :);  % Strip rows of all zeros

fprintf('Target Altitude: %.0f m \t Final Altitude: %.2f m \t Altitude Delta: %.2f   m \n', ...
        target_altitude, current_altitude, abs(target_altitude - current_altitude));
fprintf('Target Velocity: %.0f  m/s \t Final Velocity: %.2f  m/s \t Velocity Delta: %.2f m/s \n', ...
        target_velocity, current_velocity, abs(target_velocity - current_velocity));
fprintf('Target Mass:     %.0f  Kg \t Final Mass:     %.2f  Kg \t Mass Delta:     %.2f  Kg \n\n', ...
        M_b, current_mass, abs(M_b - current_mass));
    
fprintf('Downrange Distance: %.2f m \n\n', current_range);

%% Plot

altitude = mission_profile(:, 2); 
range = mission_profile(:, 7);

figure
plot(range, altitude, '-', 'LineWidth', 2.5);
 
xline(307675, '--', ...
      '(307675 m) Distance Travelled During Burn', ...
      'LineWidth', 1.5, ...
      'LabelVerticalAlignment', 'middle');
yline(85.79, '--', ...
      '(85.79 m) Kick Angle Applied; Gravity Turn Initiated', ...
      'LineWidth', 1.5, ...
      'LabelHorizontalAlignment', 'center');
yline(55000, '--', ...
      '(55,000 m) Target Orbit', ...
      'LineWidth', 1.5, ...
      'LabelHorizontalAlignment', 'center');

title('Gravity Turn Rocket Ascent Trajectory from Lunar Surface to 55 Km Circular Orbit');
xlabel('Range (meters)');
ylabel('Altitude (meters)');
legend('Rocket Vehicle Trajectory Over Burn Time');

grid on;
xlim([-5000 325000]); xticks(0:25000:325000);
ylim([-1000 60000]); yticks(0:2000:60000);

set(gcf,'position',get(0,'ScreenSize'))  % Makes plot open full screen

%% Functions

function resetTopOfVerticalConditions(vertical_profile)
    global current_altitude;
    global current_velocity;
    global current_acceleration;
    global current_mass;
    
    current_altitude = vertical_profile(end, 2);
    current_velocity = vertical_profile(end, 3);
    current_acceleration = vertical_profile(end, 4);
    current_mass = vertical_profile(end, 5);
end

