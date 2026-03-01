function feats = compute_mfcc_from_frames(y, fs)

% Convert to column if needed
if size(y,2) > size(y,1)
    y = y';
end

% Remove DC offset
y = y - mean(y);

% Normalize signal to avoid amplitude issues
maxVal = max(abs(y));
if maxVal > 0
    y = y / maxVal;
end

% Define window and overlap
winLength = round(0.025 * fs);   % 25 ms window
overlapLength = round(0.015 * fs); % 15 ms overlap

win = hamming(winLength);

% Extract MFCC features
coeffs = mfcc(y, fs, 'Window', win, 'OverlapLength', overlapLength, 'NumCoeffs', 13);

% Return MFCC features (frame-wise)
feats = coeffs;

end
