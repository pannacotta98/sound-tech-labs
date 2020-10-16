% Algot Sandahl
clearvars;
close all;
[original, Fs] = audioread('135-bpm.wav');
original = original(:,1);
originalPlayer = audioplayer(original, Fs);

%% Calculations
speed = 1.0;
pitch = 1.5;

speed = speed / pitch;

Fs2 = Fs;
if pitch ~= 1
    Fs2 = round(pitch * Fs);
end

windowSize = round(0.05 * Fs);
stepSize = round(speed * windowSize);

newFrame = zeros(round(length(original) ...
    * (windowSize / stepSize) + windowSize), 1);

k = 0;
for i = 0:stepSize:(length(original) - 1)
   for j = 0:(windowSize - 1)
       k = k + 1;
       newFrame(k) = i + j;
   end
end

% Remove zeros
ix = newFrame > 0;
newFrame = newFrame(ix);

% Remove indexes that dont exist
ix = newFrame <= length(original);
newFrame = newFrame(ix);

vocoder = original(newFrame);

vocoderPlayer = audioplayer(vocoder, Fs2);

%% Comparison plot
window = [0, 0.1 * max(length(original), length(vocoder))];
subplot(211); plot(original); title('original'); xlim(window);
subplot(212); plot(vocoder);  title('vocoder');  xlim(window);

%% Phase vocoder sound player
play(vocoderPlayer);
%%
stop(vocoderPlayer);

%% Original sound player
play(originalPlayer);
%%
stop(originalPlayer);


    






