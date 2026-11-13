%% Modélisation d'une pandémie zombie (modèle SZD, variante du modèle SIR)
% Auteur : Timothé Bardoux - IPSA, Bachelor 1, Introduction à MATLAB
% Résolution des systèmes d'équations différentielles avec ode45.

clear all; close all; clc;

%% Paramètres
N      = 100000;       % Population totale
Z0     = 100;          % Zombies initiaux
S0     = N - Z0;       % Personnes saines initiales
D0     = 0;            % Morts initiaux
R0_pop = 0;            % Personnes guéries initiales (cas 3)

tspan = [0 150];       % Durée : 150 jours

alpha = 0.55 / N;      % Taux de contamination
beta  = 0.03;          % Taux de mortalité des zombies
gamma = 0.4 / N;       % Taux de compétition / guérison
rho   = 0.02;          % Taux de mise en quarantaine (cas bonus)

%% Cas 1 : sans réponse humaine
fprintf('=== CAS 1 : Sans réponse humaine ===\n');

f1 = @(t, y) [...
    -alpha * y(1) * y(2);                     % dS/dt
     alpha * y(1) * y(2) - beta * y(2);       % dZ/dt
     beta * y(2)];                            % dD/dt

y0_1 = [S0; Z0; D0];
[t1, Y1] = ode45(f1, tspan, y0_1);
S1 = Y1(:,1); Z1 = Y1(:,2); D1 = Y1(:,3);

[pic_Z1, idx_Z1] = max(Z1);
fprintf(' Pic zombies     : %.0f personnes au jour %.1f\n', pic_Z1, t1(idx_Z1));
fprintf(' Survivants J150 : %.0f personnes\n', S1(end));
fprintf(' Morts totaux    : %.0f personnes\n\n', D1(end));

%% Cas 2 : avec rébellion humaine
fprintf('=== CAS 2 : Avec rébellion humaine ===\n');

f2 = @(t, y) [...
    -alpha * y(1) * y(2);
     alpha * y(1) * y(2) - beta * y(2) - gamma * y(1) * y(2);
     beta * y(2) + gamma * y(1) * y(2)];

y0_2 = [S0; Z0; D0];
[t2, Y2] = ode45(f2, tspan, y0_2);
S2 = Y2(:,1); Z2 = Y2(:,2); D2 = Y2(:,3);

[pic_Z2, idx_Z2] = max(Z2);
fprintf(' Pic zombies     : %.0f personnes au jour %.1f\n', pic_Z2, t2(idx_Z2));
fprintf(' Survivants J150 : %.0f personnes\n', S2(end));
fprintf(' Morts totaux    : %.0f personnes\n\n', D2(end));

%% Cas 2 : étude de l'effet de gamma
fprintf('=== CAS 2 : Étude de l''effet de gamma ===\n');

gamma_vals = [0.1/N, 0.4/N, 1.0/N, 2.0/N, 5.0/N];
labels_g   = {'γ = 0.1/N', 'γ = 0.4/N', 'γ = 1.0/N', 'γ = 2.0/N', 'γ = 5.0/N'};
colors_g   = {'b', 'r', 'g', 'm', 'k'};

figure('Name','Cas 2 - Effet de gamma','NumberTitle','off','Position',[100 100 900 400]);
subplot(1,2,1); hold on;
subplot(1,2,2); hold on;

for i = 1:length(gamma_vals)
    g = gamma_vals(i);
    f_g = @(t, y) [...
        -alpha * y(1) * y(2);
         alpha * y(1) * y(2) - beta * y(2) - g * y(1) * y(2);
         beta * y(2) + g * y(1) * y(2)];
    [tg, Yg] = ode45(f_g, tspan, y0_2);
    Sg = Yg(:,1); Zg = Yg(:,2);

    subplot(1,2,1); plot(tg, Zg, colors_g{i}, 'LineWidth', 1.8);
    subplot(1,2,2); plot(tg, Sg, colors_g{i}, 'LineWidth', 1.8);

    [pic_g, idx_g] = max(Zg);
    fprintf(' %s -> Pic : %.0f au jour %.1f | Survivants : %.0f\n', ...
        labels_g{i}, pic_g, tg(idx_g), Sg(end));
end

subplot(1,2,1);
xlabel('Temps (jours)'); ylabel('Population zombie Z(t)');
title('Évolution des zombies (Cas 2)');
legend(labels_g, 'Location','northeast'); grid on;

subplot(1,2,2);
xlabel('Temps (jours)'); ylabel('Population saine S(t)');
title('Évolution des survivants (Cas 2)');
legend(labels_g, 'Location','northeast'); grid on;

sgtitle('Cas 2 : Impact du paramètre \gamma');
fprintf('\n');

%% Cas 3 : avec remède permanent
fprintf('=== CAS 3 : Avec remède permanent ===\n');

f3 = @(t, y) [...
    -alpha * y(1) * y(2);
     alpha * y(1) * y(2) - beta * y(2) - gamma * (y(1) + y(3)) * y(2);
     gamma * (y(1) + y(3)) * y(2);
     beta * y(2)];

y0_3 = [S0; Z0; R0_pop; D0];
[t3, Y3] = ode45(f3, tspan, y0_3);
S3 = Y3(:,1); Z3 = Y3(:,2); R3 = Y3(:,3); D3 = Y3(:,4);

[pic_Z3, idx_Z3] = max(Z3);
fprintf(' Pic zombies           : %.0f personnes au jour %.1f\n', pic_Z3, t3(idx_Z3));
fprintf(' Survivants sains J150 : %.0f\n', S3(end));
fprintf(' Guéris R J150         : %.0f\n', R3(end));
fprintf(' Morts totaux          : %.0f\n\n', D3(end));

%% Cas 4 : remède disponible après 10 jours
fprintf('=== CAS 4 : Remède disponible après 10 jours ===\n');

T_remede = 10;   % Jour d'arrivée du remède

% Phase 1 : 0 à T_remede (modèle du cas 1)
[t4a, Y4a] = ode45(f1, [0 T_remede], y0_1);

% Conditions initiales de la phase 2 : état à J10, R démarre à 0
y0_4b = [Y4a(end,1); Y4a(end,2); 0; Y4a(end,3)];

% Phase 2 : T_remede à 150 (modèle du cas 3)
[t4b, Y4b] = ode45(f3, [T_remede 150], y0_4b);

% Concaténation des deux phases
t4 = [t4a; t4b];
S4 = [Y4a(:,1); Y4b(:,1)];
Z4 = [Y4a(:,2); Y4b(:,2)];
R4 = [zeros(size(Y4a,1),1); Y4b(:,3)];
D4 = [Y4a(:,3); Y4b(:,4)];

[pic_Z4, idx_Z4] = max(Z4);
fprintf(' Pic zombies           : %.0f personnes au jour %.1f\n', pic_Z4, t4(idx_Z4));
fprintf(' Survivants sains J150 : %.0f\n', S4(end));
fprintf(' Guéris R J150         : %.0f\n', R4(end));
fprintf(' Morts totaux          : %.0f\n\n', D4(end));

%% Cas bonus : mise en quarantaine
fprintf('=== CAS BONUS : Mise en quarantaine ===\n');

fq = @(t, y) [...
    -alpha * y(1) * y(2) - rho * y(1);                     % dS/dt
     alpha * y(1) * y(2) - beta * y(2) - gamma * y(1) * y(2); % dZ/dt
     rho * y(1);                                           % dQ/dt
     beta * y(2) + gamma * y(1) * y(2)];                   % dD/dt

[tq, Yq] = ode45(fq, tspan, [S0; Z0; 0; D0]);
Sq = Yq(:,1); Zq = Yq(:,2); Qq = Yq(:,3); Dq = Yq(:,4);

[pic_Zq, idx_Zq] = max(Zq);
fprintf(' Pic zombies           : %.0f personnes au jour %.1f\n', pic_Zq, tq(idx_Zq));
fprintf(' Hors de danger (S+Q)  : %.0f\n', Sq(end) + Qq(end));
fprintf(' Morts totaux          : %.0f\n\n', Dq(end));

%% Graphiques
figure;
plot(t1, S1, 'b', 'LineWidth', 2); hold on;
plot(t1, Z1, 'r', 'LineWidth', 2);
plot(t1, D1, 'k--', 'LineWidth', 2);
xlabel('Temps (jours)'); ylabel('Population');
title('Cas 1 – Sans réponse humaine');
legend('Sains S(t)', 'Zombies Z(t)', 'Morts D(t)'); grid on;

figure;
plot(t2, S2, 'b', 'LineWidth', 2); hold on;
plot(t2, Z2, 'r', 'LineWidth', 2);
plot(t2, D2, 'k--', 'LineWidth', 2);
xlabel('Temps (jours)'); ylabel('Population');
title('Cas 2 – Rébellion humaine');
legend('Sains S(t)', 'Zombies Z(t)', 'Morts D(t)'); grid on;

figure;
plot(t3, S3, 'b', 'LineWidth', 2); hold on;
plot(t3, Z3, 'r', 'LineWidth', 2);
plot(t3, R3, 'g', 'LineWidth', 2);
plot(t3, D3, 'k--', 'LineWidth', 2);
xlabel('Temps (jours)'); ylabel('Population');
title('Cas 3 – Avec remède');
legend('Sains S(t)', 'Zombies Z(t)', 'Guéris R(t)', 'Morts D(t)'); grid on;

figure;
plot(t4, S4, 'b', 'LineWidth', 2); hold on;
plot(t4, Z4, 'r', 'LineWidth', 2);
plot(t4, R4, 'g', 'LineWidth', 2);
plot(t4, D4, 'k--', 'LineWidth', 2);
xline(10, '--m', 'Remède J10');
xlabel('Temps (jours)'); ylabel('Population');
title('Cas 4 – Remède disponible à J10');
legend('Sains S(t)', 'Zombies Z(t)', 'Guéris R(t)', 'Morts D(t)'); grid on;

figure;
plot(tq, Sq, 'b', 'LineWidth', 2); hold on;
plot(tq, Zq, 'r', 'LineWidth', 2);
plot(tq, Qq, 'c', 'LineWidth', 2);
plot(tq, Dq, 'k--', 'LineWidth', 2);
xlabel('Temps (jours)'); ylabel('Population');
title('Cas bonus – Mise en quarantaine');
legend('Sains S(t)', 'Zombies Z(t)', 'Quarantaine Q(t)', 'Morts D(t)'); grid on;

figure;
plot(t1, Z1, 'b', 'LineWidth', 2); hold on;
plot(t2, Z2, 'r', 'LineWidth', 2);
plot(t3, Z3, 'g', 'LineWidth', 2);
plot(t4, Z4, 'm--', 'LineWidth', 2);
plot(tq, Zq, 'c:', 'LineWidth', 2);
xlabel('Temps (jours)'); ylabel('Population zombie Z(t)');
title('Comparaison des zombies – tous les scénarios');
legend('Cas 1', 'Cas 2', 'Cas 3', 'Cas 4', 'Bonus quarantaine'); grid on;
