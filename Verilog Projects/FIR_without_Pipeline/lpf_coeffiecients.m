clc;
clear;
close all;

%% =====================================================
% FIXED-POINT PARAMETERS
%% =====================================================
WL_in  = 17;     % Q3.14 format
FL_in  = 14;

WL_acc = 41;     % Q13.28 accumulator
FL_acc = 28;

scale_in = 2^FL_in;

MAX_IN  =  2^(WL_in-1)-1;
MIN_IN  = -2^(WL_in-1);

MAX_ACC =  2^(WL_acc-1)-1;
MIN_ACC = -2^(WL_acc-1);

%% =====================================================
% 1. GENERATE 100-TAP FIR COEFFICIENTS (Q3.14)
%% =====================================================
fs = 10000;
fc = 1000;
N  = 100;   % Order → 101 taps

h = fir1(N, fc/(fs/2), 'low');
h = h / sum(h);     % Unit gain normalization

h_q = round(h * scale_in);
h_q(h_q > MAX_IN) = MAX_IN;
h_q(h_q < MIN_IN) = MIN_IN;

num_taps = length(h_q);

% Save FIR taps (Q3.14 binary)
fid = fopen('fir_taps_Q3_14.mem','w');

for i = 1:num_taps
    val = h_q(i);
    if val < 0
        val = val + 2^WL_in;
    end
    fprintf(fid,'%s\n', dec2bin(val, WL_in));
end

fclose(fid);
disp('FIR taps saved (Q3.14 binary).');

%% =====================================================
% 2. GENERATE THREE SINE INPUTS (Q3.14)
%% =====================================================
duration = 0.1;
t = 0:1/fs:duration-1/fs;

frequencies = [900 1100 2000];
num_sines = length(frequencies);
num_samples = length(t);

signal_q = zeros(num_samples, num_sines);

for k = 1:num_sines
    
    temp = sin(2*pi*frequencies(k)*t);
    
    temp_q = round(temp * scale_in);
    temp_q(temp_q > MAX_IN) = MAX_IN;
    temp_q(temp_q < MIN_IN) = MIN_IN;
    
    signal_q(:,k) = temp_q.';
end

% Save sine inputs (3 columns, Q3.14 binary)
fid = fopen('multi_sine_Q3_14_columns.mem','w');

for i = 1:num_samples
    
    val1 = signal_q(i,1);
    val2 = signal_q(i,2);
    val3 = signal_q(i,3);
    
    if val1 < 0, val1 = val1 + 2^WL_in; end
    if val2 < 0, val2 = val2 + 2^WL_in; end
    if val3 < 0, val3 = val3 + 2^WL_in; end
    
    fprintf(fid,'%s %s %s\n', ...
        dec2bin(val1, WL_in), ...
        dec2bin(val2, WL_in), ...
        dec2bin(val3, WL_in));
end

fclose(fid);
disp('Sine inputs saved (Q3.14 binary).');

%% =====================================================
% 3. BIT-TRUE INTEGER FIR (41-BIT ACCUMULATOR)
%% =====================================================
output_acc = zeros(num_samples, num_sines, 'int64');

for k = 1:num_sines
    
    x = signal_q(:,k);
    
    for n = 1:num_samples
        
        acc = int64(0);
        
        for m = 1:num_taps
            if (n-m+1) > 0
                prod = int64(x(n-m+1)) * int64(h_q(m));  % Q6.28
                acc = acc + prod;                        % Q13.28
            end
        end
        
        % Saturation to 41-bit range
        if acc > MAX_ACC
            acc = MAX_ACC;
        elseif acc < MIN_ACC
            acc = MIN_ACC;
        end
        
        output_acc(n,k) = acc;
    end
end

disp('Bit-true FIR filtering completed.');

%% =====================================================
% 4. SAVE LPF OUTPUT (Q13.28, 41-BIT BINARY, 3 COLUMNS)
%% =====================================================
fid = fopen('lpf_output_Q13_28_41bit.mem','w');

for i = 1:num_samples
    
    val1 = output_acc(i,1);
    val2 = output_acc(i,2);
    val3 = output_acc(i,3);
    
    if val1 < 0, val1 = val1 + 2^WL_acc; end
    if val2 < 0, val2 = val2 + 2^WL_acc; end
    if val3 < 0, val3 = val3 + 2^WL_acc; end
    
    fprintf(fid,'%s %s %s\n', ...
        dec2bin(val1, WL_acc), ...
        dec2bin(val2, WL_acc), ...
        dec2bin(val3, WL_acc));
end

fclose(fid);

disp('LPF output saved (41-bit Q13.28 binary, 3 columns).');
