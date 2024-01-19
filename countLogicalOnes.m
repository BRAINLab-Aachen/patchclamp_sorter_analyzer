function count_per_row_one_column = countLogicalOnes(accepted_trials, accepted_sweeps, i, numRows)


    % Ensure that count_per_row is assigned a value even if all columns are empty
    if isempty(accepted_trials{i})
        count_per_row_one_column = zeros(size(numRows));
        return
    end
    
    current_sweeps = accepted_sweeps{i};

    trial_indices_cell = accepted_trials{i}(:, 1);

    % Determine the maximum trial index
    max_trial_index = max(cell2mat(trial_indices_cell));

    % Find the length of the longest column
    max_column_length = max(cellfun(@numel, accepted_sweeps{i}));

    % Find the maximum value among the elements of max_column_length
    largest_value = max(max_column_length);
    
    % Initialize a cell array to store the row counters for each row
    row_counters = cell(largest_value, length(trial_indices_cell));


% Loop through each specified column
for j = 1:length(trial_indices_cell)
    % Extract the trial index
    col_index = trial_indices_cell{j};
        
    % Access the specific column
    data_to_search = current_sweeps(:, col_index);
    
    if ~isempty(data_to_search)
        % Find the row numbers where the condition is true
        rows_with_logical_one = find(cellfun(@(x) ~isempty(x) && x(1), data_to_search));
        
        % Increment the counters in row_counters for each row with logical one
        for s = 1:length(rows_with_logical_one)
            row_index = rows_with_logical_one(s);
            
            % Dynamically resize row_counters if needed
            if row_index > size(row_counters, 1)
                % Resize row_counters to accommodate the new row_index
                row_counters{row_index, j} = 1;
            elseif isempty(row_counters{row_index, j})
                % Initialize the counter if it's empty
                row_counters{row_index, j} = 1;
            else
                % Increment the counter
                row_counters{row_index, j} = row_counters{row_index, j} + 1;
            end
        end

    end
end



% Convert the cell array of counters to a numeric array
count_per_row = cellfun(@length, row_counters);

% Sum along the rows to get the count of 1s in each row
count_per_row_one_column = sum(count_per_row, 2);


end