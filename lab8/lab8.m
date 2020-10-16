% Algot Sandahl
[y, Fs] = audioread('forensisktljud.wav');
yLeft = y(:,1);
yRight = y(:,2);
t = (0:length(y) - 1)' / Fs;
% plot(t, y);

% plot(y((20 * Fs):(23 * Fs)));
%% Spela orginal
yLeft = yLeft / max(abs(yLeft));
playblocking(audioplayer(yLeft, Fs));

%% === Hörbarhetsförbättring(?) ===

yListen = y ./ max(abs(y));

% Filter low freq content, such as 50 Hz hum
[b, a] = butter(4, 200 / (Fs / 2), 'high');
yListen = filter(b, a, yListen);
yListen = filter(b, a, yListen);

% Noise reduction
yListen = sgolayfilt(yListen, 3, 17);

yListen = compress(yListen);
% yListen = dist(yListen, 1.5);

yListen = sgolayfilt(yListen, 2, 27);

yListen = yListen / max(abs(yListen));
% playblocking(audioplayer(y, Fs));
playblocking(audioplayer(yListen, Fs));

% Säger ljudinspleare kasnke

%% === Analys ===
%% Plot
plot(yLeft);
%% Frekvensinehåll
spectrogram(yLeft, 200, 64, 1024, Fs, 'yaxis');

%% Jordbrum
[b, a] = butter(2, [49, 51] / (Fs / 2));
hum = filter(b, a, yLeft);
plot(hum);
% playblocking(audioplayer(hum, 4*Fs));

%% Mono
yAnalys = yLeft + (yRight .* -1);

%% Spela ljud
yAnalys = yAnalys / max(abs(yAnalys));

%% Functions
function y = compress(y)
    for i=1:length(y)
        abso = max(abs(y(i,1)), abs(y(i,2)));
        y(i,1) = y(i,1) * (2 - abso);
        y(i,2) = y(i,2) * (2 - abso);
    end
end

function yNew = dist(y, distLevel)
    yNew = (distLevel*y)./(1+distLevel*abs(y));
end