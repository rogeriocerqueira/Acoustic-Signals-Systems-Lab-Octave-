function cfg = setup_paths()
  ## SETUP_PATHS  Adiciona as pastas do projeto ao path, carrega o pacote
  ## 'signal' e cria as pastas de saída. Retorna a configuração.

  root = fileparts(mfilename('fullpath'));
  addpath(fullfile(root, 'config'));
  addpath(genpath(fullfile(root, 'lib')));
  addpath(fullfile(root, 'experiments'));
  addpath(fullfile(root, 'tools'));

  try
    pkg load signal;
  catch
    error(['Pacote "signal" não encontrado. Instale com:\n' ...
           '  pkg install -forge control signal']);
  end

  cfg = lab_config();
  ensure_dir(cfg.results_dir);
  ensure_dir(cfg.fig_dir);
  ensure_dir(cfg.out_dir);
end
