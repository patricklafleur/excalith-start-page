# Deploiement sur Synology NAS

Guide complet pour deployer cette start page sur un Synology NAS avec acces local et Tailscale.

**IMPORTANT : Ou executer les commandes ?**

Toutes les commandes et scripts de ce guide doivent etre executes **DIRECTEMENT SUR LE SYNOLOGY** via SSH, pas sur votre machine locale.

1. Connectez-vous au Synology : `ssh admin@synology.local`
2. Executez les scripts depuis le Synology
3. L'image Docker sera buildee et stockee localement sur le Synology

## Prerequis

- Synology NAS avec DSM 7.x
- Docker (Container Manager) installe via Package Center
- Git installe (optionnel, pour cloner le repo)
- Tailscale installe (pour acces distant prive)
- SSH active sur le Synology

## Probleme resolu : config reset

Cette configuration garantit que `config reset` restaure **VOS** customizations, pas les settings par defaut.

**Comment ?** En buildant l'image Docker localement avec votre `data/settings.json` customise. Ainsi :
- `defaultConfig` (importe au build) = VOS settings
- Volume mount `/app/data` persiste aussi vos modifications
- `config reset` restaure VOS settings, pas ceux d'excalith

## Architecture

```
Acces Local (LAN)          Acces Tailscale (distant)
      |                              |
      v                              v
http://192.168.1.x:8080    http://100.x.x.x:8080
                 |                   |
                 +-------------------+
                           |
                    Container Docker
                     (port 3000)
                           |
                    Volume: ./data
                  (settings.json)
```

## Installation rapide

### Methode 1 : Scripts automatises (recommande)

```bash
# Sur le Synology (via SSH)

# 1. Cloner le repo original
cd /volume1/docker
git clone https://github.com/excalith/excalith-start-page.git

# 2. Copier vos customizations
cp /chemin/vers/votre/settings.json excalith-start-page/data/settings.json

# 3. Executer le setup
cd excalith-start-page/synology
chmod +x scripts/*.sh
./scripts/setup.sh

# 4. Deployer
./scripts/deploy.sh

# 5. Verifier
./scripts/verify.sh
```

### Methode 2 : Manuel

Suivre les etapes detaillees ci-dessous.

## Instructions detaillees

### Etape 1 : Preparation

```bash
# Connexion SSH au Synology
ssh admin@synology.local

# Creer la structure de repertoires
mkdir -p /volume1/docker/excalith-start-page
cd /volume1/docker/excalith-start-page

# Cloner le repo original OU copier les fichiers via File Station
git clone https://github.com/excalith/excalith-start-page.git .

# Copier votre settings.json customise
# Option A : via scp depuis votre machine locale
# scp data/settings.json admin@synology:/volume1/docker/excalith-start-page/data/

# Option B : editer directement sur le Synology
vi data/settings.json

# Fixer les permissions (uid 1001 = utilisateur nextjs dans le container)
chown -R 1001:1001 data/
```

### Etape 1.5 : Configuration (optionnel)

Creer un fichier `.env` pour personnaliser le deploiement :

```bash
cd synology

# Copier le fichier exemple
cp .env.example .env

# Editer selon vos besoins
vi .env
```

Variables configurables :

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 8080 | Port externe pour acceder a la start page |
| `CONTAINER_NAME` | excalith-start-page | Nom du container Docker |
| `BUILD_MODE` | docker | Mode de persistence (docker = fichier) |
| `NODE_ENV` | production | Environnement Node.js |
| `HEALTHCHECK_INTERVAL` | 30 | Intervalle healthcheck (secondes) |
| `HEALTHCHECK_TIMEOUT` | 10 | Timeout healthcheck (secondes) |
| `HEALTHCHECK_RETRIES` | 3 | Nombre de retries avant unhealthy |

**Exemple :** Pour utiliser le port 3080 au lieu de 8080 :

```bash
echo "PORT=3080" > synology/.env
```

Si vous ne creez pas de fichier `.env`, les valeurs par defaut seront utilisees.

### Etape 2 : Build et demarrage

**Via Container Manager UI :**

1. Ouvrir Container Manager > Project
2. Creer nouveau projet : "excalith-start-page"
3. Chemin : `/volume1/docker/excalith-start-page/synology`
4. Selectionner `docker-compose.yml`
5. Cliquer "Build" puis "Deploy"

**Via SSH :**

```bash
cd /volume1/docker/excalith-start-page/synology

# Builder l'image avec vos customizations
docker compose build

# Demarrer le container
docker compose up -d

# Verifier les logs
docker compose logs -f start-page
```

### Etape 3 : Verification

```bash
# Verifier que le container tourne
docker ps | grep excalith-start-page

# Verifier BUILD_MODE
docker exec excalith-start-page printenv BUILD_MODE
# Output attendu: docker

# Verifier vos settings dans l'image
docker exec excalith-start-page cat /app/data/settings.json | head -10
# Devrait montrer VOS customizations

# Test HTTP local
curl -I http://localhost:8080
# Output attendu: HTTP/1.1 200 OK
```

### Etape 4 : Acces local

1. Trouver l'IP locale de votre Synology :
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. Ouvrir dans un navigateur :
   ```
   http://192.168.1.x:8080
   ```

3. Tester `config edit` :
   - Modifier un setting
   - Ouvrir Dev Tools > Network
   - Verifier POST a `/api/saveSettings` (= mode Docker OK)

4. Tester `config reset` :
   - Executer `config reset`
   - Verifier que VOS settings sont restaures (pas ceux par defaut)

### Etape 5 : Configuration Tailscale

#### Installation Tailscale

**Via Package Center :**
1. Package Center > rechercher "Tailscale"
2. Installer
3. Suivre le processus d'authentification

**Via installation manuelle :**
```bash
# Telecharger le package pour votre architecture
# https://pkgs.tailscale.com/stable/#synology

# Installer via Package Center > Manual Install
```

#### Configuration

```bash
# Demarrer Tailscale
sudo tailscale up

# Obtenir l'IP Tailscale de votre Synology
tailscale ip -4
# Exemple: 100.64.1.42

# Verifier le statut
tailscale status
```

#### Firewall (optionnel)

Restreindre le port 8080 au reseau local + Tailscale uniquement :

1. Control Panel > Security > Firewall
2. Creer une regle :
   - Source : 192.168.0.0/16 (reseau local)
   - Port : 8080
   - Action : Allow
3. Creer une regle :
   - Source : 100.64.0.0/10 (reseau Tailscale)
   - Port : 8080
   - Action : Allow

#### Test acces Tailscale

Depuis n'importe quel appareil connecte a votre reseau Tailscale :

```bash
# Test curl
curl -I http://100.64.1.42:8080

# Ou ouvrir dans un navigateur
# http://100.64.1.42:8080
```

#### MagicDNS (optionnel)

Activer MagicDNS dans Tailscale admin console pour acceder via :
```
http://synology.tail-xxxxx.ts.net:8080
```

Au lieu de l'IP numerique.

## Verification du mode Docker

Comment confirmer que vous etes bien en mode Docker (pas localStorage) :

### Methode 1 : Developer Tools

1. Ouvrir la page dans le navigateur
2. F12 > Network tab
3. Recharger la page
4. Chercher requetes a `/api/loadSettings` et `/api/saveSettings`
   - Present = mode Docker
   - Absent = mode localStorage

### Methode 2 : localStorage

1. F12 > Application (ou Storage) > Local Storage
2. Verifier la cle "settings" :
   - Vide ou absente = mode Docker
   - JSON present = mode localStorage

### Methode 3 : Variables d'environnement

```bash
docker exec excalith-start-page printenv BUILD_MODE
# Output attendu: docker
```

## Maintenance

### Backup des settings

**Manuel :**
```bash
./scripts/backup.sh
```

**Automatique (Task Scheduler DSM) :**

1. Control Panel > Task Scheduler
2. Create > Scheduled Task > User-defined script
3. Schedule : Daily, 2:00 AM
4. Task Settings :
   ```bash
   /volume1/docker/excalith-start-page/synology/scripts/backup.sh
   ```

### Mise a jour

```bash
cd /volume1/docker/excalith-start-page/synology
./scripts/update.sh
```

OU manuellement :

```bash
cd /volume1/docker/excalith-start-page

# Pull dernieres modifications
git pull

# Rebuild avec nouveaux changements
cd synology
docker compose build

# Restart
docker compose down
docker compose up -d
```

**Important :** Vos settings dans `data/settings.json` sont preserves grace au volume mount.

### Logs

```bash
# Logs en temps reel
docker compose logs -f start-page

# Dernieres 50 lignes
docker logs excalith-start-page --tail 50

# Depuis une date
docker logs excalith-start-page --since 2024-01-01
```

### Restart

```bash
# Via docker compose
cd /volume1/docker/excalith-start-page/synology
docker compose restart

# OU via docker directement
docker restart excalith-start-page
```

## Troubleshooting

### Le container ne demarre pas

```bash
# Verifier les logs
docker logs excalith-start-page

# Verifier les permissions
ls -lah /volume1/docker/excalith-start-page/data/
# Devrait etre owned by 1001:1001

# Corriger les permissions
chown -R 1001:1001 /volume1/docker/excalith-start-page/data/
docker restart excalith-start-page
```

### Port 8080 deja utilise

```bash
# Trouver le process qui utilise le port
sudo lsof -i :8080

# Changer le port dans docker-compose.yml
# Modifier "8080:3000" en "8888:3000"
docker compose up -d
```

### Settings ne persistent pas

```bash
# Verifier BUILD_MODE
docker exec excalith-start-page printenv BUILD_MODE
# Devrait afficher: docker

# Verifier le volume mount
docker inspect excalith-start-page | grep -A 10 Mounts
# Devrait montrer ./data monte sur /app/data

# Verifier le fichier existe
docker exec excalith-start-page ls -la /app/data/
# Devrait montrer settings.json
```

### config reset restaure les mauvais settings

Ce probleme indique que l'image n'a pas ete buildee avec vos customizations.

**Solution :**

```bash
# Verifier que data/settings.json contient VOS customizations
cat /volume1/docker/excalith-start-page/data/settings.json | head -10

# Rebuild l'image
cd /volume1/docker/excalith-start-page/synology
docker compose build --no-cache

# Restart
docker compose down
docker compose up -d
```

### Tailscale ne connecte pas

```bash
# Verifier que Tailscale tourne
tailscale status

# Test depuis le Synology lui-meme
curl http://localhost:8080

# Verifier que le port n'est pas bloque par le firewall
# DSM > Control Panel > Security > Firewall

# Test de connectivite Tailscale
tailscale netcheck
```

### Page ne charge pas (502 Bad Gateway)

```bash
# Verifier que le container tourne
docker ps | grep excalith-start-page

# Verifier les logs
docker logs excalith-start-page

# Verifier le healthcheck
docker inspect excalith-start-page | grep -A 20 Health
```

## Scripts disponibles

- `scripts/setup.sh` - Preparation initiale (repertoires, permissions)
- `scripts/deploy.sh` - Build et demarrage du container
- `scripts/verify.sh` - Verification complete du deploiement
- `scripts/backup.sh` - Backup des settings avec rotation
- `scripts/update.sh` - Mise a jour du code et rebuild

## Performance

**Ressources typiques :**
- RAM : 50-100 MB
- CPU : negligeable au repos
- Stockage : ~200 MB (image + data)
- Startup time : 5-10 secondes

**Optimisation (optionnelle) :**

Si ressources limitees, ajouter dans `docker-compose.yml` :

```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 256M
    reservations:
      memory: 128M
```

## Securite

- Port 8080 accessible uniquement en local + Tailscale
- Pas d'exposition publique
- Tailscale fournit chiffrement de bout en bout
- Settings stockes localement sur le NAS
- Pas de donnees sensibles exposees

**Bonnes pratiques :**
1. Ne pas exposer le port publiquement
2. Utiliser le firewall DSM pour restreindre l'acces
3. Backups reguliers des settings
4. Mises a jour periodiques de l'image

## Support

Pour questions ou problemes :
- Projet original : https://github.com/excalith/excalith-start-page
- Issues : https://github.com/excalith/excalith-start-page/issues
