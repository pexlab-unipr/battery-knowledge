function data = ideal_battery_data(par)
    %
    % Parameters
    V_oc0 = par.V_oc0; % [V] open circuit voltage (OCV) at fully charged battery
    V_ocL = par.V_ocL; % [V] OCV at fully discharged battery
    V_ocx = par.V_ocx; % [V] OCV at reference state of charge (SOH, sigma)
    sigma_ocx = par.sigma_ocx; % [1] reference SOH
    Rs = par.Rs;
    %
    A = [
        0, sigma_ocx, 1;
        1, 1, 1;
        -V_oc0, -V_ocx, -V_ocL].';
    b = -A(:,1).*A(:,3);
    p = A\b;
    p
    fun_voc = @(sigma, p) (p(1)*(1-sigma) + p(2))./((1-sigma) + p(3));
    ibat = [0.5, 1, 3, 5, 10];
    sigma = linspace(0, 1, 1001).';
    figure
    hold on
    plot(1 - sigma, fun_voc(sigma, p), '--k')
    for ii = 1:numel(ibat)
        voc = fun_voc(sigma, p);
        plot(1 - sigma, voc - Rs*ibat(ii) - Rs/20*ibat(ii)^2)
    end
    box on
    grid on
    ylim([V_ocL, V_oc0])
end
