function est = fit_pluck_position(h)
  ## FIT_PLUCK_POSITION  Estima onde a corda foi palhetada a partir dos harmônicos.
  ##
  ##   est = fit_pluck_position(h)      % h vindo de find_harmonics
  ##
  ## Modelo (corda ideal palhetada na fração beta do comprimento, medida a
  ## partir da ponte, captação proporcional à velocidade):
  ##     A_n  ∝  |sin(n*pi*beta)| / n
  ## O fator sin() é um FILTRO PENTE: zera os harmônicos com n*beta inteiro.
  ## Ex.: beta = 1/4 -> faltam os harmônicos 4, 8, 12...
  ##
  ## Compensamos o 1/n, normalizamos e procuramos o beta (grade fina) que
  ## minimiza o erro quadrático em dB, com ganho livre e saturação em -40 dB
  ## (o fundo de um "notch" real é limitado pelo ruído).
  ok = isfinite(h.amp_db);
  n  = h.n(ok);
  m  = h.amp_db(ok) + 20*log10(n);
  m  = max(m - max(m), -40);
  grid = 0.03:0.0005:0.5;
  cost = zeros(size(grid));
  for i = 1:numel(grid)
    model = max(20*log10(abs(sin(n*pi*grid(i))) + 1e-6), -40);
    c = mean(m - model);
    cost(i) = mean((m - model - c).^2);
  end
  [est.cost, k] = min(cost);
  est.beta = grid(k);
  est.grid = grid;  est.cost_curve = cost;
  est.n = n;  est.measured_db = m;
  model = max(20*log10(abs(sin(n*pi*est.beta)) + 1e-6), -40);
  est.model_db = model + mean(m - model);
end
