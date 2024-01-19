function discardCallback(~, ~)
    global skipCellFlag;
    skipCellFlag = true;  % Skip the cell
    close(gcf);  % Close the figure
end