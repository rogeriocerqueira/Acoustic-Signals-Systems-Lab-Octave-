function [X, f] = rfft_mag(x, fs, nfft)
  ## RFFT_MAG  Espectro de magnitude unilateral com janela de Hann.
  ##
  ##   [X, f] = rfft_mag(x, fs)         % nfft = numel(x)
  ##   [X, f] = rfft_mag(x, fs, nfft)   % zero-padding para interpolar o espectro
  ##
  ## A amplitude é compensada pelo ganho coerente da janela: uma senoide de
  ## amplitude A aparece com pico ~A (0 dB para A = 1).
  x = x(:);
  N = numel(x);
  if nargin < 3, nfft = N; end
  w  = hann_win(N);
  Xc = fft(x .* w, nfft);
  K  = floor(nfft/2) + 1;
  X  = abs(Xc(1:K)) / (sum(w)/2);
  f  = (0:K-1)' * fs / nfft;
end
