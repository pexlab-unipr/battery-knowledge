function [data, meta] = preprocess_battery_data(data, Qn_Ah, V_L)
    %
    N_tests = numel(data);
    var_names = [...
        "V_max", "V_min", "I_ave", "C_rate", "Q_end_Ah", "T_end", ...
        "N_s", "is_i_const", "is_t_unique", "is_extended"];
    var_types = [...
        "double", "double", "double", "double", "double", "double", ...
        "double", "logical", "logical", "logical"];
    meta = table( ...
        'Size', [N_tests, numel(var_names)], ...
        'VariableTypes', var_types, ...
        'VariableNames', var_names);
    % General cleaning of the traces
    for ii = 1:N_tests
        % Start from time zero
        % TODO: if current is not constant, search for start time
        data{ii}.time = data{ii}.time - data{ii}.time(1);
        qbat_Ah = cumtrapz(data{ii}.time, data{ii}.ibat)/3600;
        data{ii} = addvars(data{ii}, qbat_Ah, 'NewVariableNames', "qbat_Ah");
        % Compute metadata
        meta.V_max(ii) = max(data{ii}.vbat);
        meta.V_min(ii) = min(data{ii}.vbat);
        meta.I_ave(ii) = mean(data{ii}.ibat);
        meta.C_rate(ii) = meta.I_ave(ii)/Qn_Ah;
        meta.Q_end_Ah(ii) = trapz(data{ii}.time, data{ii}.ibat)/3600;
        meta.T_end(ii) = data{ii}.time(end);
        meta.N_s(ii) = height(data{ii});
        meta.is_i_const(ii) = std(data{ii}.ibat) < meta.I_ave(ii)/1000;
        meta.is_t_unique(ii) = numel(data{ii}.time) == numel(unique(data{ii}.time));
    end
    % Order data by ascending C-rate, just for convenience
    [meta, sorted_indeces] = sortrows(meta, "C_rate", "ascend");
    data = data(sorted_indeces);
    for ii = 1:N_tests
        % Remove duplicates and points rolling back in time
        % [~, unique_indeces, ~] = unique(data{ii}.time);
        unique_indeces = [true; diff(data{ii}.time) > 0];
        data{ii} = data{ii}(unique_indeces,:);
        % Look for cut-off voltage
        flt = data{ii}.vbat < (meta.V_max(ii) + meta.V_min(ii))/2;
        fun = @(t) interp1(data{ii}.time(flt), data{ii}.vbat(flt), t, ...
            'linear', 'extrap') - V_L;
        meta.T_end(ii) = fzero(fun, meta.T_end(ii));
        meta.is_extended(ii) = meta.T_end(ii) > data{ii}.time(end);
        % Resample to get same point density in time on all traces
        ts = (0:ceil(meta.T_end(ii))).';
        data{ii} = array2table([ts, ...
            interp1(data{ii}.time, data{ii}{:, 2:end}, ts, 'linear', 'extrap')], ...
            'VariableNames', data{ii}.Properties.VariableNames);
    end
end
