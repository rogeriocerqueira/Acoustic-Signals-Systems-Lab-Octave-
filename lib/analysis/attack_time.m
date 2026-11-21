function [t_att, t10, t90] = attack_time(env, fs)
  ## ATTACK_TIME  Tempo de ataque 10% -> 90% do pico da envoltória (s).
  [pk, ipk] = max(env);
  i10 = find(env(1:ipk) >= 0.1*pk, 1);
  i90 = find(env(1:ipk) >= 0.9*pk, 1);
  t10 = (i10 - 1)/fs;  t90 = (i90 - 1)/fs;
  t_att = t90 - t10;
end
