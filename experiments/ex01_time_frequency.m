function res = ex01_time_frequency(cfg)
  ## EX01  Tempo, envoltória, espectro e espectrograma de uma nota.
  ##
  ## Pergunta: como a mesma nota aparece nos domínios do tempo, da
  ## frequência e tempo-frequência, e o que cada visão revela?
  res = new_result('ex01', 'Tempo, frequência e tempo-frequência', ...
    'Como a mesma nota aparece em cada domínio, e o que cada visão revela que as outras escondem?');
  [x, fs] = load_mono(cfg, cfg.files.note);
  t = (0:numel(x)-1)'/fs;
  [env, te] = envelope_rms(x, fs, 10);
  [t_att, t10, t90] = attack_time(env, fs);
  seg = segment(x, fs, cfg.analysis.steady_start, cfg.analysis.steady_len);
  f0 = yin_f0(seg, fs, cfg.analysis.f0_min, cfg.analysis.f0_max, cfg.analysis.yin_threshold);

  fig = new_fig(cfg, 'ex01 tempo', [1000 700]);
  subplot(3,1,1);
  plot(t, x, 'Color', [0.6 0.6 0.6]); hold on;
  plot(te, env*sqrt(2), 'r', 'LineWidth', 1.5); plot(te, -env*sqrt(2), 'r', 'LineWidth', 1.5);
  grid on; xlabel('Tempo (s)'); ylabel('Amplitude');
  title('Forma de onda e envoltória RMS (x 1.41)'); legend('x[n]', 'envoltória');
  subplot(3,1,2);
  i0 = round((cfg.analysis.steady_start)*fs);  i1 = i0 + round(5*fs/f0);
  plot(t(i0:i1)*1e3, x(i0:i1), 'b'); grid on;
  xlabel('Tempo (ms)'); ylabel('Amplitude');
  title(sprintf('Zoom: 5 períodos (T = 1/f0 = %.2f ms)', 1e3/f0));
  subplot(3,1,3);
  plot(te*1e3, 20*log10(env + 1e-9), 'k'); hold on;
  plot([t10 t10]*1e3, ylim, 'g--'); plot([t90 t90]*1e3, ylim, 'm--');
  xlim([0 100]); grid on; xlabel('Tempo (ms)'); ylabel('Nível (dB)');
  title(sprintf('Ataque: %.1f ms (10%% -> 90%%)', t_att*1e3));
  res.figures{end+1} = save_fig(cfg, fig, 'ex01_time');

  fig = new_fig(cfg, 'ex01 espectro');
  subplot(1,2,1);
  plot_spectrum(seg, fs, 'b'); hold on;
  for n = 1:10, plot(n*f0*[1 1], [-140 10], 'r:'); end
  ylim([-120 10]); title('Espectro do trecho estável (linhas: n*f0)');
  subplot(1,2,2);
  plot_spectrogram(x, fs, cfg, 4000); title('Espectrograma (STFT)');
  res.figures{end+1} = save_fig(cfg, fig, 'ex01_spectrum');

  [note, cents] = freq_to_note(f0, cfg.guitar.a4_hz);
  res = add_metric(res, 'Duração', numel(x)/fs, '%.2f s');
  res = add_metric(res, 'Pico', 20*log10(max(abs(x))), '%.1f dBFS');
  res = add_metric(res, 'RMS', 20*log10(sqrt(mean(x.^2))), '%.1f dBFS');
  res = add_metric(res, 'Fator de crista', 20*log10(max(abs(x))/sqrt(mean(x.^2))), '%.1f dB', ...
                   'pico/RMS: sinais percussivos têm crista alta');
  res = add_metric(res, 'Tempo de ataque (10-90%)', t_att*1e3, '%.1f ms');
  res = add_metric(res, 'f0 (YIN)', f0, '%.2f Hz');
  res = add_metric(res, 'Nota mais próxima', sprintf('%s (%+.1f cents)', note, cents));
  res = add_metric(res, 'Centroide espectral', spectral_centroid(seg, fs), '%.0f Hz', 'correlato de "brilho"');
end
