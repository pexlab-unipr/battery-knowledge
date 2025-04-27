function [qbat_pu, ibat, vbat, voc] = model_from_battery_data(data, meta)
    % Model battery
    % Assuming each test is done at constant current

    % Resample all traces to have gridded points on raw SOC
    Q_pu_supermax = max(meta.Q_pu_max);
    N_q = max(meta.N_s);
    N_i = numel(data);
    q_pu = linspace(0, Q_pu_supermax, N_q).';
    %
    init0 = zeros(N_q, N_i);
    qbat_pu = init0;
    ibat = init0;
    vbat = init0;
    vbat_dc = init0;
    vbat_dyn = init0;
    voc = zeros(N_q, 1);
    for ii = 1:N_i
        qbat_pu(:,ii) = q_pu;
        ibat(:,ii) = meta.I_ave(ii)*ones(size(q_pu));
        vbat(:,ii) = interp1(data{ii}.qbat_pu, data{ii}.vbat, q_pu, 'linear', 'extrap');
        % separate dynamic behavior
        vbat_dc(:,ii) = vbat(:,ii);
        flt_dyn = q_pu < 0.2;
        flt_dc = (q_pu < 0.5) & ~flt_dyn;
        p = polyfit(q_pu(flt_dc), vbat(flt_dc,ii), 1);
        vbat_dc(flt_dyn, ii) = polyval(p, q_pu(flt_dyn));
        vbat_dyn(:,ii) = vbat(:,ii) - vbat_dc(:,ii);
    end
    %
    for ii = 1:N_q
        fo = fit(ibat(ii,:).', vbat(ii,:).', 'power2');
        voc(ii) = fo.c;
    end
    %
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
    
    figure
    hold on
    plot(qbat_pu, vbat, '-')
    plot(qbat_pu, vbat_dc, '--')
    plot(qbat_pu(:,1), voc, 'k--')

%     figure
%     plot(qbat_pu, vbat_dyn)
end
