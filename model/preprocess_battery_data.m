function data = preprocess_battery_data(data)
    %
    N_tests = numel(data);
    for ii = 1:N_tests
        data{ii}.time = data{ii}.time - data{ii}.time(1);
        qbat_Ah = cumtrapz(data{ii}.time, data{ii}.ibat)/3600;
        data{ii} = addvars(data{ii}, qbat_Ah, 'NewVariableNames', "qbat_Ah");
    end
end
