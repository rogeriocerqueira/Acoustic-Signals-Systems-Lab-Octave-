function [x, fs] = load_mono(cfg, name)
  ## LOAD_MONO  Lê audio/<name>, converte para mono e remove o nível DC.
  ##
  ##   [x, fs] = load_mono(cfg, cfg.files.note)
  path = fullfile(cfg.audio_dir, name);
  if ~exist(path, 'file')
    error('Arquivo não encontrado: %s\nRode tools/generate_test_signals ou coloque seu WAV em audio/.', path);
  end
  [x, fs] = audioread(path);
  if size(x, 2) > 1
    x = mean(x, 2);
  end
  x = x(:) - mean(x);
end
