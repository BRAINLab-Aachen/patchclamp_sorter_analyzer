% Written by Morten Jakob, November 2023


%% ADD FUNCTIONS PATH SO THEY CAN BE STORED IN A FOLDER!!!


% Get the current folder's path
currentFolderPath = pwd;

% Specify the folder name
folderName = 'PC_Analysis_Functions';

% Concatenate the folder path
fullFolderPath = fullfile(currentFolderPath, folderName);

% Add the folder to the MATLAB path
addpath(fullFolderPath);

% Specify the folder name
folderName = 'Output';

% Concatenate the folder path
fullFolderPath = fullfile(currentFolderPath, folderName);

% Add the folder to the MATLAB path
addpath(fullFolderPath);

% Specify the folder name
folderName = 'DATA';

% Concatenate the folder path
fullFolderPath = fullfile(currentFolderPath, folderName);

% Add the folder to the MATLAB path
addpath(fullFolderPath);

%% IMPORTER SECTION!!!


all_data = readtable("Claas&Morten_PC_Human_acute.xlsx");
last_row = height(all_data);

% Imports data for each Neuron
for i = 1:last_row
    filepath = all_data(i, 11).DataFile{1};
    eval(['Cell' num2str(i) ' = HEKA_Importer(filepath);']);
end

% Check if variables are not initialized and then initialize them
if ~exist('accepted_trials', 'var') || ~exist('accepted_sweeps', 'var') || ...
   ~exist('rm_data', 'var') || ~exist('stim_onset', 'var') || ...
   ~exist('timebase_data', 'var')
   
   [accepted_trials, accepted_sweeps, rm_data, stim_onset, timebase_data, tryfit_output, apstuff_output, freq_adap_rheo, gap_free_output] = initialize_variables(last_row);

    assignin('base', 'accepted_trials', accepted_trials);
    assignin('base', 'accepted_sweeps', accepted_sweeps);
    assignin('base', 'rm_data', rm_data);
    assignin('base', 'stim_onset', stim_onset);
    assignin('base', 'timebase_data', timebase_data);
    assignin('base', 'tryfit_output', tryfit_output);
    assignin('base', 'apstuff_output', apstuff_output);
    assignin('base', 'freq_adap_rheo', freq_adap_rheo);
    assignin('base', 'gap_free_output', gap_free_output);
end

%% SORTER SECTION!!!


% Set the initial cell to start with
start_cell_number = 1;

% Identificator for the Gap-Free_Recordings (will change to Gap-Free)
ident_gf = 'VMON';

warning('off', 'all');

% Main processing loop
for k = start_cell_number:last_row

    variableName = ['Cell' num2str(k)];
    currentCell = eval(variableName);
    
    global skipCellFlag;
    skipCellFlag = false;

    [rm_data] = calculate_rm(currentCell, k, rm_data);
    assignin('base', 'rm_data', rm_data);

    [accepted_trials, accepted_sweeps, stim_onset, timebase_data] = select_trails_and_sweeps(currentCell, k, accepted_trials, accepted_sweeps, rm_data, stim_onset, timebase_data, ident_gf);
    assignin('base', 'accepted_trials', accepted_trials);
    assignin('base', 'accepted_sweeps', accepted_sweeps);
    assignin('base', 'stim_onset', stim_onset);
    assignin('base', 'timebase_data', timebase_data);    

    close all;
    clc;

    userDecision = input('Do you want to continue? (y/n): ', 's');
    if userDecision == 'n'
       % Stop possible after each cell!
       break;
    end
end

warning('on', 'all');

%% Gap-Free Section!!!

% Identificator for the Gap-Free_Recordings (will change to Gap-Free)
ident_gf = 'VMON';

% Set the initial cell to start with
start_cell_number = 1;

for k = start_cell_number:last_row

    variableName = ['Cell' num2str(k)];
    currentCell = eval(variableName);


    [gap_free_output] = get_gap_free(currentCell, k, ident_gf, gap_free_output);
    assignin('base', 'gap_free_output', gap_free_output);
end

%% ANALYSIS SECTION!!!

% Important for Rheobase-Plot!
step_increments = 50;

% Important for firing per second.500ms Stimulation lead to a factor of 2!
stim_factor = 2;

% Sets the interval of current steps with which the linear fit is
% performed!
lin_fit_start = 2;
lin_fit_end = 3;

% when lin_fit_end exeds array bounds, this value is the alternative!
% when this also exeds array bounds the standart is 6!
alt_value_lin_fit_end = 7;


% Treshold for peakdetection above the median betwenn (6000:14000)
initial_treshold = 0.02;


for k = start_cell_number:last_row

    % Get the number of rows
    numRows = size(accepted_sweeps{k}, 1);
    
    start_point = 50;
    a_values_pA = start_point:step_increments:(numRows-3)*step_increments;
    % display(a_values_pA)


    variableName = ['Cell' num2str(k)];
    currentCell = eval(variableName);
    
    [tryfit_output] = fit_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, tryfit_output);
    assignin('base', 'tryfit_output', tryfit_output);

    % tryfit_output contains:    
    % tryfit_output{k}{1} = tau;
    % tryfit_output{k}{2} = baseline;
    % tryfit_output{k}{3} = resistance;
    % tryfit_output{k}{4} = distance;
    % tryfit_output{k}{5} = sag;
    % tryfit_output{k}{6} = exp2_vars;    

    [apstuff_output] = ap_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, apstuff_output, initial_treshold);

    assignin('base', 'apstuff_output', apstuff_output);
    
    % apstuff_output contains:
    % apstuff_output{k}{1, step_index}{sweep_index-3} = threshold;
    % apstuff_output{k}{2, step_index}{sweep_index-3} = amp;
    % apstuff_output{k}{3, step_index}{sweep_index-3} = half_width;
    % apstuff_output{k}{4, step_index}{sweep_index-3} = rise_time;
    % apstuff_output{k}{5, step_index}{sweep_index-3} = ap_times;
    % apstuff_output{k}{a+5, 1} = avg_threshold;
    % apstuff_output{k}{a+5, 2} = avg_amp;
    % apstuff_output{k}{a+5, 1} = avg_half_width;
    % apstuff_output{k}{a+5, 2} = avg_rise_time;
    
     [freq_adap_rheo] = freq_adap_per_sweep_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, freq_adap_rheo, apstuff_output, step_increments, stim_factor);
     assignin('base', 'freq_adap_rheo', freq_adap_rheo);

     [freq_adap_rheo] = freq_adap_rheo_function(currentCell, k, accepted_trials, accepted_sweeps, stim_onset, timebase_data, freq_adap_rheo, apstuff_output, step_increments, stim_factor, lin_fit_start, lin_fit_end, a_values_pA, alt_value_lin_fit_end);
     assignin('base', 'freq_adap_rheo', freq_adap_rheo);

    % IMPORTANT!!! FIRING FREQUENCY & ADAPTATION-RATIO FIRST PER SWEEP THEN AVERAGE PER pA!!!  
    
    % freq_adap_rheo contains:
    % freq_adap_rheo{k}{1, c}{a} = apaptation_ratio_per_sweep;
    % freq_adap_rheo{k}{2, c}{a} = firing_per_sweep;
    % freq_adap_rheo{k}{a+2, 1} = apaptation_ratio_per_current_step;
    % freq_adap_rheo{k}{a+2, 2} = firing_per_current_step;
    % freq_adap_rheo{k}{3, 3} = rheobase_per_cell;

    % RHEOBASE: EXCLUDE DECRESING TRENDS AND TO FLAT CURVE AT LOW CURRENT STEPS!  
% 
%     userDecision = input('Do you want to continue? (y/n): ', 's');
%     if userDecision == 'n'
%        % Stop possible after each cell!
%        break;
%     end

close all;

end

%% EXCEL FILE GENERATION!!!

% Define the base filenames
baseFilenames = {'rheobase_Cell', 'ap_plot_Cell', 'tryfit_plot_Cell', 'rm_all_sweeps_per_cell', 'gap-free_cell'};

% Generate a unique Excel file name with date and time
dateTimeNow = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
excelFileName = ['MyExcelFile_' dateTimeNow '.xlsx'];

% Create a new Excel file with a unique name
xlswrite(excelFileName, {'Image'}, 'Sheet1'); % This creates the file with an initial sheet

% Start an ActiveX server to interact with Excel
Excel = actxserver('Excel.Application');
Workbook = Excel.Workbooks.Open(fullfile(pwd, excelFileName));
Sheets = Excel.ActiveWorkbook.Sheets;

% Create a list of valid sheet names
validSheetNames = arrayfun(@(i) ['Cell' num2str(i)], 1:last_row, 'UniformOutput', false);

% Iterate over each sheet and delete those not in validSheetNames
for i = Sheets.Count:-1:1
    sheetName = Sheets.Item(i).Name;
    if ~ismember(sheetName, validSheetNames)
        Sheets.Item(i).Delete;
    end
end

% Add or use existing valid sheets and insert images
for i = 1:last_row
    % Check if the sheet already exists
    try
        newSheet = get(Sheets, 'Item', ['Cell' num2str(i)]);
        % Clear the contents of the existing sheet
        range = newSheet.UsedRange;
        range.ClearContents;
    catch
        % Sheet doesn't exist, add a new sheet
        newSheet = Sheets.Add([], Sheets.Item(Sheets.Count));
        newSheet.Name = ['Cell' num2str(i)];
    end
    
    % Get the number of columns
    numCols = size(accepted_sweeps{i}, 2);

    numRows = 0;
    idx_max_Row = 0;
    
    for j = 1:numCols
        currentLength = size(accepted_sweeps{i}(:, j), 1);
        
        if currentLength > numRows
            numRows = currentLength;
        end
    end


    current_labels = -100:step_increments:(numRows-3)*step_increments;

    current_header_exl = current_labels;
    
    % Write data to the sheet
    for row = 1:numRows
            % Address cells using 'H' followed by the row number
            cellAddress = ['H' num2str(row+1)];
            newSheet.Range(cellAddress).Value = current_header_exl(row);
    end
    
    cellAddress = 'I1';
    newSheet.Range(cellAddress).Value = 'Firing Frequency in Hz';
    
    for row = 1:numRows-3
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['I' num2str(row+4)];
            newSheet.Range(cellAddress).Value = freq_adap_rheo{i}{row+2, 2};
        end
    end

    cellAddress = 'J1';
    newSheet.Range(cellAddress).Value = 'Adaptation Ratio';

    for row = 1:numRows
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['J' num2str(row+4)];
            newSheet.Range(cellAddress).Value = freq_adap_rheo{i}{row+2, 1};
        end
    end
    
    cellAddress = 'K1';
    newSheet.Range(cellAddress).Value = 'threshold';

    for row = 1:numRows
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['K' num2str(row+4)];
            newSheet.Range(cellAddress).Value = apstuff_output{i}{row+5, 1};
        end
    end
    
    cellAddress = 'L1';
    newSheet.Range(cellAddress).Value = 'amp';

    for row = 1:numRows
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['L' num2str(row+4)];
            newSheet.Range(cellAddress).Value = apstuff_output{i}{row+5, 2};
        end
    end
    
    cellAddress = 'M1';
    newSheet.Range(cellAddress).Value = 'half_width';

    for row = 1:numRows
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['M' num2str(row+4)];
            newSheet.Range(cellAddress).Value = apstuff_output{i}{row+5, 1};
        end
    end
    
    cellAddress = 'N1';
    newSheet.Range(cellAddress).Value = 'rise_time';

    for row = 1:numRows
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['N' num2str(row+4)];
            newSheet.Range(cellAddress).Value = apstuff_output{i}{row+5, 2};
        end
    end
    
    cellAddress = 'O1';
    newSheet.Range(cellAddress).Value = 'tau';

    for row = 1
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['O' num2str(row+1)];
            newSheet.Range(cellAddress).Value = tryfit_output{i}{1};
        end
    end
    
    cellAddress = 'P1';
    newSheet.Range(cellAddress).Value = 'baseline';

    for row = 1
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['P' num2str(row+1)];
            newSheet.Range(cellAddress).Value = tryfit_output{i}{2};
        end
    end

    cellAddress = 'Q1';
    newSheet.Range(cellAddress).Value = 'resistance';

    for row = 1
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['Q' num2str(row+1)];
            newSheet.Range(cellAddress).Value = tryfit_output{i}{3};
        end
    end

    cellAddress = 'R1';
    newSheet.Range(cellAddress).Value = 'distance';

    for row = 1
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['R' num2str(row+1)];
            newSheet.Range(cellAddress).Value = tryfit_output{i}{4};
        end
    end

    cellAddress = 'S1';
    newSheet.Range(cellAddress).Value = 'sag';

    for row = 1
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['S' num2str(row+1)];
            newSheet.Range(cellAddress).Value = tryfit_output{i}{5};
        end
    end

    cellAddress = 'T1';
    newSheet.Range(cellAddress).Value = 'rheobase';

    try
        cellAddress = 'T2';
        newSheet.Range(cellAddress).Value = freq_adap_rheo{i}{3, 3};
    end


    count_per_row = countLogicalOnes(accepted_trials, accepted_sweeps, i, numRows);

    cellAddress = 'U1';
    newSheet.Range(cellAddress).Value = 'Number of selected sweeps';

    for row = 1:numRows
        try
            % Address cells using 'H' followed by the row number
            cellAddress = ['U' num2str(row+1)];
            newSheet.Range(cellAddress).Value = count_per_row(row, 1);
        end
    end

    for j = 1:length(baseFilenames)
        % Construct the image filename
        imageFilename = fullfile('Output', [baseFilenames{j} num2str(i) '.png']);

        % Check if the image file exists
        if exist(imageFilename, 'file')
            % Insert the image into the Excel sheet
            Left = 0;  % Left position

            if j < 4
                Top = (j - 1) * 320; % Top position for j < 4
            elseif j == 4
                Top = (j - 1) * 320; 
            else
                Top = (j - 1) * 420;
            end

            Shape = newSheet.Shapes.AddPicture(fullfile(pwd, imageFilename), 0, 1, Left, Top, -1, -1);
        end
    end

    newSheet.Columns.Item('I:Z').AutoFit;
end

% Save and close the workbook
Workbook.Save;
Workbook.Close;
Excel.Quit;
Excel.delete;

system('taskkill /F /IM EXCEL.EXE');

%% Delete Figure Output!!!

% Specify the folder name
folderName = 'Output';

% Concatenate the folder path
fullFolderPath = fullfile(currentFolderPath, folderName);

% Remove the contents of the folder
if exist(fullFolderPath, 'dir')
    % Remove all contents inside the folder
    delete(fullfile(fullFolderPath, '*'));

    % Display a message
    disp(['Contents of folder ' folderName ' have been deleted.']);
else
    % Display a warning if the folder doesn't exist
    warning(['Folder ' folderName ' does not exist.']);
end
