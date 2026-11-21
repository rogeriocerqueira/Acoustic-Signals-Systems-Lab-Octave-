function res = ex02_lti_filters(cfg)
  ## EX02  Filtros LTI (Butterworth LP/HP/BP): resposta, polos/zeros, fase.
  ##
  ## Pergunta: o que um filtro faz com o timbre, e qual o custo de fase
  ## de um filtro causal (filter) comparado ao de fase zero (filtfilt)?
  res = new_result('ex02', 'Filtros LTI e timbre', ...
    'Como filtros Butterworth mudam o timbre, e qual a diferença prática entre filtragem causal (filter) e de fase zero (filtfilt)?');
  [x, fs] = load_mono(cfg, cfg.files.note);
  F = cfg.filters;  ny = fs/2;
  specs = { 'LP', F.lp_hz,  'low';
            'HP', F.hp_hz,  'high';
            'BP', F.bp_hz,  'bandpass' };
  nf = 8192;
  fig  = new_fig(cfg, 'ex02 respostas', [1100 750]);
  fig2 = new_fig(cfg, 'ex02 polos e zeros', [1100 380]);
  c0 = spectral_centroid(x, fs);
  res = add_metric(res, 'Centroide original', c0, '%.0f Hz');
  cols = {'b', 'r', [0 0.6 0]};
  for i = 1:size(specs,1)
    [lab, fc, typ] = specs{i,:};
    if strcmp(typ, 'bandpass')
      [b, a] = butter(F.order, fc/ny);
    else
      [b, a] = butter(F.order, fc/ny, typ);
    end
    [H, w] = freqz(b, a, nf, fs);
    ph = unwrap(angle(H));
    gd = -diff(ph) ./ diff(2*pi*w) * fs;       % atraso de grupo (amostras)

    figure(fig);
    subplot(3,1,1); semilogx(w, db(H), 'Color', cols{i}, 'LineWidth', 1.3); hold on;
    subplot(3,1,2); semilogx(w, ph/pi, 'Color', cols{i}); hold on;
    subplot(3,1,3); semilogx(w(2:end), gd/fs*1e3, 'Color', cols{i}); hold on;

    figure(fig2); subplot(1,3,i);
    zplane(b, a); title(sprintf('%s (ordem %d)', lab, numel(a)-1));

    ## frequências de -3 dB medidas na resposta (confere o projeto)
    m = db(H);  s = sign(m + 3.0103);  idx = find(diff(s) ~= 0);
    fc_meas = arrayfun(@(k) interp1(m(k:k+1), w(k:k+1), -3.0103), idx);

    ## atraso de grupo no centro da banda passante (filter); filtfilt = 0
    f_pass = struct('low', fc/4, 'high', 4*fc, 'bandpass', sqrt(prod(fc)));
    fp = f_pass.(typ);
    gd_fp = interp1(w(2:end), gd, fp);
    gd_max = max(gd(w(2:end) > 20));
    y_z = filtfilt(b, a, x);
    save_audio(cfg, sprintf('ex02_%s.wav', lower(lab)), y_z, fs);
    res.audio{end+1} = sprintf('ex02_%s.wav', lower(lab));

    res = add_metric(res, sprintf('%s: -3 dB projetado', lab), sprintf('%s Hz', mat2str(fc)));
    res = add_metric(res, sprintf('%s: -3 dB medido', lab), sprintf('%s Hz', mat2str(round(fc_meas(:)'))));
    res = add_metric(res, sprintf('%s: centroide após filtrar', lab), spectral_centroid(y_z, fs), '%.0f Hz');
    res = add_metric(res, sprintf('%s: atraso de grupo em %.0f Hz', lab, fp), 1e3*gd_fp/fs, '%.2f ms', ...
                     'com filter(); com filtfilt() é 0');
    res = add_metric(res, sprintf('%s: atraso de grupo máximo', lab), 1e3*gd_max/fs, '%.2f ms', ...
                     'ocorre perto do(s) corte(s)');
  end
  figure(fig);
  subplot(3,1,1); grid on; ylim([-60 5]); xlim([20 ny]); ylabel('|H| (dB)');
  title('Resposta em magnitude'); legend('LP', 'HP', 'BP', 'location', 'southwest');
  subplot(3,1,2); grid on; xlim([20 ny]); ylabel('Fase (\times\pi rad)'); title('Fase (desenrolada)');
  subplot(3,1,3); grid on; xlim([20 ny]); ylim([0 15]); ylabel('ms'); xlabel('Frequência (Hz)');
  title('Atraso de grupo  \tau_g = -d\phi/d\omega');
  res.figures{end+1} = save_fig(cfg, fig, 'ex02_responses');
  res.figures{end+1} = save_fig(cfg, fig2, 'ex02_pole_zero');
end
