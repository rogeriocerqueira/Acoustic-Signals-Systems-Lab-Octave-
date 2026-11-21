function res = ex08_cab_ir(cfg)
  ## EX08  Simulação de caixa por convolução e custo computacional.
  ##
  ## Pergunta: um sistema LTI fica definido pela resposta ao impulso? Quanto
  ## a convolução por FFT economiza em relação à direta?
  res = new_result('ex08', 'Caixa por resposta ao impulso (convolução)', ...
    'Como uma resposta ao impulso substitui a caixa do amplificador, e quanto a convolução por FFT economiza em relação à direta?');
  [x, fs]  = load_mono(cfg, cfg.files.di);
  [ir, fsi] = load_mono(cfg, cfg.files.ir);
  if fsi ~= fs
    ir = resample(ir, fs, fsi);
    res.notes{end+1} = sprintf('IR reamostrada de %d para %d Hz.', fsi, fs);
  end
  x = x / max(abs(x));
  dist = waveshaper(x, cfg.fx.drive, cfg.fx.shaper, cfg.fx.oversample);
  y    = convolve_ir(dist, ir);

  ## resposta em frequência da caixa
  [Hir, w] = freqz(ir, 1, 8192, fs);
  fig = new_fig(cfg, 'ex08 IR', [1100 750]);
  subplot(2,2,1); plot((0:numel(ir)-1)/fs*1e3, ir); grid on;
  xlabel('Tempo (ms)'); ylabel('h[n]'); title(sprintf('Resposta ao impulso (%d amostras)', numel(ir)));
  subplot(2,2,2); semilogx(w, db(Hir) - max(db(Hir))); grid on; xlim([20 fs/2]); ylim([-50 3]);
  xlabel('Frequência (Hz)'); ylabel('dB'); title('|H(f)| da caixa = FFT de h[n]');
  subplot(2,2,3);
  plot_spectrum(dist, fs, 'Color', [0.8 0.3 0.3]); hold on; plot_spectrum(y, fs, 'b');
  ylim([-130 0]); legend('só distorção', 'distorção + caixa', 'location', 'southwest');
  title('Espectro médio');

  ## benchmark: conv direta vs FFT (overlap-add)
  xs = x(1:min(numel(x), fs));                    % 1 s de sinal
  Ls = cfg.fx.bench_ir_s;  td = zeros(size(Ls)); tf = td; err = td;
  for i = 1:numel(Ls)
    h = synth_ir(fs, 'room', Ls(i));
    tic; y1 = conv(xs, h);        td(i) = toc;
    tic; y2 = convolve_ir(xs, h); tf(i) = toc;
    err(i) = max(abs(y1 - y2)) / max(abs(y1));
    res = add_metric(res, sprintf('IR %.0f ms: direta / FFT', 1e3*Ls(i)), ...
                     sprintf('%.1f ms / %.1f ms', 1e3*td(i), 1e3*tf(i)), ...
                     sprintf('ganho %.0fx, erro relativo %.1e', td(i)/tf(i), err(i)));
  end
  subplot(2,2,4);
  loglog(Ls*1e3, td*1e3, 'ro-', Ls*1e3, tf*1e3, 'bo-', 'MarkerFaceColor', 'auto'); grid on;
  xlabel('Tamanho da IR (ms)'); ylabel('Tempo (ms) p/ 1 s de áudio');
  legend('conv direta O(NM)', 'fftfilt O(N log M)', 'location', 'northwest');
  title('Custo computacional');
  res.figures{end+1} = save_fig(cfg, fig, 'ex08_cab_ir');

  save_audio(cfg, 'ex08_dist_sem_caixa.wav', dist, fs);
  save_audio(cfg, 'ex08_dist_com_caixa.wav', y, fs);
  res.audio = {'ex08_dist_sem_caixa.wav', 'ex08_dist_com_caixa.wav'};
  hf = @(s) band_energy_db(s, fs, 6000);
  res = add_metric(res, 'Energia acima de 6 kHz: sem / com caixa', ...
                   sprintf('%.1f dB / %.1f dB', hf(dist), hf(y)), ...
                   'fração da energia total: o "chiado" que a caixa remove');
  res = add_metric(res, 'Centroide sem / com caixa', ...
                   sprintf('%.0f Hz / %.0f Hz', spectral_centroid(dist, fs), spectral_centroid(y, fs)), ...
                   'pode SUBIR: a caixa também corta o grave abaixo de ~80 Hz');
end

function e = band_energy_db(x, fs, fc)
  ## Fração (dB) da energia do sinal acima de fc.
  [X, f] = rfft_mag(x, fs);
  P = X.^2;
  e = 10*log10(sum(P(f >= fc)) / sum(P));
end
