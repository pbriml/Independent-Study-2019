% Paige Brimley 
% Fall 2019 Independent Study 
% The purpose of this script is to predict the true profile of hydrogen
% evolution from the SFR as N-cstr's in series with the SFR 

clc; clear; close all 

%run the residence time distribution calculations and clear variables 
backmixing_calibration 
clear a avg_torr b const delX i N x_end x_tail xmax y0 

%% Inputs for file import 
filename = 'CeO2_data' ; % enter in the excel file you want to read 
sheet = 2 ; % enter in the sheet number 
data = 'B25:B800' ; % data range, you might need to convert to ppm  

dt = 0.7 ; % mass spec measurement interval, usually 0.7 seconds 

%% Import Data
H2 = xlsread(filename, sheet, data) ; % hydrogen profile 
time = (1:length(H2)) ; % time vector, seconds
window = 20 ; % window for data smoothing, can adjust as needed 
H2 = movmean(H2, window) ; %smoothing data with a moving average 

plot(time, H2, 'LineWidth', 2) 
axis('tight')
xlabel('time, seconds')
ylabel('H_2 Production, ppm')

%% Adjusting profiles 
y_h2 = H2./max(H2) ; % mole fractions 

% derivative of H2 profile using central difference approximations 
dydt = (y_h2(3:end)-y_h2(1:end-2))/(2*dt) ;  

figure
plot(dydt)

H2_adjust = (((tm/N_cstr).*dydt + y_h2(1:end-2))).*max(H2) ; % actual profile in SFR
H2_adjust = movmean(H2_adjust, 20) ; 
figure
plot(time(1:length(H2_adjust)), H2_adjust, 'o')
hold on 
plot(time, H2, 'r-o')
plot(time, zeros(1,length(time)), 'm--', 'LineWidth', 2)
legend(' CSTR-adjusted ', 'Measured Profile') 
xlabel('Time, seconds') 
ylabel('H_2 production, ppm') 
axis('tight') 
title('Measured and Corrected H2 Profiles - CeO2 1450/1200') 

check_H2 = cumtrapz(H2) ; 
check_H2fit = cumtrapz(H2_adjust(1:143)) ; 
err = (check_H2fit(end) - check_H2(end))/check_H2(end) ; 
disp(abs(err))
