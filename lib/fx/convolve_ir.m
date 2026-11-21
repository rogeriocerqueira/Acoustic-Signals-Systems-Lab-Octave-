function y = convolve_ir(x, ir)
  ## CONVOLVE_IR  Aplica uma resposta ao impulso (caixa, sala) por convolução.
  ##
  ##   y = convolve_ir(x, ir)
  ##
  ## Um sistema LTI fica totalmente descrito por sua resposta ao impulso h[n]:
  ##   y[n] = (x * h)[n] = sum_k h[k] x[n-k]
  ## Usa fftfilt (overlap-add com FFT), que custa O(N log M) por amostra em vez
  ## de O(M) da convolução direta. A saída inclui a "cauda" de length(ir)-1.
  x = x(:);  ir = ir(:);
  y = fftfilt(ir, [x; zeros(numel(ir)-1, 1)]);
end
