function label = recognize_command_final(y, model, mu, sigma)

    fs = 16000;

    % Ensure input is numeric
    if ~isnumeric(y) || isempty(y)
        label = "Invalid audio input";
        return;
    end

    % Convert to column vector
    y = reshape(y, [], 1);

    % Normalize
    maxVal = max(abs(y));
    if maxVal > 0
        y = y / maxVal;
    end

    % Smooth
    y = smoothdata(y, 'movmean', 5);

    % MFCC extraction
    coeff = mfcc(y, fs, 'NumCoeffs', 14, 'LogEnergy', 'Ignore');

    feats = mean(coeff, 1);

    % Match training size
    n = min(length(feats), length(mu));
    feats = feats(1:n);
    mu = mu(1:n);
    sigma = sigma(1:n);

    feats = (feats - mu) ./ sigma;

    % Predict
    label = predict(model, feats);

end
