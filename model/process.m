% Process battery data, cleverly!

%% Cleaning
clear
clc
close all

%% PARAMETER
filenames = [...
    "data_discharge_0C5.csv", ...
    "data_discharge_1C.csv", ...
    "data_discharge_3C.csv", ...
    "data_discharge_5C.csv", ...
    "data_discharge_10C.csv"];
Itest_C = [0.5, 1, 3, 5, 10];
Qn_Ah = 1.1;

%% Processing
Qn = Qn_Ah * 3600;
Nds = numel(filenames);
data = cell(1, Nds);
meta = table('Size', [Nds, 8], ...
    'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', }, ...
    'VariableNames', {'I', 'Qt', 'Tdis', 'V0', 'beta', 'R12', 'sigma_L', 'R12_pair'});
for ii = 1:Nds
    data{ii} = importfile(filenames(ii));
    data{ii}.q = data{ii}.q/1e3; % exceptionally in [Ah]
    meta.I(ii) = Itest_C(ii) * Qn_Ah;
    meta.Qt(ii) = max(data{ii}.q);
    data{ii}.t = data{ii}.q*3600/meta.I(ii);
    meta.Tdis(ii) = max(data{ii}.t);
    data{ii}.qn = data{ii}.q/meta.Qt(ii);
    [bfit, gof] = fitbat(data{ii}.qn, data{ii}.v);
    meta.V0(ii) = bfit.V0;
    meta.beta(ii) = bfit.beta;
    meta.R12(ii) = bfit.A/meta.I(ii);
    meta.sigma_L(ii) = 1 - bfit.B;
    % Alternate way to compute R12
    flt1 = (data{1}.qn >= 0.2) & (data{1}.qn <= 0.8);
    fltx = (data{ii}.qn >= 0.2) & (data{ii}.qn <= 0.8);
    v1 = data{1}.v(flt1);
    vx = data{ii}.v(fltx);
    qn_eq = linspace(0.2, 0.8, 101);
    v1 = interp1(data{1}.qn(flt1), v1, qn_eq, 'linear', 'extrap');
    vx = interp1(data{ii}.qn(fltx), vx, qn_eq, 'linear', 'extrap');
    meta.R12_pair(ii) = mean((v1 - vx)/(meta.I(ii) - meta.I(1)));
end

meta

%% Plot
figure
hold on
for ii = 1:Nds
    plot(data{ii}.q, data{ii}.v)
end
xlabel('Charge (Ah)')
ylabel('Voltage (V)')
box on
grid on

figure
hold on
for ii = 1:Nds
    plot(data{ii}.t, data{ii}.v)
end
xlabel('Time (s)')
ylabel('Voltage (V)')
box on
grid on

figure
hold on
for ii = 1:Nds
    plot(data{ii}.qn, data{ii}.v)
end
xlabel('Normalized charge (1)')
ylabel('Voltage (V)')
box on
grid on

figure
hold on
plot(meta.I, meta.R12, '.-b')
plot(meta.I, meta.R12_pair, '.-r')
