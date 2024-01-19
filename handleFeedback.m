function [accepted_trials, accepted_sweeps] = handleFeedback(~, ~, feedback, k, i, jFig, plotHandles, endSweep)
    accepted_trials = getappdata(jFig, 'accepted_trials');
    accepted_sweeps = getappdata(jFig, 'accepted_sweeps');

    if strcmpi(feedback, 'y')
        % Get the existing table from the cell
        existingTable = accepted_trials{k};
        
        % Append i as a new row to the existing table
        newRow = {i};
        existingTable = [existingTable; newRow];
        
        % Assign the updated table back to the cell
        accepted_trials{k} = existingTable;
    end

    for s = 1:endSweep
        visibilityStatus = get(plotHandles{s}, 'Visible');
        if strcmp(visibilityStatus, 'on')
            accepted_sweeps{k}{s, i} = true;
        elseif strcmp(visibilityStatus, 'off')
            accepted_sweeps{k}{s, i} = false;
        end
    end
    setappdata(jFig, 'accepted_trials', accepted_trials);
    setappdata(jFig, 'accepted_sweeps', accepted_sweeps);

    close(gcf); % Close the figure
    uiresume(gcf); % Resume script execution
end