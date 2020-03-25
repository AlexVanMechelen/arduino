%% define parameters and creta tcp/ip object
T_sample = 0.01;
n_samples = 100;
ts = (0:n_samples-1)*T_sample;

arduino = tcpclient('localhost', 6011, 'Timeout', 60);


% Standard modes (must correspond to similar mode in Ardunio code)
OPEN_LOOP   = 0;
CLASSICAL   = 1; %classical (PID family) controller
STATE_SPACE = 2;

%%
mode = OPEN_LOOP;
w = 20.0;
height = 1.0;
set_disturbance(arduino, height)
set_mode_params(arduino, mode, w, [])
reset_system(arduino);
%%
set_mode_params(arduino, mode, w, [])
for w = linspace(20.0, 0.0, 101)
    [y, u] = get_response(arduino, w, 5);
    if(y(end) > height)
        break
    end
    pause(0.1)
end    
%%
mode = OPEN_LOOP;

w = -0.5
set_mode_params(arduino, mode, w, [])

input('press enter')

w = 0.75
[y, u] = get_response(arduino, w, n_samples)

figure; plot(ts, y); title("y");
figure; plot(ts, u); title("u");
%%
set_disturbance(arduino, 10.0)
pause(2.0)
set_disturbance(arduino, 0.0)
[y, u] = get_response(arduino, 0.0, 500);
figure; plot(y); title("y");
%%
mode = CLASSICAL;
w = 0.0;
set_mode_params(arduino, mode, w, [0.95, 0.7, -1.]);

input('press enter')

w = 0.5;
n_samples = 2000;
ts = (0:n_samples-1)*T_sample;
[y, u] = get_response(arduino, w, n_samples)
figure; plot(ts, y); title("y");
figure; plot(ts, u); title("u");
%% Estimate parameters
Y_ = Y;
p = polyfit(ts(1:20), Y(1:20), 2);
x_fit = polyval(p, ts);
plot(ts, Y, ts, x_fit);
%%
%K = p(1)*2/abs(w);
K = -5/7 * 9.81;
sys = tf([K], [1 0 0]); sysd = c2d(sys, T_sample);
figure; step(abs(w)*sys, ts)
figure; rlocus(sysd);
%% construct first loop
figure; rlocus(sysd);
R = zpk([0.95], [0.9], 1, T_sample);
figure; rlocus(R*sysd);
gain = -1.;
sysd_cl = feedback(gain*R*sysd, 1);
figure; step(sysd_cl, 2.5);
%%
sys_e_u = feedback(-gain*R, sysd);
figure; step(sys_e_u)
%%
close_connection(arduino)
clear CLASSICAL

%%
figure; hold on;
plot(ts, Y-Y(1), 'r')
step(0.5*sysd_cl)
