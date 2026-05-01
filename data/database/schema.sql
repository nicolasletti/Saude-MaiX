-- ============================================================
-- SCHEMA: Sistema de Triagem para Síndrome do X Frágil (SXF)
-- Projeto de Extensão | PUCPR / IBK
-- ============================================================

-- ============================================================
-- TABELA: usuarios
-- Profissionais de saúde que utilizam o sistema
-- ============================================================
CREATE TABLE usuarios (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(150)        NOT NULL,
    email           VARCHAR(150)        NOT NULL UNIQUE,
    senha_hash      VARCHAR(255)        NOT NULL,
    crm_crf         VARCHAR(30)         NULL COMMENT 'Registro profissional (CRM, CRF, etc.)',
    cargo           ENUM(
                        'medico',
                        'enfermeiro',
                        'neurologista',
                        'geneticista',
                        'outro'
                    )                   NOT NULL DEFAULT 'outro',
    ativo           TINYINT(1)          NOT NULL DEFAULT 1,
    criado_em       DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- TABELA: responsaveis
-- Responsáveis legais pelos pacientes (pais, tutores, etc.)
-- ============================================================
CREATE TABLE responsaveis (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(150)        NOT NULL,
    parentesco      ENUM(
                        'pai',
                        'mae',
                        'tutor',
                        'outro'
                    )                   NOT NULL DEFAULT 'outro',
    telefone        VARCHAR(20)         NULL,
    email           VARCHAR(150)        NULL,
    criado_em       DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TABELA: pacientes
-- Indivíduos avaliados pelo checklist de triagem
-- ============================================================
CREATE TABLE pacientes (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(150)        NOT NULL,
    data_nascimento DATE                NOT NULL,
    sexo            ENUM('M', 'F')      NOT NULL COMMENT 'M = masculino, F = feminino',
    responsavel_id  INT                 NULL,
    usuario_id      INT                 NOT NULL COMMENT 'Profissional que cadastrou',
    observacoes     TEXT                NULL,
    criado_em       DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_paciente_responsavel
        FOREIGN KEY (responsavel_id) REFERENCES responsaveis(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_paciente_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
        ON DELETE RESTRICT
);

-- ============================================================
-- TABELA: sintomas
-- Catálogo dos 12 sintomas clínicos do checklist validado
-- Pesos derivados do Random Forest (artigo IBK)
-- ============================================================
CREATE TABLE sintomas (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    codigo          VARCHAR(30)         NOT NULL UNIQUE COMMENT 'Identificador único do sintoma',
    descricao       VARCHAR(200)        NOT NULL,
    peso_masculino  DECIMAL(5,4)        NOT NULL COMMENT 'Peso para score em pacientes masculinos',
    peso_feminino   DECIMAL(5,4)        NULL     COMMENT 'NULL = não aplicável (ex: macroorquidismo)',
    aplicavel_sexo  ENUM('M', 'F', 'MF') NOT NULL DEFAULT 'MF' COMMENT 'MF = ambos',
    ordem_exibicao  TINYINT UNSIGNED    NOT NULL DEFAULT 0
);

-- ============================================================
-- Dados: 12 sintomas com pesos validados (AUC > 0,70)
-- Fonte: Tabela do slide 7 da apresentação
-- ============================================================
INSERT INTO sintomas
    (codigo, descricao, peso_masculino, peso_feminino, aplicavel_sexo, ordem_exibicao)
VALUES
    ('deficiencia_intelectual',   'Deficiência intelectual',                        0.32,   0.20,   'MF', 1),
    ('face_alongada_orelhas',     'Face alongada / orelhas de abano',               0.29,   0.09,   'MF', 2),
    ('macroorquidismo',           'Macroorquidismo',                                0.26,   NULL,   'M',  3),
    ('hipermobilidade_articular', 'Hipermobilidade articular',                      0.19,   0.04,   'MF', 4),
    ('dificuldades_aprendizagem', 'Dificuldades de aprendizagem',                   0.18,   0.28,   'MF', 5),
    ('deficit_atencao',           'Déficit de atenção',                             0.17,   0.12,   'MF', 6),
    ('mov_repetitivos',           'Movimentos repetitivos',                         0.17,   0.05,   'MF', 7),
    ('atraso_fala',               'Atraso na fala',                                 0.14,   0.01,   'MF', 8),
    ('hiperatividade',            'Hiperatividade',                                 0.12,   0.04,   'MF', 9),
    ('evita_contato_visual',      'Evita contato visual',                           0.06,   0.08,   'MF', 10),
    ('evita_contato_fisico',      'Evita contato físico',                           0.04,   0.07,   'MF', 11),
    ('agressividade',             'Agressividade',                                  0.01,   0.02,   'MF', 12);

-- ============================================================
-- TABELA: avaliacoes
-- Cada aplicação do checklist a um paciente
-- ============================================================
CREATE TABLE avaliacoes (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id         INT             NOT NULL,
    usuario_id          INT             NOT NULL COMMENT 'Profissional que realizou a avaliação',

    -- Score calculado
    score               DECIMAL(6,4)    NOT NULL COMMENT 'Score = Σ (peso_j × X_ij)',
    limiar              DECIMAL(6,4)    NOT NULL COMMENT 'Limiar: 0.56 (M) ou 0.55 (F)',
    recomendacao        ENUM(
                            'encaminhar_teste_genetico',
                            'monitorar',
                            'nao_indicado'
                        )               NOT NULL,

    -- Metadados clínicos
    idade_na_avaliacao  TINYINT UNSIGNED NOT NULL COMMENT 'Idade do paciente em anos na data da avaliação',
    observacoes         TEXT            NULL,
    data_avaliacao      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_avaliacao_paciente
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_avaliacao_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
        ON DELETE RESTRICT
);

-- ============================================================
-- TABELA: avaliacao_sintomas
-- Respostas binárias (presente/ausente) por avaliação
-- ============================================================
CREATE TABLE avaliacao_sintomas (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    avaliacao_id    INT             NOT NULL,
    sintoma_id      INT             NOT NULL,
    presente        TINYINT(1)      NOT NULL COMMENT '1 = presente, 0 = ausente',
    peso_aplicado   DECIMAL(5,4)    NOT NULL COMMENT 'Peso efetivo usado no cálculo do score',

    CONSTRAINT fk_avs_avaliacao
        FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_avs_sintoma
        FOREIGN KEY (sintoma_id) REFERENCES sintomas(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_avaliacao_sintoma
        UNIQUE (avaliacao_id, sintoma_id)
);

-- ============================================================
-- ÍNDICES de performance para consultas frequentes
-- ============================================================
CREATE INDEX idx_pacientes_usuario    ON pacientes (usuario_id);
CREATE INDEX idx_pacientes_sexo       ON pacientes (sexo);
CREATE INDEX idx_avaliacoes_paciente  ON avaliacoes (paciente_id);
CREATE INDEX idx_avaliacoes_usuario   ON avaliacoes (usuario_id);
CREATE INDEX idx_avaliacoes_data      ON avaliacoes (data_avaliacao);
CREATE INDEX idx_avaliacoes_rec       ON avaliacoes (recomendacao);
CREATE INDEX idx_avs_avaliacao        ON avaliacao_sintomas (avaliacao_id);

