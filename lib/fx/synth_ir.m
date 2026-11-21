function ir = synth_ir(fs, kind, len_s, seed)
  ## SYNTH_IR  Respostas ao impulso sintéticas para testes.
  ##
  ##   ir = synth_ir(fs, 'cab')          % caixa 1x12" aproximada (~50 ms)
  ##   ir = synth_ir(fs, 'room', 1.0)    % "sala": ruído com decaimento exponencial
  ##
  ## 'cab': ruído com decaimento rápido, passa-faixa ~80 Hz-5 kHz (cone do
  ##        alto-falante) e um pico de presença em ~2.5 kHz.
  ## 'room': ruído branco * exp(-6.9 t / RT60), levemente escurecido.
  if nargin < 4, seed = 3; end
  randn('seed', seed);
  switch kind
    case 'cab'
      if nargin < 3, len_s = 0.05; end
      N = round(len_s*fs);  t = (0:N-1)'/fs;
      ir = randn(N,1) .* exp(-t/0.004);
      [b, a] = butter(2, [80 5000]/(fs/2));
      ir = filter(b, a, ir);
      [b, a] = butter(4, 5500/(fs/2));
      ir = filter(b, a, ir);
      ir = peaking_eq(ir, fs, 2500, 6, 1.2);
      ir = peaking_eq(ir, fs, 120, 4, 1.5);
    case 'room'
      if nargin < 3, len_s = 1.0; end
      N = round(len_s*fs);  t = (0:N-1)'/fs;
      ir = randn(N,1) .* exp(-log(1000)*t/(0.8*len_s));
      ir = filter(0.6, [1 -0.4], ir);
      ir(1) = max(abs(ir)) * 2;                 % som direto
    otherwise
      error('synth_ir: tipo desconhecido "%s".', kind);
  end
  ir = ir / max(abs(ir));
end

function y = peaking_eq(x, fs, f0, gain_db, Q)
  ## Equalizador paramétrico (biquad "peaking", RBJ Audio EQ Cookbook).
  A  = 10^(gain_db/40);  w0 = 2*pi*f0/fs;  al = sin(w0)/(2*Q);
  b = [1 + al*A, -2*cos(w0), 1 - al*A];
  a = [1 + al/A, -2*cos(w0), 1 - al/A];
  y = filter(b/a(1), a/a(1), x);
end
