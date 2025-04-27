% Process battery data, cleverly!

%% Cleaning
clear
clc
close all

%% Parameters

% Battery
V_L = 2.0; % minimum cell voltage, must be known from datasheet or chemistry
Qn_Ah = 1.1; % [Ah] cell nominal capacity, from datasheet
Data_folder = "../data/HTPFR18650-1100mAh-3.2V_datasheet";

% Standard format of battery data
%   CSV with 3 fields: time, voltage, current
%   Column separator: ";"
%   Decimal separator: "."
%   "time" in seconds or timestamp
%   "voltage" and "current" in SI units

%% Processing

% Load CSV files in a given folder
filenames = get_filenames(Data_folder, ".csv");

% Preprocess CSV files in a single dataset (MAT file)
data = merge_battery_data(filenames);
[data, meta] = preprocess_battery_data(data, Qn_Ah, V_L);
[qbat_pu, ibat, vbat] = model_from_battery_data(data, meta);

figure
surf(qbat_pu, ibat, vbat)
xlabel('Normalized charge (1)')
ylabel('Current (A)')
zlabel('Voltage (V)')

qq = qbat_pu(:,1);
iq = linspace(0, max(meta.I_ave), 21);
vq = interp2(qbat_pu.', ibat.', vbat.', qq.', iq.', 'makima');

figure
plot(qq, vq)


figure
plot(iq, vq(:,))
%
par.V_oc0 = 3.65;
par.V_ocL = 2;
par.V_ocx = 3.55;
par.sigma_ocx = 0.5;
par.Rs = 50e-3;
par.Qn_Ah = 1.1;
ideal_battery_data(par)

%%
figure
subplot(1,3,1)
hold on
for ii = 1:numel(data)
    plot(data{ii}.time, data{ii}.vbat)
end
xlabel('Time (s)')
ylabel('Battery voltage (V)')
box on
grid on
subplot(1,3,2)
hold on
for ii = 1:numel(data)
    plot(data{ii}.time, data{ii}.ibat)
end
xlabel('Time (s)')
ylabel('Battery current (A)')
box on
grid on
subplot(1,3,3)
hold on
for ii = 1:numel(data)
    plot(data{ii}.time, data{ii}.qbat_Ah)
end
xlabel('Time (s)')
ylabel('Battery charge (Ah)')
box on
grid on

figure
hold on
for ii = 1:numel(data)
    plot(data{ii}.qbat_Ah, data{ii}.vbat)
end
xlabel('Battery charge (Ah)')
ylabel('Battery voltage (V)')
box on
grid on

figure
hold on
plot(meta.I_ave, meta.Q_end_Ah, 'x-')
xlabel('Battery current (A)')
ylabel('Battery charge (Ah)')
box on
grid on

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
