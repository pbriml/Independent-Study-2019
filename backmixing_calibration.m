% Written by: Paige Brimley, Fall 2019 
%
% The purpose of this script is to import data from tracer tests to create
% a backmixing model. This script is designed to be run in conjunction with
% "Backmixing_H2_Profile.m". 
% 
% Possible improvements: 
%   -Use another method for smoothing data
%   -Use a different method for calculating numerical derivatives and 
%    integrals
%   -Change windows on sigma-squared and mean residence time averages 
%
% Assuming STP, ideal gas behavior 
% Conversion to/from ppm: 
% http://www.cee.mtu.edu/~reh/courses/ce251/251_notes_dir/node2.html
% 
% Description of Sections: 
% 1. Inputs: 
%    In this section you will input the file information of the data you
%    wish to analyze, along with a few other values. 
% 
% 2. Data Import: 
%    The data from section (1) will be imported and smoothed using a moving
%    average function. You can change the size of the window over which to
%    smooth based on the characteristics of the data (i.e., how noisy it
%    is). If you need more information on the "movmean" function, type
%    "help movmean" in the command window. 
%
% 3. Unit Conversion: 
%    THIS SCRIPT WORKS ONLY WITH DATA IN PPM. This section is necessary 
%    ONLY if the data is imported with units of torr (the default for the 
%    mass spec). You MUST comment this section out if you do the conversion
%    beforehand or are importing data in different units. 
% 
% 4. Plotting Smoothed Data: 
%    This section plots your smoothed and converted data. Use the graph to
%    decide if you like how the data looks. 
% 
% 5. Residence Time Distribution Calcultions: 
%    This section is where the E function, mean residence time, and number
%    of CSTR's is calculated. If you have not smoothed the data enough in 
%    the prior sections, the curves will be too noisy for accurate 
%    calculations! See the Carrillo paper for details on these
%    calculations. 

%% Inputs 

clc; clear; close all 

O2_conc = 537.4 ; % O2 concentration from compressed gas cylinder 
dt = 0.7 ; %interval between measurements (seconds), usually 0.7 

filename = '101719_TracerTest_Calibration_MS' ; % name of file 
sheet = 1 ; % sheet number that data is on 
data = 'F4:F47863' ; % data range 

%% Data Import 

O2_raw = xlsread(filename, sheet, data);

%filtering data through moving average, can change size of window 
window = 20 ; % window over which to average, adjust based on preferences 
minimum = 12000 ; % starting point of data
maximum = 12340 ; % ending point of data 

O2_data = movmean(O2_raw(minimum:maximum), window) ;  

% use to determine if smoothing is adequate, can comment out otherwise 
figure
plot(O2_raw(minimum:maximum), 'LineWidth', 2) 
hold on
plot(O2_data, 'r', 'LineWidth', 2)
axis('tight')
title('O_2 Data , moving average comparison to raw')

O2_data = O2_data - min(O2_data) ; % scaling data to zero
%% Unit Conversion (torr to PPM) 
% You can comment this section out if data is already in ppm 
% Currently, you must enter these in manually 
xmax = length(O2_data) ; % ending point 
x_tail = 242 ; % part where curve levels off, this is used for scaling 
avg_torr = mean( O2_data(x_tail:xmax)) ; %average of tail 
 
S = O2_conc/avg_torr ; %conversion factor from partial pressure to ppm 
O2_data = S.*O2_data; % converting all data to ppm 

%% Plotting Smoothed Data
t = (1:length(O2_data)); % time vector
figure
plot(t, O2_data, 'o') 
ylabel('O2')
axis('tight')
%% Residence Time Distribution Calculations 

y_frac = O2_data./max(O2_data) ; % mole fraction of O2 

% Calculating RTD function (E) via the central difference method.  
% Numerical derivatives amplify noise, therefore use the generated graph to
% determine if the smoothing done prior is adequate. If the data is still
% too noisy, you might need to enlarge the smoothing window or use another
% technique or set of measurements. 

E = (y_frac(3:end)-y_frac(1:end-2))/(2*dt) ; 
figure  
plot(E, 'o', 'LineWidth', 2) 
title(' E, residence time distribution function') 

% calculating mean residence time, using Simpson's 3/8 rule:
b = max(t) ; a = t(1) ; N = length(E) - 1;
delX = (b-a)/3 ; const = 3*delX/8 ;  

% for loop using Simpson's 3/8 rule, data MUST be evenly spaced to use:  
for i = 1:N 
    if i == 1 
        step(i) = const*t(i)*E(i) ; 
    elseif i == N 
        step(i) = const*t(i)*E(i) ; 
    else 
        step(i) = const*3*t(i)*E(i) ; 
    end 
    
end 

t1 = 1:length(step) ;
figure
plot(t1, step, 'o')
tm = mean(step(end - 20:end)) ; % arbitrarily choosing a window to round over

for i = 1:N 
    if i == 1 
        step(i) = const*((t(i) - tm)^2)*E(i) ; 
    elseif i == N 
        step(i) = const*((t(i) - tm)^2)*E(i) ; 
    else 
        step(i) = const*3*((t(i) - tm)^2)*E(i) ; 
    end 

end 

step = movmean(step, 3) ; 
figure
plot(step, '*')
%rounding tail of sigma-squared curve to find value 
sigma_2 = round(mean(step(end-150:end))) ;

N_cstr = ceil((tm^2)/(sigma_2)) ; 


