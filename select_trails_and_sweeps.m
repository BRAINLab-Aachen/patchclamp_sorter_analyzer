function [accepted_trials, accepted_sweeps, stim_onset, timebase_data] = select_trails_and_sweeps(currentCell, k, accepted_trials, accepted_sweeps, rm_data, stim_onset, timebase_data, ident_gf)

    RecTable = currentCell.RecTable;
    totalRecordings = size(RecTable, 1);
    screenSize = get(0, 'ScreenSize');
    
    global skipCellFlag;
    skipCellFlag = false;
    
    % Assuming rm_data{k} is a matrix of size [numRows x totalRecordings]
    rm_median_per_cell = rm_data{k};
    
    % Create a figure for the scatter plot
    screenSize = get(0, 'Screensize'); % Get screen size for positioning
    hFig = figure('Position', screenSize);
    drawnow;
    hFig.WindowState = 'maximized'; % Maximizing the figure window
    
    hold on; % Hold on to plot multiple datasets
    
    
    % Initialize arrays for scatter plot data
    X = []; % For recording numbers
    Y = []; % For median values
    RS_data = cell(totalRecordings-1, 1);
    
    % Loop through each recording
    for i = 1:(totalRecordings-1)
        % Loop through each sweep within the recording
        for s = 1:numel(rm_median_per_cell(:, i))
            % Extract the median values for the current sweep
            medianValues = rm_median_per_cell{s, i};
            
            % Append the recording number and median values to the arrays
            X = [X; repmat(i, length(medianValues), 1)]; % Append 'i' multiple times for each sweep value
            Y = [Y; medianValues]; % Append median values
    
            % Check if RecTable{i, 3} is a cell array before indexing
            if iscell(RecTable{i, 3})
                % Accumulate RS_data
                RS_data{i} = RecTable.Rs{i, 1}{1, 1};
            else
                % Directly access the data if not a cell array
                RS_data{i} = RecTable.Rs{i, 1}{1, 1};
            end
        end
    end

    scatter(X, Y, 'x');
    
    % X-axis starts at 0 and extends slightly beyond the largest recording number
    xlim([0 max(X)+1]); 
    % Calculate the median of all median values
    referenceRM = median(Y);
    
    % Plot a horizontal line at the median value
    yline(referenceRM, '--', 'Median (Reference for Sweep Selection)', 'Color', 'r', 'LineWidth', 2); % Adds a red dashed line for the median
    
    xlabel('Step Trails');
    ylabel('Voltage in V');

    % Add a second y-axis
    yyaxis right;

    for i = 1:(totalRecordings-1)
        RS_data{i} = RS_data{i} / 1e6;
    end
    
    % Plot RS_data_accumulated on the second y-axis
    for i = 1:(totalRecordings-1)
        % Filter data based on conditions
        subset_X = X(Y == median(Y(X == i)));
        subset_RS_data = RS_data{i}(1:length(subset_X));  % Ensure lengths match
    
        % Check if there are valid data points before plotting
        if ~isempty(subset_X)
            plot(subset_X, subset_RS_data, 'r-o');
        else
            disp(['No valid data for recording ' num2str(i)]);
        end
    end

%     % Plot RS_data_accumulated on the second y-axis
%     for i = 1:(totalRecordings-1)
%         % Check if there are valid indices before plotting
%         validIndices = Y == median(Y(X == i));
%         if any(validIndices)
%             plot(X(validIndices), RS_data{i}, 'r-o');
%         else
%             disp(['No valid data for recording ' num2str(i)]);
%         end
%     end
% 
% % 
%     % Plot RS_data_accumulated on the second y-axis
%     for i = 1:(totalRecordings-1)
%         plot(X(Y == median(Y(X == i))), RS_data{i}, 'r-o'); % Example, adjust based on your data
%     end

    ylabel('Series Resistance in MOhm');

    title(['Resting membrane median of every sweep per trial plus series resistance per trail of cell ', num2str(k)]);
    
    % Optional: Add grid for better readability
    grid on;

    % Add 'Proceed' button
    uicontrol('Style', 'pushbutton', 'String', 'Proceed', ...
              'Position', [100, 20, 100, 40], 'Callback', @proceedCallback);

    % Add 'Discard Cell' button
    uicontrol('Style', 'pushbutton', 'String', 'Discard Cell', ...
              'Position', [250, 20, 100, 40], 'Callback', @discardCallback);

    % Generate the filename with the plot number
    filename = sprintf('Output/rm_all_sweeps_per_cell%d.png', k);

    % Save the plot with the generated filename
    saveas(gcf, filename);

    % Wait for a button press before continuing
    waitfor(gcf);
    
    hold off;

    if skipCellFlag
        disp('Processing stopped due to skip flag.');
        return;  % Exit the function early
    end
    
    for i = 1:totalRecordings
        
        sweepsData = RecTable{i, 'dataRaw'}{1, 1}{1, 1};
        stimulusData = RecTable{i, 'stimWave'}{1, 1}.DA_3;
        numSweeps = RecTable{i, 6};
        startSweep = 1;
        endSweep = numSweeps;
        sampleRate = RecTable{i, 'SR'}; 
        
        if ~strcmp(RecTable{i, 10}, ident_gf)
            
            timebase_data{k}{i} = (0:(length(sweepsData(:, 1)) - 1)) / sampleRate;    

            hFig = figure('Position', [screenSize(1), screenSize(2), screenSize(3), screenSize(4)]);
            drawnow; 
            jFig = get(handle(hFig), 'JavaFrame');
            jFig.setMaximized(true);

            ax(i) = subplot(3,1,[1 2]);
            plotHandle1 = gca;
            hold on;
            
            lineThickness = 1;
            
            plotHandles = cell(1, endSweep - startSweep + 1);
            
            toggleBtnHandles = cell(1, endSweep - startSweep + 1);
            
            % Plot sweeps and create buttons to toggle visibility
            for sweepIdx = startSweep:endSweep
                plotHandles{sweepIdx} = plot(timebase_data{k}{1, i}, sweepsData(:, sweepIdx), 'LineWidth', lineThickness);
                buttonLabel = sprintf('%d', sweepIdx); 
                toggleBtnHandles{sweepIdx} = uicontrol('Style', 'pushbutton', 'String', buttonLabel, ...
                   'Position', [40*(sweepIdx-startSweep+1) 20 40 40], 'Callback', {@toggleSweepVisibility, sweepIdx, plotHandles});

                buttonColor = get(plotHandles{sweepIdx}, 'Color');
                set(toggleBtnHandles{sweepIdx}, 'BackgroundColor', buttonColor);
            end
            
            % Label the X and Y axes, and provide a title for the stimulus subplot
            xlabel('Time in s');
            ylabel('Voltage in V');
            title(['All Sweeps of Trail ', num2str(i)]);
            
            % Store your data in the figure's application data
            setappdata(jFig, 'accepted_trials', accepted_trials);
            setappdata(jFig, 'accepted_sweeps', accepted_sweeps);


            % Create a 'Use' button with titleTextrec as an argument
            useBtn = uicontrol('Style', 'pushbutton', 'String', 'Use!', ...
                'Position', [1200 20 100 40], 'Callback', {@handleFeedback, 'y', k, i, jFig, plotHandles, endSweep});

            % Create a 'Don't use' button with titleTextrec as an argument
            dontUseBtn = uicontrol('Style', 'pushbutton', 'String', 'Don''t use!', ...
                'Position', [1400 20 100 40], 'Callback', {@handleFeedback, 'n', k, i, jFig, plotHandles, endSweep});
            

            % Coordinates and size of the annotation box
            leftPosition = 0.92;  % Horizontal position (left side of the figure)
            bottomPosition = 0.5;  % Vertical position (middle of the figure)
            boxWidth = 0.1;  % Width of the annotation box
            boxHeight = 0.3;  % Height of the annotation box

            % Coordinates for the text annotation
            xPosition = leftPosition-0.025;  % Use the same horizontal position as the checkboxes
            yPosition = bottomPosition + boxHeight;  % Slightly above the top of the checkbox area
            
            % Combine the Reference Value and Interval information in one annotation
            annotationText = sprintf('Reference: %.3f V\nInterval: ± 0.005 V', referenceRM);

            % Create the annotation with combined information
            annotation(hFig, 'textbox', [xPosition, yPosition, boxWidth, 0.1], ...  % Note: You might need to adjust the height
                       'String', annotationText, ...
                       'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
                       'FontSize', 10, 'FontWeight', 'bold');
            
            % Create a string array for the annotation
            annotationStr = '';
            for sweepIdx = startSweep:endSweep
                try
                    % Calculate the average of the relevant data points for this sweep
                    sweepAverage = mean(sweepsData(500:4500, sweepIdx));
                catch ex
                    % If an error occurs, display a warning and continue with the next iteration
                    warning('Error calculating sweepAverage for sweep %d: %s', sweepIdx, ex.message);
                    continue;
                end
                
                % Check if the sweep meets the criteria
                try
                    if abs(sweepAverage - referenceRM) <= 0.005
                        checkboxColor = '0,1,0'; % Green for criteria met
                    else
                        checkboxColor = '1,0,0'; % Red for criteria not met
                    end
                catch ex
                    % If an error occurs, display a warning and continue with the next iteration
                    warning('Error checking criteria for sweep %d: %s', sweepIdx, ex.message);
                    continue;
                end
                
                % Get the color of the sweep
                try
                    color = get(plotHandles{sweepIdx}, 'Color');
                catch ex
                    % If an error occurs, display a warning and continue with the next iteration
                    warning('Error getting color for sweep %d: %s', sweepIdx, ex.message);
                    continue;
                end
                
                % Append the sweep number with a colored symbol to the string
                annotationStr = [annotationStr, ...
                                 sprintf('\\color[rgb]{%s}# ', checkboxColor), ... % Colored asterisk symbol
                                 sprintf('\\color[rgb]{%f,%f,%f}%d\n', color, sweepIdx)];
            end


            % Create the annotation box
            annotation('textbox', [leftPosition, bottomPosition, boxWidth, boxHeight], ...
           'String', annotationStr, ...
           'EdgeColor', 'none', ...
           'HorizontalAlignment', 'left', ...
           'FontSize', 16); % Set the font size to twice the default (10 * 2 = 20 points)

            hold off;
             
            % Create a subplot for the stimulus protocol
            ax(i) = subplot(3,1,3); 
            plotHandle2 = gca;
            hold on;
            
            lineThickness = 5;
            
            % Initialize cell array to store plot handles
            plotHandles = cell(1, endSweep - startSweep + 1);
            try
                for sweepIdx = startSweep:endSweep
                    % Plot the data and store the plot handle
                    plotHandles{i} = plot(plotHandle2, timebase_data{k}{1, i}, stimulusData(:, sweepIdx), 'LineWidth', lineThickness);
                end
            end

            % Assume plotHandle2 is your axes handle
            plotHandle2.YLim = [-0.15, 0.35];

            % Define even YTicks within the range set by YLim
            % Here we calculate the start and end points, ensuring they are even numbers
            startYTick = ceil(plotHandle2.YLim(1)/0.05)*0.05; % round up to the nearest even multiple of 0.02
            endYTick = floor(plotHandle2.YLim(2)/0.05)*0.05; % round down to the nearest even multiple of 0.02

            % Generate a range of even YTicks
            evenYTicks = startYTick:0.05:endYTick; % adjust the step size if necessary

            % Set the custom even YTicks
            plotHandle2.YTick = evenYTicks;

            % Update the YTickLabels to reflect the new YTicks multiplied by 1000
            % Convert the ticks to strings and update YTickLabel
            plotHandle2.YTickLabel = arrayfun(@(x) num2str(x*1000), evenYTicks, 'UniformOutput', false);

            % Label the X and Y axes, and provide a title for the stimulus subplot
            xlabel('Time in s');
            ylabel('A');
            title('Stimulus Protocol');
            hold off;
            
            % Block script execution until one of the buttons is pressed
            uiwait(gcf);

            % After the buttons are clicked and handleFeedback is called, you can retrieve the updated tables as follows:
            accepted_trials = getappdata(jFig, 'accepted_trials');
            accepted_sweeps = getappdata(jFig, 'accepted_sweeps');  
 
            stim_onset{k}{1, i} = (find(stimulusData(:, 1) < -0.05, 1)-1);
%         else
%             VMON_fig = ['gap-free_cell' num2str(k)];
%             VMON_new = figure('Position', [screenSize(1), screenSize(2), screenSize(3), screenSize(4)]);
%             
%             % Sets the Thickness of Traces in VMON-Plot
%             lineThickness = 0.1;
%             
%             eval(['gap-free_cell' num2str(k) ' = [];']);
% 
%             totalDataPoints = 0;
% 
%             % Check and ensure consistent sweep lengths before concatenating
%             sweepLength = length(sweepsData(:, startSweep));
%             for sweepIdx = startSweep:endSweep
%                 currentSweep = sweepsData(:, sweepIdx);
%                 if length(currentSweep) ~= sweepLength
%                     error('Sweep lengths are not consistent.');
%                 end
%                 % Assign the current sweep to the dynamically named variable
%                 eval(['gap-free' num2str(k) ' = [gap-free' num2str(k) '; currentSweep];']);
%                 totalDataPoints = totalDataPoints + length(currentSweep);
%             end
%             
%             timebase_data{k}{i} =  (0:(totalDataPoints-1)) / sampleRate;
%             
%             eval(['VMON_1000 = gap-free' num2str(k) ' * 1000;']);
%             
%             % Plot all sweeps continuously without gaps
%             plotHandle2 = gca;
%             % Retrieve the dynamically named variable and does the plot
%             plot(plotHandle2, timebase_data{k}{1, i}, VMON_1000, 'LineWidth', lineThickness);
% 
%             % Label the X and Y axes, and provide a title for the stimulus subplot
%             xlabel('Time in s');
%             ylabel('mV');
%             title('Gap-Free Protocol');
% 
%             filename = sprintf('Output/gap-free_cell%d.png', k);
%             
% %             % Check if the file already exists in the current folder
% %             if ~exist([VMON_fig '.png'], 'file')
% %                 % Save the figure as a PNG file in the current folder
% %                 saveas(VMON_new, [VMON_fig '.png']);
% %                 disp(['Figure ' VMON_fig ' saved as a PNG file.']);
% %             else
% %                 disp(['Figure ' VMON_fig ' already exists as a PNG file in the current folder.']);
% %             end
        end            
    end
end
