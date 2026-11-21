function res = ex07_distortion_aliasing(cfg)
  ## EX07  Distorção não linear e aliasing.
  ##
  ## Pergunta: por que distorção digital "ingênua" soa áspera, e quanto a
  ## sobreamostragem resolve? De onde vêm os harmônicos pares?
  res = new_result('ex07', 'Distorção, aliasing e sobreamostragem', ...
    'Por que distorção digital ingênua soa áspera? Quanto a sobreamostragem melhora? De onde vêm os harmônicos pares?');
  fs = 48000;  d = cfg.fx.drive;
  t  = (0:fs-1)'/fs;                               % 1 s
  ft = cfg.fx.test_tone_hz;
  s  = 0.9*sin(2*pi*ft*t);

  ## (a) aliasing vs fator de sobreamostragem
  os_list = [1 2 4 8 16];
  r = zeros(size(os_list)); tt = zeros(size(os_list));
  for i = 1:numel(os_list)
    tic; y = waveshaper(s, d, 'hard', os_list(i)); tt(i) = toc;
    r(i) = inharmonic_ratio(y, fs, ft);
    res = add_metric(res, sprintf('Aliasing (hard clip) os=%dx', os_list(i)), r(i), '%.1f dB', ...
                     sprintf('tempo %.0f ms', 1e3*tt(i)));
  end
  y1 = waveshaper(s, d, 'hard', 1);
  y8 = waveshaper(s, d, 'hard', cfg.fx.oversample);

  fig = new_fig(cfg, 'ex07 aliasing', [1100 750]);
  subplot(2,2,1);
  xx = linspace(-1.5, 1.5, 600)';
  plot(xx, max(min(d*xx,1),-1), xx, tanh(d*xx)/tanh(d), ...
       xx, waveshaper(xx, d, 'asym', 1) / max(abs(waveshaper(xx, d, 'asym', 1))), 'LineWidth', 1.3);
  grid on; xlabel('entrada x'); ylabel('saída f(x)');
  legend('hard', 'tanh', 'asym (normalizada)', 'location', 'southeast'); title(sprintf('Curvas de transferência (drive = %g)', d));
  subplot(2,2,2);
  semilogx(os_list, r, 'ko-', 'MarkerFaceColor', 'k'); grid on;
  set(gca, 'xtick', os_list); xlabel('Fator de sobreamostragem'); ylabel('dB');
  title('Potência fora da série harmônica');
  subplot(2,1,2);
  [X1, f] = rfft_mag(y1, fs);  X8 = rfft_mag(y8, fs);
  plot(f, db(X1), 'Color', [0.85 0.3 0.3]); hold on; plot(f, db(X8), 'b');
  for k = 1:floor((fs/2)/ft), plot(k*ft*[1 1], [-150 10], 'k:'); end
  xlim([0 fs/2]); ylim([-140 5]); grid on; xlabel('Frequência (Hz)'); ylabel('dB');
  legend('sem sobreamostragem', sprintf('%dx', cfg.fx.oversample));
  title(sprintf('Senoide de %d Hz com clipping: tudo fora das linhas pontilhadas é aliasing', ft));
  res.figures{end+1} = save_fig(cfg, fig, 'ex07_aliasing');

  ## (b) harmônicos pares vs ímpares: simetria da curva
  s2 = 0.8*sin(2*pi*220*t);
  why = struct('tanh', 'curva simétrica => só ímpares', 'asym', 'curva assimétrica => surgem pares');
  for typ = {'tanh', 'asym'}
    y = waveshaper(s2, d, typ{1}, cfg.fx.oversample);
    h = find_harmonics(y, fs, 220, 10);
    P = 10.^(h.amp_db/10);
    eo = 10*log10(sum(P(2:2:end)) / sum(P(3:2:end)));
    res = add_metric(res, sprintf('Pares/ímpares (%s)', typ{1}), eo, '%.1f dB', why.(typ{1}));
  end

  ## (c) aplicado na guitarra
  [x, fsx] = load_mono(cfg, cfg.files.di);
  x = x / max(abs(x));
  save_audio(cfg, 'ex07_di.wav', x, fsx);
  save_audio(cfg, 'ex07_dist_sem_os.wav', waveshaper(x, d, cfg.fx.shaper, 1), fsx);
  save_audio(cfg, 'ex07_dist_com_os.wav', waveshaper(x, d, cfg.fx.shaper, cfg.fx.oversample), fsx);
  res.audio = {'ex07_di.wav', 'ex07_dist_sem_os.wav', 'ex07_dist_com_os.wav'};
end
