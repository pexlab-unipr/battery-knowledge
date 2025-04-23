function data = merge_battery_data(filenames)
    %
    N_tests = numel(filenames);
    data = cell(1, N_tests); % tests organized column-wise
    for ii = 1:N_tests
        data{ii} = importfile(filenames(ii));
    end
end
