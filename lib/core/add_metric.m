function res = add_metric(res, label, value, fmt, comment)
  ## ADD_METRIC  Acrescenta uma linha à tabela de métricas do experimento.
  ##   res = add_metric(res, 'f0 estimada', 110.02, '%.2f Hz')
  ##   res = add_metric(res, 'Nota', 'A2', 'comentário')   % valor já em texto
  if nargin < 4, fmt = '%g'; end
  if nargin < 5, comment = ''; end
  if ischar(value) && nargin == 4, comment = fmt; end
  if ischar(value), s = value; else, s = sprintf(fmt, value); end
  res.metrics(end+1, :) = {label, s, comment};
  printf('    %-38s %s\n', label, s);
end
