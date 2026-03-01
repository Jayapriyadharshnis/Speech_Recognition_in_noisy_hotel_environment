function speech_gui_final_voice()

clc;
clear;
close all;

disp("Voice Command Recognition GUI - Hotel Version");

% === Load trained model ===
S = load('outputs/trained_model.mat');
model = S.model;
mu = S.mu;
sigma = S.sigma;

disp("Trained model loaded successfully.");

% === Create GUI window ===
fig = uifigure('Name','Hotel Voice Assistant','Position',[200 100 850 600]);

uilabel(fig,...
    'Text','Voice Command Recognition System',...
    'FontSize',20,...
    'FontWeight','bold',...
    'Position',[200 550 450 40]);

% === Table for order display ===
cols = {'Item Name','Type','Price (Rs)'};

tbl = uitable(fig,...
    'Data',cell(0,3),...
    'ColumnName',cols,...
    'Position',[150 250 550 250]);

% === Record button ===
uibutton(fig,...
    'Text','Record Command',...
    'FontSize',14,...
    'Position',[320 190 200 40],...
    'ButtonPushedFcn',@(src,event)recordCommand());

% === Result label ===
uilabel(fig,...
    'Text','Result:',...
    'FontSize',14,...
    'Position',[150 150 100 30]);

resultLabel = uilabel(fig,...
    'Text','',...
    'FontSize',14,...
    'FontWeight','bold',...
    'Position',[220 150 500 30]);

% === Menu database ===
menuItems = {
    'idly','Veg',20;
    'dosa','Veg',30;
    'chapathi','Veg',25;
    'poori','Veg',25;
    'fishfry','Non-Veg',80;
    'chickenbriyani','Non-Veg',100
};

% =====================================================
% RECORD FUNCTION
% =====================================================
function recordCommand()

    fs = 16000;

    recObj = audiorecorder(fs,16,1);

    disp("Recording...");
    recordblocking(recObj,2);

    y = getaudiodata(recObj);

    % Validate audio
    if isempty(y) || ~isnumeric(y)
        uialert(fig,"Audio not captured properly.","Error");
        return;
    end

    disp("Recording complete.");

    % Noise reduction
    y = medfilt1(y,5);

    % Recognize command
    label = recognize_command_final(y, model, mu, sigma);

    resultLabel.Text = "Predicted Command: " + label;

    disp("Predicted Command: " + label);

    % Interpret command
    txt = lower(char(label));

    msg = "";

    if contains(txt,"i_want")

        food = erase(txt,"i_want_");

        addItem(food);

        msg = "Order added: " + food;

    elseif contains(txt,"cancel")

        food = erase(txt,"cancel_");

        removeItem(food);

        msg = "Order cancelled: " + food;

    else

        msg = "Command not recognized";

        uialert(fig,msg,"Info");

    end

    % Speak response
    try
        NET.addAssembly('System.Speech');
        speaker = System.Speech.Synthesis.SpeechSynthesizer;
        Speak(speaker, char(msg));
    catch
        disp(msg);
    end

end

% =====================================================
% ADD ITEM
% =====================================================
function addItem(food)

    idx = find(strcmp(food,menuItems(:,1)));

    if isempty(idx)
        uialert(fig,"Item not in menu.","Info");
        return;
    end

    newRow = menuItems(idx,:);

    data = tbl.Data;

    data(end+1,:) = newRow;

    tbl.Data = data;

    disp("Added: " + food);

end

% =====================================================
% REMOVE ITEM
% =====================================================
function removeItem(food)

    data = tbl.Data;

    if isempty(data)
        uialert(fig,"No items to remove.","Info");
        return;
    end

    idx = find(strcmp(food,data(:,1)));

    if isempty(idx)
        uialert(fig,"Item not found.","Info");
        return;
    end

    data(idx,:) = [];

    tbl.Data = data;

    disp("Removed: " + food);

end

end

% =====================================================
% SPEECH RECOGNITION FUNCTION
% =====================================================
function label = recognize_command_final(y, model, mu, sigma)

fs = 16000;

% Convert to column vector
y = reshape(y,[],1);

% Normalize
maxVal = max(abs(y));

if maxVal > 0
    y = y / maxVal;
end

% Smooth signal
y = smoothdata(y,'movmean',5);

% Extract MFCC features
coeff = mfcc(y,fs,'NumCoeffs',14,'LogEnergy','Ignore');

feats = mean(coeff,1);

% Match training feature size
n = min(length(feats),length(mu));

feats = feats(1:n);

mu = mu(1:n);

sigma = sigma(1:n);

% Normalize
feats = (feats - mu) ./ sigma;

% Predict command
label = predict(model,feats);

end
