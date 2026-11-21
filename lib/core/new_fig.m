function fig = new_fig(cfg, name, sz)
  ## NEW_FIG  Cria figura (visível ou não, conforme cfg.show_figures).
  if nargin < 3, sz = [1000 560]; end
  vis = 'off';
  if cfg.show_figures, vis = 'on'; end
  fig = figure('visible', vis, 'name', name, 'position', [80 80 sz]);
end
