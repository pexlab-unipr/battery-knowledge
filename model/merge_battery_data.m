function data = merge_battery_data(filenames)
    %
    N_tests = numel(filenames);
    data = cell(N_tests, 1); % tests organized in a column, to match metadata
    for ii = 1:N_tests
        data{ii} = importfile(filenames(ii));
    end
end
