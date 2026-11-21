## ============================================================
## Guitar / Acoustic Signals & Systems Lab (Octave)
## Autor: Rogério Cerqueira
## Requisitos: Octave 7+ e pkg 'signal'
## Como usar:
##  1) Defina os arquivos WAV nas variáveis abaixo.
##  2) Rode:  pkg load signal;  run('guitar_signals_lab.m')
## ============================================================

clear; close all; clc;
pkg load signal;                  % carrega butter, filtfilt, spectrogram, resample

## ---------------------- ARQUIVOS ENTRADA --------------------
## Grave/coloque seus áudios na pasta do script
file_note   = 'nota_a4.wav';      % guitarra/violão DI ou microfonado
file_riff   = 'riff.wav';         % um trecho com palhetadas
file_di     = 'gtr_DI.wav';       % DI bem limpo (para usar com IR)
file_ir     = 'cab_IR.wav';       % impulse response de caixa/sala (mono ou stereo)

## ----------------- Funções utilitárias locais ----------------
db = @(x) 20*log10(max(abs(x), 1e-12));     % magnitude -> dB (proteção de log)
normsig = @(x) x ./ max(1, max(abs(x)));    % normaliza [-1,1] sem explodir

function [X,f] = rfft_mag(x,fs)
  N = numel(x);
  win = hann(N);
  Xc = fft(x(:) .* win);
  K = floor(N/2)+1;
  X = abs(Xc(1:K)) / (sum(win)/2);  % compensação da janela p/ amplitude
  f = (0:K-1)*(fs/N);
end

function plot_time(x,fs,ttl)
  t = (0:numel(x)-1)/fs;
  plot(t, x); grid on;
  xlabel('Tempo (s)'); ylabel('Amplitude'); title(ttl);
end

function plot_fft(x,fs,ttl)
  [Xmag, f] = rfft_mag(x,fs);
  semilogx(f, db(Xmag)); grid on;
  xlim([20 fs/2]); ylim([-140 10]);
  xlabel('Frequência (Hz)'); ylabel('Magnitude (dB)'); title(ttl);
end

function niceaudio_write(name, y, fs)
  y = y(:);
  y = y ./ max(1, 1.05*max(abs(y)));  % headroom
  audiowrite(name, y, fs);
  printf('> Arquivo salvo: %s (%.2f s, fs=%d)\n', name, numel(y)/fs, fs);
end

## ============================================================
## 1) Carregar sinal principal e visualizar no tempo/FFT
## ============================================================
printf('\n[1] Tempo e FFT...\n');
[x, fs] = audioread(file_note);
if (size(x,2) > 1), x = mean(x,2); end
x = x(:);
N = numel(x);

figure('name','Tempo - nota');
plot_time(x,fs,'Nota - domínio do tempo');

figure('name','FFT - nota');
plot_fft(x,fs,'Nota - magnitude (dB)');

## ============================================================
## 2) Espectrograma (STFT)
## ============================================================
printf('[2] Espectrograma...\n');
wlen = round(0.040*fs);          % 40 ms
over = round(0.75*wlen);
nfft = 2^nextpow2(wlen);

[S,F,T] = spectrogram(x, hann(wlen), over, nfft, fs);
figure('name','Espectrograma - nota');
imagesc(T, F, 20*log10(abs(S)+1e-12)); axis xy;
xlabel('Tempo (s)'); ylabel('Hz'); title('Espectrograma (dB)');
c = colorbar; ylabel(c,'dB'); ylim([0 fs/2]);

## ============================================================
## 3) Filtros LTI: LP / HP / BP e resposta em frequência
## ============================================================
printf('[3] Filtros LTI (LP/HP/BP) e respostas...\n');
fc_lp = 3000;   % corte passa-baixa (~efeito cabo/captador)
fc_hp = 120;    % remove grave muito baixo
fc1 = 700; fc2 = 3500

