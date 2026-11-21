function r_db = inharmonic_ratio(y, fs, f0)
  ## INHARMONIC_RATIO  Potência FORA da série harmônica de f0, relativa à de dentro (dB).
  ##
  ## Para uma senoide distorcida sem aliasing, toda a energia está em k*f0.
  ## O que cai entre os harmônicos é (quase só) aliasing. Quanto mais
  ## negativo, mais limpo.
  [X, f] = rfft_mag(y, fs);
  P  = X.^2;
  df = fs / numel(y);
  k  = round(f / f0);
  harm = (k >= 1) & (abs(f - k*f0) <= 4*df);
  dc   = f < f0/2;
  r_db = 10*log10(sum(P(~harm & ~dc)) / sum(P(harm)));
end
