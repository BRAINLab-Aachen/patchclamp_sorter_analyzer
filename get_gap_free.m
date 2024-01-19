function [gap_free_output] = get_gap_free(currentCell, k, ident_gf, gap_free_output)

RecTable = currentCell.RecTable;

% Count indices where 'Gap-free' is written in the specified column
gap_indices = find(contains(RecTable{:, 10}, ident_gf, 'IgnoreCase', true));

% Initialize output arrays
rec_idx = [];
cell_nr = [];
rec_nr = [];
rec_nr_for_cell = [];

% Loop through each gap index
for j = 1:height(gap_indices)
    % Check if the value in column 2 is the same as the last encountered value
    current_rec_number = gap_indices(j);
    
    count_value = RecTable{current_rec_number, 3};

    current_cell_number = RecTable{current_rec_number, 1};
    
    % Store the information in the output arrays
    rec_idx = [rec_idx; gap_indices(j)];
    cell_nr = [cell_nr; current_cell_number];
    rec_nr = (1:length(gap_indices))';
    rec_nr_for_cell = [rec_nr_for_cell; count_value];
    
    % Update the last encountered value
    last_encountered_value = current_rec_number;
end

% Create a table from the output arrays
gap_free_output{k}{1, 1} = table(rec_idx, cell_nr, rec_nr_for_cell, rec_nr);

% Initialize cell arrays for table columns
ConcatenatedData = cell(height(gap_free_output{k}{1, 1}), 1);
TimebaseData = cell(height(gap_free_output{k}{1, 1}), 1);

% Loop through each row of the output table
for r = 1:height(gap_free_output{k}{1, 1})

    current_rec_number = gap_indices(r);

    sweepsData = RecTable{current_rec_number, 'dataRaw'}{1, 1}{1, 1};
    numSweeps = RecTable{current_rec_number, 6};
    sampleRate = RecTable{current_rec_number, 'SR'};
    
    % Check and ensure consistent sweep lengths before concatenating
    sweepLength = length(sweepsData(:, 1));
    concatenatedData = [];

    for sweepIdx = 1:numSweeps
        currentSweep = sweepsData(:, sweepIdx);
        if length(currentSweep) ~= sweepLength
            error('Sweep lengths are not consistent.');
        end

        % Concatenate the current sweep to the concatenatedData array
        concatenatedData = [concatenatedData; currentSweep];
    end

    % Create a timebase array based on the number of data points and sampling rate
    timebase_data = (0:(length(concatenatedData) - 1)) / sampleRate;

    % Assign values to cell arrays with column vectors
    ConcatenatedData{r} = vertcat(concatenatedData);  % Transpose to create a column vector
    TimebaseData{r} = vertcat(timebase_data).';    
end

Cell_Nr = gap_free_output{k}{1, 1}.cell_nr;
Rec_Nr = gap_free_output{k}{1, 1}.rec_idx;
Rec_Nr_Cell = gap_free_output{k}{1, 1}.rec_nr_for_cell;

% Create the output table
gap_free_output{k}{2, 1} = table(ConcatenatedData, TimebaseData, Cell_Nr, Rec_Nr, Rec_Nr_Cell, 'VariableNames', {'ConcatenatedData', 'TimebaseData', 'Cell_Nr', 'Rec_Nr', 'Rec_Nr_Cell'});


for l = 1:height(gap_free_output{k}{2, 1})

    table_variable = gap_free_output{k}{2, 1};

    current_rec_number = gap_indices(l);

    % Replace underscores in variable_name with LaTeX-style formatting
    plot_title = strrep(['Gap_Free_Nr_' num2str(l) '_of_Cell' num2str(k)], '_', '\_');

    
    % Plot the first concatenated data against the time data
    figure('Units', 'normalized', 'Position', [0, 0, 1, 1]); % Full-screen figure
    plot(table_variable.TimebaseData{l}, table_variable.ConcatenatedData{l});
    xlabel('Time (seconds)');
    ylabel('Voltage in V');
    title(['Plot for ' plot_title]);
    
    % Open the figure before prompting the user
    drawnow;  % Force MATLAB to draw the figure immediately

    % Dynamically generate the filename
    filename = ['Output/gap-free_cell' num2str(k) '.png'];
    
    % Save the figure with the dynamically generated filename
    saveas(gcf, filename);
    
    % Initialize areas table outside the loop
    areas_filepath = table([], [], 'VariableNames', {'AreaUnderCurve', 'IntervalTime'});

    % Loop until the user decides to stop
    set_more_intervals = 'y';
    while strcmpi(set_more_intervals, 'y')
        
            intervals = table;
            interval_skipped = false;  % Flag to indicate whether interval setting was skipped
        
            % Prompt the user to set the interval
            set_interval = input('Set Interval? (Enter y): ', 's');

            if strcmpi(set_interval, 'y')
                % Prompt the user to click on the plot for interval boundaries
                for i = 1:2
                    % Get user input by clicking on the plot
                    [x_clicked, y_clicked] = ginput(1);
                    fprintf('Clicked Point %d: x = %.4f, y = %.4f\n', i, x_clicked, y_clicked);
        
                    % Store interval information in the intervals table
                    interval_info = table(x_clicked, y_clicked, 'VariableNames', ...
                        {'ClickedX', 'ClickedY'});
                    intervals = [intervals; interval_info];
                end
        
                % Display the intervals table
                disp('Intervals Information:');
                disp(intervals);     
            else
                disp('Interval setting skipped.');
                interval_skipped = true;  % Set the flag to true
                                % End the loop if interval is skipped
                if interval_skipped
                    break;
                end
            end
        
            % Only proceed with further processing if interval is not skipped
            if ~interval_skipped

                % Assuming intervals table is already available
                interval_x = sort(intervals.ClickedX);
                interval_y = intervals.ClickedY;
                
                % Find the index of the closest value to interval_x(1)
                [~, int_start] = min(abs(table_variable.TimebaseData{l} - interval_x(1)));
                
                % Find the index of the closest value to interval_x(2)
                [~, int_end] = min(abs(table_variable.TimebaseData{l} - interval_x(2)));
                
                % Display results
                disp(['int_start: ', num2str(int_start)]);
                disp(['int_end: ', num2str(int_end)]);

               % Define the two points for linear fit
                point1 = [interval_x(1), interval_y(1)];
                point2 = [interval_x(2), interval_y(2)];
                
                % Extract interval data using row indices
                interval_time = table_variable.TimebaseData{l}(int_start:int_end);
                interval_data = table_variable.ConcatenatedData{l}(int_start:int_end);
                
                % Perform linear fit between the two marked points
                linear_fit_coefficients = polyfit([point1(1), point2(1)], [point1(2), point2(2)], 1);
                linear_fit = polyval(linear_fit_coefficients, interval_time);

                int_start = int_start-5000;
                int_end = int_end+5000;
                
                % Extract interval data using row indices
                interval_time_plot = table_variable.TimebaseData{l}(int_start:int_end);
                interval_data_plot = table_variable.ConcatenatedData{l}(int_start:int_end);

                % Plot the original data and linear fit
                figure;
                plot(interval_time_plot, interval_data_plot, 'DisplayName', 'Original Data');
                hold on;
                plot(interval_time, linear_fit, '--', 'LineWidth', 2, 'DisplayName', 'Linear Fit');
                xlabel('Time');
                ylabel('Data');
                legend('show');
                title('Selected Interval and Linear Fit');
                grid on;
                hold off;
                
                try 
                    % Calculate the area under the curve
                    area_under_curve = trapz(interval_time, abs(interval_data - linear_fit));
            
                    % Display the area under the curve
                    disp(['Area under the curve: ' num2str(area_under_curve)]);
            
                    % Store the result in a table
                    area_table = table(area_under_curve, (interval_x(2)-interval_x(1)), 'VariableNames', {'AreaUnderCurve', 'IntervalTime'});
                catch
                    disp('Area under the curve calculation skipped.');
                    area_table = table(NaN, NaN, 'VariableNames', {'AreaUnderCurve', 'IntervalTime'});
                end
            
                % Store the result in the areas table
                areas_filepath = [areas_filepath; area_table];
            
                % Optionally, display or save the areas_filepath table
                disp('Areas Table:');
                disp(areas_filepath);
            
                % Prompt the user to set more intervals or close the figure
                set_more_intervals = input('Set more intervals? (Enter y for more, any other key to close): ', 's');

            end
    end      

    
    if ~interval_skipped
        try
            % Assuming you have a FinalAreasTable, replace it with your actual table variable
            FinalAreasTable = areas_filepath;
            
            % Create a new row with the specified values
            new_row = table(area_under_curve, (interval_x(2)-interval_x(1)), 'VariableNames', {'AreaUnderCurve', 'IntervalTime'});
            
            % Append the new row to the existing table
            FinalAreasTable = [FinalAreasTable; new_row];
    
            % Append the FinalAreasTable and corresponding values to the cell array
            cell_variable{l, 1} = FinalAreasTable;
            cell_variable{l, 2} = Rec_Nr(l);
            cell_variable{l, 3} = Rec_Nr_Cell(l);
            cell_variable{l, 4} = Cell_Nr(l);
            
            % Close all figures
            close all; 

            % Create a table with appropriate column names
            gap_free_output{k}{3, 1} = cell2table(cell_variable, 'VariableNames', {'FinalAreasTable', 'Rec_Nr', 'Rec_Nr_Cell', 'Cell_Nr'});
            
        end
    end
    
    clear ConcatenatedData FinalAreasTable RecTable TimebaseData all_variables area_table area_under_curve areas_filepath cell_nr cell_numbers cell_variable concatenatedData count count_value currentSweep current_rec_number current_file dat_file_number_in_excel_list end_idx filtered_data filtered_interval_data folderName fullFolderPath i interval_data interval_indices interval_info interval_skipped interval_time interval_x interval_y intervals j l last_encountered_value linear_fit linear_fit_coefficients matching_variables new_row numSweeps pattern patterns_to_keep plot_title r rec_idx rec_nr rec_nr_for_cell sampleRate sampling_rate set_interval set_more_intervals start_idx sweepIdx sweepLength sweepsData timebase_data unique_values userDecision variable_table variables_to_clear variables_to_keep x_clicked y_clicked;
end