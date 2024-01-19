function [accepted_trials, accepted_sweeps, rm_data, stim_onset, timebase_data, tryfit_output, apstuff_output, freq_adap_rheo, gap_free_output] = initialize_variables(last_row)

    accepted_trials = cell(1, last_row); 
    for k = 1:last_row
        accepted_trials{k} = cell(0, 0);
    end
    
    accepted_sweeps = cell(1, last_row);
    for k = 1:last_row
        accepted_sweeps{k} = cell(0, 0);
    end
    
    rm_data = cell(1, last_row); 
    for k = 1:last_row
        rm_data{k} = cell(0, 0); 
    end
    
    stim_onset = cell(1, last_row); 
    for k = 1:last_row
        stim_onset{k} = cell(0, 0);
    end
    
    timebase_data = cell(1, last_row); 
    for k = 1:last_row
        timebase_data{k} = cell(0, 0);
    end

    tryfit_output = cell(1, last_row); 
    for k = 1:last_row
        tryfit_output{k} = cell(0, 0);
    end

    apstuff_output = cell(1, last_row); 
    for k = 1:last_row
        apstuff_output{k} = cell(0, 0);
    end

    freq_adap_rheo = cell(1, last_row); 
    for k = 1:last_row
        freq_adap_rheo{k} = cell(0, 0);
    end
    gap_free_output = cell(1, last_row); 
    for k = 1:last_row
        gap_free_output{k} = cell(0, 0);
    end
end