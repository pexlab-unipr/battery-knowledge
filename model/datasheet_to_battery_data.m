function datasheet_to_battery_data(folder_in, folder_out, Qn_Ah)
    %
    filenames = get_filenames(folder_in, ".csv");
    [status, msg, msgID] = mkdir(folder_out);
    for ii = 1:numel(filenames)
        data = readmatrix(filenames(ii), "Delimiter", ";", "DecimalSeparator", ",");
        [filepath, name, ext] = fileparts(filenames(ii));
        tokens = regexp(name, "_([0-9]+)C([0-9]*)$", 'tokens');
        c_rate = str2double(tokens{1}(1) + "." + tokens{1}(2));
        q_bat = data(:,1)/1000*3600; % given in [mAh]
        v_bat = data(:,2);
        i_bat = c_rate * Qn_Ah * ones(size(v_bat, 1), 1);
        dt = diff(q_bat)./i_bat(1:end-1);
        dt = [dt; dt(end)];
        ts = cumsum(dt);
        data = [ts, v_bat, i_bat];
        writematrix(data, fullfile(folder_out, name + ext), "Delimiter", ";");
    end
end
