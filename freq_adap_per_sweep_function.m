function[freq_adap_rheo] = freq_adap_per_sweep_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, freq_adap_rheo, apstuff_output, step_increments, stim_factor)


% Get the number of rows
numRows = size(accepted_sweeps{k}, 1);

% Get the number of columns
numCols = size(accepted_sweeps{k}, 2);


for a = 1:(numRows-3)
    for c = 1:numCols
        try
            timepoints = apstuff_output{k}{5, c}(1, a);
            
            % Convert the cell array to a numeric array
            numericTimepoints = cell2mat(timepoints);
            
            % Calculate differences between consecutive elements
            intervals = diff(numericTimepoints);

            firing_per_sweep = size(numericTimepoints, 1)*stim_factor;
        end
        try
            freq_adap_rheo{k}{2, c}{a} = firing_per_sweep;
        end
        try
            apaptation_ratio_per_sweep = intervals(1)/intervals(5);
        end
        try
            freq_adap_rheo{k}{1, c}{a} = apaptation_ratio_per_sweep;
        end
    end
end

