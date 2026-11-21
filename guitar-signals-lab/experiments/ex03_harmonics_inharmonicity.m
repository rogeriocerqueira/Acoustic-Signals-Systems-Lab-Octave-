function res = ex03_harmonics_inharmonicity(cfg)
  ## EX03  Série harmônica, afinação e inarmonicidade da corda.
  ##
  ## Pergunta: os parciais de uma corda real são múltiplos inteiros de f0?
  ## Se não, quanto desviam, e o modelo de corda rígida explica o desvio?
  res = new_result('ex03', 'Harmônicos e inarmonicidade', ...
    'Os parciais de uma corda real são múltiplos exatos de f0? Quanto desviam, e o modelo de corda rígida f_n = n f0 sqrt(1+Bn^2) explica o desvio?');
  [x, fs] = load_mono(cfg, cfg.files.note);
  a = cfg.analysis;
  seg = segment(x, fs, a.steady_start, a.steady_len);
  f0_yin = yin_f0(seg, fs, a.f0_min, a.f0_max, a.yin_threshold);
  h = find_harmonics(seg, fs, f0_yin, a.n_harmonics);
  fit = fit_inharmonicity(h.n(h.valid), h.freq(h.valid));

  fig = new_fig(cfg, 'ex03 harmonicos', [1100 750]);
  subplot(2,1,1);
  plot(h.spec_f, h.spec_db, 'Color', [0.4 0.4 0.4]); hold on;
  v = h.valid;
  plot(h.freq(v), h.amp_db(v), 'rv', 'MarkerFaceColor', 'r');
  fmax = min(fs/2, 1.1*max(h.freq(v)));
  for n = 1:a.n_harmonics, plot(n*fit.f0*[1 1], [-130 0], 'b:'); end
  xlim([0 fmax]); ylim([-130 5]); grid on;
  xlabel('Frequência (Hz)'); ylabel('dB');
  title('Parciais encontrados (triângulos) vs. série harmônica ideal n*f0 (pontilhado)');
  subplot(2,2,3);
  nn = linspace(1, max(fit.n), 200);
  plot(fit.n, fit.cents, 'ko', 'MarkerFaceColor', 'k'); hold on;
  plot(nn, 1200*log2(sqrt(1 + fit.B*nn.^2)), 'r', 'LineWidth', 1.5);
  grid on; xlabel('Harmônico n'); ylabel('Desvio (cents)');
  title(sprintf('Desvio de n·f0  (B = %.2e)', fit.B));
  legend('medido', 'modelo', 'location', 'northwest');
  subplot(2,2,4);
  plot(fit.n.^2, (fit.fn./fit.n).^2, 'ko'); hold on;
  plot(fit.n.^2, fit.f0^2*(1 + fit.B*fit.n.^2), 'r', 'LineWidth', 1.5);
  grid on; xlabel('n^2'); ylabel('(f_n/n)^2  (Hz^2)');
  title(sprintf('Linearização: reta => modelo válido (R^2 = %.4f)', fit.r2));
  res.figures{end+1} = save_fig(cfg, fig, 'ex03_harmonics');

  [note, cents] = freq_to_note(fit.f0, cfg.guitar.a4_hz);
  res = add_metric(res, 'f0 (YIN, domínio do tempo)', f0_yin, '%.3f Hz');
  res = add_metric(res, 'f0 (ajuste dos parciais)', fit.f0, '%.3f Hz', 'mais robusto: usa todos os parciais');
  res = add_metric(res, 'Afinação', sprintf('%s %+.1f cents', note, cents));
  res = add_metric(res, 'Parciais válidos', sum(h.valid), '%d');
  res = add_metric(res, 'Coeficiente de inarmonicidade B', fit.B, '%.3e', 'cordas de violão: ~1e-5 a 1e-4');
  res = add_metric(res, 'R^2 do ajuste', fit.r2, '%.5f');
  res = add_metric(res, 'Desvio do maior parcial', fit.cents(end), '%+.1f cents', ...
                   sprintf('harmônico %d', fit.n(end)));
  res.notes{end+1} = sprintf(['O YIN mede o período da forma de onda inteira; como os parciais altos estão ' ...
    'esticados, ele pode ficar levemente acima do f0 do modelo (diferença aqui: %+.1f cents).'], ...
    1200*log2(f0_yin/fit.f0));
end
