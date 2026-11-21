function dec = harmonic_decay(x, fs, f0, freqs)
  ## HARMONIC_DECAY  Mede o tempo de decaimento T60 de cada parcial.
  ##
  ##   dec = harmonic_decay(x, fs, f0, freqs)
  ##
  ## Para cada frequência em freqs, acompanha o nível (dB) do bin mais forte
  ## numa faixa de +-f0/4 ao longo da STFT, e ajusta uma reta ao trecho de
  ## decaimento (do pico -3 dB até ~40 dB abaixo, sem encostar no ruído).
  ## Decaimento exponencial = reta em dB, e:
  ##     T60 = -60 / inclinação   [s]
  ##
  ## Campos: T60 (s), slope (dB/s), track (nível dB, nh x M), t (s),
  ##         fit_range (índices inicial/final do ajuste por parcial).
  win = 2^nextpow2(round(8 * fs / f0));     % ~8 períodos: separa harmônicos
  hop = round(win / 8);
  [S, f, t] = stft_frames(x, fs, win, hop, 2*win);
  Sdb = db(abs(S) / (sum(hann_win(win))/2));
  nh = numel(freqs);
  dec.T60 = nan(nh,1); dec.slope = nan(nh,1);
  dec.track = nan(nh, numel(t)); dec.t = t; dec.fit_range = nan(nh,2);
  for i = 1:nh
    if ~isfinite(freqs(i)), continue; end
    band = abs(f - freqs(i)) <= f0/4;
    tr = max(Sdb(band, :), [], 1);
    dec.track(i,:) = tr;
    [pk, ipk] = max(tr);
    noise = prctile(tr, 5);
    stop_db = max(pk - 40, noise + 10);
    i0 = ipk;
    while i0 < numel(tr) && tr(i0) > pk - 3, i0++; end
    i1 = i0;
    while i1 < numel(tr) && tr(i1) > stop_db, i1++; end
    if i1 - i0 < 5, continue; end
    p = polyfit(t(i0:i1), tr(i0:i1), 1);
    dec.slope(i) = p(1);
    if p(1) < 0, dec.T60(i) = -60 / p(1); end
    dec.fit_range(i,:) = [i0 i1];
  end
end
