# MediTrack API - Bloc 2

## Description
API backend pour MediTrack, déployée sur AWS en utilisant une architecture conteneurisée moderne (ECS Fargate) avec une base de données sécurisée (RDS PostgreSQL).

## Architecture
- **ECS Fargate** : Exécution de l'API conteneurisée
- **RDS PostgreSQL** : Base de données relationnelle sécurisée
- **ALB (Application Load Balancer)** : Exposition publique sécurisée
- **ECR** : Registre privé pour les images Docker
- **VPC existante** : Réutilisation de l'infrastructure du Bloc 1

## Structure du projet
```
meditrack-api-b2/
├── api-backend/          # Code source de l'API
│   ├── package.json      # Dépendances Node.js
│   ├── Dockerfile        # Configuration conteneur
│   └── index.js          # Code source API
├── terraform/            # Infrastructure as Code
│   ├── main.tf          # Configuration des ressources AWS
│   ├── variables.tf     # Variables de configuration
│   └── outputs.tf       # Sorties des ressources
└── README.md            # Documentation du projet
```

## Prérequis
- Compte AWS avec Free Tier activé
- AWS CLI configuré (`aws configure`)
- Terraform installé
- Docker installé

## Déploiement
1. **Build et push de l'image Docker :**
   ```bash
   cd api-backend
   docker build -t meditrack-api .
   aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-3.amazonaws.com
   docker tag meditrack-api:latest 123456789012.dkr.ecr.eu-west-3.amazonaws.com/meditrack-api:latest
   docker push 123456789012.dkr.ecr.eu-west-3.amazonaws.com/meditrack-api:latest
   ```

2. **Déploiement Terraform :**
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

## Variables à configurer
- `vpc_id` : ID de la VPC du Bloc 1
- `private_subnets` : IDs des sous-réseaux privés du Bloc 1
- `public_subnets` : IDs des sous-réseaux publics du Bloc 1
- `security_group_id` : ID du security group du Bloc 1

## Ressources AWS utilisées (Free Tier)
- **ECR** : 500 Mo de stockage gratuit
- **RDS PostgreSQL** : db.t3.micro (750h/mois gratuites)
- **ECS Fargate** : 750h/mois gratuites
- **ALB** : 750h/mois gratuites

## Endpoints
- **ALB DNS** : URL publique de l'API
- **Base de données** : Endpoint RDS sécurisé
- **ECR** : URL du registre privé

## Sécurité
- Chiffrement des données au repos (RDS)
- Accès restreint via security groups
- Connexion sécurisée entre composants
- Conformité RGPD/HDS

## Tests
- `GET /` : Vérification que l'API est en cours d'exécution
- `GET /contacts` : Récupération des contacts
- `POST /contact` : Création d'un nouveau contact