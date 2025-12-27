# Convertisseur de devises (microservices) testé sur ubuntu 25.04

Application composée de trois microservices Flask : un service qui récupère les taux, un service qui calcule les conversions et une petite interface web. Chaque service tourne dans son propre conteneur Docker et l'ensemble se lance avec `docker-compose`.

Pour une installation clé en main sur Ubuntu, exécutez le script `[setup_ubuntu.sh](./setup_ubuntu.sh)` depuis la racine du dépôt :
```bash
chmod +x ./setup_ubuntu.sh
./setup_ubuntu.sh
```
Il installe les dépendances, construit les images et démarre les conteneurs.

## Services
- **rate_service** : API Flask qui interroge `api.exchangerate.host` pour obtenir les taux en temps réel.
- **convert_service** : API Flask qui appelle `rate_service`, valide le montant et calcule la conversion.
- **frontend** : application Flask qui sert une page HTML simple et relaie les requêtes vers `convert_service`.

## Prérequis
- Python 3, pip, Flask, Docker et docker-compose installés.

### Installation automatique (Ubuntu)
Un script automatise l'installation des dépendances, la construction des images et le lancement des conteneurs :
```bash
chmod +x setup_ubuntu.sh
./setup_ubuntu.sh
```
Il installe Python 3, pip, Docker, docker-compose, construit les images et démarre les services. Si `docker-compose-plugin` n'est pas disponible sur votre version d'Ubuntu (ex. 25.04), le script bascule automatiquement vers le paquet `docker-compose` ou une installation `pip` pour fournir la commande `docker-compose`. L'interface sera accessible sur http://localhost:8000 (login URL), l'API de conversion sur http://localhost:5001/convert et l'API de taux sur http://localhost:5000/rate. Si le script ajoute votre utilisateur au groupe `docker`, reconnectez-vous (ou lancez `newgrp docker`) pour utiliser Docker sans `sudo`.

### Ubuntu (terminal Bash)
1. Installer Python, pip, Flask et Docker :
   ```bash
   sudo apt update
   # docker-compose-plugin (Docker Compose v2) n'est pas présent sur toutes les versions d'Ubuntu.
   # Remplacez-le par docker-compose si le paquet n'existe pas sur votre distribution.
   sudo apt install -y python3 python3-pip python3-venv docker.io docker-compose-plugin
   # ou, si le paquet ci-dessus est introuvable :
   # sudo apt install -y python3 python3-pip python3-venv docker.io docker-compose
   python3 -m pip install --user --upgrade pip
   python3 -m pip install --user flask
   ```
2. Autoriser votre utilisateur à utiliser Docker sans `sudo` :
   ```bash
   sudo usermod -aG docker "$USER"
   newgrp docker
   ```
3. Vérifier que Docker et docker-compose fonctionnent :
   ```bash
   docker --version
   docker compose version   # ou docker-compose version selon votre installation
   ```

### Windows 11 (PowerShell)
1. Installer Python (inclut pip) via le Microsoft Store ou Winget :
   ```powershell
   winget install -e --id Python.Python.3.11
   python -m pip install --upgrade pip
   python -m pip install flask
   ```
2. Installer Docker Desktop (inclut docker-compose) :
   ```powershell
   winget install -e --id Docker.DockerDesktop
   ```
   - Lors du premier lancement, activez WSL 2 si demandé, puis redémarrez.
3. Vérifier que Docker fonctionne :
   ```powershell
   docker --version
   docker compose version   # ou docker-compose version selon votre installation
   ```

## Installation du projet
1. Cloner le dépôt puis entrer dans le dossier :
   ```bash
   git clone <adresse_du_repo> convert_devises_microservices
   cd convert_devises_microservices
   ```
2. Construire et lancer tous les conteneurs (premier démarrage) :
   ```bash
   docker-compose up --build
   ```
   Vous pouvez ensuite relancer plus rapidement avec :
   ```bash
   docker-compose up
   ```

## Lancement avec Docker Compose
```bash
docker-compose up --build
```
Les points d'entrée :
- API des taux : http://localhost:5000/rate
- API de conversion : http://localhost:5001/convert
- Interface web : http://localhost:8000

Variables d'environnement (voir `docker-compose.yml`) :
- `EXTERNAL_RATE_API` : endpoint utilisé par `rate_service` (défaut `https://api.exchangerate.host/latest`).
- `RATE_SERVICE_URL` : URL utilisée par `convert_service` pour joindre `rate_service`.
- `CONVERTER_URL` : URL utilisée par `frontend` pour joindre `convert_service`.

## Exemples de requêtes
- Récupérer un taux :
  ```bash
  curl "http://localhost:5000/rate?base=USD&target=EUR"
  ```
- Conversion via l'API :
  ```bash
  curl "http://localhost:5001/convert?base=USD&target=JPY&amount=25"
  ```
- Conversion via le frontend (même origine) :
  ```bash
  curl -X POST -F "base=USD" -F "target=GBP" -F "amount=10" http://localhost:8000/convert
  ```
Puis ouvrez http://localhost:8000 dans un navigateur pour utiliser l'interface.

## Tests unitaires (logique de conversion)
Les tests se trouvent dans `convert_service/tests`. Depuis `convert_service` :
```bash
pip install -r requirements.txt
pytest
```

## Structure du projet
- `rate_service/` : API de taux, Dockerfile, requirements.
- `convert_service/` : API de conversion, logique métier, tests, Dockerfile, requirements.
- `frontend/` : interface web + proxy, templates, Dockerfile, requirements.
- `docker-compose.yml` : orchestre les trois services.

## Remarques
- Le service de taux dépend d'une API externe ; assurez-vous d'avoir un accès réseau à `api.exchangerate.host`.
- Le service des taux interroge toujours le TND pour qu'il soit disponible si vous souhaitez convertir depuis/vers le dinar tunisien.
- Le formulaire web propose un bouton « Swap » pour intervertir rapidement les devises source et cible.
