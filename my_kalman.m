% this function takes the noisy speech signal and enhances it using kalman
% filter method
function noisy = my_kalman(noisy, Fs)

    p = 20; % number of filter coefficients
    tao = 100; % number of future samples to be used
    T_p_max = 0.0125 * Fs; % maximum pitch period
    
    r = max(p, tao+1);
    
    win_dur = 0.032 * Fs; % window duration in samples
    padded_noisy = [zeros(1, 0.02*Fs + win_dur/2), noisy, zeros(1, 0.02*Fs + win_dur/2)];
    
    start_idx = 0.02*Fs + 2;
    final_idx = length(noisy) + start_idx - 1;
    
    b = zeros(length(noisy), 1); % instantaneous periodicity
    T_p = zeros(length(noisy), 1); % pitch period
    e = zeros(length(noisy), 1); % excitation signal
    A = zeros(p, length(noisy)); % filter coefficients
    
    fprintf("Enhancement starts\n");
    for i = 1:5 % iterate 5 times
        for n = start_idx:final_idx
        
            seg = padded_noisy(n:n+win_dur-1);
            
            % filter coefficients are calculated from the smoothed window
            windowed_seg = seg .* hamming(win_dur)';
            windowed_seg1 = padded_noisy(n-0.008*Fs:n-0.008*Fs+win_dur-1) .* hamming(win_dur)'; % 8ms back
            windowed_seg2 = padded_noisy(n+0.008*Fs:n+0.008*Fs+win_dur-1) .* hamming(win_dur)'; % 8ms forth
            windowed_seg3 = padded_noisy(n-0.02*Fs:n-0.02*Fs+win_dur-1) .* hamming(win_dur)'; % 20ms back
            windowed_seg4 = padded_noisy(n+0.02*Fs:n+0.02*Fs+win_dur-1) .* hamming(win_dur)'; % 20ms forth
        
            fft_mag_mat = [abs(fft(windowed_seg)); 
                           abs(fft(windowed_seg1));
                           abs(fft(windowed_seg2));
                           abs(fft(windowed_seg3));
                           abs(fft(windowed_seg4))];
        
        
            phase = angle(fft(windowed_seg));
            smooth_fft_mag = min(fft_mag_mat, [], 1);
        
            smooth_seg = ifft(abs(smooth_fft_mag) .* exp(1j*phase));
            smooth_seg = real(smooth_seg);
        
            a = my_levinson(smooth_seg, 20);
            a(isnan(a)) = 0;
            A(:, n-start_idx+1) = a;
        
            % clipping is done
            clipped_seg = zeros(1, win_dur);
            C_L = max(abs(seg)) * 0.4;
            clipped_seg(seg>-C_L & seg<C_L) = 0;
            clipped_seg(seg>C_L) = seg(seg>C_L) - C_L;
            clipped_seg(seg<-C_L) = seg(seg<-C_L) + C_L;
        
            % autocorrelation is calculated
            acf = xcorr(clipped_seg);
            acf = acf(win_dur:end);
            
            % peak index between 3ms-12.5ms is found and defined as pitch period
            [peak, peak_idx] = max(acf(0.003*Fs+1:0.0125*Fs+1));
            T_p(n-start_idx+1) = peak_idx + 0.003*Fs - 1;
            
            % periodicity is calculated
            b(n-start_idx+1) = peak / acf(1);
            if b(n-start_idx+1) < 0.5
                b(n-start_idx+1) = 0;
            end
        
            e(n-start_idx+1) = seg(win_dur/2) - seg(win_dur/2-20:win_dur/2-1) * flip(a);
        
        end
        
        % d is calculated from e and b
        d = zeros(length(noisy), 1);
        for k = 1:length(noisy)
            if k > T_p(k)
                d(k) = e(k) - b(k) * e(k - T_p(k));
            else
                d(k) = e(k);
            end
        end
        
        % variance of d is estimated
        var_d = zeros(length(noisy), 1);
        for k = 1:length(noisy)
            if k-0.004*Fs <= 0
                var_d(k) = var(d(1:k+0.004*Fs-1));
            elseif k+0.004*Fs > length(noisy)
                var_d(k) = var(d(k-0.004*Fs+1:end));
            else
                var_d(k) = var(d(k-0.004*Fs+1:k+0.004*Fs));
            end
        end
        
        % kalman filter
        % initialization
        sig_w = sqrt(var(noisy(1:0.1*Fs))); % estimate the std of the white noise
        
        a = zeros(p, 1);
        P_1 = zeros(r, r);
        P_2 = zeros(r, T_p_max);
        P_3 = zeros(T_p_max, T_p_max);
        x_hat = zeros(r+T_p_max, 1);
        
        % kalman filtering
        for n = 1:length(noisy)
        
            f = P_1(:, 1:p)*a + P_2(:, 1);
            g = P_3(:, T_p(n))*b(n);
        
            q_1 = a'*(f(1:p) + P_2(1:p, 1)) + P_3(1, 1);
            q_2 = (a'*P_2(1:p, T_p(n)) + P_3(1, T_p(n))) * b(n);
            q_3 = g(T_p(n))*b(n) + var_d(n);
            q_4 = (a'*P_2(1:p, 1:T_p_max-1) + P_3(1, 1:T_p_max-1))';
            q_5 = P_2(1:r-1, T_p(n)) * b(n);
        
            G = [q_1; f(1:r-1); q_2; q_4] / (q_1 + sig_w^2);
        
            P_1 = [q_1, f(1:r-1)';
                   f(1:r-1), P_1(1:r-1, 1:r-1)] - G(1:r)*[q_1, f(1:r-1)'];
            
            P_2 = [q_2, q_4';
                   q_5, P_2(1:r-1, 1:T_p_max-1)] - G(1:r)*[q_2, q_4'];
        
            P_3 = [q_3, g(1:T_p_max-1)';
                   g(1:T_p_max-1), P_3(1:T_p_max-1, 1:T_p_max-1)] - G(r+1:r+T_p_max) * [q_2, q_4'];
        
            h = a' * x_hat(1:p) + x_hat(r+1);
        
            if n > 1
                x_hat = [h; x_hat(1:r-1); x_hat(r+T_p(n))*b(n); x_hat(r+1:r+T_p_max-1)] + (noisy(n-1)-h)*G;
            else
                x_hat = [h; x_hat(1:r-1); x_hat(r+T_p(n))*b(n); x_hat(r+1:r+T_p_max-1)] + (-h)*G;
            end
        
            if (n > (tao+1))
                noisy(n-tao-1) = x_hat(tao+1);
            end
        
            a = A(:, n);
        end
        
        noisy(end-tao:end) = flip(x_hat(1:tao+1));
        padded_noisy = [zeros(1, 0.02*Fs + win_dur/2), noisy, zeros(1, 0.02*Fs + win_dur/2)];
    
        fprintf("Iteration %d is done.\n", i);
    
    end

end