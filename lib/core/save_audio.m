function save_audio(cfg, name, y, fs)
  ## SAVE_AUDIO  Normaliza com ~0.4 dB de folga e grava em results/audio/.
  y = y(:);
  pk = max(abs(y));
  if pk > 0
    y = 0.95 * y / pk;
  end
  path = fullfile(cfg.out_dir, name);
  audiowrite(path, y, fs);
  printf('    > áudio: results/audio/%s (%.2f s)\n', name, numel(y)/fs);
end
