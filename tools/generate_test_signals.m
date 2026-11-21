function generate_test_signals(cfg, force)
  ## GENERATE_TEST_SIGNALS  Cria WAVs sintéticos com parâmetros conhecidos.
  ##
  ##   generate_test_signals(cfg)          % só cria os que faltam
  ##   generate_test_signals(cfg, true)    % recria todos
  ##
  ## Serve para dois propósitos:
  ##  1) o projeto roda "de primeira", sem gravações;
  ##  2) VALIDAÇÃO: como sabemos f0, B, beta e T60 verdadeiros, dá para medir
  ##     o erro de cada algoritmo antes de confiar nele com áudio real.
  ## Os valores verdadeiros vão para audio/ground_truth.txt.
  if nargin < 2, force = false; end
  ensure_dir(cfg.audio_dir);
  fs = 48000;
  f  = cfg.files;
  gt = {};

  ## nota principal: Lá2 (corda Lá solta), 110 Hz
  p = struct('B', 1e-4, 'beta', 0.15, 'T60', 3.0, 'damping', 0.08, 'seed', 1);
  if want(cfg, f.note, force)
    write_wav(cfg, f.note, synth_plucked_string(110, fs, 3.0, p), fs);
  end
  gt{end+1} = sprintf('%s: f0=110 Hz, B=%.1e, beta=%.2f, T60(fund)=%.2f s, damping=%.2f', ...
                      f.note, p.B, p.beta, p.T60, p.damping);

  ## mesma nota em duas posições de palhetada
  pb = p; pb.beta = 0.08; pb.seed = 2;
  pn = p; pn.beta = 0.25; pn.seed = 3;
  if want(cfg, f.note_bridge, force)
    write_wav(cfg, f.note_bridge, synth_plucked_string(110, fs, 2.0, pb), fs);
  end
  if want(cfg, f.note_neck, force)
    write_wav(cfg, f.note_neck, synth_plucked_string(110, fs, 2.0, pn), fs);
  end
  gt{end+1} = sprintf('%s: beta=%.2f (%.1f cm da ponte)', f.note_bridge, pb.beta, pb.beta*cfg.guitar.scale_length_cm);
  gt{end+1} = sprintf('%s: beta=%.2f (%.1f cm da ponte)', f.note_neck,  pn.beta, pn.beta*cfg.guitar.scale_length_cm);

  ## riff: pentatônica de Mi menor, ~120 BPM em colcheias
  notes  = [82.41 98.00 110.00 123.47 146.83 164.81 146.83 123.47 110.00 98.00];
  step   = 0.25;
  onsets = 0.10 + (0:numel(notes)-1) * step;
  if want(cfg, f.riff, force) || want(cfg, f.di, force)
    dur = onsets(end) + 1.5;
    riff = zeros(round(dur*fs), 1);
    for i = 1:numel(notes)
      q = p; q.T60 = 1.5; q.seed = 10 + i; q.beta = 0.12 + 0.03*mod(i,3);
      len = (i < numel(notes)) * (step + 0.03) + (i == numel(notes)) * 1.4;
      y = synth_plucked_string(notes(i), fs, len, q);
      nf = round(0.02*fs);                       % abafamento ao trocar de nota
      y(end-nf+1:end) .*= linspace(1, 0, nf)';
      i0 = round(onsets(i)*fs) + 1;
      riff(i0:i0+numel(y)-1) += 0.7*y;
    end
    riff /= max(abs(riff));
    if want(cfg, f.riff, force), write_wav(cfg, f.riff, riff, fs); end
    if want(cfg, f.di,   force), write_wav(cfg, f.di,   0.8*riff, fs); end
  end
  gt{end+1} = sprintf('%s: onsets(s)=[%s]', f.riff, sprintf('%.3f ', onsets));
  gt{end+1} = sprintf('%s: notas(Hz)=[%s]', f.riff, sprintf('%.2f ', notes));

  ## IR de caixa
  if want(cfg, f.ir, force)
    write_wav(cfg, f.ir, synth_ir(fs, 'cab'), fs);
  end

  fid = fopen(fullfile(cfg.audio_dir, 'ground_truth.txt'), 'w');
  fprintf(fid, '# Valores verdadeiros dos sinais sintéticos (gerados por tools/generate_test_signals.m)\n');
  fprintf(fid, '%s\n', gt{:});
  fclose(fid);
end

function tf = want(cfg, name, force)
  tf = force || ~exist(fullfile(cfg.audio_dir, name), 'file');
end

function write_wav(cfg, name, y, fs)
  y = 0.9 * y(:) / max(abs(y));
  audiowrite(fullfile(cfg.audio_dir, name), y, fs, 'BitsPerSample', 24);
  printf('  [gerado] audio/%s\n', name);
end
