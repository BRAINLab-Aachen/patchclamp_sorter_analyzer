function [rm_data] = calculate_rm(currentCell, k, rm_data)

    RecTable = currentCell.RecTable;
    totalRecordings = size(RecTable, 1);
    screenSize = get(0, 'ScreenSize');
    
    for i = 1:(totalRecordings-1)
        
        sweepsData = RecTable{i, 'dataRaw'}{1, 1}{1, 1};
        stimulusData = RecTable{i, 'stimWave'}{1, 1}.DA_3;
        numSweeps = RecTable{i, 6};
        startSweep = 1;
        endSweep = numSweeps;
        samplingRate = RecTable{i, 'SR'}; 
        
        for s = 1:endSweep 
            % Ensure the index range is within the valid bounds
            validIndexRange = 500:min(4500, numel(sweepsData));
            
            % rm_data generation
            relevantData = sweepsData(validIndexRange, s);

            flattenedData = relevantData(:);

            rm_data{k}{s, i} = median(flattenedData);
        end
    end
end