# GDeskEx Light

Versão **experimental e limitada** do GDeskEx, criada especialmente para computadores com pouca memória RAM (**1.5 GB**).

Esta versão aplica várias restrições para conseguir rodar o Windows Subsystem for Android (WSA) em máquinas fracas.

> **Atenção:** Esta é uma versão experimental.  
> Se o seu computador tiver **8 GB de RAM ou mais**, use a versão principal:  
> → [GDeskEx (versão completa)](https://github.com/Elguilande/gdeskex)

---

## Características do Modo Light

| Item                        | Limitação                              |
|----------------------------|----------------------------------------|
| **Memória RAM alocada**    | 1.5 GB (1536 MB)                       |
| **Máximo de aplicativos**  | 12 apps de usuário                     |
| **Processos em background (Online)** | Máximo 3                       |
| **Processos em background (Offline)** | Máximo 5                      |
| **Google Play Store**      | Permitido                              |
| **Animações**              | Reduzidas                              |
| **low_ram**                | Ativado                                |

---

## Requisitos do Sistema

| Item                    | Mínimo                          | Recomendado          |
|-------------------------|---------------------------------|----------------------|
| **Sistema Operacional** | Windows 10 22H2 ou Windows 11   | Windows 11           |
| **Arquitetura**         | x64                             | x64                  |
| **Memória RAM**         | 4 GB (com limitações)           | 8 GB                 |
| **Armazenamento**       | 10 GB livres (SSD recomendado)  | SSD                  |
| **Virtualização**       | Ativada na BIOS + Windows       | Ativada              |

---

## Como Usar

### 1. Baixar o script
```powershell
irm https://raw.githubusercontent.com/Elguilande/gdeskex-light/main/gdeskex-light.ps1 -OutFile gdeskex-light.ps1
```

### 2. Liberar execução de scripts
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### 3. Executar comandos
Sempre use desta forma:

```powershell
.\gdeskex-light.ps1 wsa-light
.\gdeskex-light.ps1 wsa-light-install
.\gdeskex-light.ps1 wsa-status
.\gdeskex-light.ps1 install C:\Downloads\app.apk
```

---

## Comandos Disponíveis

### Comandos do WSA (Light)

| Comando              | Descrição                                      |
|----------------------|------------------------------------------------|
| `wsa-light`          | Aplica todas as otimizações do modo Light      |
| `wsa-status`         | Mostra status do WSA + quantidade de apps      |
| `wsa-install`        | faz o download do WSA                          |
| `wsa-memory [MB]`    | Define limite de memória                       |
| `wsa-restart`        | Reinicia o WSA                                 |

### Comandos de Aplicativos

| Comando                    | Descrição                                      |
|---------------------------|------------------------------------------------|
| `install [caminho.apk]`   | Instala um APK (respeita o limite de 12 apps)  |
| `run [pacote]`            | Executa um aplicativo                          |
| `list`                    | Lista todos os pacotes instalados              |
| `list-user`               | Lista apenas apps de usuário                   |
| `remove [pacote]`         | Desinstala um aplicativo                       |

---

## Exemplos de Uso

```powershell
# Aplicar o modo Light (obrigatório na primeira vez)
.\gdeskex-light.ps1 wsa-light

# instala o WSA
.\gdeskex.ps1 wsa-install

# Ver status e quantos apps estão instalados
.\gdeskex-light.ps1 wsa-status

# Instalar um APK
.\gdeskex-light.ps1 install C:\Users\SeuUsuario\Downloads\telegram.apk

# Executar um app
.\gdeskex-light.ps1 run org.telegram.messenger

# Listar apps instalados
.\gdeskex-light.ps1 list-user

# Remover um app
.\gdeskex-light.ps1 remove com.exemplo.app
```

---

## Avisos Importantes

- Esta versão é **experimental** e pode ser instável.
- O limite de **12 aplicativos** é rígido. Se tentar instalar mais, a instalação será bloqueada.
- Com internet, o sistema tenta manter no máximo **3 processos** em segundo plano.
- Sem internet, o limite sobe para **5 processos**.
- Não é recomendado usar aplicativos pesados (jogos, editores de vídeo, etc).
- Prefira aplicativos leves e offline sempre que possível.

---

## Diferença para a versão principal

| Recurso                    | GDeskEx Normal      | GDeskEx Light      |
|---------------------------|---------------------|--------------------|
| Memória recomendada       | 8 GB+               | 1.5 GB             |
| Limite de apps            | Sem limite          | 12 apps            |
| Otimização de processos   | Básica              | Agressiva          |
| Estabilidade              | Alta                | Experimental       |
| Público-alvo              | Uso geral           | PCs fracos         |

---

## Resolução de Problemas

| Problema                          | Solução                                                                 |
|-----------------------------------|-------------------------------------------------------------------------|
| `running scripts is disabled`     | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`           |
| Limite de apps atingido           | Remova algum app com `remove` antes de instalar outro                  |
| WSA não inicia                    | Verifique se a Virtualização está ativada na BIOS                      |
| Muito lento                       | Use apenas apps leves e evite muitos processos em segundo plano        |

---

## Autor

Criado por **Elves Guilande** – GTSXAI

Repositório principal: [GDeskEx](https://github.com/Elguilande/gdeskex)


---
