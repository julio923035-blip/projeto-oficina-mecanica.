-- =====================================================
-- BANCO DE DADOS: OFICINA MECANICA
-- Sistema de gerenciamento de clientes, veiculos,
-- funcionarios, ordens de servico, pecas e pagamentos.
-- =====================================================

CREATE DATABASE IF NOT EXISTS oficina_mecanica;
USE oficina_mecanica;

-- Para executar novamente em um banco de testes, remova
-- primeiro as tabelas existentes na ordem inversa das dependencias.

-- 1. CLIENTES
CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    endereco VARCHAR(255) NOT NULL
);

-- 2. VEICULOS
-- Cada veiculo pertence a somente um cliente.
CREATE TABLE veiculo (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    placa VARCHAR(10) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    ano INT NOT NULL,
    cor VARCHAR(30) NOT NULL,
    id_cliente INT NOT NULL,
    CONSTRAINT uq_veiculo_cliente UNIQUE (id_veiculo, id_cliente),
    CONSTRAINT fk_veiculo_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_veiculo_ano CHECK (ano BETWEEN 1886 AND 2100)
);

-- 3. FUNCIONARIOS
-- O campo cargo pode receber: Mecanico, Auxiliar mecanico ou Atendente.
CREATE TABLE funcionario (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(20) NOT NULL,
    endereco VARCHAR(255) NOT NULL,
    data_contratacao DATE NOT NULL,
    cargo ENUM('Mecanico', 'Auxiliar mecanico', 'Atendente') NOT NULL
);

-- 4. MECANICOS
-- Tabela especializada: cada mecanico tambem e um funcionario.
CREATE TABLE mecanico (
    id_funcionario INT PRIMARY KEY,
    especialidade ENUM('Mecanica geral', 'Eletrica automotiva', 'Suspensao', 'Outra') NOT NULL,
    CONSTRAINT fk_mecanico_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 5. SERVICOS DISPONIVEIS
CREATE TABLE servico (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(150) NOT NULL,
    mao_de_obra DECIMAL(10,2) NOT NULL,
    tempo_estimado INT NOT NULL COMMENT 'Tempo estimado em minutos',
    CONSTRAINT chk_servico_valor CHECK (mao_de_obra >= 0),
    CONSTRAINT chk_servico_tempo CHECK (tempo_estimado > 0)
);

-- 6. PECAS E ESTOQUE
CREATE TABLE peca (
    id_peca INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(150) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    quantidade_estoque INT NOT NULL DEFAULT 0,
    estoque_minimo INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_peca_preco CHECK (preco_unitario >= 0),
    CONSTRAINT chk_peca_estoque CHECK (quantidade_estoque >= 0),
    CONSTRAINT chk_peca_minimo CHECK (estoque_minimo >= 0)
);

-- 7. ORDENS DE SERVICO
-- Cada ordem pertence a um cliente, a um veiculo desse cliente
-- e possui um mecanico responsavel.
CREATE TABLE ordem_servico (
    id_os INT AUTO_INCREMENT PRIMARY KEY,
    data_abertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME,
    problema_relatado TEXT NOT NULL,
    diagnostico TEXT,
    status ENUM('Aguardando atendimento', 'Em execucao', 'Aguardando pecas', 'Concluido', 'Cancelado')
        NOT NULL DEFAULT 'Aguardando atendimento',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    id_cliente INT NOT NULL,
    id_veiculo INT NOT NULL,
    id_mecanico INT NOT NULL,
    CONSTRAINT fk_os_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente),
    CONSTRAINT fk_os_veiculo_cliente FOREIGN KEY (id_veiculo, id_cliente)
        REFERENCES veiculo(id_veiculo, id_cliente),
    CONSTRAINT fk_os_mecanico FOREIGN KEY (id_mecanico)
        REFERENCES mecanico(id_funcionario),
    CONSTRAINT chk_os_valor CHECK (valor_total >= 0),
    CONSTRAINT chk_os_datas CHECK (data_conclusao IS NULL OR data_conclusao >= data_abertura)
);

-- 8. SERVICOS EXECUTADOS EM CADA ORDEM (N:N)
-- Registra o valor cobrado e o funcionario que executou o servico.
CREATE TABLE os_servico (
    id_os INT NOT NULL,
    id_servico INT NOT NULL,
    valor_cobrado DECIMAL(10,2) NOT NULL,
    id_funcionario_executa INT NOT NULL,
    PRIMARY KEY (id_os, id_servico),
    CONSTRAINT fk_oss_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico(id_os)
        ON DELETE CASCADE,
    CONSTRAINT fk_oss_servico FOREIGN KEY (id_servico)
        REFERENCES servico(id_servico),
    CONSTRAINT fk_oss_funcionario FOREIGN KEY (id_funcionario_executa)
        REFERENCES funcionario(id_funcionario),
    CONSTRAINT chk_oss_valor CHECK (valor_cobrado >= 0)
);

-- 9. PECAS UTILIZADAS EM CADA ORDEM (N:N)
CREATE TABLE os_peca (
    id_os INT NOT NULL,
    id_peca INT NOT NULL,
    quantidade_utilizada INT NOT NULL,
    PRIMARY KEY (id_os, id_peca),
    CONSTRAINT fk_osp_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico(id_os)
        ON DELETE RESTRICT,
    CONSTRAINT fk_osp_peca FOREIGN KEY (id_peca)
        REFERENCES peca(id_peca),
    CONSTRAINT chk_osp_quantidade CHECK (quantidade_utilizada > 0)
);

-- 10. PAGAMENTOS
-- Uma ordem de servico pode receber varios pagamentos.
CREATE TABLE pagamento (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    id_os INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_pagamento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    forma_pagamento ENUM('Dinheiro', 'Cartao de credito', 'Cartao de debito', 'Pix') NOT NULL,
    CONSTRAINT fk_pagamento_os FOREIGN KEY (id_os)
        REFERENCES ordem_servico(id_os)
        ON DELETE CASCADE,
    CONSTRAINT chk_pagamento_valor CHECK (valor > 0)
);

-- =====================================================
-- TRIGGERS PARA CONTROLE AUTOMATICO DO ESTOQUE
-- Ao inserir uma peca na ordem, baixa a quantidade do estoque.
-- Ao alterar a quantidade, ajusta somente a diferenca.
-- Ao remover a peca da ordem, devolve a quantidade ao estoque.
-- A exclusao de uma OS com pecas vinculadas e bloqueada (RESTRICT);
-- remova primeiro os itens de os_peca para que o estoque seja devolvido.
-- =====================================================

DELIMITER $$

CREATE TRIGGER trg_os_peca_bi
BEFORE INSERT ON os_peca
FOR EACH ROW
BEGIN
    DECLARE estoque_atual INT;

    SELECT quantidade_estoque INTO estoque_atual
    FROM peca
    WHERE id_peca = NEW.id_peca
    FOR UPDATE;

    IF estoque_atual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Peca nao encontrada no estoque.';
    END IF;

    IF estoque_atual < NEW.quantidade_utilizada THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para esta peca.';
    END IF;
END$$

CREATE TRIGGER trg_os_peca_ai
AFTER INSERT ON os_peca
FOR EACH ROW
BEGIN
    UPDATE peca
    SET quantidade_estoque = quantidade_estoque - NEW.quantidade_utilizada
    WHERE id_peca = NEW.id_peca;
END$$

CREATE TRIGGER trg_os_peca_bu
BEFORE UPDATE ON os_peca
FOR EACH ROW
BEGIN
    DECLARE estoque_atual INT;
    DECLARE estoque_disponivel INT;

    SELECT quantidade_estoque INTO estoque_atual
    FROM peca
    WHERE id_peca = OLD.id_peca
    FOR UPDATE;

    IF NEW.id_peca <> OLD.id_peca THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nao altere a peca vinculada; remova e cadastre novamente.';
    END IF;

    SET estoque_disponivel = estoque_atual + OLD.quantidade_utilizada;

    IF estoque_disponivel < NEW.quantidade_utilizada THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para atualizar esta utilizacao.';
    END IF;
END$$

CREATE TRIGGER trg_os_peca_au
AFTER UPDATE ON os_peca
FOR EACH ROW
BEGIN
    UPDATE peca
    SET quantidade_estoque = quantidade_estoque
        + OLD.quantidade_utilizada - NEW.quantidade_utilizada
    WHERE id_peca = OLD.id_peca;
END$$

CREATE TRIGGER trg_os_peca_ad
AFTER DELETE ON os_peca
FOR EACH ROW
BEGIN
    UPDATE peca
    SET quantidade_estoque = quantidade_estoque + OLD.quantidade_utilizada
    WHERE id_peca = OLD.id_peca;
END$$

DELIMITER ;

-- As 12 consultas SQL (4 basicas, 4 intermediarias e 4 avancadas)
-- estao organizadas ao final deste arquivo, depois dos INSERTs.

-- =====================================================
-- 11. DADOS DE EXEMPLO (INSERT INTO)
-- Execute esta secao uma unica vez, depois da criacao
-- das tabelas e dos triggers, em um banco sem esses registros.
-- Os codigos foram informados explicitamente para manter
-- os relacionamentos entre as tabelas previsiveis.
-- =====================================================

-- 11.1 CLIENTES
INSERT INTO cliente (id_cliente, nome, cpf, telefone, email, endereco) VALUES
(1, 'Mariana Alves Costa', '111.222.333-01', '(61) 99111-1001', 'mariana.costa@email.com', 'Rua das Acacias, 120 - Asa Sul, Brasilia/DF'),
(2, 'Roberto Mendes Lima', '222.333.444-02', '(61) 99222-2002', 'roberto.lima@email.com', 'Quadra 204, Bloco B - Aguas Claras, Brasilia/DF'),
(3, 'Fernanda Ribeiro Souza', '333.444.555-03', '(61) 99333-3003', 'fernanda.souza@email.com', 'Rua 8, lote 15 - Vicente Pires, Brasilia/DF'),
(4, 'Carlos Eduardo Martins', '444.555.666-04', '(61) 99444-4004', 'carlos.martins@email.com', 'Quadra  central, casa 22 - Taguatinga/DF'),
(5, 'Patricia Oliveira Nunes', '555.666.777-05', '(61) 99555-5005', 'patricia.nunes@email.com', 'Rua do Comercio, 45 - Guara II, Brasilia/DF');

-- 11.2 VEICULOS
-- O cliente 1 possui dois veiculos, demonstrando a relacao 1:N.
INSERT INTO veiculo (id_veiculo, placa, marca, modelo, ano, cor, id_cliente) VALUES
(1, 'JHX1A23', 'Chevrolet', 'Onix', 2021, 'Prata', 1),
(2, 'JKA2B34', 'Toyota', 'Corolla', 2020, 'Preto', 2),
(3, 'JLB3C45', 'Honda', 'CG 160 Fan', 2022, 'Vermelha', 3),
(4, 'JMC4D56', 'Hyundai', 'HB20', 2019, 'Branco', 4),
(5, 'JND5E67', 'Honda', 'Civic', 2018, 'Cinza', 1),
(6, 'JOE6F78', 'Fiat', 'Fiorino', 2023, 'Branca', 5);

-- 11.3 FUNCIONARIOS
-- Mantidos somente os quatro primeiros funcionarios do conjunto original.
INSERT INTO funcionario (id_funcionario, nome, cpf, telefone, endereco, data_contratacao, cargo) VALUES
(1, 'Joao Pedro Almeida', '666.777.888-06', '(61) 99611-6001', 'Rua A, 10 - Taguatinga/DF', '2022-03-14', 'Mecanico'),
(2, 'Maria Clara Ferreira', '777.888.999-07', '(61) 99622-6002', 'Rua B, 20 - Ceilandia/DF', '2021-08-02', 'Mecanico'),
(3, 'Pedro Henrique Gomes', '888.999.000-08', '(61) 99633-6003', 'Rua C, 30 - Samambaia/DF', '2023-01-09', 'Mecanico'),
(4, 'Lucas Santos Ribeiro', '999.000.111-09', '(61) 99644-6004', 'Rua D, 40 - Guara/DF', '2024-02-19', 'Auxiliar mecanico');

-- 11.4 MECANICOS
-- Os tres registros referenciam funcionarios cujo cargo e Mecanico.
INSERT INTO mecanico (id_funcionario, especialidade) VALUES
(1, 'Mecanica geral'),
(2, 'Eletrica automotiva'),
(3, 'Suspensao');

-- 11.5 SERVICOS
INSERT INTO servico (id_servico, descricao, mao_de_obra, tempo_estimado) VALUES
(1, 'Troca de oleo do motor', 120.00, 30),
(2, 'Alinhamento de direcao', 90.00, 40),
(3, 'Balanceamento de rodas', 70.00, 30),
(4, 'Diagnostico eletrico', 150.00, 60),
(5, 'Troca de pastilhas de freio', 180.00, 90),
(6, 'Revisao do sistema de suspensao', 250.00, 120),
(7, 'Limpeza do sistema de injecao', 220.00, 90),
(8, 'Instalacao de bateria', 80.00, 30);

-- 11.6 PECAS E PRODUTOS
-- O estoque informado e o saldo inicial, antes das utilizacoes nas OS.
INSERT INTO peca (id_peca, descricao, preco_unitario, quantidade_estoque, estoque_minimo) VALUES
(1, 'Oleo de motor 10W40 - litro', 45.00, 40, 10),
(2, 'Filtro de oleo', 25.00, 25, 8),
(3, 'Jogo de pastilhas de freio', 120.00, 18, 5),
(4, 'Bateria automotiva 60Ah', 480.00, 8, 3),
(5, 'Vela de ignicao', 35.00, 30, 10),
(6, 'Filtro de ar', 40.00, 22, 8),
(7, 'Amortecedor dianteiro', 350.00, 12, 4),
(8, 'Kit de correia dentada', 210.00, 10, 3),
(9, 'Fluido de freio', 35.00, 20, 6),
(10, 'Lampada de farol', 18.00, 40, 10);

-- 11.7 ORDENS DE SERVICO
-- O valor_total corresponde a mao de obra/servicos mais as pecas utilizadas.
INSERT INTO ordem_servico
(id_os, data_abertura, data_conclusao, problema_relatado, diagnostico, status, valor_total, id_cliente, id_veiculo, id_mecanico) VALUES
(1, '2026-10-20 08:30:00', '2026-10-20 11:45:00', 'Motor fazendo ruido e necessidade de revisao preventiva.', 'Oleo vencido e necessidade de alinhamento e balanceamento.', 'Concluido', 395.00, 1, 1, 1),
(2, '2026-11-10 09:15:00', NULL, 'Veiculo apresenta falhas na partida e problema no sistema eletrico.', 'Diagnostico indicou necessidade de verificacao eletrica e substituicao da bateria.', 'Em execucao', 728.00, 2, 2, 2),
(3, '2026-11-11 10:00:00', NULL, 'Cliente relata barulho ao frear e instabilidade na suspensao.', 'Pastilhas desgastadas e amortecedores com necessidade de avaliacao; aguardando pecas.', 'Aguardando pecas', 430.00, 3, 3, 3),
(4, '2026-10-28 13:20:00', '2026-10-28 16:10:00', 'Aumento no consumo de combustivel e perda de desempenho.', 'Sistema de injecao com necessidade de limpeza; velas e filtro de ar substituidos.', 'Concluido', 400.00, 4, 4, 1),
(5, '2026-11-13 08:00:00', NULL, 'Cliente solicitou avaliacao geral do veiculo.', NULL, 'Aguardando atendimento', 0.00, 5, 6, 2),
(6, '2026-11-12 14:10:00', NULL, 'Cliente percebeu batidas na parte dianteira do veiculo.', 'Foi identificada necessidade de substituicao dos amortecedores dianteiros.', 'Em execucao', 950.00, 1, 5, 3);

-- 11.8 SERVICOS VINCULADOS AS ORDENS DE SERVICO
-- O funcionario executor pode ser o mecanico responsavel ou outro colaborador.
INSERT INTO os_servico (id_os, id_servico, valor_cobrado, id_funcionario_executa) VALUES
(1, 1, 120.00, 1),
(1, 2, 90.00, 4),
(1, 3, 70.00, 4),
(2, 4, 150.00, 2),
(2, 8, 80.00, 2),
(3, 5, 180.00, 3),
(3, 6, 250.00, 3),
(4, 7, 220.00, 1),
(6, 6, 250.00, 3);

-- 11.9 PECAS VINCULADAS AS ORDENS DE SERVICO
-- O trigger trg_os_peca_ai reduz automaticamente o estoque ao inserir.
INSERT INTO os_peca (id_os, id_peca, quantidade_utilizada) VALUES
(1, 1, 2),
(1, 2, 1),
(2, 4, 1),
(2, 10, 1),
(4, 5, 4),
(4, 6, 1),
(6, 7, 2);

-- 11.10 PAGAMENTOS
-- A OS 1 foi quitada em dois pagamentos; outras possuem pagamentos parciais.
INSERT INTO pagamento (id_pagamento, id_os, valor, data_pagamento, forma_pagamento) VALUES
(1, 1, 200.00, '2026-10-20 11:50:00', 'Dinheiro'),
(2, 1, 195.00, '2026-10-20 12:00:00', 'Pix'),
(3, 2, 300.00, '2026-11-10 10:30:00', 'Cartao de credito'),
(4, 4, 400.00, '2026-10-28 16:15:00', 'Cartao de debito'),
(5, 6, 250.00, '2026-11-12 15:00:00', 'Pix'),
(6, 6, 300.00, '2026-11-13 08:30:00', 'Cartao de credito');

-- =====================================================
-- 12. CONSULTAS SQL PARA ANALISE DO SISTEMA
-- Execute cada consulta separadamente ou selecione o bloco desejado.
-- =====================================================

-- -----------------------------------------------------
-- CONSULTAS BASICAS (1 a 4)
-- Objetivo: consultar dados de uma tabela ou fazer JOIN simples.
-- -----------------------------------------------------

-- 1. Listar todos os clientes.
SELECT id_cliente, nome, cpf, telefone, email, endereco
FROM cliente
ORDER BY nome;

-- 2. Listar os veiculos e seus respectivos proprietarios.
SELECT v.id_veiculo, v.placa, v.marca, v.modelo, v.ano, v.cor,
       c.nome AS nome_cliente
FROM veiculo v
INNER JOIN cliente c ON c.id_cliente = v.id_cliente
ORDER BY c.nome, v.modelo;

-- 3. Consultar o catalogo de servicos, do mais caro para o mais barato.
SELECT id_servico, descricao, mao_de_obra, tempo_estimado
FROM servico
ORDER BY mao_de_obra DESC;

-- 4. Consultar o estoque de pecas e identificar itens no nivel minimo.
SELECT id_peca, descricao, quantidade_estoque, estoque_minimo,
       CASE
           WHEN quantidade_estoque <= estoque_minimo THEN 'REPOR ESTOQUE'
           ELSE 'ESTOQUE OK'
       END AS situacao_estoque
FROM peca
ORDER BY descricao;

-- -----------------------------------------------------
-- CONSULTAS INTERMEDIARIAS (5 a 8)
-- Objetivo: combinar varias tabelas e apresentar detalhes relacionados.
-- -----------------------------------------------------

-- 5. Consultar ordens de servico com cliente, veiculo e mecanico responsavel.
SELECT os.id_os, os.data_abertura, os.data_conclusao, os.status,
       c.nome AS cliente, v.placa, v.modelo,
       f.nome AS mecanico_responsavel, os.valor_total
FROM ordem_servico os
INNER JOIN cliente c ON c.id_cliente = os.id_cliente
INNER JOIN veiculo v ON v.id_veiculo = os.id_veiculo
INNER JOIN mecanico m ON m.id_funcionario = os.id_mecanico
INNER JOIN funcionario f ON f.id_funcionario = m.id_funcionario
ORDER BY os.data_abertura DESC;

-- 6. Listar os servicos executados em cada ordem e o funcionario executor.
SELECT os.id_os, s.descricao AS servico,
       oss.valor_cobrado, f.nome AS funcionario_executor
FROM os_servico oss
INNER JOIN ordem_servico os ON os.id_os = oss.id_os
INNER JOIN servico s ON s.id_servico = oss.id_servico
INNER JOIN funcionario f ON f.id_funcionario = oss.id_funcionario_executa
ORDER BY os.id_os, s.descricao;

-- 7. Listar as pecas utilizadas, quantidades e custo de cada item por ordem.
SELECT op.id_os, p.descricao AS peca,
       op.quantidade_utilizada, p.preco_unitario,
       (op.quantidade_utilizada * p.preco_unitario) AS custo_total_pecas
FROM os_peca op
INNER JOIN peca p ON p.id_peca = op.id_peca
ORDER BY op.id_os, p.descricao;

-- 8. Consultar os pagamentos realizados, com o cliente e a ordem correspondente.
SELECT pg.id_pagamento, os.id_os, c.nome AS cliente,
       pg.valor, pg.data_pagamento, pg.forma_pagamento
FROM pagamento pg
INNER JOIN ordem_servico os ON os.id_os = pg.id_os
INNER JOIN cliente c ON c.id_cliente = os.id_cliente
ORDER BY pg.data_pagamento DESC;

-- -----------------------------------------------------
-- CONSULTAS AVANCADAS (9 a 12)
-- Objetivo: utilizar agregacoes, subconsultas, CASE, GROUP BY e HAVING.
-- -----------------------------------------------------

-- 9. Calcular quanto foi pago e qual saldo ainda falta pagar em cada ordem.
SELECT os.id_os, c.nome AS cliente, os.valor_total AS valor_ordem,
       COALESCE(SUM(pg.valor), 0) AS total_pago,
       os.valor_total - COALESCE(SUM(pg.valor), 0) AS saldo_devedor,
       CASE
           WHEN os.valor_total = 0 THEN 'SEM VALOR DEFINIDO'
           WHEN COALESCE(SUM(pg.valor), 0) >= os.valor_total THEN 'QUITADA'
           WHEN COALESCE(SUM(pg.valor), 0) > 0 THEN 'PAGAMENTO PARCIAL'
           ELSE 'PENDENTE'
       END AS situacao_pagamento
FROM ordem_servico os
INNER JOIN cliente c ON c.id_cliente = os.id_cliente
LEFT JOIN pagamento pg ON pg.id_os = os.id_os
GROUP BY os.id_os, c.nome, os.valor_total
ORDER BY saldo_devedor DESC;

-- 10. Criar um ranking dos servicos mais realizados e seu faturamento total.
SELECT s.id_servico, s.descricao,
       COUNT(oss.id_os) AS quantidade_realizada,
       COALESCE(SUM(oss.valor_cobrado), 0) AS faturamento_total
FROM servico s
LEFT JOIN os_servico oss ON oss.id_servico = s.id_servico
GROUP BY s.id_servico, s.descricao
ORDER BY quantidade_realizada DESC, faturamento_total DESC;

-- 11. Encontrar clientes com mais de uma ordem de servico e somar os valores.
SELECT c.id_cliente, c.nome,
       COUNT(os.id_os) AS quantidade_ordens,
       SUM(os.valor_total) AS valor_total_atendimentos
FROM cliente c
INNER JOIN ordem_servico os ON os.id_cliente = c.id_cliente
WHERE c.id_cliente IN (
    SELECT id_cliente
    FROM ordem_servico
    GROUP BY id_cliente
    HAVING COUNT(id_os) > 1
)
GROUP BY c.id_cliente, c.nome
ORDER BY quantidade_ordens DESC, valor_total_atendimentos DESC;

-- 12. Apurar a quantidade de ordens por mecanico, separando os status.
SELECT f.id_funcionario, f.nome AS mecanico,
       m.especialidade,
       COUNT(os.id_os) AS total_ordens,
       SUM(CASE WHEN os.status = 'Concluido' THEN 1 ELSE 0 END) AS ordens_concluidas,
       SUM(CASE WHEN os.status = 'Em execucao' THEN 1 ELSE 0 END) AS ordens_em_execucao,
       SUM(CASE WHEN os.status = 'Aguardando pecas' THEN 1 ELSE 0 END) AS ordens_aguardando_pecas
FROM mecanico m
INNER JOIN funcionario f ON f.id_funcionario = m.id_funcionario
LEFT JOIN ordem_servico os ON os.id_mecanico = m.id_funcionario
GROUP BY f.id_funcionario, f.nome, m.especialidade
ORDER BY total_ordens DESC, f.nome;
