function a = my_levinson(s, P)
    
    if size(s, 1) == 1
        s = s';
    end
    
    acf = xcorr(s);
    acf = acf(length(s):end);

    % levinson-durbin
    a = zeros(P, 1);
    E = acf(1); % prediction error
    
    a_old = zeros(P, 1);
    for i = 1:P
        k = (acf(i+1) - a_old(1:i-1)'*flip(acf(2:i))) / E;
        a(i) = k;
    
        if i > 1
            for j = 1:i-1
                a(j) = a_old(j) - k*a_old(i-j);
            end
        end
    
        % update
        E = (1-k^2) * E;
        a_old = a;
    end

end