function data = ideal_battery_data(par)
    %
    
    % Parameters
    V_oc0 = par.V_oc0; % [V] open circuit voltage (OCV) at fully charged battery
    V_ocL = par.V_ocL; % [V] OCV at fully discharged battery
    V_ocx = par.V_ocx; % [V] OCV at reference state of charge (SOH, sigma)
    sigma_ocx = par.sigma_ocx; % [1] reference SOH
    Rs = par.Rs; % [ohm] series resistance
    Qn_Ah = par.Qn_Ah;
    
    % voc function fitting
    A = [
        0, sigma_ocx, 1;
        1, 1, 1;
        -V_oc0, -V_ocx, -V_ocL].';
    b = -A(:,1).*A(:,3);
    p = A\b;
    
    % Evaluation of models
    fun_voc = @(sigma, p) (p(1)*(1-sigma) + p(2))./((1-sigma) + p(3));
    ibat = [0.5, 1, 3, 5, 10].';
    sigma = linspace(0, 1, 1001).';
    voc = fun_voc(sigma, p);
    Q_Ah = zeros(size(ibat));
    for ii = 1:numel(ibat)
        Q_Ah(ii) = Qn_Ah * (1 - fzero(@(x) fun_voc(x, p) - Rs*ibat(ii) - V_ocL, 0));
    end
    
    % Visualization
    figure
    hold on
    plot(1 - sigma, voc, '--k')
    for ii = 1:numel(ibat)
        plot(1 - sigma, voc - Rs*ibat(ii))
    end
    box on
    grid on
    ylim([V_ocL, V_oc0])
    %
    figure
    plot(ibat, Q_Ah, 'x-')
end
