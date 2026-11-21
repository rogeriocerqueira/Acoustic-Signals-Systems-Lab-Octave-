function y = waveshaper(x, drive, type, os)
  ## WAVESHAPER  Distorção sem memória y = f(x), com sobreamostragem opcional.
  ##
  ##   y = waveshaper(x, drive, 'tanh', 8)
  ##
  ## Tipos:
  ##   'hard'  clipping rígido      y = clip(drive x, -1, 1)
  ##   'tanh'  saturação suave       y = tanh(drive x)
  ##   'asym'  saturação assimétrica y = tanh(drive (x + b)) - tanh(drive b)
  ##           (a assimetria gera harmônicos PARES, típico de válvula)
  ##
  ## Por que sobreamostrar? Uma não-linearidade cria harmônicos acima de fs/2.
  ## Em tempo discreto eles não "somem": dobram (aliasing) para frequências
  ## que NÃO são múltiplas de f0, soando ásperas. Subindo a taxa por os,
  ## distorcendo e filtrando antes de voltar (resample faz os dois filtros
  ## anti-imagem/anti-alias), a maior parte desses harmônicos é removida.
  if nargin < 3, type = 'tanh'; end
  if nargin < 4, os = 1; end
  x = x(:);
  N = numel(x);
  if os > 1
    xu = resample(x, os, 1);
  else
    xu = x;
  end
  switch type
    case 'hard'
      yu = max(min(drive*xu, 1), -1);
    case 'tanh'
      yu = tanh(drive*xu) / tanh(drive);
    case 'asym'
      bias = 0.25;
      yu = tanh(drive*(xu + bias)) - tanh(drive*bias);
      yu = yu - mean(yu);                        % remove DC criado pela assimetria
    otherwise
      error('waveshaper: tipo desconhecido "%s".', type);
  end
  if os > 1
    y = resample(yu, 1, os);
  else
    y = yu;
  end
  y = y(1:N);
end
