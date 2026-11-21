function [f0, t, ap, rms_db] = pitch_track(x, fs, cfg, win_s, hop_s)
  ## PITCH_TRACK  Rastreamento de f0 quadro a quadro (YIN em janelas deslizantes).
  ##
  ##   [f0, t] = pitch_track(x, fs, cfg)
  ##
  ## Quadros com energia baixa (silêncio) ou aperiódicos recebem NaN.
  if nargin < 4, win_s = 0.06; end
  if nargin < 5, hop_s = 0.01; end
  a = cfg.analysis;
  L   = max(round(win_s*fs), 2*ceil(fs/a.f0_min) + 2);
  hop = round(hop_s*fs);
  x = x(:);
  M = 1 + floor((numel(x) - L) / hop);
  f0 = nan(1, M); ap = ones(1, M); rms_db = zeros(1, M);
  gate = 20*log10(sqrt(mean(x.^2)) + eps) - 25;   % 25 dB abaixo do RMS global
  for m = 1:M
    fr = x((m-1)*hop + (1:L));
    rms_db(m) = 20*log10(sqrt(mean(fr.^2)) + eps);
    if rms_db(m) < gate, continue; end
    [f0(m), ap(m)] = yin_f0(fr, fs, a.f0_min, a.f0_max, a.yin_threshold);
  end
  t = ((0:M-1)*hop + L/2) / fs;
end
