function res = ex04_decay(cfg)
  ## EX04  Decaimento de cada parcial (T60).
  ##
  ## Pergunta: todos os harmônicos morrem juntos? Como o T60 varia com a
  ## frequência, e o que isso diz sobre as perdas na corda?
  res = new_result('ex04', 'Decaimento dos parciais (T60)', ...
    'Todos os harmônicos morrem juntos? Como o tempo de decaimento T60 varia com a frequência?');
  [x, fs] = load_mono(cfg, cfg.files.note);
  a = cfg.analysis;
  seg = segment(x, fs, a.steady_start, a.steady_len);
  f0 = yin_f0(seg, fs, a.f0_min, a.f0_max, a.yin_threshold);
  h  = find_harmonics(seg, fs, f0, min(a.n_harmonics, 15));
  dec = harmonic_decay(x, fs, f0, h.freq);

  fig = new_fig(cfg, 'ex04 decaimento', [1100 500]);
  subplot(1,2,1); hold on;
  show = [1 2 3 5 8 12];  show = show(show <= numel(h.freq));
  cmap = jet(numel(show));
  leg = {};
  for k = 1:numel(show)
    i = show(k);
    plot(dec.t, dec.track(i,:), 'Color', cmap(k,:));
    leg{end+1} = sprintf('n=%d', i);
  end
  for k = 1:numel(show)
    i = show(k);
    if isfinite(dec.T60(i))
      r = dec.fit_range(i,1):dec.fit_range(i,2);
      p = polyfit(dec.t(r), dec.track(i,r), 1);
      plot(dec.t(r), polyval(p, dec.t(r)), 'k--', 'LineWidth', 1.2);
    end
  end
  grid on; xlabel('Tempo (s)'); ylabel('Nível (dB)');
  title('Nível de cada parcial (tracejado: ajuste linear em dB)'); legend(leg);
  subplot(1,2,2);
  ok = isfinite(dec.T60);
  plot(h.freq(ok), dec.T60(ok), 'ko-', 'MarkerFaceColor', 'k');
  grid on; xlabel('Frequência do parcial (Hz)'); ylabel('T60 (s)');
  title('T60 vs. frequência');
  res.figures{end+1} = save_fig(cfg, fig, 'ex04_decay');

  res = add_metric(res, 'T60 fundamental', dec.T60(1), '%.2f s');
  for n = [2 5 10]
    if n <= numel(dec.T60), res = add_metric(res, sprintf('T60 harmônico %d', n), dec.T60(n), '%.2f s'); end
  end
  k = find(ok, 1, 'last');
  res = add_metric(res, sprintf('Razão T60(1)/T60(%d)', k), dec.T60(1)/dec.T60(k), '%.2f', ...
                   '>1: agudos decaem mais rápido');
end
