function datasheet_to_battery_data(folder_in, folder_out)
    %
    filenames = get_filenames(folder_in, ".csv");
    % [status, msg, msgID] = mkdir(folder_out);
    for ii = 1:numel(filenames)
        asd = readtable(filenames(ii));
        [filepath, name, ext] = fileparts(filenames(ii));
        asd

    end
end
