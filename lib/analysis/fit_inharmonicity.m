function fit = fit_inharmonicity(n, fn)
  ## FIT_INHARMONICITY  Ajusta o modelo de corda rígida aos parciais medidos.
  ##
  ##   fit = fit_inharmonicity(n, fn)
  ##
  ## Uma corda real tem rigidez à flexão, então seus parciais seguem
  ##     f_n = n * f0 * sqrt(1 + B n^2)            (Fletcher, 1964)
  ## Elevando ao quadrado e dividindo por n^2:
  ##     (f_n / n)^2 = f0^2 + (f0^2 B) * n^2
  ## que é uma RETA em n^2. Logo f0 e B saem de mínimos quadrados lineares.
  ##
  ## Campos: f0, B, r2 (coef. de determinação), cents (desvio de cada parcial
  ## em relação à série harmônica ideal n*f0), n, fn.
  n = n(:); fn = fn(:);
  ok = isfinite(fn);
  n = n(ok); fn = fn(ok);
  y = (fn ./ n).^2;
  X = [ones(size(n)), n.^2];
  c = X \ y;
  fit.f0 = sqrt(c(1));
  fit.B  = c(2) / c(1);
  yhat = X * c;
  fit.r2 = 1 - sum((y - yhat).^2) / sum((y - mean(y)).^2);
  fit.n  = n;  fit.fn = fn;
  fit.cents = 1200 * log2(fn ./ (n * fit.f0));
end
