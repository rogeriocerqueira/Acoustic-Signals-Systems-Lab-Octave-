function [y, info] = karplus_strong(f0, fs, dur, opts)
  ## KARPLUS_STRONG  Corda dedilhada pelo algoritmo de Karplus-Strong estendido.
  ##
  ##   [y, info] = karplus_strong(110, 48000, 3, struct('T60', 3))
  ##
  ## O algoritmo é um sistema LTI com realimentação:
  ##
  ##   x[n] --(+)------------------------------------------> y[n]
  ##           ^                                     |
  ##           |   g * Hlp(z) * Hap(z) * z^-L  <-----+
  ##
  ##   Hlp(z) = (1 + z^-1)/2               passa-baixa: perdas dependentes da freq.
  ##   Hap(z) = (C + z^-1)/(1 + C z^-1)    passa-tudo: atraso FRACIONÁRIO (afinação)
  ##   g                                   ganho do laço (< 1): controla o T60
  ##
  ##   H(z) = 1 / (1 - g Hlp Hap z^-L)
  ##
  ## Multiplicando numerador e denominador por (1 + C z^-1), H(z) vira uma
  ## razão de polinômios e a síntese inteira é UMA chamada a filter(b, a, x).
  ##
  ## Afinação: atraso total do laço em baixas freq. = L + 0.5 + d, onde d é o
  ## atraso do passa-tudo. Queremos L + 0.5 + d = fs/f0.
  ## Perdas: a cada período o fundamental é multiplicado por g*cos(pi f0/fs);
  ## impondo queda de 60 dB em T60 segundos:
  ##   g = 10^(-3/(f0*T60)) / cos(pi f0/fs)
  ##
  ## opts: T60 (s), beta (posição da palhetada), brightness (0..1, filtra a
  ##       excitação), fractional (true = usa passa-tudo), seed
  if nargin < 4, opts = struct(); end
  d = struct('T60', 3, 'beta', 0.15, 'brightness', 0.7, 'fractional', true, 'seed', 7);
  fn = fieldnames(d);
  for i = 1:numel(fn)
    if ~isfield(opts, fn{i}), opts.(fn{i}) = d.(fn{i}); end
  end
  randn('seed', opts.seed);

  P = fs / f0;                                   % período desejado (amostras)
  g = min(10^(-3/(f0*opts.T60)) / cos(pi*f0/fs), 0.99999);

  if opts.fractional
    Ntot = P - 0.5;                              % parte a cargo de z^-L e Hap
    L = floor(Ntot);  dfrac = Ntot - L;
    if dfrac < 0.1, L -= 1; dfrac += 1; end      % mantém C longe de 1 (estável e plano)
    C = (1 - dfrac) / (1 + dfrac);
    b = [1 C];
    a = zeros(1, L+3);  a(1) = 1;  a(2) = C;
    a(L+1:L+3) -= g * 0.5 * [C, 1 + C, 1];       % (1+z^-1)(C+z^-1) = C + (1+C)z^-1 + z^-2
  else
    L = round(P - 0.5);  C = 0;  dfrac = 0;
    b = 1;
    a = zeros(1, L+2);  a(1) = 1;
    a(L+1:L+2) -= g * 0.5 * [1 1];
  end

  ## excitação: um período de ruído, filtrado (brilho) e com pente (posição)
  Le = round(P);
  e  = randn(Le, 1);
  p  = 1 - opts.brightness;                      % polo do passa-baixa de 1a ordem
  e  = filter(1 - p, [1 -p], e);
  D  = max(1, round(opts.beta * P));
  e  = e - [zeros(D,1); e(1:end-D)];             % e[n] - e[n-D]: filtro pente
  e  = e - mean(e);

  x = [e; zeros(round(dur*fs) - Le, 1)];
  y = filter(b, a, x);
  y /= max(abs(y));

  info = struct('b', b, 'a', a, 'L', L, 'C', C, 'frac', dfrac, 'g', g, ...
                'loop_delay', L + 0.5 + dfrac, ...
                'opts', opts);
end
