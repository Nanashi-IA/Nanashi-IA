# Nanashi Privacy AI 🚀🔒🐝

**Nanashi (無名 – "sans nom" en japonais)** : L'IA souveraine décentralisée privacy-first, 100% on-device, optimisée exclusivement pour Apple Silicon (M-series).

**Le Grok killer privacy-zero-trust** : Pas de cloud, pas de censure, pas de tracking. Vos données restent sur votre appareil. Forever gratuit + rewards pour les contributeurs.

## Pourquoi Nanashi domine 2026
| Autres IA (Grok, ChatGPT, etc.) | Nanashi IA                          | Pourquoi ça change tout                  |
|---------------------------------|-------------------------------------|------------------------------------------|
| Cloud + tracking                | 100% on-device                      | Aucune fuite possible                    |
| Latence 300ms–2s                | <100ms sur M4/M5                    | Réponse instantanée                      |
| Censure & abonnements           | Zero censorship + gratuit forever   | Liberté totale                           |
| Pas de rewards                  | Taxes 1% → stakers & contributors   | Tu gagnes en utilisant/contribuant       |
| Centralisé                      | Décentralisé (subnet Bittensor)     | Souveraineté réelle                      |

### Features clés
- **Privacy absolue** : Split inference + injection de bruit → données jamais exposées.
- **Nanashi Consensus** : Proof of Intelligence anonyme (zk-ready).
- **Performance** : Ollama + MLX → Llama 3.1/Mistral full Neural Engine.
- **UI premium** : Neon/glassmorphism dashboard (mining, chat sécurisé, audit).
- **Hybrid mode** : Local + contribution anonyme décentralisée.

- ### 🛰️ Nanashi Swarm (Decentralized Updates)

Nanashi introduit une architecture de mise à jour **"Zero-Trust & Bandwidth-Efficient"**. Fini les téléchargements de 10 Go à chaque correctif.

* **Smart Registry (`NanashiRegistry.sol`)** : Chaque version est signée et ancrée sur la blockchain (Hash IPFS + Checksum). Impossible d'injecter du code malveillant sans la clé privée de la DAO.
  
* **Incremental LoRA (`nanashi_updater.py`)** : Le client télécharge uniquement les "différentiels" d'intelligence (adapters LoRA de ~50Mo) via IPFS et les fusionne à chaud dans le Neural Engine via MLX.
* **Résultat** : Votre IA évolue chaque semaine sans saturation réseau et sans redémarrage.
  
### Roadmap 2026 (mise à jour février)
- **Q1 (en cours)** : MVP local finalisé, MLX integration, UI avancée.
- **Q2** : Subnet Bittensor testnet (privacy PoI + zk proofs).
- **Q3** : App iOS native + multimodal (vision/texte).
- **Q4** : Token $NANA fair launch + mainnet subnet.

### Demo instantanée (Mac M-series)
```bash
brew install ollama
ollama serve &
ollama pull llama3.1:8b
open index.html

# Nanashi IA – White Paper (Résumé)

**Version 1.5 – Février 2026**  
**Pas de nom. Pas de trace. Contrôle total.**

Nanashi IA est un écosystème d’IA souveraine avec NanashiOS (OS local pour agents) et $NANA (token de gouvernance).

## FIGURE 1 — ARCHITECTURE GLOBALE

```mermaid
flowchart TD
  A["👤 Utilisateur"] --> B["NanashiOS Core"]
  B --> C["Marketplace Agents"]
  B --> D["Mumei Protocol (Bittensor Subnet)"]
  D --> E["Proof of Intelligence"]
  E --> F["$NANA Rewards"]
  B --> G["Nanashi DAO"]
  style A fill:#001133,stroke:#00f2ff
  style B fill:#220033,stroke:#bc13fe
  style D fill:#002211,stroke:#00ff9d
  style E fill:#440033,stroke:#ff3131
  style F fill:#330022,stroke:#fe13bc
  style G fill:#001133,stroke:#00f2ff

FIGURE 2 — ÉCONOMIE $NANA
pie title Allocation $NANA
  "Liquidity & Launch" : 20
  "Community & Airdrop" : 15
  "Team & Advisors" : 12
  "Treasury DAO" : 25
  "Ecosystem Fund" : 15
  "Staking Rewards" : 10
  "Public Sale / IDO" : 3

FIGURE 3 — GOUVERNANCE DAO
flowchart TD
  A["$NANA Staké"] --> B["Proposition"]
  B --> C["Vote On-chain"]
  C --> D["Timelock 48h"]
  D --> E["Exécution"]
  style A fill:#001133,stroke:#00f2ff
  style D fill:#440033,stroke:#ff3131

White Paper complet : Disponible dans le dépôt NanashiOS : https://github.com/NanashiOS-Lab/NanashiOS/blob/main/docs/whitepaper.md
Plus d’infos blockchain : contracts/ dans ce dépôt.
