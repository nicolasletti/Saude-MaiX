# Saude-MaiX

Sistema de apoio à triagem clínica baseado em entrada de sintomas e cálculo de score ponderado.

---

## Objetivo

Fornecer uma aplicação capaz de:

* Receber sintomas de pacientes
* Processar um score baseado em regras definidas
* Classificar risco clínico
* Armazenar histórico de triagens

---

## Arquitetura

O projeto segue uma arquitetura em camadas:

* **Frontend**: Interface de entrada de dados
* **Backend**: API responsável pela lógica de negócio
* **Banco de Dados**: Persistência de pacientes e resultados

Fluxo básico:

1. Usuário insere sintomas
2. Backend processa dados
3. Score é calculado
4. Resultado é armazenado
5. Resposta é retornada

---

## Estrutura do Projeto

```
src/
  backend/       # API e lógica
  frontend/      # Interface
  core/          # Regras centrais (ex: cálculo de score)

data/
  database/      # Scripts e estrutura do banco
  seeds/         # Dados iniciais

tests/
  unit/          # Testes unitários
  integration/   # Testes de integração

docs/
  arquitetura.md
  requisitos.md
```

---

## Padrões de Desenvolvimento

* Separar **controller** (entrada HTTP) de **service** (regra de negócio)
* Não colocar lógica crítica no frontend
* Utilizar nomes descritivos para funções e variáveis
* Manter funções pequenas e coesas

---

## Versionamento

* Um commit por funcionalidade
* Mensagens claras (ex: `feat: cálculo de score inicial`)
* Evitar subir arquivos desnecessários:

  * `.vscode/`
  * `.ipynb_checkpoints/`
  * arquivos de ambiente

---

## Como rodar o projeto

### Backend

```bash
cd src/backend
pip install -r requirements.txt
python main.py
```

ou (Node):

```bash
npm install
npm run dev
```

---

## Testes

```bash
pytest
```

ou

```bash
npm test
```

---

## Contribuição

1. Criar branch a partir da `main`
2. Implementar funcionalidade
3. Criar testes
4. Abrir Pull Request

---

## Próximos passos

* Implementar cálculo de score
* Definir modelo de dados
* Criar endpoints de triagem
* Integrar frontend

---
