function [tryfit_output] = fit_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, tryfit_output)

current_trails = accepted_trials{k};
current_sweeps = accepted_sweeps{k};

if isempty(current_trails)
    % Skip to the next iteration of the loop
    return;
end

RecTable = currentCell.RecTable;

% Counts how many recordings for cell k were selected!
filled_count = sum(cellfun(@(x) isnumeric(x) && ~isempty(x), current_trails));
   
% Initialize variables to accumulate the sweeps and count
overallSumSweeps = zeros(20000, 1); % Initialize overall sum of sweeps
overallSweepCount = 0;

% Iterate through all use_step_index values
for z = 1:filled_count
    
    use_step = current_trails{z, 1};

    % Access sweep data for the selected STEP recording
    sweepsData = RecTable{use_step, 'dataRaw'}{1, 1}{1, 1};

    % Access stimulus data for the selected STEP recording
    stimulusData = RecTable{use_step, 'stimWave'}{1, 1}.DA_3;

    % Selected recordings are used to access the right column for the sweep selection output
    % for the specified recording and determines the rows where a logical 1 is set
    rows_with_logical_one = find(current_sweeps{1, use_step});

    % Initialize variables to accumulate sweeps and count for the current use_step_index
    sumSweeps = zeros(20000, 1);
    sweepCount = 0;

    % Iterate through rows_with_logical_one
    for i = 1:length(rows_with_logical_one)
        
        current_row = rows_with_logical_one(i);
        
        if current_row == 1
            myDataRow = sweepsData(:, 1);
        end

        if current_row == 1
            sweepCount = sweepCount + 1;
        end

        % Accumulate sweeps where current_row is equal to 1
        if current_row == 1
            sumSweeps = sumSweeps + myDataRow;
        end
    end

    % Calculate the average sweep for the current use_step_index
    averageSweep = sumSweeps / sweepCount;

    % Accumulate the sum of sweeps and count for all use_step_index
    overallSumSweeps = overallSumSweeps + sumSweeps;
    overallSweepCount = overallSweepCount + sweepCount;
end

% Calculate the overall average by dividing the accumulated sum of sweeps by overallSweepCount
overallAverageSweep = overallSumSweeps / overallSweepCount;

min_idx = 5000;
max_idx = 7000;

avr_interval = overallAverageSweep(min_idx:max_idx);

[minValue, minIndex] = min(avr_interval);

min_y_val = minValue;
min_data = minIndex;

sampleRate = RecTable{i, 'SR'};

timebaseDaten = timebase_data{k}{1};

plot_figs = true;

remove_bad_fit = false;

% Unit is nA!
stimulus_amp = -0.1; 

stim_onset = stim_onset{k}{1};

stim_offset = stim_onset+10000; 

try
    [tau, baseline, resistance, distance, sag, exp2_vars] = tryfit(overallAverageSweep, timebaseDaten, stimulus_amp, stim_onset, stim_offset, plot_figs, remove_bad_fit, min_data, k, min_y_val);
end

% Assign values to the cell array at the specific position
try
    tryfit_output{k}{1} = tau;
end
try
    tryfit_output{k}{2} = baseline;
end
try
    tryfit_output{k}{3} = resistance;
end
try
    tryfit_output{k}{4} = distance;
end
try
    tryfit_output{k}{5} = sag;
end
try
    tryfit_output{k}{6} = exp2_vars;
end

% Generate the filename with the plot number
filename = sprintf('Output/tryfit_plot_Cell%d.png', k);

% Save the plot with the generated filename
saveas(gcf, filename);

% Close the current figure to avoid overlap
close(gcf)

end