function ensure_dir(d)
  ## ENSURE_DIR  Cria a pasta d se ela ainda não existir.
  if ~exist(d, 'dir')
    mkdir(d);
  end
end
