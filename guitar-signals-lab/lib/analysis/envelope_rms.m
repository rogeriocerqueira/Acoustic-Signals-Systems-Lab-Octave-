function [env, t] = envelope_rms(x, fs, win_ms)
  ## ENVELOPE_RMS  Envoltória RMS com janela deslizante de win_ms milissegundos.
  if nargin < 3, win_ms = 10; end
  L = max(1, round(win_ms*1e-3*fs));
  env = sqrt(filter(ones(L,1)/L, 1, x(:).^2));
  env = [env(ceil(L/2):end); repmat(env(end), ceil(L/2)-1, 1)];   % compensa atraso
  t = (0:numel(env)-1)' / fs;
end
