function cfg = lab_config()
  ## LAB_CONFIG  Parâmetros centrais do laboratório.
  ##
  ##   cfg = lab_config()
  ##
  ## Tudo que você talvez queira mudar (nomes de arquivo, janelas de análise,
  ## cortes de filtro, drive da distorção...) está aqui. Os experimentos
  ## não têm números "mágicos" internos: eles leem este struct.

  root = fileparts(fileparts(mfilename('fullpath')));

  ## ---------------------------------------------------------- caminhos
  cfg.root        = root;
  cfg.audio_dir   = fullfile(root, 'audio');
  cfg.results_dir = fullfile(root, 'results');
  cfg.fig_dir     = fullfile(cfg.results_dir, 'figures');
  cfg.out_dir     = fullfile(cfg.results_dir, 'audio');

  ## ---------------------------------------------------------- arquivos
  ## Coloque seus WAVs em audio/. Se algum faltar e generate_if_missing
  ## for true, tools/generate_test_signals.m cria versões sintéticas.
  cfg.files.note        = 'nota.wav';        % uma nota isolada (ex.: corda Lá solta)
  cfg.files.note_bridge = 'nota_ponte.wav';  % mesma nota, palhetada perto da ponte
  cfg.files.note_neck   = 'nota_braco.wav';  % mesma nota, palhetada perto do braço
  cfg.files.riff        = 'riff.wav';        % trecho com várias notas
  cfg.files.di          = 'gtr_DI.wav';      % sinal DI limpo (sem amp)
  cfg.files.ir          = 'cab_IR.wav';      % resposta ao impulso de caixa/sala
  cfg.generate_if_missing = true;

  ## ---------------------------------------------------------- execução
  cfg.show_figures = false;   % true = abre janelas; false = só salva PNG
  cfg.fig_dpi      = 110;

  ## ---------------------------------------------------------- violão/guitarra
  cfg.guitar.scale_length_cm = 64.8;   % escala (pestana -> rastilho)
  cfg.guitar.a4_hz           = 440;    % referência de afinação

  ## ---------------------------------------------------------- análise
  cfg.analysis.f0_min        = 60;     % Hz  (Mi grave ~82 Hz, com folga)
  cfg.analysis.f0_max        = 1400;   % Hz
  cfg.analysis.yin_threshold = 0.12;   % limiar da CMNDF no YIN
  cfg.analysis.stft_win_ms   = 40;     % janela do espectrograma
  cfg.analysis.stft_overlap  = 0.75;
  cfg.analysis.steady_start  = 0.15;   % s após o início: evita o transiente do ataque
  cfg.analysis.steady_len    = 0.50;   % s de trecho "estável" para análise harmônica
  cfg.analysis.early_start   = 0.03;   % s: janela curta logo após o ataque
  cfg.analysis.early_len     = 0.20;   %    (usada para posição da palhetada)
  cfg.analysis.n_harmonics   = 25;

  ## ---------------------------------------------------------- filtros LTI
  cfg.filters.order = 4;
  cfg.filters.lp_hz = 3000;          % ~ efeito de cabo longo / captador escuro
  cfg.filters.hp_hz = 120;           % remove grave excessivo
  cfg.filters.bp_hz = [700 3500];    % faixa de "presença"

  ## ---------------------------------------------------------- síntese (Karplus-Strong)
  cfg.ks.beta = 0.15;                % posição da palhetada (fração da corda)
  cfg.ks.brightness_grid = [0.02 0.05 0.1 0.2 0.35 0.5 0.65 0.8 0.95];

  ## ---------------------------------------------------------- distorção / IR
  cfg.fx.drive        = 6;
  cfg.fx.shaper       = 'asym';      % 'tanh' | 'hard' | 'asym'
  cfg.fx.oversample   = 8;
  cfg.fx.test_tone_hz = 2960;        % tom de teste p/ evidenciar aliasing
  cfg.fx.bench_ir_s   = [0.05 0.1 0.25 0.5];  % tamanhos de IR no benchmark
end
