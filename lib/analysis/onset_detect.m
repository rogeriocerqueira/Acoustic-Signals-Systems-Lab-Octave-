function [onsets, novelty, t, peak_idx] = onset_detect(x, fs, min_gap_s)
  ## ONSET_DETECT  Detecta ataques de notas por fluxo espectral.
  ##
  ##   onsets = onset_detect(x, fs)       % instantes em segundos
  ##
  ## Fluxo espectral: soma, sobre as frequências, dos AUMENTOS de log-magnitude
  ## entre quadros consecutivos (retificação de meia onda). Um ataque injeta
  ## energia nova em muitas frequências ao mesmo tempo -> pico na novidade.
  ## Picos são aceitos acima de um limiar adaptativo (mediana móvel + delta).
  if nargin < 3, min_gap_s = 0.06; end
  win = 2^nextpow2(round(0.023*fs));  hop = round(win/4);
  [S, ~, t] = stft_frames(x, fs, win, hop);
  L = log1p(100 * abs(S));
  flux = sum(max(diff(L, 1, 2), 0), 1);
  novelty = [0, flux] / max(flux + eps);
  thr = movmedian(novelty, 15) + 0.08;
  gap = max(1, round(min_gap_s * fs / hop));
  onsets = []; peak_idx = [];
  last = -inf;
  for m = 2:numel(novelty)-1
    if novelty(m) > thr(m) && novelty(m) >= novelty(m-1) && novelty(m) > novelty(m+1) ...
       && (m - last) >= gap
      onsets(end+1) = t(m) - win/(2*fs);      % compensa centro da janela
      peak_idx(end+1) = m;
      last = m;
    end
  end
end
