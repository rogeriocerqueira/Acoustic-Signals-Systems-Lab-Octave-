function c = spectral_centroid(x, fs)
  ## SPECTRAL_CENTROID  "Centro de massa" do espectro (Hz).
  ## Correlaciona bem com a percepção de brilho do timbre.
  [X, f] = rfft_mag(x, fs);
  P = X.^2;
  c = sum(f .* P) / max(sum(P), eps);
end
