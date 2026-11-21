function [f0, aperiodicity, cmndf] = yin_f0(x, fs, fmin, fmax, thr)
  ## YIN_F0  Estima a frequência fundamental de um quadro com o algoritmo YIN.
  ##
  ##   [f0, ap] = yin_f0(x, fs, fmin, fmax, thr)
  ##
  ## Referência: de Cheveigné & Kawahara (2002), "YIN, a fundamental
  ## frequency estimator for speech and music", JASA 111(4).
  ##
  ## Passos:
  ##  1) Função diferença  d(tau) = sum_j (x_j - x_{j+tau})^2
  ##     Calculada em O(N log N) expandindo o quadrado:
  ##       d(tau) = E0 + E(tau) - 2 r(tau)
  ##     com r(tau) = correlação cruzada (via FFT) e E por somas acumuladas.
  ##  2) Diferença média cumulativa normalizada (CMNDF):
  ##       d'(tau) = d(tau) * tau / sum_{k=1..tau} d(k),   d'(0) = 1
  ##  3) Primeiro tau com d'(tau) < thr, refinado até o mínimo local.
  ##  4) Interpolação parabólica -> período fracionário.
  ##
  ## f0 = NaN se o quadro não for periódico o suficiente.
  ## aperiodicity = d'(tau*): perto de 0 = muito periódico, perto de 1 = ruído.
  if nargin < 5, thr = 0.12; end
  x = x(:);
  tau_min = max(2, floor(fs / fmax));
  tau_max = ceil(fs / fmin);
  W = numel(x) - tau_max - 1;
  if W < tau_max
    error('yin_f0: quadro curto demais (%d amostras) para fmin = %g Hz.', numel(x), fmin);
  end

  ## --- 1) função diferença via FFT
  nfft = 2^nextpow2(W + tau_max + 1);
  r = real(ifft(fft(x(1:W+tau_max+1), nfft) .* conj(fft(x(1:W), nfft))));
  r = r(1:tau_max+1);                       % lags 0..tau_max
  cs = [0; cumsum(x.^2)];
  E0 = cs(W+1);                             % sum x(1:W).^2
  tau = (0:tau_max)';
  Et = cs(tau + W + 1) - cs(tau + 1);       % sum x(1+tau : W+tau).^2
  d  = max(E0 + Et - 2*r, 0);

  ## --- 2) CMNDF
  cmndf = ones(size(d));
  csd = cumsum(d(2:end));
  cmndf(2:end) = d(2:end) .* tau(2:end) ./ max(csd, eps);

  ## --- 3) limiar absoluto + descida ao mínimo local
  k = [];
  for i = (tau_min+1):(tau_max)            % índice i <-> tau = i-1
    if cmndf(i) < thr
      while i < tau_max && cmndf(i+1) < cmndf(i)
        i = i + 1;
      end
      k = i;
      break;
    end
  end
  if isempty(k)
    [aperiodicity, k] = min(cmndf(tau_min+1:tau_max));
    k = k + tau_min;
    if aperiodicity > 0.35                 % sem periodicidade confiável
      f0 = NaN;
      return;
    end
  end
  aperiodicity = cmndf(k);

  ## --- 4) interpolação parabólica em torno de k
  if k > 1 && k < numel(cmndf)
    a = cmndf(k-1); b = cmndf(k); c = cmndf(k+1);
    den = a - 2*b + c;
    p = 0;
    if abs(den) > eps, p = 0.5 * (a - c) / den; end
  else
    p = 0;
  end
  period = (k - 1) + p;
  f0 = fs / period;
end
