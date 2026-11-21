function h = find_harmonics(x, fs, f0, nh)
  ## FIND_HARMONICS  Localiza os nh primeiros parciais de uma nota.
  ##
  ##   h = find_harmonics(x, fs, f0, nh)
  ##
  ## Retorna struct com campos:
  ##   n       índice do harmônico (1..nh)
  ##   freq    frequência medida (Hz), com interpolação parabólica
  ##   amp_db  amplitude do pico (dB, 0 dB = senoide de amplitude 1)
  ##   valid   true se o pico se destaca do piso de ruído
  ##   spec_f, spec_db  espectro usado (para plotar)
  ##
  ## Em cordas reais os parciais NÃO estão em n*f0 exatos (inarmonicidade),
  ## então a busca é adaptativa: a posição prevista do parcial n é
  ## extrapolada a partir dos parciais n-1 e n-2 já encontrados.
  x = x(:);
  N = numel(x);
  nfft = 4 * 2^nextpow2(N);                 % zero-padding 4x -> picos mais finos
  [X, f] = rfft_mag(x, fs, nfft);
  Xdb = db(X);
  df  = fs / nfft;
  floor_db = median(Xdb) + 12;              % piso de ruído + margem

  h.n = (1:nh)'; h.freq = nan(nh,1); h.amp_db = nan(nh,1); h.valid = false(nh,1);
  est = nan(nh,1);                          % posição usada para extrapolar
  for n = 1:nh
    if n == 1
      pred = f0;
    elseif n == 2
      pred = 2 * est(1);
    else
      pred = est(n-1) + (est(n-1) - est(n-2));
    end
    lo = pred - 0.25*f0;  hi = pred + 0.25*f0;
    if hi > 0.95 * fs/2, break; end
    i_lo = max(2, floor(lo/df) + 1);  i_hi = min(numel(X)-1, ceil(hi/df) + 1);
    [~, k] = max(Xdb(i_lo:i_hi));  k = k + i_lo - 1;
    a = Xdb(k-1); b = Xdb(k); c = Xdb(k+1);
    den = a - 2*b + c;
    p = 0; if abs(den) > eps, p = 0.5*(a - c)/den; end
    fk = (k - 1 + p) * df;
    ak = b - 0.25*(a - c)*p;
    h.freq(n) = fk;  h.amp_db(n) = ak;
    h.valid(n) = ak > floor_db;
    if h.valid(n), est(n) = fk; else, est(n) = pred; end
  end
  h.spec_f = f;  h.spec_db = Xdb;
end
