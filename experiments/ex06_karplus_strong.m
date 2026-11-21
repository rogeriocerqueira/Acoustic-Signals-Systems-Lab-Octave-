function res = ex06_karplus_strong(cfg)
  ## EX06  Ressíntese por Karplus-Strong calibrado pela gravação.
  ##
  ## Pergunta: um sistema LTI com realimentação de poucos parâmetros
  ## consegue imitar a nota gravada? Onde ele falha?
  res = new_result('ex06', 'Ressíntese com Karplus-Strong', ...
    'Um filtro recursivo com 4 parâmetros (f0, T60, brilho, posição) consegue imitar a nota gravada? Onde ele falha?');
  [x, fs] = load_mono(cfg, cfg.files.note);
  a = cfg.analysis;
  seg = segment(x, fs, a.steady_start, a.steady_len);
  f0  = yin_f0(seg, fs, a.f0_min, a.f0_max, a.yin_threshold);
  h   = find_harmonics(seg, fs, f0, 10);
  fit = fit_inharmonicity(h.n(h.valid), h.freq(h.valid));
  f0  = fit.f0;
  dec = harmonic_decay(x, fs, f0, f0);
  T60 = dec.T60(1);
  dur = numel(x)/fs;

  ## calibração do brilho: escolhe o valor cujo centroide mais se aproxima
  c_ref = spectral_centroid(seg, fs);
  best = inf;
  for br = cfg.ks.brightness_grid
    o = struct('T60', T60, 'beta', cfg.ks.beta, 'brightness', br);
    y = karplus_strong(f0, fs, dur, o);
    e = abs(log2(spectral_centroid(segment(y, fs, a.steady_start, a.steady_len), fs) / c_ref));
    if e < best, best = e; br_best = br; end
  end
  [y, info] = karplus_strong(f0, fs, dur, struct('T60', T60, 'beta', cfg.ks.beta, 'brightness', br_best));
  [y_int, info_int] = karplus_strong(f0, fs, dur, struct('T60', T60, 'beta', cfg.ks.beta, ...
                                     'brightness', br_best, 'fractional', false));
  ys = segment(y, fs, a.steady_start, a.steady_len);
  f_frac = yin_f0(ys, fs, a.f0_min, a.f0_max, a.yin_threshold);
  f_int  = yin_f0(segment(y_int, fs, a.steady_start, a.steady_len), fs, a.f0_min, a.f0_max, a.yin_threshold);
  dks = harmonic_decay(y, fs, f0, f0);

  ## erro de timbre: diferença RMS (dB) entre as amplitudes dos 10 primeiros harmônicos
  hk = find_harmonics(ys, fs, f0, 10);
  ar = h.amp_db(1:10) - max(h.amp_db(1:10));
  ak = hk.amp_db(1:10) - max(hk.amp_db(1:10));
  harm_err = sqrt(mean((ar - ak).^2));

  ## a afinação com atraso inteiro piora em notas agudas: teste em Mi5 (659 Hz)
  fh = 659.26;
  yh1 = karplus_strong(fh, fs, 1, struct('T60', 1, 'fractional', true));
  yh0 = karplus_strong(fh, fs, 1, struct('T60', 1, 'fractional', false));
  eh1 = 1200*log2(yin_f0(segment(yh1, fs, 0.1, 0.3), fs, 200, 2000, 0.12)/fh);
  eh0 = 1200*log2(yin_f0(segment(yh0, fs, 0.1, 0.3), fs, 200, 2000, 0.12)/fh);

  fig = new_fig(cfg, 'ex06 KS', [1100 750]);
  subplot(2,2,1); plot_spectrogram(x, fs, cfg, 3000); title('Gravação');
  subplot(2,2,2); plot_spectrogram(y, fs, cfg, 3000); title('Karplus-Strong');
  subplot(2,2,3);
  bar(1:10, [h.amp_db(1:10) - max(h.amp_db), hk.amp_db(1:10) - max(hk.amp_db)]);
  grid on; xlabel('Harmônico'); ylabel('dB (rel. ao maior)');
  legend('gravação', 'KS', 'location', 'southwest'); title('Amplitudes harmônicas');
  subplot(2,2,4);
  [Hk, w] = freqz(info.b, info.a, 2^16, fs);
  plot(w, db(Hk) - max(db(Hk)), 'b'); xlim([0 8*f0]); ylim([-60 3]); grid on;
  xlabel('Frequência (Hz)'); ylabel('|H| (dB)');
  title(sprintf('|H(e^{j\\omega})| do KS: pente com picos em k*f0 (L = %d, C = %.3f)', info.L, info.C));
  res.figures{end+1} = save_fig(cfg, fig, 'ex06_karplus_strong');

  save_audio(cfg, 'ex06_original.wav', x, fs);
  save_audio(cfg, 'ex06_karplus_strong.wav', y, fs);
  save_audio(cfg, 'ex06_karplus_strong_sem_allpass.wav', y_int, fs);
  res.audio = {'ex06_original.wav', 'ex06_karplus_strong.wav', 'ex06_karplus_strong_sem_allpass.wav'};

  res = add_metric(res, 'f0 alvo', f0, '%.3f Hz');
  res = add_metric(res, 'Ganho do laço g', info.g, '%.6f', sprintf('para T60 = %.2f s', T60));
  res = add_metric(res, 'Brilho escolhido', br_best, '%.2f', 'por busca no centroide');
  res = add_metric(res, 'Erro de afinação COM passa-tudo', 1200*log2(f_frac/f0), '%+.2f cents');
  res = add_metric(res, 'Erro de afinação SEM passa-tudo', 1200*log2(f_int/f0), '%+.2f cents', ...
                   'atraso inteiro: limitação clássica');
  res = add_metric(res, 'T60 gravação / KS', sprintf('%.2f s / %.2f s', T60, dks.T60(1)));
  res = add_metric(res, 'Mi5 (659 Hz): erro com / sem passa-tudo', sprintf('%+.2f / %+.2f cents', eh1, eh0), ...
                   'notas agudas = períodos curtos = erro maior');
  res = add_metric(res, 'Erro de timbre (10 harmônicos)', harm_err, '%.1f dB RMS', 'menor = mais parecido');
  res.notes{end+1} = ['O KS gera parciais EXATAMENTE harmônicos (sem inarmonicidade) e todos com a mesma ' ...
    'lei de perdas do filtro (1+z^-1)/2. Extensão natural: filtro passa-tudo de dispersão no laço para simular B.'];
end
