function [threshold, amp, half_width, rise_time] = ap_stuff(timeseries, timebaseDaten, ap_times, stim_onset, do_plot, cell_index, ap_indices)

% takes single trial data (timeseries) and corresponding
% timepoints(timebaseDaten) as well as the timepoints of stimulation onset 
% (stim_onset) and AP occurence (ap_times) and computes threshold(threshold)
% amplitude (amp), half width (half_width) and rise time (rise_time) of 
% first action potential in the response



% transform data (legacy)
recording = timeseries';
time = timebaseDaten';

ap_times_new = zeros(size(ap_times));
for spike = 1:numel(ap_times)
    ap_times_new(spike) = find(timebaseDaten == ap_times(spike));
end

ap_times = ap_times_new;

figure_handle_ap = gobjects(0);

% aproximate second derivate on smoothed timeseries

f = smooth(recording);  % data
Y = diff(f);            % first derivative
Z = diff(Y);            % second derivative
ZZ = diff(Z);           % third derivative

% find first inflection point by calculating first positive deviation from
% zero bigger then 2* std
% mean_Z = mean(Z);
% std_Z = std(Z);
% ind = find(Z > (mean_Z+1*std_Z));
% first_inflection_time = ind(ind < ap_times(1));
% first_inflection_time = first_inflection_time(stim_onset+50 < first_inflection_time);
% first_inflection_time = first_inflection_time(1);

% try to find inflection point by using the highest value in the second
% derivate before first action potential

% eval_period = ZZ(stim_onset:ap_times(1));
% ind = find(max(eval_period) == eval_period)+ stim_onset;
% first_inflection_time = ind-1; % argument that we want to see the point before the rise of the acceleration


% try to find inflection point by computing the first rise of slop above
% 2*std


mean_fd = mean(Y);
std_fd = std(Y);
try
    % Get offset at the beginning to avoid detecting the first upstroke artefact
    detect_offset = 50;
    
    % Check if ap_times has at least one element
    if ~isempty(ap_times)
        eval_period = (stim_onset + detect_offset):ap_times(1);
        ind_der = Y(eval_period) > mean_fd + 2 * std_fd;
        first_ind = eval_period(ind_der);
        
        % Check if first_ind is not empty
        if ~isempty(first_ind)
            first_inflection_time = first_ind(1);
        else
            first_inflection_time = ap_times(1) - 30; % Use a default value if no suitable index is found
        end
    else
        % Handle the case where ap_times is empty
        first_inflection_time = NaN; % Or use any other appropriate handling
    end
catch
    % Handle any other exceptions that might occur
    first_inflection_time = NaN; % Or use any other appropriate handling
end


% Check if first_inflection_time is a valid index
if isnumeric(first_inflection_time) && isscalar(first_inflection_time) && first_inflection_time >= 1 && first_inflection_time <= numel(recording)
    % first_inflection_time is a valid index, proceed with threshold calculation
    threshold = recording(first_inflection_time);
else
    % Handle the case where first_inflection_time is not a valid index
%     fprintf('Invalid first_inflection_time: %s\n', num2str(first_inflection_time));
    % You can set a default value for threshold or handle this case as needed
    threshold = NaN; % Or any other appropriate handling
end

% mean_fd = mean(Y);
% std_fd = std(Y);
% try
%     % get offset at beginning to avoid detecting the first upstroke artefact
%     detect_offset = 50;
%     eval_period = (stim_onset+detect_offset):ap_times(1);
%     ind_der = Y(eval_period) > mean_fd + 2*std_fd;
%     first_ind = eval_period(ind_der);
%     first_inflection_time = first_ind(1);
% catch
%     % get different offset at the beginning in case of the AP being really
%     % early (old method retained for combatibility reasons)
%     detection_start = ap_times(1)-30;
%     eval_period = (detection_start):ap_times(1);
%     ind_der = Y(eval_period) > mean_fd + 2*std_fd;
%     first_ind = eval_period(ind_der);
%     first_inflection_time = first_ind(1);
% end
% compute ap descriptors
% calculate threshold and amplitude
threshold = recording(first_inflection_time);
amp = recording(ap_indices(1))-threshold;
% compute half width
% get max time to detect downstroke of AP to avoid detection in 2nd ap
lag = 50;
[c, hw_index] = min(abs(recording(1:ap_times(1))-(amp/2+threshold)));
[c, hw_index2] = min(abs(recording(ap_times(1):ap_times(1)+lag)-(amp/2+threshold)));
hw_index2 = hw_index2 + ap_times(1);
half_width = hw_index2 - hw_index;
% compute rise time 
rise_time = ap_times(1) - first_inflection_time;

% convert all time values to seconds
temp_size = size(timebaseDaten);
time_step = timebaseDaten(end)/double(temp_size(2));

rise_time = rise_time*time_step;
half_width = half_width*time_step;

persistent last_cell_index

% Check if plotting is required
if do_plot
        % Check if cell_index has changed (or if it's the first call)
        if isempty(last_cell_index) || last_cell_index ~= cell_index
            % Open a new figure window if cell_index changed
            figure; % Capture and store the figure handle
            % Update the persistent variable
            last_cell_index = cell_index;
        end
        
    % Plotting commands
    hold on;
    plot(recording, 'k');
    plot(hw_index, recording(hw_index), 'ok');
    plot(hw_index2, recording(hw_index2), 'ok');
    plot(first_inflection_time, recording(first_inflection_time), 'or');
    plot(ap_times(1), recording(ap_times(1)), 'or');

    % Set the title of the plot
    title(sprintf('All Currentinjection Answers of Cell: %d', cell_index));
end
% 
% % if plot is true
% if do_plot == true
%     hold on
%     plot(recording, 'k')
%     plot(hw_index, recording(hw_index), 'ok')
%     plot(hw_index2, recording(hw_index2), 'ok')
%     plot(first_inflection_time, recording(first_inflection_time), 'or')
%     plot(ap_times(1), recording(ap_times(1)), 'or')
% end


end
