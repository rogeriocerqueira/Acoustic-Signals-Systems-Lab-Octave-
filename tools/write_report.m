function write_report(cfg, results)
  ## WRITE_REPORT  Gera results/REPORT.md com perguntas, métricas, figuras e áudios.
  p = fullfile(cfg.results_dir, 'REPORT.md');
  fid = fopen(p, 'w');
  fprintf(fid, '# Relatório: Guitar Signals Lab\n\n');
  fprintf(fid, 'Gerado automaticamente por `run_all` em %s.\n\n', datestr(now, 'yyyy-mm-dd HH:MM'));
  fprintf(fid, '| # | Experimento | Tempo |\n|---|---|---|\n');
  for i = 1:numel(results)
    r = results{i};
    fprintf(fid, '| %s | [%s](#%s) | %.1f s |\n', r.id, r.title, r.id, r.elapsed);
  end
  fprintf(fid, '\n');
  for i = 1:numel(results)
    r = results{i};
    fprintf(fid, '---\n\n<a id="%s"></a>\n## %s: %s\n\n', r.id, upper(r.id), r.title);
    if ~isempty(r.question), fprintf(fid, '> **Pergunta:** %s\n\n', r.question); end
    if ~isempty(r.metrics)
      fprintf(fid, '| Métrica | Valor | Observação |\n|---|---|---|\n');
      for j = 1:size(r.metrics, 1)
        fprintf(fid, '| %s | %s | %s |\n', r.metrics{j, :});
      end
      fprintf(fid, '\n');
    end
    for j = 1:numel(r.notes), fprintf(fid, '_Nota:_ %s\n\n', r.notes{j}); end
    for j = 1:numel(r.figures), fprintf(fid, '![%s](figures/%s.png)\n\n', r.figures{j}, r.figures{j}); end
    if ~isempty(r.audio)
      fprintf(fid, '**Áudios:** %s\n\n', strjoin(cellfun(@(a) sprintf('[`%s`](audio/%s)', a, a), ...
              r.audio, 'UniformOutput', false), ' · '));
    end
  end
  fclose(fid);
end
