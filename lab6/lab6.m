% Algot Sandahl

clear
[y, Fs] = audioread('AnalogRytm_120BPM.wav');
[yGoal, ~] = audioread('TimeFactor_RE501_120BPM.wav');
%%
subplot(1,2,1); spectrogram(y(:,1));     title('y');     %xlim([0, 0.1]);
subplot(1,2,2); spectrogram(yGoal(:,1)); title('yGoal'); %xlim([0, 0.1]);
%%
bpm = 120;
delayTimeMs = 0.75 * (60000 / bpm);

% Delay
[b, a] = butter(2, [0.005, 0.6]);
% [b, a] = butter(2, 0.6);
y = filteredDelay(y, delayTimeMs, 0.2, b, a, Fs);
y = filteredDelay(y, delayTimeMs, 0.2, b, a, Fs);
y = filteredDelay(y, delayTimeMs, 0.2, b, a, Fs);

% Reverb (which admittedly is not great)
y = reverb(y, 30, 0.65, Fs);

% Distort
y = dist(y, 1.2);

% Compress
% y = compress(y);

% Add noise
noise = wgn(length(y),1,0);
[b2, a2] = butter(2, 0.4, 'high');
filteredNoise = filter(b2, a2, noise);
y = y + 0.001 * filteredNoise;

% Add hum
t = ((0:length(y)-1) ./ Fs)';
hum = sin(2 * pi * 50 * t);
y = y + 0.023 * hum;

y = y / max(abs(y));

subplot(2,1,1); plot(y);     title('y');     xlim([0, 4.5e5]);
subplot(2,1,2); plot(yGoal); title('yGoal'); xlim([0, 4.5e5]);

%playblocking(audioplayer(y, Fs));
playblocking(audioplayer(y, Fs, 24, 5));

%%
function yNew = filteredDelay(y, delayTimeMs, level, filterB, filterA, Fs)
    silence = zeros(round((delayTimeMs / 1000) * Fs), 2);
    echo = filter(filterB, filterA, [silence; y]);
    yExtended = [y; silence];
    yNew = echo * level + yExtended;
end

function yNew = schroederAllpass(y, length, gain)
    b = zeros(1, length+1);
    b(1) = -gain;
    b(length+1) = 1;
    
    a = zeros(1, length+1);
    a(1) = 1;
    a(length+1) = -gain;
    
    yNew = filter(b, a, y);
end

function yNew = reverb(y, reverbTime, gain, Fs)
    reverbed = y;
    numberOfAllpass = 3;
    
    for i = 0:numberOfAllpass-1
        reverbLength = ceil((reverbTime/1000)*Fs / (3^i));
        reverbed = [reverbed; zeros(round(abs(reverbTime/100))*Fs, 2)];
        reverbed = schroederAllpass(reverbed, reverbLength, gain);
    end

    [b, a] = butter(4, [0.2 0.8]);
    reverbed = filter(b, a, reverbed);
    yNew = [y; zeros(length(reverbed) - length(y), 2)] + 0.5 * reverbed;
end

function yNew = dist(y, distLevel)
    yNew = (distLevel*y)./(1+distLevel*abs(y));
end

function y = compress(y)
    for i=1:length(y)
        abso = max(abs(y(i,1)), abs(y(i,2)));
        y(i,1) = y(i,1) * (2 - abso);
        y(i,2) = y(i,2) * (2 - abso);
    end
end