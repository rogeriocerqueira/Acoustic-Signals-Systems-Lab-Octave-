function [y, info] = synth_plucked_string(f0, fs, dur, opts)
  ## SYNTH_PLUCKED_STRING  Nota de corda palhetada por síntese aditiva "física".
  ##
  ##   y = synth_plucked_string(110, 48000, 3, struct('B', 1e-4, 'beta', 0.15))
  ##
  ## Usada para gerar sinais de teste com parâmetros CONHECIDOS (ground truth),
  ## o que permite validar os algoritmos de análise antes de usar gravações.
  ##
  ## Cada parcial n:
  ##   frequência  f_n  = n f0 sqrt(1 + B n^2)          (inarmonicidade)
  ##   amplitude   A_n  = sin(n pi beta) / n             (posição da palhetada)
  ##   decaimento  T60_n = T60 / (1 + damping (n-1))     (agudos morrem antes)
  ## mais um ataque curto, um "clique" de palheta filtrado e ruído de fundo.
  ##
  ## opts (todos opcionais): B, beta, T60, damping, attack_ms, pick_noise,
  ##                         noise_floor_db, max_partials, seed
  if nargin < 4, opts = struct(); end
  d = struct('B', 1e-4, 'beta', 0.15, 'T60', 3.0, 'damping', 0.08, ...
             'attack_ms', 2, 'pick_noise', 0.02, 'noise_floor_db', -75, ...
             'max_partials', 60, 'seed', 1);
  fn = fieldnames(d);
  for i = 1:numel(fn)
    if ~isfield(opts, fn{i}), opts.(fn{i}) = d.(fn{i}); end
  end
  randn('seed', opts.seed); rand('seed', opts.seed);

  N = round(dur*fs);
  t = (0:N-1)' / fs;
  y = zeros(N, 1);
  info.freqs = []; info.T60 = [];
  for n = 1:opts.max_partials
    f = n * f0 * sqrt(1 + opts.B * n^2);
    if f > 0.45*fs, break; end
    A = sin(n*pi*opts.beta) / n;
    T = opts.T60 / (1 + opts.damping*(n-1));
    y += A * sin(2*pi*f*t + 2*pi*rand()) .* exp(-log(1000) * t / T);
    info.freqs(end+1) = f; info.T60(end+1) = T;
  end
  y .*= 1 - exp(-t / (opts.attack_ms*1e-3));          % ataque suave
  nb = round(0.008*fs);                                % clique de palheta: 8 ms
  click = filter(1, [1 -0.6], randn(nb,1)) .* exp(-(0:nb-1)'/(0.0015*fs));
  y(1:nb) += opts.pick_noise * click / max(abs(click));
  y /= max(abs(y));
  y += 10^(opts.noise_floor_db/20) * randn(N, 1);
  info.opts = opts;
end
