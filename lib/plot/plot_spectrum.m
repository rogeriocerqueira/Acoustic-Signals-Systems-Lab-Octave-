function plot_spectrum(x, fs, varargin)
  ## PLOT_SPECTRUM  Espectro de magnitude (dB) em eixo log nos eixos atuais.
  ##   plot_spectrum(x, fs, 'b-', 'LineWidth', 1)   % argumentos extras -> semilogx
  [X, f] = rfft_mag(x, fs);
  semilogx(f(2:end), db(X(2:end)), varargin{:});
  grid on; xlim([20 fs/2]);
  xlabel('Frequência (Hz)'); ylabel('Magnitude (dB)');
end
