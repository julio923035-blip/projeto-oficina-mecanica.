#  Sistema de Gerenciamento de Oficina Mecânica

![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Concluído-success?style=for-the-badge)

##  Sobre o Projeto

Este projeto consiste no desenvolvimento de um banco de dados relacional para o gerenciamento de uma oficina mecânica.

O sistema foi desenvolvido com MySQL, tendo como finalidade organizar e armazenar informações relacionadas a clientes, veículos, funcionários, serviços, peças, ordens de serviço e pagamentos.

O projeto busca demonstrar na prática os conceitos de modelagem de dados, relacionamentos entre tabelas, integridade referencial e consultas SQL.

##  Objetivo

Desenvolver uma estrutura de banco de dados capaz de organizar as principais operações de uma oficina mecânica, permitindo o armazenamento, gerenciamento e consulta das informações.

##  Tecnologias Utilizadas

- MySQL
- SQL
- MySQL Workbench

##  Estrutura do Banco de Dados

O banco de dados é composto por 10 tabelas:

| Tabela | Descrição |
|---|---|
| cliente | Armazena os dados dos clientes. |
| veiculo | Registra os veículos e seus proprietários. |
| funcionario | Armazena os dados dos funcionários. |
| mecanico | Registra as especialidades dos mecânicos. |
| servico | Contém o catálogo de serviços disponíveis. |
| peca | Gerencia as peças e o estoque. |
| ordem_servico | Registra os atendimentos e serviços solicitados. |
| os_servico | Relaciona os serviços executados às ordens. |
| os_peca | Registra as peças utilizadas em cada ordem. |
| pagamento | Armazena os pagamentos realizados. |

##  Funcionalidades Desenvolvidas

- Cadastro de clientes e veículos.
- Cadastro e organização de funcionários.
- Registro de mecânicos e suas especialidades.
- Gerenciamento de serviços disponíveis.
- Controle de peças e estoque.
- Abertura e acompanhamento de ordens de serviço.
- Registro de serviços executados.
- Controle de pagamentos e valores pendentes.
- Consultas para análise das informações do sistema.

##  Relacionamentos e Integridade dos Dados

O projeto utiliza relacionamentos entre tabelas por meio de chaves primárias (PRIMARY KEY) e chaves estrangeiras (FOREIGN KEY).

Também foram utilizadas restrições para garantir a consistência dos dados, como:

- NOT NULL
- UNIQUE
- CHECK
- ENUM
- AUTO_INCREMENT

##  Controle Automático de Estoque

Foram desenvolvidos TRIGGERS para automatizar o controle de peças utilizadas nas ordens de serviço.

Os gatilhos permitem:

- Diminuir automaticamente a quantidade de peças no estoque após sua utilização.
- Atualizar o estoque quando a quantidade utilizada for alterada.
- Devolver peças ao estoque quando sua utilização for removida.
- Impedir operações que resultem em estoque insuficiente.

##  Consultas SQL

O projeto contém 12 consultas SQL, organizadas em três níveis:

**Consultas básicas**
- Listagem de clientes.
- Consulta de veículos e proprietários.
- Catálogo de serviços.
- Verificação da situação do estoque.

**Consultas intermediárias**
- Ordens de serviço com clientes, veículos e mecânicos.
- Serviços executados e funcionários responsáveis.
- Peças utilizadas em cada ordem.
- Histórico de pagamentos.

**Consultas avançadas**
- Cálculo de pagamentos e saldos devedores.
- Ranking dos serviços mais realizados.
- Identificação de clientes com múltiplas ordens.
- Análise de produtividade dos mecânicos.

##  Como Executar o Projeto

1. Instale o MySQL Server e o MySQL Workbench.
2. Abra o MySQL Workbench e conecte-se ao servidor.
3. Abra o arquivo `oficina_mecanica.sql`.
4. Execute o script para criar o banco de dados, tabelas e triggers.
5. Execute os comandos INSERT para inserir os dados de exemplo.
6. Execute as consultas SQL para visualizar os resultados.

**Observação:** A seção de criação do banco, tabelas e triggers deve ser executada antes dos INSERTs. Os dados de exemplo devem ser inseridos apenas uma vez em um banco vazio.

##  Conhecimentos Desenvolvidos

- Modelagem de banco de dados relacional.
- Criação e estruturação de tabelas.
- Relacionamentos 1:N e N:N.
- Chaves primárias e estrangeiras.
- Manipulação de dados com INSERT.
- Consultas com SELECT, WHERE e ORDER BY.
- Utilização de INNER JOIN e LEFT JOIN.
- Funções de agregação e subconsultas.
- Utilização de GROUP BY e HAVING.
- Automação com TRIGGERS.

##  Autor

Estudante de Tecnologia, interessado em desenvolvimento de software, banco de dados e programação.

Este projeto foi desenvolvido com finalidade acadêmica e como prática de aprendizado em SQL e MySQL.

---

 Projeto desenvolvido para fins de estudo e aprendizado.
 
 Observações e Melhorias Futuras

Durante o desenvolvimento e a análise do projeto, foram identificados alguns pontos que ainda podem ser aprimorados.

Embora o banco de dados já apresente uma estrutura funcional, com tabelas relacionadas, inserção de dados, consultas SQL e controle automatizado de estoque, ainda existem funcionalidades que precisam de complementação e validação.

### 🔍 Pontos a melhorar

- Revisar e aprimorar algumas funcionalidades do banco de dados.
- Realizar testes mais completos para verificar a integridade e o funcionamento das operações.
- Desenvolver exemplos práticos de execução dos TRIGGERS.
- Validar o comportamento dos gatilhos em diferentes situações, como inserção, atualização e exclusão de peças.
- Verificar se o controle automático de estoque está funcionando corretamente em todos os cenários.

### ⚙️ Testes pendentes dos TRIGGERS

O projeto possui cinco TRIGGERS responsáveis pelo controle automático do estoque de peças. Entretanto, ainda é necessário desenvolver e executar exemplos práticos para demonstrar seu funcionamento.

Os testes futuros deverão verificar:

1. **BEFORE INSERT:** verificar se o sistema impede a utilização de peças quando o estoque é insuficiente.
2. **AFTER INSERT:** verificar se a quantidade em estoque diminui após a utilização de uma peça.
3. **BEFORE UPDATE:** verificar se o sistema valida alterações na quantidade de peças utilizadas.
4. **AFTER UPDATE:** verificar se o estoque é atualizado corretamente após uma alteração.
5. **AFTER DELETE:** verificar se as peças removidas de uma ordem de serviço retornam ao estoque.

### 🚧 Situação do projeto

O projeto possui sua estrutura principal desenvolvida, mas permanece aberto a melhorias, testes e aperfeiçoamentos.

A proposta é continuar evoluindo o banco de dados, garantindo maior confiabilidade, organização e consistência das informações.
