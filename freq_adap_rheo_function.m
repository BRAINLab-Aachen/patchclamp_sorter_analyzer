function[freq_adap_rheo] = freq_adap_rheo_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, freq_adap_rheo, apstuff_output, step_increments, stim_factor, lin_fit_start, lin_fit_end, a_values_pA, alt_value_lin_fit_end)


% Get the number of rows
numRows = size(accepted_sweeps{k}, 1);

% Get the number of columns
numCols = size(accepted_sweeps{k}, 2);


% % Iterate over the values of a
% for a = 1:(numRows-3)
% 
%     % Initialize arrays to store data for the current a
%     data_for_a_apaptation = [];
%     data_for_a_firing = [];
% 
%     % Iterate over the values of c
%     for c = 1:numCols
%         try
%             % Extract firing_per_sweep for the specified a and c
%             data_for_a_and_c_apaptation = freq_adap_rheo{k}{1, c}{a};
%             data_for_a_and_c_firing = freq_adap_rheo{k}{2, c}{a};
%             
%             % Concatenate data for the current c to the arrays for the current a
%             data_for_a_apaptation = [data_for_a_apaptation, data_for_a_and_c_apaptation];
%             data_for_a_firing = [data_for_a_firing, data_for_a_and_c_firing];
%         end
%     end
%     
%     % Compute the mean for the current a
%     apaptation_ratio_per_current_step = mean(data_for_a_apaptation);
%     firing_per_current_step = mean(data_for_a_firing);

% Iterate over the values of a
for a = 1:(numRows-3)

    % Initialize arrays to store data for the current a
    data_for_a_apaptation = [];
    data_for_a_firing = [];

    % Iterate over the values of c
    for c = 1:numCols
        try
            % Extract data for the specified a and c
            data_for_a_and_c_apaptation = freq_adap_rheo{k}{1, c}{a};
            data_for_a_and_c_firing = freq_adap_rheo{k}{2, c}{a};
    
            % Check for NaN values and exclude them
            nan_indices = isnan(data_for_a_and_c_apaptation) | isnan(data_for_a_and_c_firing);
    
            % Check if the arrays are not empty before concatenating
            if ~isempty(data_for_a_and_c_apaptation) && ~isempty(data_for_a_and_c_firing)
                data_for_a_and_c_apaptation(nan_indices) = [];
                data_for_a_and_c_firing(nan_indices) = [];
    
                % Concatenate data for the current c to the arrays for the current a
                data_for_a_apaptation = [data_for_a_apaptation, data_for_a_and_c_apaptation];
                data_for_a_firing = [data_for_a_firing, data_for_a_and_c_firing];
            end
        end
    end
    
    % Compute the mean for the current a, excluding NaN values and empty cells
    apaptation_ratio_per_current_step = mean(data_for_a_apaptation, 'omitnan');
    firing_per_current_step = mean(data_for_a_firing, 'omitnan');


    try
        freq_adap_rheo{k}{a+2, 1} = apaptation_ratio_per_current_step;
    end
    try
        freq_adap_rheo{k}{a+2, 2} = firing_per_current_step;
    end

end


% Initialize an array to store firing frequencies
firing_values = zeros(1, numRows-3);

% Loop through values of 'a'
for a = 1:(numRows-3)
    try
        % Get firing frequency for the current 'a'
        firing_per_current_step = freq_adap_rheo{k}{a + 2, 2};
    
        % Store the firing frequency in the array
        firing_values(a) = firing_per_current_step;
    end
end

% Create a new figure and plot firing frequencies against injected current
figure;
plot(a_values_pA, firing_values, 'ms', 'MarkerSize', 8);
hold on;
% 
% % Extract the last 4 values
% last_four_a_values_pA = a_values_pA((end-lin_fit_start):(end-lin_fit_end));
% last_four_firing_values = firing_values((end-lin_fit_start):(end-lin_fit_end));
% 
% % Perform a quadratic fit on the last 4 values (change the degree as needed)
% coefficients = polyfit(last_four_a_values_pA, last_four_firing_values, 2); % Change the degree as needed
% 
% % Ensure that the fit curve is above x=0 for y=1
% fit_values = polyval(coefficients, a_values_pA);
% fit_values_adjusted = fit_values + max(0, 1 - min(fit_values));
% 
% % Plot the adjusted fit curve
% plot(a_values_pA, fit_values_adjusted, 'r', 'LineWidth', 2);
% 
% % Find where y = 1 is reached
% x_y_equals_1 = roots(coefficients - 1); % Solve for x when y = 1
% 
% % Ensure that the crosspoint with y=1 is not below x=0
% if ~isempty(x_y_equals_1)
%     x_y_equals_1 = max(0, x_y_equals_1); % Take the positive root, ensuring it's not below x=0
% end
% 
% % Mark the point where y = 1 is reached with purple color
% plot(x_y_equals_1, 1, 'mo', 'MarkerSize', 10, 'LineWidth', 2);  % 'mo' for purple color
% text(x_y_equals_1, 1.1, ['pA = ' num2str(x_y_equals_1, '%.2f')], 'FontSize', 12, 'Color', 'm');  % 'm' for purple color
% 
% % Label the x-axis with 'pA' values
% xlabel('Injected current in pA');
% 
% % Label the y-axis
% ylabel('Firing frequency in Hz');
% 
% % Title for the plot
% title('Firing frequencies against injected current (Individual Points)');
% 
% % Show the plot
% grid on;
% legend('Individual Points', 'Quadratic Fit (Adjusted)', 'Point where y = 1', 'Location', 'Best');
% hold off;
% 

if isempty(a_values_pA)
    return
end

% Assuming lin_fit_end is calculated or defined somewhere
array_length = length(a_values_pA);

% Check if lin_fit_end is larger than the length of arrays
if lin_fit_end > array_length
    % If it is, set it to a maximum value of 6
    lin_fit_end = min(lin_fit_end, alt_value_lin_fit_end);
end

% Check if lin_fit_end is larger than the length of arrays
if lin_fit_end > array_length
    % If it is, set it to a maximum value of 6
    lin_fit_end = min(lin_fit_end, 6);
end

% Extract the last 4 values
last_four_a_values_pA = a_values_pA((lin_fit_start):(lin_fit_end));
last_four_firing_values = firing_values((lin_fit_start):(lin_fit_end));

% Perform a linear fit on the last 4 values
coefficients = polyfit(last_four_a_values_pA, last_four_firing_values, 1);
% 
% % Perform a linear fit
% coefficients = polyfit(a_values_pA, firing_values, 1);
slope = coefficients(1);
intercept = coefficients(2);

% Plot the linear fit
plot(a_values_pA, slope * a_values_pA + intercept, 'r', 'LineWidth', 2);

% Find where y = 1 is reached
x_y_equals_1 = (1 - intercept) / slope;

try
    freq_adap_rheo{k}{3, 3} = x_y_equals_1;
end

% Mark the point where y = 1 is reached with purple color
plot(x_y_equals_1, 1, 'mo', 'MarkerSize', 10, 'LineWidth', 2);  % 'mo' for purple color
text(x_y_equals_1, 1.1, ['pA = ' num2str(x_y_equals_1, '%.2f')], 'FontSize', 12, 'Color', 'm');  % 'm' for purple color

% Label the x-axis with 'pA' values
xlabel('Injected current in pA');

% Label the y-axis
ylabel('Firing frequency in Hz');

% Title for the plot
title('Firing frequencies against injected current (Individual Points)');

% Show the plot
grid on;
legend('Individual Points', 'Linear Fit', 'Point where y = 1', 'Location', 'Best');
hold off;

% Generate the filename with the plot number
filename = sprintf('Output/rheobase_Cell%d.png', k);

% Save the plot with the generated filename
saveas(gcf, filename);

% Close the current figure to avoid overlap
close(gcf);

end