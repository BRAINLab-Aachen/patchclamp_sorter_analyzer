function [tau, baseline, resistance, distance, sag, exp2_vars] = tryfit(myDataRow, timebaseDaten, stimulus_amp, stim_onset, stim_offset, plot_figs, remove_bad_fit, min_data, cell_index, min_y_val)

% Takes single trial data (myDataRow) and corresponding
% timepoints(timebaseDaten) together with stimulus amplitude,
% onset and offset to exponentially fit stimulus response and compute
% time constant, resistance, sag,distance and baseline as well as parameters 
% used for fitting (exp2_vars)!!!

% IMPORTANT: THE ERROR LIED IN THE INTERVALLS FOR X AND Y!!! THEY HAVE TO
% BE RIGHT!!!

bad_fit = 0;

% GIVE THE FUNCTION THE MINIMUM OF THE AVERAGE SO THE INTERVAL CAN BE
% DYNAMICALY SET AND WHEN IT DOES NOT WORK GIVE IT 1500 AS A DEFAULT!!!

if isempty(min_data)
    x = timebaseDaten(1:1500)';
    y = myDataRow(stim_onset:stim_onset+1499);
    display('Used Standard Interval for Fit')
else
    x = timebaseDaten(1:(min_data))';
    y = myDataRow(stim_onset:stim_onset+(min_data-1));
end


% x = timebaseDaten(1:min_data)';  
% y = myDataRow(stim_onset:stim_onset+(min_data-1));

% x = timebaseDaten(1:1500)';  
% y = myDataRow(stim_onset:stim_onset+1499);
%y = y - y(end);
%y = y / y(1);
%FITDATA = fit(x,y, 'exp1');
%%
% Decreasing exp

fo = fitoptions('Method','NonlinearLeastSquares', 'Lower',[0, -Inf, min_y_val], 'Upper',[Inf, (min_data+100), Inf],...
              'StartPoint',[1, -Inf, min_y_val]);
ft_decrease = fittype('a*exp(b*x)+c','options',fo);

clear fo;
%%
[FITDATA, gof] = fit(x,y, ft_decrease);
clear ft_decrease;

if remove_bad_fit == 1
    if gof.adjrsquare < 0
        bad_fit = 1;
        % disp("Bad Fit")
    end
end


zeit = timebaseDaten (1:end-(stim_onset-1))';
hoch = myDataRow(stim_onset:end);
if plot_figs == true
    figure;
    hold on;
    plot(zeit, hoch);
    % plot(FITDATA, x, y)
    plot(x, y);
end

tau = -1 / FITDATA.b;

exp_fit = zeros(length(zeit), 1);
for n = 1:length(zeit)
    exp_fit(n) = FITDATA.a * exp(FITDATA.b * zeit(n, 1)) + FITDATA.c;
end

if plot_figs == true
    plot(zeit, exp_fit);
    title(['Hyperpolarization-dependent Voltage for Cell ' num2str(cell_index)]);

    xlabel('Time [s]');
    ylabel('Membrane Voltage [mV]'), ;
end

baseline = mean(myDataRow(1:stim_onset-100));

%Widerstand in MOhm
resistance = (baseline - exp_fit(stim_onset+1000))/stimulus_amp*-1000;

distance = baseline - exp_fit(stim_offset);

Mittel2 = mean(myDataRow(stim_offset-2000:stim_offset)) - exp_fit(stim_offset); 
sag = (100/distance)*Mittel2;


if bad_fit == 1
    tau = NaN;
    resistance = NaN;
    distance = NaN;
    sag = NaN;
end

exp2_vars = struct;

exp2_vars.Fita = FITDATA.a;
exp2_vars.Fitb = FITDATA.b;
exp2_vars.Fitc = FITDATA.c;

% % Do a double exponential fit
% x = timebaseDaten(1:2000)';
% y = myDataRow(stim_onset:stim_onset+1999);
% 
% fo = fitoptions('Method','NonlinearLeastSquares', 'Lower',[0, -Inf, -Inf, -Inf, -Inf], 'Upper',[Inf, 0, Inf, Inf, Inf],...
%                'StartPoint',[1, -1, 0, 1, 1]);
% ft_decrease = fittype('a*exp(b*x)+c*exp(d*x)+e','options',fo);
% clear fo;
% [FITDATA, gof] = fit(x,y, ft_decrease);
% clear ft_decrease;
% tau_1 = -1/FITDATA.b;
% tau_2 = -1/FITDATA.d;
% 
% % disp("Did double exp fit");
% 
% if plot_figs == true
%     exp_fit = zeros(length(zeit), 1);
%     for n = 1:length(zeit)
%         exp_fit(n) = FITDATA.a * exp(FITDATA.b * zeit(n, 1)) + FITDATA.c * exp(FITDATA.d * zeit(n, 1))+FITDATA.e;
%     end
%     zeit = timebaseDaten (1:end-(stim_onset-1))';
%     hoch = myDataRow(stim_onset:end); %-myDataRow(myy);
%     figure;
%     hold on;
%     plot(zeit, hoch);
%     plot(FITDATA, x, y)
%     plot(x, y);
% end
%     
% exp2_vars = struct;
% 
% exp2_vars.Fita = FITDATA.a;
% exp2_vars.Fitb = FITDATA.b;
% exp2_vars.Fitc = FITDATA.c;
% exp2_vars.Fitd = FITDATA.d;
% exp2_vars.Fite = FITDATA.d;
% 
% exp2_vars.tau1 = tau_1;
% exp2_vars.tau2 = tau_2;

end