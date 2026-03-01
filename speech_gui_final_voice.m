function speech_gui_final_voice()
clc; clear; close all;
disp("🎙️ Voice Command Recognition GUI - Hotel Version");

% === Load trained model ===
S = load('outputs/trained_model.mat');
model = S.model;
mu = S.mu;
sigma = S.sigma;
disp("✅ Trained model loaded successfully.");

% === GUI window ===
fig = uifigure('Name','Hotel Voice Assistant','Position',[200 100 850 600]);
uilabel(fig,'Text','🍴 Voice Command Recognition System','FontSize',20,...
    'FontWeight','bold','Position',[180 550 500 40]);

cols = {'Item Name','Type','Price (₹)'};
tbl = uitable(fig,'Data',cell(0,3),'ColumnName',cols,...
    'Position',[150 250 550 250]);

uibutton(fig,'Text','🎧 Record Command','FontSize',14,...
    'Position',[320 190 200 40],'ButtonPushedFcn',@(src,event)recordCommand());

uilabel(fig,'Text','Result:','FontSize',14,...
    'Position',[150 150 100 30]);
resultLabel = uilabel(fig,'Text','','FontSize',14,'FontWeight','bold',...
    'Position',[220 150 500 30]);

% === Menu items ===
menuItems = {
    'idly','Veg',20;
    'dosa','Veg',30;
    'chapathi','Veg',25;
    'poori','Veg',25;
    'fishfry','Non-Veg',80;
    'chickenbriyani','Non-Veg',100
};

% === Record Command ===
    function recordCommand()
        fs = 16000; recObj = audiorecorder(fs,16,1);
        disp("🎧 Recording...");
        recordblocking(recObj, 2);
        y = getaudiodata(recObj);
        disp("✅ Recorded.");

        % --- Basic noise filter (smooth audio) ---
        y = medfilt1(y,5);   % simple median filter (no toolbox needed)

        % --- Predict ---
        label = recognize_command_voice(y, model, mu, sigma);
        resultLabel.Text = "🧠 Predicted Command: " + label;
        disp("🧠 Predicted Command: " + label);

        % --- Interpret ---
        txt = lower(char(label));
        msg = "";
        if contains(txt,"i_want")
            food = erase(txt,"i_want_");
            addItem(food);
            msg = "Your order for " + food + " has been added.";
        elseif contains(txt,"cancel")
            food = erase(txt,"cancel_");
            removeItem(food);
            msg = "Your order for " + food + " has been cancelled.";
        else
            msg = "Sorry, I could not understand your command.";
            uialert(fig,msg,"⚠️ Error");
        end

        % --- Speak output ---
        try
            NET.addAssembly('System.Speech');
            speaker = System.Speech.Synthesis.SpeechSynthesizer;
            Speak(speaker, char(msg));
        catch
            disp("🔊 " + msg);
        end
    end

% === Add item ===
    function addItem(food)
        idx = find(strcmp(food,menuItems(:,1)));
        if isempty(idx)
            uialert(fig,"Item not found in menu.","ℹ️ Info"); return;
        end
        newRow = menuItems(idx,:);
        data = tbl.Data;
        data(end+1,:) = newRow;
        tbl.Data = data;
        disp("✅ Added: " + food);
    end

% === Remove item ===
    function removeItem(food)
        data = tbl.Data;
        if isempty(data)
            uialert(fig,"No items to cancel.","ℹ️ Info"); return;
        end
        idx = find(strcmp(food,data(:,1)));
        if isempty(idx)
            uialert(fig,"Item not in order list.","ℹ️ Info"); return;
        end
        data(idx,:) = [];
        tbl.Data = data;
        disp("❌ Removed: " + food);
    end
end

% ========================
% 🔍 Voice Recognition Helper
% ========================
function label = recognize_command_voice(y, model, mu, sigma)
    % --- Feature extraction ---
    feats = compute_mfcc_from_frames(y,16000); % your MFCC extractor
    feats = mean(feats,1);

    % --- Normalize ---
    if length(mu) == length(feats)
        feats = (feats - mu) ./ sigma;
    else
        feats = normalize(feats);
    end

    % --- Predict ---
    label = predict(model,feats);
end
