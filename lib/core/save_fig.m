function name = save_fig(cfg, fig, name)
  ## SAVE_FIG  Salva a figura como results/figures/<name>.png.
  path = fullfile(cfg.fig_dir, [name '.png']);
  print(fig, path, '-dpng', sprintf('-r%d', cfg.fig_dpi));
  printf('    > figura: results/figures/%s.png\n', name);
  if ~cfg.show_figures
    close(fig);
  end
end
