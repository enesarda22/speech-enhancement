% this function detects the frames that only contain noise
function non_speech_mask2 = speech_detection(speech, Fs)
    win_dur = 0.032 * Fs;
    hop_dur = ceil(win_dur / 4);
    
    % forst 100ms is used to compute thresholds
    noise_seg = speech(1:0.1*Fs); 
    E = log(noise_seg.^2);
    E(isinf(E)) = 0;
    
    mu_E = mean(E);
    
    zcf_th = 0.25; % zero crossing threshold is based on the unvoiced zcr distributions
    low_E_th = mu_E*0.6;
    
    n_frames = ceil((length(speech)-win_dur) / hop_dur) + 1; % number of frames
    E = zeros(n_frames, 1);
    Z = zeros(n_frames, 1);
    frames = zeros(n_frames, win_dur);
    for i = 1:n_frames
        
        idxs = (i-1)*hop_dur+1:(i-1)*hop_dur+win_dur;
        frame = speech(idxs);
        frames(i, :) = frame;
    
        energies = log(frame.^2);
        energies(isinf(energies)) = 0;
        E(i) = mean(energies);
        Z(i) = zerocrossrate(frame);
    
    end

    % moving median is used on energies and zcrs
    E = movmedian(E, 10); 
    Z = movmedian(Z, 10);
    
    % another energy threshold is based on the maximum energy
    max_E = max(E);
    max_E_th = max_E * 1.8;
  
    % masking is done
    mask = E>max_E_th;
    groups = cumsum(mask(2:end)~=mask(1:end-1));
    groups = [0; groups];
    
    n_groups = groups(end);
    non_speech_mask = zeros(n_frames, 1);
    for k = 0:n_groups
        idxs = find(groups==k);
        if mask(idxs(1)) == 0
            non_speech_mask(idxs) = 1;
            continue
        end
        start_idx = idxs(1);
        
        for i = start_idx-1:-1:1
            if E(i) > low_E_th
                idxs = [i; idxs];
            else
                break
            end
        end
        
        for i = idxs(end)+1:length(E)
            if E(i) > low_E_th
                idxs = [idxs; i];
            else
                break
            end
        end
        
        start_idx = idxs(1);
        
        for i = start_idx-1:-1:1
            if Z(i) > zcf_th
                idxs = [i; idxs];
            else
                break
            end
        end
        
        for i = idxs(end)+1:length(Z)
            if Z(i) > zcf_th
                idxs = [idxs; i];
            else
                break
            end
        end
    
        non_speech_mask(idxs) = 0;
    end

    % masking is imposed on all the samples
    groups = cumsum(non_speech_mask(2:end)~=non_speech_mask(1:end-1));
    groups = [0; groups];
    
    n_groups = groups(end);

    non_speech_mask2 = zeros(size(speech));
    last_idx = 1;
    for i = 0:n_groups
        n_idxs = (sum(groups==i))*hop_dur;
        masks = non_speech_mask(groups==i);
        non_speech_mask2(last_idx:last_idx+n_idxs-1) = ones(1, n_idxs) * masks(1);
        last_idx = last_idx+n_idxs;
    end

end
