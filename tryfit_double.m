function [tau, baseline, resistance, distance, sag, exp2_vars] = tryfit_double(myDataRow, timebaseDaten, stimulus_amp, stim_onset, stim_offset, plot_figs, remove_bad_fit, min_data, cell_index, min_y_val)
    % Function to fit a double-exponential model to the data and compute various parameters.
    
    bad_fit = 0;

    if isempty(min_data)
        x = timebaseDaten(stim_onset:(stim_onset+1500))';
        y = myDataRow(stim_onset:stim_onset+1499);
        display('Used Standard Interval for Fit')
    else
        x = timebaseDaten(1:(min_data))';
        y = myDataRow(stim_onset:(stim_onset+(min_data-1)));
    end

    % Double exponential fit
    fo_double = fitoptions('Method','NonlinearLeastSquares', 'Lower',[-0.1, 6500, -0.1, min_data, min_y_val], 'Upper',[0, Inf, 0, Inf, 0], 'StartPoint',[-0.1, 6000, -0.1, min_data, min_y_val]);
    ft_double = fittype('a*exp(-b*x)+c*exp(-d*x)+e','options',fo_double);
    
    [FITDATA_double, gof_double] = fit(x, y, ft_double);

    tau_1 = -1 / FITDATA_double.b;
    tau_2 = -1 / FITDATA_double.d;

    if plot_figs
        figure;
        plot(timebaseDaten, myDataRow, timebaseDaten, feval(FITDATA_double, timebaseDaten));
        title(['Double Exponential Fit for Cell ' num2str(cell_index)]);
        xlabel('Time [s]');
        ylabel('Membrane Voltage [mV]');
        legend('Data', 'Fit');
        grid on;
    end
    
    % Compute other parameters
    baseline = mean(myDataRow(1:stim_onset-100));
    resistance = (baseline - feval(FITDATA_double, stim_onset+1000)) / stimulus_amp * -1000;
    distance = baseline - feval(FITDATA_double, stim_offset);
    Mittel2 = mean(myDataRow(stim_offset-2000:stim_offset)) - feval(FITDATA_double, stim_offset);
    sag = (100 / distance) * Mittel2;

    % Handle bad fit
    if bad_fit
        tau = NaN;
        resistance = NaN;
        distance = NaN;
        sag = NaN;
    end

    % Prepare output structure
    exp2_vars = struct('Fita', FITDATA_double.a, 'Fitb', FITDATA_double.b, 'Fitc', FITDATA_double.c, 'Fitd', FITDATA_double.d, 'Fite', FITDATA_double.e, 'tau1', tau_1, 'tau2', tau_2);
end
