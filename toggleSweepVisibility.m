function toggleSweepVisibility(~, ~, sweepIdx, plotHandles)

    sweepPlotHandle = plotHandles{sweepIdx};
    
    if ~strcmp(sweepPlotHandle.Visible, 'on')
        sweepPlotHandle.Visible = 'on'; 
    else
        sweepPlotHandle.Visible = 'off'; 
    end
end