function[apstuff_output] = ap_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, apstuff_output, initial_treshold)

current_trails = accepted_trials{k};
current_sweeps = accepted_sweeps{k};

if isempty(current_trails)
    % Skip to the next iteration of the loop
    return;
end

RecTable = currentCell.RecTable;

% Counts how many recordings for cell k were selected!
filled_count = sum(cellfun(@(x) isnumeric(x) && ~isempty(x), current_trails));

% Iterate through all use_step_index values
for z = 1:filled_count
    
    use_step = current_trails{z, 1};

    % Access sweep data for the selected STEP recording
    sweepsData = RecTable{use_step, 'dataRaw'}{1, 1}{1, 1};

    % Access stimulus data for the selected STEP recording
    stimulusData = RecTable{use_step, 'stimWave'}{1, 1}.DA_3;
    
    % Access the specific column
    data_to_search = current_sweeps(:, use_step);

    if ~isempty(data_to_search)
        data_with_ones = cellfun(@(x) ~isempty(x) && x(1), data_to_search);
    
        % Find the row numbers where the condition is true
        rows_with_logical_one = find(data_with_ones);
    else
         rows_with_logical_one = int32([]);
    end

    % Iterate through rows_with_logical_one     
    for i = 1:length(rows_with_logical_one)
        
            % Finds the first selected sweep index!
            current_row = rows_with_logical_one(i);

            % Accesses the recording data for the selected sweep!
            myDataRow = sweepsData(:, current_row);

            if  current_row >= 4
                
                    timebaseDaten = timebase_data{k}{1};

                    stim_on = stim_onset{k}{1};    

                    % Define the threshold value
                    threshold = (median(myDataRow(6000:14000))+initial_treshold);

                    % Identify the interval (4500 to 15500)
                    interval = false(length(myDataRow), 1);  % Initialize with false
                    interval(4950:15050) = true;  % Set true for the specified interval

                    % Create a logical array for threshold crossing within the interval
                    thresholdCrossingInterval = (myDataRow > threshold) & [false; diff(myDataRow > threshold)] & [false; diff(myDataRow) > 0] & interval;

                    % Create the final output array, preserving alignment with original data
                    thresholdCrossing = false(length(myDataRow), 1);  % Initialize with false
                    thresholdCrossing(interval) = thresholdCrossingInterval(interval);  % Apply logic only in the interval

                    % Get the indices corresponding to the threshold crossings
                    ap_indices = find(thresholdCrossing);
                    
                    % Set a window around each threshold crossing index to look for peaks
                    window_before = 0;  % Number of points before the threshold crossing
                    window_after = 20;   % Number of points after the threshold crossing
                    
                    
                    peaks_indices = [];
                    
                    % Loop through each threshold crossing index
                    for i = 1:length(ap_indices)
                        start_index = max(ap_indices(i) - window_before, 1);
                        end_index = min(ap_indices(i) + window_after, length(myDataRow));
                        
                        % Extract the window around the threshold crossing index
                        window_data = myDataRow(start_index:end_index);
                                                    % Find peaks in the window using findpeaks
                            [pks, locs] = findpeaks(window_data);
                            
                            % Adjust peak indices to the global indices
                            locs = locs + start_index - 1;
                            
                            % Append peak indices to the result
                            peaks_indices = [peaks_indices; locs];
                 
                    end

                    
%                     % Display the result
%                     disp('Peak indices closely following threshold crossings:');
%                     disp(peaks_indices);


                    % Calculate the Second Derivative
                    dx = timebaseDaten(2) - timebaseDaten(1); % Assuming evenly spaced data
                    firstDerivative = diff(myDataRow) / dx;
                    secondDerivative = diff(firstDerivative) / dx;

                    % Preallocate arrays for timepoints of zero crossings and maxima
                    ap_times_zero_crossings = zeros(size(ap_indices));
                    ap_times_maxima = zeros(size(ap_indices));
                    try
                        % Loop through each threshold crossing
                        for i = 1:length(ap_indices)
                            % Define the search window (100 data points before the threshold crossing)
                            windowStart = max(1, ap_indices(i) - 50);
                            windowEnd = ap_indices(i) - 1; % Up to the point of threshold crossing
    
                            % Find zero crossings from positive to negative in the second derivative within this window
                            secondDerivativeWindow = secondDerivative(windowStart:windowEnd);
                            if length(secondDerivativeWindow) > 1
                                % Calculate the difference between consecutive elements
                                secondDerivDiff = diff(secondDerivativeWindow);
    
                                % Find indices where second derivative goes from positive to negative
                                crossingIndices = find(secondDerivativeWindow(1:end-1) > 0 & secondDerivDiff < 0);
    
                                % Find the maximum value and its index within the window
                                [maxValue, maxIndex] = max(secondDerivativeWindow);
    
                                % Adjust indices to align with the original data array and get the last crossing point and maximum point
                                if ~isempty(crossingIndices)
                                    ap_times_zero_crossings(i) = timebaseDaten(crossingIndices(end) + windowStart);
                                    ap_times_maxima(i) = timebaseDaten(maxIndex + windowStart);
                                else
                                    ap_times_zero_crossings(i) = NaN; % No crossing found in the window
                                    ap_times_maxima(i) = NaN; % No maximum found in the window
                                end
                            else
                                ap_times_zero_crossings(i) = NaN; % Window is too small for analysis
                                ap_times_maxima(i) = NaN; % No maximum found in the window
                            end
                        end
                    end

                    % Remove NaN values from the result
                    ap_times = ap_times_maxima(~isnan(ap_times_maxima));

                    do_plot = true;
                    try
                        [threshold, amp, half_width, rise_time] = ap_stuff(myDataRow, timebaseDaten, ap_times, stim_on, do_plot, k, peaks_indices);
                    end
                    try
                        apstuff_output{k}{1, use_step}{current_row-3} = threshold;
                    end
                    try
                        apstuff_output{k}{2, use_step}{current_row-3} = amp;
                    end
                    try
                        apstuff_output{k}{3, use_step}{current_row-3} = half_width;
                    end
                    try
                        apstuff_output{k}{4, use_step}{current_row-3} = rise_time;
                    end
                    try
                        apstuff_output{k}{5, use_step}{current_row-3} = ap_times;
                    end
            end
    end
end    


% Get the number of rows
numRows = size(accepted_sweeps{k}, 1);

% Get the number of columns
numCols = size(accepted_sweeps{k}, 2);


% Iterate over the values of a
for a = 1:(numRows-3)

    % Initialize arrays to store data for the current a
    data_for_a_threshold = [];
    data_for_a_amp = [];
    data_for_a_half_width = [];
    data_for_a_rise_time = [];
% 
%     % Iterate over the values of c
%     for c = 1:numCols
%         try
%             % Extract firing_per_sweep for the specified a and c
%             data_for_a_c_threshold =  apstuff_output{k}{1, c}{a};
%             data_for_a_c_amp =  apstuff_output{k}{2, c}{a};
%             data_for_a_c_half_width =  apstuff_output{k}{3, c}{a};
%             data_for_a_c_rise_time =  apstuff_output{k}{4, c}{a};
% 
% 
%             data_for_a_threshold =  [data_for_a_threshold, data_for_a_c_threshold];
%             data_for_a_amp =  [data_for_a_amp, data_for_a_c_amp];
%             data_for_a_half_width =  [data_for_a_half_width, data_for_a_c_half_width];
%             data_for_a_rise_time =  [data_for_a_rise_time, data_for_a_c_rise_time];
%         end
%     end
%     
%     % Compute the mean for the current a
%     avg_threshold = mean(data_for_a_threshold);
%     avg_amp = mean(data_for_a_amp);
%     avg_half_width = mean(data_for_a_half_width);
%     avg_rise_time = mean(data_for_a_rise_time);

    % Iterate over the values of c
    for c = 1:numCols
        try
            % Extract firing_per_sweep for the specified a and c
            data_for_a_c_threshold =  apstuff_output{k}{1, c}{a};
            data_for_a_c_amp =  apstuff_output{k}{2, c}{a};
            data_for_a_c_half_width =  apstuff_output{k}{3, c}{a};
            data_for_a_c_rise_time =  apstuff_output{k}{4, c}{a};
    
            % Check for NaN values and exclude them
            nan_indices = isnan(data_for_a_c_threshold) | isnan(data_for_a_c_amp) | isnan(data_for_a_c_half_width) | isnan(data_for_a_c_rise_time);
    
            % Check if the arrays are not empty before concatenating
            if ~isempty(data_for_a_c_threshold) && ~isempty(data_for_a_c_amp) && ~isempty(data_for_a_c_half_width) && ~isempty(data_for_a_c_rise_time)
                data_for_a_c_threshold(nan_indices) = [];
                data_for_a_c_amp(nan_indices) = [];
                data_for_a_c_half_width(nan_indices) = [];
                data_for_a_c_rise_time(nan_indices) = [];
    
                data_for_a_threshold =  [data_for_a_threshold, data_for_a_c_threshold];
                data_for_a_amp =  [data_for_a_amp, data_for_a_c_amp];
                data_for_a_half_width =  [data_for_a_half_width, data_for_a_c_half_width];
                data_for_a_rise_time =  [data_for_a_rise_time, data_for_a_c_rise_time];
            end
        end
    end
    
    % Compute the mean for the current a, excluding NaN values and empty cells
    avg_threshold = mean(data_for_a_threshold, 'omitnan');
    avg_amp = mean(data_for_a_amp, 'omitnan');
    avg_half_width = mean(data_for_a_half_width, 'omitnan');
    avg_rise_time = mean(data_for_a_rise_time, 'omitnan');


    try
        apstuff_output{k}{a+5, 1} = avg_threshold;
    end
    try
        apstuff_output{k}{a+5, 2} = avg_amp;
    end
    try
        apstuff_output{k}{a+5, 3} = avg_half_width;
    end
    try
        apstuff_output{k}{a+5, 4} = avg_rise_time;
    end
end


filename = sprintf('Output/ap_plot_cell%d.png', k);

% Save the plot with the generated filename
saveas(gcf, filename);

% Close the current figure to avoid overlap
close(gcf);
end