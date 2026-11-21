function [S, f, t] = stft_frames(x, fs, win_len, hop, nfft)
  ## STFT_FRAMES  Transformada de Fourier de tempo curto (implementação explícita).
  ##
  ##   [S, f, t] = stft_frames(x, fs, win_len, hop, nfft)
  ##
  ## S : K x M (complexo), K = nfft/2+1 bins, M quadros
  ## f : frequências (Hz) de cada linha;  t : instante central de cada quadro (s)
  ##
  ## Cada coluna é FFT{ x[n + m*hop] * w[n] }. Escrita à mão de propósito,
  ## para que o algoritmo fique visível no relatório.
  if nargin < 5, nfft = 2^nextpow2(win_len); end
  x = x(:);
  if numel(x) < win_len
    x(end+1:win_len) = 0;
  end
  M   = 1 + floor((numel(x) - win_len) / hop);
  idx = (1:win_len)' + (0:M-1) * hop;      % matriz de índices (broadcasting)
  frames = x(idx) .* hann_win(win_len);
  S = fft(frames, nfft);
  S = S(1:floor(nfft/2)+1, :);
  f = (0:size(S,1)-1)' * fs / nfft;
  t = ((0:M-1) * hop + win_len/2) / fs;
end
