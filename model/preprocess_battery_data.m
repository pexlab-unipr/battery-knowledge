function [data, meta] = preprocess_battery_data(data, Qn_Ah, V_L)
    % Preprocess raw battery data to adapt to different acquisition
    % procedures, hardware and configurations, while removing experimental
    % non-idealities.

    % V_max      : [V]  maximum voltage measured
    % V_min      : [V]  minimum voltage measured
    % I_ave      : [A]  average current after recognition of timespan of the 
    %                   test
    % C_rate     : [1]  C-rate of the test (may be non-constant)
    % Q_end_Ah   : [Ah] charge at cut-off voltage (possibly extrapolated)
    % Q_pu_max   : [1]  maximum normalized charge (charge/Qn_Ah), can be 
    %                   greater than unity
    % T_start    : [s]  time of start of test (absolute), becomes zero of
    %                   test time
    % T_end      : [s]  time to reach cut-off voltage (relative to T_start)
    % T_last     : [s]  time of last data point (relative to T_start)
    % T_test     : [s]  first time recorded (absolute)
    % N_s        : [1]  number of samples after cleaning
  
    N_tests = numel(data);
    var_names = [...
        "V_max", "V_min", "I_ave", "C_rate", "Q_end_Ah", "SOC_raw_max", ...
        "T_start", "T_end", "T_last", "T_test", "N_s", ...
        "is_i_const", "is_t_unique", "is_extended"];
    var_types = [...
        "double", "double", "double", "double", "double", "double", ...
        "double", "double", "double", "double", "double", ...
        "logical", "logical", "logical"];
    meta = table( ...
        'Size', [N_tests, numel(var_names)], ...
        'VariableTypes', var_types, ...
        'VariableNames', var_names);
    % General cleaning of the traces
    for ii = 1:N_tests
        
        % Search for start time (1st time with nonzero current
        meta.T_test(ii) = data{ii}.time(1);
        meta.T_start(ii) = data{ii}.time(find(data{ii}.ibat, 1, 'first'));
        
        % Start from time zero
        data{ii}.time = data{ii}.time - meta.T_start(ii);
        
        % Cleaning of time vector
        % TODO: remove points with final zero current?
        idx_time_positive = data{ii}.time >= 0; % remove negative times
        [~, ~, idx_time_unique] = unique(data{ii}.time); % remove duplicates
        idx_time_unique = [true; diff(idx_time_unique) > 0];
        idx_time_increase = [true; diff(data{ii}.time) > 0]; % remove negative time increase
        idx_time_ok = idx_time_positive & idx_time_unique & idx_time_increase;
        meta.is_t_unique(ii) = any(~idx_time_ok);
        meta.V_max(ii) = max(data{ii}.vbat); % compute before removal
        meta.V_min(ii) = min(data{ii}.vbat);
        data{ii} = data{ii}(idx_time_ok,:);
        meta.T_last(ii) = data{ii}.time(end); % compute after removal
        meta.I_ave(ii) = mean(data{ii}.ibat);
        meta.C_rate(ii) = meta.I_ave(ii)/Qn_Ah;
        meta.is_i_const(ii) = std(data{ii}.ibat) < meta.I_ave(ii)/1000;
        
        % Look for cut-off voltage using linear regression on the last 4
        % points available in voltage
        flt = find(data{ii}.vbat > V_L, 4, 'last');
        mq = polyfit(data{ii}.time(flt), data{ii}.vbat(flt), 1);
        meta.T_end(ii) = (V_L - mq(2))/mq(1);
        meta.is_extended(ii) = meta.T_end(ii) > meta.T_last(ii);
        % Add extrapolated point, if missing
        if meta.is_extended(ii) % add extrapolated point
            data{ii} = [data{ii}; {meta.T_end(ii), V_L, meta.I_ave(ii)}];
        end
        meta.N_s(ii) = height(data{ii});
        
        % Compute charge by current integration
        qbat_Ah = cumtrapz(data{ii}.time, data{ii}.ibat)/3600;
        qbat_pu = qbat_Ah/Qn_Ah;
        data{ii} = addvars(data{ii}, qbat_Ah, qbat_pu, ...
            'NewVariableNames', ["qbat_Ah", "qbat_pu"]);
        meta.Q_end_Ah(ii) = trapz(data{ii}.time, data{ii}.ibat)/3600;
        meta.Q_pu_max(ii) = max(data{ii}.qbat_pu);
        % 
    end
    % Order data by ascending C-rate, just for convenience
    [meta, sorted_indeces] = sortrows(meta, "C_rate", "ascend");
    data = data(sorted_indeces);
    
end
