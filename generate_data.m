%% setup
clear; clc;
Fs = 16000;

sound_files = ["1272-128104-0005", "1462-170138-0013", "1673-143397-0002"];
files = dir("../data/mat/*.mat");

SNRs = 0:2:10;
new_SNRs = zeros(length(sound_files), length(SNRs));
filtered_signals = zeros(length(sound_files), 80000, length(SNRs));
noisy_signals = zeros(length(sound_files), 80000, length(SNRs));
clean_signals = zeros(length(sound_files), 80000);


for i = 1:length(sound_files)

    sound_file = sound_files(i);
    files = dir("../data/mat/" + sound_file + "*.mat");
    file = files(i);
    load(file.folder + "/" + file.name); % load the data
    clean_signals(i, :) = speech;
end


%% white noise
for i = 1:length(sound_files)

    sound_file = sound_files(i);
    files = dir("../data/mat/" + sound_file + "*.mat");

    file = files(i);
    load(file.folder + "/" + file.name); % load the data

    pow = mean(speech.^2);

    for j = 1:length(SNRs)

        SNR = SNRs(j);
        sig = sqrt(pow / 10^(SNR/10));
        
        noise = sig * randn(size(speech)); % noise is white gaussian
        noisy = speech + noise; 

        filtered = my_kalman(noisy, Fs);
        new_SNR = 10*log10(pow / mean((filtered-speech).^2))

        new_SNRs(i, j) = new_SNR;
        filtered_signals(i, :, j) = filtered;
        noisy_signals(i, :, j) = noisy;
    end

end

save white_noise_SNRs.mat new_SNRs

%% plot white gaussian nose SNR

load white_noise_SNRs.mat
load white_noise_filtered.mat
load white_noise_noisy.mat

for i = 1:length(sound_files)
    new_SNR_values = new_SNRs(i, :);
    scatter(SNRs, new_SNR_values, 50, "filled");
    hold on;
end

plot(SNRs, mean(new_SNRs));

xlabel("Input SNR (dB)")
ylabel("Output SNR (dB)")
legend(["Speaker1", "Speaker2", "Speaker3", "Mean"])
grid on
axis square
set(gca, "FontSize", 14);

%% white noise spectrogram
i = 1;
j = 6;
subplot(3, 1, 1);
spectrogram(clean_signals(i, :), 512, 384, 1024, Fs, "yaxis");
title("Clean Signal")
set(gca, "FontSize", 14);
subplot(3, 1, 2);
spectrogram(noisy_signals(i, :, j), 512, 384, 1024, Fs, "yaxis");
title("Noisy Signal")
set(gca, "FontSize", 14);
subplot(3, 1, 3);
spectrogram(filtered_signals(i, :, j), 512, 384, 1024, Fs, "yaxis");
title("Filtered Signal")
set(gca, "FontSize", 14);

%% colored noise
clear; clc;
Fs = 16000;
noise_files = ["CAFE-CAFE-1", "CAR-WINUPB-1", "HOME-KITCHEN-1", "STREET-CITY-1"];

old_SNRs = zeros(length(noise_files), 5);
new_SNRs = zeros(length(noise_files), 5);
filtered_signals = zeros(length(noise_files), 80000, 5);
noisy_signals = zeros(length(noise_files), 80000, 5);

for i = 1:length(noise_files)
    noise_file = noise_files(i);
    files = dir("../data/mat/*" + noise_file + ".mat");

    for j = 1:5
        file = files(j);
        load(file.folder + "/" + file.name); % load the data

        pow = mean(speech.^2);
        noise_pow = mean(noise.^2);

        SNR = 10*log10(pow / noise_pow);
        
        noisy = speech + noise;
        filtered = my_kalman_colored(noisy, Fs);
        new_SNR = 10*log10(pow / mean((filtered-speech).^2));

        [SNR, new_SNR]

        old_SNRs(i, j) = SNR;
        new_SNRs(i, j) = new_SNR;
        filtered_signals(i, :, j) = filtered;
        noisy_signals(i, :, j) = noisy;

    end
end

save colored_noise_SNRs.mat old_SNRs
save colored_noise_new_SNRs.mat new_SNRs
save colored_noise_filtered.mat filtered_signals
save colored_noise_noisy.mat noisy_signals
%%
clean_signals = zeros(length(noise_files), 80000, 5);
for i = 1:length(noise_files)
    noise_file = noise_files(i);
    files = dir("data/mat/*" + noise_file + ".mat");

    for j = 1:5
        file = files(j);
        load(file.folder + "/" + file.name); % load the data
        clean_signals(i, :, j) = speech;
    end
end
%% plot colored noise SNR
load colored_noise_SNRs.mat
load colored_noise_new_SNRs.mat
load colored_noise_filtered.mat
load colored_noise_noisy.mat

noise_labels = ["Cafe Noise", "Car Noise", "Kitchen Noise", "Street Noise"];
for i = 1:length(noise_labels)

    subplot(2, 2, i);
    new_SNR_values = new_SNRs(i, :);
    old_SNR_values = old_SNRs(i, :);
    scatter(old_SNR_values, new_SNR_values, 50, "filled");
    hold on;
    
    xlabel("Input SNR (dB)")
    ylabel("Output SNR (dB)")
    title(noise_labels(i))
    grid on
    axis square
    set(gca, "FontSize", 14);

end

%% plot colored noise spectrogram
i = 1;
j = 3;
subplot(3, 1, 1);
spectrogram(clean_signals(i, :, j), 512, 384, 1024, Fs, "yaxis");
title("Clean Signal")
set(gca, "FontSize", 14);
subplot(3, 1, 2);
spectrogram(noisy_signals(i, :, j), 512, 384, 1024, Fs, "yaxis");
title("Noisy Signal")
set(gca, "FontSize", 14);
subplot(3, 1, 3);
spectrogram(filtered_signals(i, :, j), 512, 384, 1024, Fs, "yaxis");
title("Filtered Signal")
set(gca, "FontSize", 14);
