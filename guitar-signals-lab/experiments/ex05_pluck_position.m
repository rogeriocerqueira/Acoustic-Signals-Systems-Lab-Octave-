function res = ex05_pluck_position(cfg)
  ## EX05  Posição da palhetada como filtro pente.
  ##
  ## Pergunta: dá para descobrir, só pelo áudio, onde a corda foi tocada?
  res = new_result('ex05', 'Onde a corda foi palhetada?', ...
    'Só pelo espectro, dá para estimar a que distância da ponte a corda foi palhetada?');
  a = cfg.analysis;
  files = {cfg.files.note_bridge, 'perto da ponte'; cfg.files.note_neck, 'perto do braço'};
  fig = new_fig(cfg, 'ex05 posição', [1100 700]);
  for i = 1:2
    [x, fs] = load_mono(cfg, files{i,1});
    seg = segment(x, fs, a.early_start, a.early_len);
    f0  = yin_f0(seg, fs, a.f0_min, a.f0_max, a.yin_threshold);
    h   = find_harmonics(seg, fs, f0, 30);
    est = fit_pluck_position(h);
    cm  = est.beta * cfg.guitar.scale_length_cm;

    subplot(2,2,i);
    stem(est.n, est.measured_db, 'k', 'filled'); hold on;
    plot(est.n, est.model_db, 'r-o', 'LineWidth', 1.2);
    for k = 1:floor(max(est.n)*est.beta)
      plot(k/est.beta*[1 1], [-45 5], 'b:');
    end
    ylim([-45 5]); grid on; xlabel('Harmônico n'); ylabel('dB (comp. 1/n)');
    title(sprintf('%s: \\beta = %.3f  (%.1f cm)', files{i,2}, est.beta, cm));
    legend('medido', 'modelo |sin(n\pi\beta)|', 'location', 'southwest');
    subplot(2,2,2+i);
    plot(est.grid, est.cost_curve, 'k'); hold on;
    plot(est.beta, est.cost, 'ro', 'MarkerFaceColor', 'r');
    grid on; xlabel('\beta (fração da corda a partir da ponte)'); ylabel('Erro (dB^2)');
    title('Função custo');

    res = add_metric(res, sprintf('%s: beta', files{i,2}), est.beta, '%.3f');
    res = add_metric(res, sprintf('%s: distância da ponte', files{i,2}), cm, '%.1f cm', ...
                     sprintf('escala de %.1f cm', cfg.guitar.scale_length_cm));
    res = add_metric(res, sprintf('%s: harmônicos "apagados"', files{i,2}), ...
                     sprintf('n = %s', mat2str(round((1:3)/est.beta))), 'múltiplos de 1/beta');
    res = add_metric(res, sprintf('%s: centroide', files{i,2}), spectral_centroid(seg, fs), '%.0f Hz');
  end
  res.figures{end+1} = save_fig(cfg, fig, 'ex05_pluck_position');
  res.notes{end+1} = ['Em guitarra elétrica, a posição do CAPTADOR cria um segundo filtro pente ' ...
    'com a mesma forma. O ajuste então mistura os dois; use DI de violão ou microfone para isolar a palhetada.'];
end
