function plot_spectrogram(x, fs, cfg, fmax, range_db)
  ## PLOT_SPECTROGRAM  Espectrograma em dB nos eixos atuais.
  if nargin < 4, fmax = min(8000, fs/2); end
  if nargin < 5, range_db = 90; end
  L   = round(cfg.analysis.stft_win_ms*1e-3*fs);
  hop = max(1, round(L*(1 - cfg.analysis.stft_overlap)));
  [S, f, t] = stft_frames(x, fs, L, hop, 2^nextpow2(L)*2);
  Sdb = db(abs(S));
  pk = max(Sdb(:));
  keep = f <= fmax;
  imagesc(t, f(keep), Sdb(keep,:), [pk - range_db, pk]);
  axis xy; ylim([0 fmax]); colormap(gca, 'jet');
  xlabel('Tempo (s)'); ylabel('Frequência (Hz)');
  cb = colorbar; ylabel(cb, 'dB');
end
