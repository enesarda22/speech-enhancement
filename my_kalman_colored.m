% this function takes the noisy speech signal that is corrupted by colored noise
% and enhances it using kalman filter method
function noisy = my_kalman_colored(noisy, Fs)

    % whiten the noise
    assumed_noise = noisy(1:0.1*Fs) .* hamming(0.1*Fs)';
    c = my_levinson(assumed_noise, 16);

%     non_speech_mask = speech_detection(speech, Fs);
% 
%     groups = cumsum(non_speech_mask(2:end)~=non_speech_mask(1:end-1));
%     groups = [0, groups];
%     
%     n_groups = groups(end);
%     c = zeros(16, floor(n_groups/2));
%     
%     for i = 0:2:n_groups
%     
%         current_noise = noisy(groups==i);
%         c(:, i/2+1) = my_levinson(current_noise, 16);
%     
%         idxs = ((groups==i) | (groups==(i+1)));
%         noisy(idxs) = filter([1; -c(:, i/2+1)], 1, noisy(idxs));
%     
%     end
    
    % whiten the noise
    noisy = filter([1; -c], 1, noisy);

    % estimate the filtered speech
    noisy = my_kalman(noisy, Fs);

    % get the desired speech by inverse-filtering
    noisy = filter(1, [1; -c], noisy);

%     for i = 0:2:n_groups
% 
%         idxs = ((groups==i) | (groups==(i+1)));
%         noisy(idxs) = filter(1, [1; -c(:, i/2+1)], noisy(idxs));
%     
%     end

end