%% File Header
% Written by Samuel Kopp and Bradley Sweet
% December 5th, 2019
% Embry-Riddle Aeronautical University, Daytona Beach, Florida
% AE 313 (Space Mechanics) Final Project
% License: MIT
%
% Copyright 2019 Samuel Kopp
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
% documentation files (the "Software"), to deal in the Software without restriction, including without limitation
% the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
% and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
% THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
% OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

clc; clear; close all;
tic

%% Time
test1 = 32 * 60;
test2 = 53 * 60 * 60;
day = 24 * 60 * 60;
month = 30 * day;
year = 365 * day;

t  = 0;
dt = test1;
tf = test1;

%% Constants
mu_earth     = 398600.435;
radius_earth = 6378.1366;
K = [0, 0, 1];

%% Inputs (Test Values)
lat     = 32.248814;      % latitude of station     (deg)
long    = -110.987419;    % longitude of station    (deg)
gst     = 36;             % Greenwich sidereal time (deg)
el      = 61.7066;        % elevation               (deg)
el_dot  = -0.4321605433;  % elevation rate          (deg/s)
az      = 18.0912;        % azimuth                 (deg)
az_dot  = 0.59;           % azimuth rate            (deg/s)
rho_mag = 822;            % range                   (km)
rho_dot = 3.4899169;      % range rate              (km/s)
j2      = 0.0010826359;   % J2 perturbation

%% Data
rows = fix(tf/dt) + 1;
row_index = 0;

%["t", "i", "j", "k"];
all_p_rECI = zeros(rows, 4);
all_np_rECI = zeros(rows, 4);

%["t", "i", "j", "k"];
all_p_vECI = zeros(rows, 4);
all_np_vECI = zeros(rows, 4);

%["t", "a", "e", "i", "W", "w", "f"];
all_p_OEs = zeros(rows, 7);
all_np_OEs = zeros(rows, 7);

p_rECI = zeros(rows, 4);
np_rECI = zeros(rows, 4);

p_vECI = zeros(rows, 4);
np_vECI = zeros(rows, 4);

p_OEs = zeros(rows, 7);
np_OEs = zeros(rows, 7);

diff_rECI = zeros(rows, 4);
diff_vECI = zeros(rows, 4);
diff_OEs = zeros(rows, 7);

%% Control Flow
% tf = input("Enter total propagation time in seconds: ");
% dt = input("Enter desired timestep in seconds: ");
%
% custom_inputs = input("Enter 'y' to use custom SEZ values or 'n' to use supplied test values: ", 's');
% if lower(custom_inputs) == "y"
%     lat     = input("Enter satellite's latitude in degrees: ");
%     long    = input("Enter satellite's longitude in degrees: ");
%     gst     = input("Enter station�s  Greenwich sidereal time: ");
%     el      = input("Enter satellite's elevation in degrees: ");
%     el_dot  = input("Enter satellite's elevation rate in degrees per second: ");
%     az      = input("Enter satellite's azimuth in degrees: ");
%     az_dot  = input("Enter satellite's azimuth rate in degrees per second: ");
%     rho_mag = input("Enter satellite's range in kilometers: ");
%     rho_dot = input("Enter satellite's range rate in kilometers per second: ");
% end
inputs = [lat, long, gst, el, el_dot, az, az_dot, rho_dot, rho_mag];

% plot_req = input("Enter 'y' to generate a plot or 'n' to only generate data: ", 's');

[p_rECI, p_vECI] = SEZ2ECI(inputs, radius_earth);
np_rECI = p_rECI;
np_vECI = p_vECI;

f = 0;
p_OEs = RV2OE(p_rECI, p_vECI, f, mu_earth, t, K);
np_OEs = p_OEs;
f = p_OEs(6);

while t <= tf
%% Orbit Propogation
    p_OEs = RV2OE(p_rECI, p_vECI, f, mu_earth, t, K);
    np_OEs = RV2OE(np_rECI, np_vECI, f, mu_earth, t, K);

    % Data recording
    row_index = row_index + 1;
    all_p_rECI(row_index, :) = [t, p_rECI];
    all_p_vECI(row_index, :) = [t, p_vECI];
    all_p_OEs(row_index, :)  = [t, p_OEs];
    all_np_rECI(row_index, :) = [t, np_rECI];
    all_np_vECI(row_index, :) = [t, np_vECI];
    all_np_OEs(row_index, :)  = [t, np_OEs];

    t = t + dt;
    p_OEs = perturbation_j2(p_OEs, j2, mu_earth, radius_earth, t);

    [p_rECI, p_vECI, f] = OE2RV(p_OEs, mu_earth, t);
    [np_rECI, np_vECI, ~] = OE2RV(np_OEs, mu_earth, t);
end

for i = 1:rows
   t = all_p_rECI(i, 1);

   dr = all_p_rECI(i, :) - all_np_rECI(i, :);
   dv = all_p_vECI(i, :) - all_np_vECI(i, :);
   doe = all_p_OEs(i, :) - all_np_OEs(i, :);

   diff_rECI(i, :) = [t, dr(2:end)];
   diff_vECI(i, :) = [t, dv(2:end)];
   diff_OEs(i, :) = [t, doe(2:end)];
end

% if lower(plot_req) == "y"
      plot_orbit(all_p_rECI, all_np_rECI);
% end

toc
%% Orbital Mechanics Functions

% returning negative of expected value (maybe degree functions)
function [rECI, vECI, f] = OE2RV(OEs, mu, t)
%% Orbital Elements to Position and Velocity
    a = OEs(1);
    e = OEs(2);
    i = OEs(3);
    W = OEs(4);
    w = OEs(5);
    f = OEs(6);

    p = a * (1-e^2);
    f = find_f(a, e, f, mu, t);

    sin_f = sind(f);
    cos_f = cosd(f);

    rPQW = (p / (1 + e*cos_f)) * [cos_f; sin_f; 0];
    vPQW = (mu / (sqrt(mu * p))) * [-sin_f; e+cos_f; 0];

    sin_w = sind(w);
    cos_w = cosd(w);
    sin_W = sind(W);
    cos_W = cosd(W);
    sin_i = sind(i);
    cos_i = cosd(i);
    sinw_sinW = sin_w * sin_W;
    cosw_cosi = cos_w * cos_i;
    cosW_sini = cos_W * sin_i;

    R = [cos_w*cos_W - sinw_sinW*cos_i, -sin_w*cos_W - sin_W*cosw_cosi, cosW_sini;
         cos_w*sin_W + sin_w*cos_W*cos_i, -sinw_sinW + cos_W*cosw_cosi, -cosW_sini;
         sin_w*sin_i, cos_w*sin_i, cos_i];

    rECI = transpose(R * rPQW);
    vECI = transpose(R * vPQW);
end

function OEs = RV2OE(rECI, vECI, f, mu, t, K)
%% Position and Velocity to Orbital Elements
    r = sqrt(rECI(1)^2 + rECI(2)^2 + rECI(3)^2);
    r_hat = rECI / r;

    v = sqrt(vECI(1)^2 + vECI(2)^2 + vECI(3)^2);

    a = -mu / (2 * ((v^2 / 2) - (mu / r)));

    h_vec = cross(rECI, vECI);
    h = sqrt(h_vec(1)^2 + h_vec(2)^2 + h_vec(3)^2);
    h_hat = (h_vec / h);

    e_vec = (1/mu) * cross(vECI, h_vec) - r_hat;
    e = sqrt(e_vec(1)^2 + e_vec(2)^2 + e_vec(3)^2);
    e_hat = e_vec / e;

    n_vec = cross(K, h_vec);
    n = sqrt(n_vec(1)^2 + n_vec(2)^2 + n_vec(3)^2);
    n_hat = n_vec / n;

    W = atan2d(n_hat(2), n_hat(1));

    i = acosd(dot(h_hat, K));

    if dot(e_hat, K) >= 1
        w = acosd(dot(n_hat, e_hat));
    else
        w = 360 - acosd(dot(n_hat, e_hat));
    end

    if t == 0
        if dot(rECI,vECI) >= 1
            f = acosd(dot(e_hat, r_hat));
        else
            f = 360 - acosd(dot(e_hat, r_hat));
        end
    end

    OEs = [a, e, i, W, w, f];
end

function [rECI, vECI] = SEZ2ECI(inputs, R)
%% SEZ frame to ECI frame
    lat     = inputs(1);
    long    = inputs(2);
    gst     = inputs(3);
    el      = inputs(4);
    el_dot  = deg2rad(inputs(5));
    az      = inputs(6);
    az_dot  = deg2rad(inputs(7));
    rho_mag = inputs(9);
    rho_dot = inputs(8);
    theta_lst = gst + long;

    % Precompute constant values
    sin_lat = sind(lat);
    cos_lat = cosd(lat);
    sin_el = sind(el);
    cos_el = cosd(el);
    sin_az = sind(az);
    cos_az = cosd(az);
    sin_theta = sind(theta_lst);
    cos_theta = cosd(theta_lst);
    term1 = rho_dot * cos_el;
    term2 = rho_mag * sin_el * el_dot;
    term3 = rho_mag * cos_el * az_dot;

    % SEZ distance from station in km
    rhoSEZ = rho_mag * [-cos_el*cos_az;
                         cos_el*sin_az;
                         sin_el];

    rhoSEZ_dot = [-term1*cos_az + term2*cos_az + term3*sin_az;
                   term1*sin_az - term2*sin_az + term3*cos_az;
                   rho_dot*sin_el + rho_mag*cos_el*el_dot];

    % SEZ to ECI transformation matrix
    D = [sin_lat*cos_theta, -sin_theta, cos_lat*cos_theta;
         sin_lat*sin_theta,  cos_theta, cos_lat*sin_theta;
        -cos_lat, 0, sin_lat];

    % ECI distance from station in km
    rhoECI = D * rhoSEZ;
    % ECI range rate
    rhoECI_dot = D * rhoSEZ_dot;

    R1_ECI = R * [cos_lat*cos_theta;
                  cos_lat*sin_theta;
                  sin_lat];

    w_earth = [0; 0; deg2rad(15)/3600];

    rECI = R1_ECI + rhoECI;
    vECI = transpose(rhoECI_dot + cross(w_earth, rECI));
    rECI = transpose(rECI);
end

function f2 = find_f(a, e, f, mu, t)
%% True Anomaly Numerical Integrator
    sqrt_1e = sqrt(1+e);
    sqrt_e1 = sqrt(1-e);

    E1 = 2 * atan2d(sqrt_e1 * tand(f/2), sqrt_1e);
    M1 = E1 - e*sind(E1);

    M2 = M1 + sqrt(mu/a^3) * t;
    E2 = M2 + e*sind(M2);

    while(E2 - M2 - e*sind(E2) >= 1e-5)
        E2 = E2 - (E2-e*sind(E2)-M2) / (1 - e*cosd(E2));
    end

    f2 = 2 * atan2d(sqrt_1e * tand(E2/2), sqrt_e1);
end

function OEs = perturbation_j2(OEs, j2, mu, R, t)
%% Orbital perturbation from j2 force
    a = OEs(1);
    e = OEs(2);
    i = OEs(3);
    W = OEs(4);
    w = OEs(5);

    oblateness = j2 * sqrt(mu/a^3) * (R/a)^2;
    denominator = (1 - e^2)^2;
    cos_i = cosd(i);

    W = W - (3/2) * oblateness * (cos_i / denominator) * t;
    w = w + (3/4) * oblateness * ((5 * cos_i^2) / denominator) * t;

    OEs = [a, e, i, W, w, OEs(6)];
end

%% Plotting Functions

function plot_orbit(rp, rnp)
    figure('name', 'Orbital Propagation');
    hold on;

    [x,y,z] = sphere(50);
    surf(x*6378.1366, y*6378.1366, z*6378.1366);

    i = length(rp);
    comet3(rp(1:i, 2), rp(1:i, 3), rp(1:i, 4), .001)
    comet3(rnp(1:i, 2), rnp(1:i, 3), rnp(1:i, 4), .001);

    xmax = max(rp(:, 2));
    xmin = min(rp(:, 2));
    ymax = max(rp(:, 3));
    ymin = min(rp(:, 3));
    axis([xmin xmax ymin ymax])
end
