function y = db(x)
  ## DB  Magnitude linear -> decibéis, com piso em -240 dB para evitar log(0).
  y = 20*log10(max(abs(x), 1e-12));
end
