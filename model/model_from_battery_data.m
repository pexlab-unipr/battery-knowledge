function [qbat_pu, ibat, vbat] = model_from_battery_data(data, meta)
    % Model battery
    % Assuming each test is done at constant current

    % Resample all traces to have gridded points on raw SOC
    Q_pu_supermax = max(meta.Q_pu_max);
    N_s_max = max(meta.N_s);
    q_pu = linspace(0, Q_pu_supermax, N_s_max).';
    N_tests = numel(data);
    data_mats = zeros(N_s_max, 3, N_tests);
    for ii = 1:N_tests
        data_mats(:,1,ii) = q_pu;
        data_mats(:,2,ii) = meta.I_ave(ii)*ones(size(q_pu));
        flt = true(size(data{ii}.qbat_pu)); % data{ii}.qbat_pu > 0.2;
        data_mats(:,3,ii) = interp1(data{ii}.qbat_pu(flt), data{ii}.vbat(flt), q_pu, 'linear', 'extrap');
    end
    qbat_pu = squeeze(data_mats(:, 1, :));
    ibat = squeeze(data_mats(:, 2, :));
    vbat = squeeze(data_mats(:, 3, :));
    Rs = zeros(size(qbat_pu, 1), 1);
    for ii = 1:numel(Rs)
        p = polyfit(ibat(ii,:), vbat(ii,:), 1);
        Rs(ii) = -p(1);
    end
    flt = qbat_pu(:,1) > 0.2 & qbat_pu(:,1) < 0.8;
    p = polyfit(qbat_pu(flt,1), Rs(flt), 2);

    %
    figure
    plot(qbat_pu(:,1), Rs, qbat_pu(:,1), polyval(p, qbat_pu(:,1)))

    figure
    surf(qbat_pu, ibat, vbat)
    xlabel('Normalized charge (1)')
    ylabel('Current (A)')
    zlabel('Voltage (V)')
    
    flt = qbat_pu(:,1) < 0.8;
    flt = flt & (mod((1:size(qbat_pu, 1)).', 20) == 0);
    figure
    plot(ibat(1,:), vbat(flt,:))


end
