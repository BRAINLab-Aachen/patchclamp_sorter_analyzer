function proceedCallback(~, ~)
    global skipCellFlag;
    skipCellFlag = false;  % Do not skip the cell
    
    close(gcf);  % Close the figure
end