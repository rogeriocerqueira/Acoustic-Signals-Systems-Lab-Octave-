function results = run_all(which)
  ## RUN_ALL  Executa os experimentos e gera results/REPORT.md.
  ##
  ##   run_all            % todos
  ##   run_all([3 4 6])   % só alguns
  ##
  ## Pela linha de comando:
  ##   octave-cli --eval "run_all"
  cfg = setup_paths();
  graphics_toolkit_safe(cfg);

  if cfg.generate_if_missing
    generate_test_signals(cfg, false);
  end

  exps = { @ex01_time_frequency, @ex02_lti_filters, @ex03_harmonics_inharmonicity, ...
           @ex04_decay, @ex05_pluck_position, @ex06_karplus_strong, ...
           @ex07_distortion_aliasing, @ex08_cab_ir, @ex09_riff_transcription };
  if nargin < 1, which = 1:numel(exps); end

  results = {};
  t_all = tic;
  for k = which
    printf('\n[%02d] %s\n', k, func2str(exps{k}));
    t = tic;
    try
      r = exps{k}(cfg);
      r.elapsed = toc(t);
      results{end+1} = r;
    catch err
      printf('  !! falhou: %s\n', err.message);
      r = new_result(sprintf('ex%02d', k), func2str(exps{k}), '');
      r.notes{end+1} = ['ERRO: ' err.message];
      r.elapsed = toc(t);
      results{end+1} = r;
    end
  end
  write_report(cfg, results);
  printf('\nConcluído em %.1f s. Relatório: results/REPORT.md\n', toc(t_all));
end

function graphics_toolkit_safe(cfg)
  ## Sem display (servidor/CI), usa gnuplot para salvar PNGs.
  if ~cfg.show_figures && isempty(getenv('DISPLAY')) && any(strcmp(available_graphics_toolkits(), 'gnuplot'))
    graphics_toolkit('gnuplot');
  end
end
