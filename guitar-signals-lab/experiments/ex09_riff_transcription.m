function res = ex09_riff_transcription(cfg)
  ## EX09  Transcrição simples de um riff: ataques + altura.
  ##
  ## Pergunta: combinando detecção de ataques e rastreamento de f0, dá para
  ## recuperar automaticamente as notas e o ritmo de um trecho tocado?
  res = new_result('ex09', 'Transcrição automática de um riff', ...
    'Combinando detecção de ataques (fluxo espectral) e rastreamento de f0 (YIN), dá para recuperar notas e ritmo de um trecho tocado?');
  [x, fs] = load_mono(cfg, cfg.files.riff);
  [on, nov, tn, pk] = onset_detect(x, fs);
  [f0, tp] = pitch_track(x, fs, cfg);

  ## nota de cada segmento = mediana do f0 entre ataques (ignora 30 ms iniciais)
  bounds = [on, numel(x)/fs];
  names = {}; freqs = [];
  for i = 1:numel(on)
    m = tp > bounds(i) + 0.03 & tp < bounds(i+1) - 0.01 & isfinite(f0);
    if any(m)
      freqs(end+1) = median(f0(m));
      names{end+1} = freq_to_note(freqs(end), cfg.guitar.a4_hz);
    else
      freqs(end+1) = NaN; names{end+1} = '?';
    end
  end

  fig = new_fig(cfg, 'ex09 riff', [1100 750]);
  subplot(3,1,1); plot((0:numel(x)-1)/fs, x, 'Color', [0.5 0.5 0.5]); hold on;
  for k = 1:numel(on), plot(on(k)*[1 1], [-1 1], 'r'); end
  grid on; ylabel('Amplitude'); title('Forma de onda e ataques detectados');
  subplot(3,1,2); plot(tn, nov, 'k'); hold on; plot(tn(pk), nov(pk), 'rv', 'MarkerFaceColor', 'r');
  grid on; ylabel('Novidade'); title('Função de fluxo espectral');
  subplot(3,1,3); plot_spectrogram(x, fs, cfg, 1000); hold on;
  plot(tp, f0, 'w.', 'MarkerSize', 8);
  for k = 1:numel(on)
    if isfinite(freqs(k)), text(on(k) + 0.02, min(950, 1.6*freqs(k)), names{k}, 'Color', 'w', 'FontWeight', 'bold'); end
  end
  title('Espectrograma + f0 (YIN) + notas transcritas');
  res.figures{end+1} = save_fig(cfg, fig, 'ex09_riff');

  ioi = diff(on);
  res = add_metric(res, 'Ataques detectados', numel(on), '%d');
  res = add_metric(res, 'Intervalo mediano entre ataques', median(ioi)*1e3, '%.0f ms');
  res = add_metric(res, 'Andamento (se colcheias)', 60/(2*median(ioi)), '%.0f BPM');
  res = add_metric(res, 'Notas transcritas', strjoin(names, ' '));

  ## comparação com o gabarito, se existir (sinais sintéticos)
  gt = read_ground_truth(cfg, cfg.files.riff);
  if ~isempty(gt)
    tol = 0.05;
    hit = arrayfun(@(t) any(abs(on - t) <= tol), gt);
    prec = sum(arrayfun(@(t) any(abs(gt - t) <= tol), on)) / max(numel(on), 1);
    rec  = mean(hit);
    res = add_metric(res, 'Precisão / revocação dos ataques (±50 ms)', ...
                     sprintf('%.0f%% / %.0f%%', 100*prec, 100*rec), 'vs. audio/ground_truth.txt');
  end
end

function on = read_ground_truth(cfg, name)
  on = [];
  p = fullfile(cfg.audio_dir, 'ground_truth.txt');
  if ~exist(p, 'file'), return; end
  txt = fileread(p);
  tok = regexp(txt, [regexptranslate('escape', name) ': onsets\(s\)=\[([^\]]*)\]'], 'tokens', 'once');
  if ~isempty(tok), on = str2num(tok{1}); end
end
