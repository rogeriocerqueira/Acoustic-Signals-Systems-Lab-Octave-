function y = segment(x, fs, t0, len)
  ## SEGMENT  Recorta x entre t0 e t0+len segundos (limitado ao tamanho do sinal).
  i0 = max(1, round(t0*fs) + 1);
  i1 = min(numel(x), i0 + round(len*fs) - 1);
  y = x(i0:i1);
end
