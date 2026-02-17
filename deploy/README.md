# Deploiement Synology

Guide de deploiement pour Synology NAS avec Container Manager.

## Caracteristiques

- **Build statique** - Image nginx ultra-legere (~20-50MB)
- **Pre-built** - Image hebergee sur GitHub Container Registry
- **Deploiement instantane** - Pas de build local necessaire
- **Settings localStorage** - Sauvegardes dans le navigateur

## Prerequis

- Synology NAS avec DSM 7.x
- Container Manager installe
- Acces reseau pour pull depuis ghcr.io

## Installation

### Via Container Manager (recommande)

1. Cloner ce repo sur votre Synology:
   ```bash
   cd /volume1/docker
   git clone https://github.com/patricklafleur/excalith-start-page.git
   ```

2. Ouvrir Container Manager
3. Projet → Create
4. Pointer vers `/volume1/docker/excalith-start-page/deploy/docker-compose.yml`
5. Deployer

### Via SSH

```bash
cd /volume1/docker
git clone https://github.com/patricklafleur/excalith-start-page.git
cd excalith-start-page/deploy
docker compose up -d
```

## Configuration

Editez `.env` pour personnaliser:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 8080 | Port externe d'acces |
| `CONTAINER_NAME` | excalith-start-page | Nom du container |
| `HEALTHCHECK_INTERVAL` | 30 | Intervalle healthcheck (secondes) |
| `HEALTHCHECK_TIMEOUT` | 10 | Timeout healthcheck (secondes) |
| `HEALTHCHECK_RETRIES` | 3 | Nombre de retries |

## Acces

- **Local:** http://[synology-ip]:8080
- **Tailscale:** http://[tailscale-ip]:8080

## Settings personnalises

Les settings sont sauvegardes dans localStorage de votre navigateur.

### Backup de vos settings:

```bash
# Dans l'interface
> config copy
[✓] Settings copied to clipboard

# Ou
> config export
[✓] Settings exported to settings.json
```

Puis coller dans `data/settings.json` du repo pour les inclure dans le build par defaut.

## Mise a jour

L'image Docker est automatiquement buildee via GitHub Actions a chaque push sur main.

### Option 1: Via Container Manager

1. Ouvrir le projet
2. Action → Pull → Latest
3. Restart le container

### Option 2: Via SSH

```bash
cd /volume1/docker/excalith-start-page/deploy
docker compose pull
docker compose up -d
```

## Commandes utiles

```bash
cd /volume1/docker/excalith-start-page/deploy

# Deployer
docker compose up -d

# Mettre a jour
docker compose pull && docker compose up -d

# Voir les logs
docker compose logs -f

# Restart
docker compose restart

# Stop
docker compose down

# Status
docker compose ps
```

## Fonctionnalites personnalisees

Ce fork inclut:
- **Filtres environnement** (dev/staging/prod) par section
- **Expand all / Collapse all** pour gerer l'affichage
- **Limite d'affichage** configurable (`maxVisibleLinks`)
- **Config copy** - copier settings dans clipboard
- **Config export** - telecharger settings en JSON

## Architecture

```
GitHub Actions (build automatique)
         ↓
GitHub Container Registry (ghcr.io)
         ↓
Docker Pull (Synology)
         ↓
Container nginx (static files)
```

## Troubleshooting

### Impossible de pull l'image

Verifier la connexion reseau et que ghcr.io est accessible:
```bash
docker pull ghcr.io/patricklafleur/excalith-start-page:latest
```

### Port deja utilise

Changer le PORT dans `.env`:
```bash
PORT=8081
```

Puis redemarrer:
```bash
docker compose up -d
```

### Settings perdus

Les settings sont dans localStorage. Si vous changez de navigateur:
1. Exportez vos settings: `config export`
2. Importez-les dans le nouveau navigateur: `config import <url>`

## Support

- Projet original: https://github.com/excalith/excalith-start-page
- Fork avec features: https://github.com/patricklafleur/excalith-start-page
