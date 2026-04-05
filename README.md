# MediTrack API - Bloc 2

## Description
API backend pour MediTrack, déployée sur AWS en utilisant une architecture conteneurisée moderne (ECS Fargate) avec une base de données sécurisée (RDS PostgreSQL).

## Architecture
- **ECS Fargate** : Exécution de l'API conteneurisée
- **RDS PostgreSQL 16** : Base de données relationnelle sécurisée (chiffrement SSL)
- **ALB (Application Load Balancer)** : Exposition publique sécurisée
- **ECR** : Registre privé pour les images Docker
- **VPC existante** : Réutilisation de l'infrastructure du Bloc 1
- **CloudWatch Logs** : Centralisation des logs ECS (`/ecs/meditrack-task`)

## Ressources AWS déployées
| Ressource | Identifiant |
|---|---|
| VPC | `vpc-0c2104571acf62314` |
| Subnet public A | `subnet-0a1c6a71c82029e2b` (eu-west-3a) |
| Subnet public B | `subnet-066786660c256b561` (eu-west-3b) |
| Security Group ECS | `sg-086ac4729224d079f` |
| Security Group RDS | `sg-062150b16dcc1bbc2` |
| Internet Gateway | `igw-07328f12f43d1caa3` |
| Instance RDS | `meditrack-db.ch2wkq00gd3u.eu-west-3.rds.amazonaws.com` |
| Dépôt ECR | `730335232588.dkr.ecr.eu-west-3.amazonaws.com/meditrack-api` |
| Cluster ECS | `meditrack-cluster` |
| Service ECS | `meditrack-service` |
| ALB | `meditrack-alb-788195322.eu-west-3.elb.amazonaws.com` |
| Target Group | `meditrack-tg` |
| Rôle IAM | `ecsTaskExecutionRole` |
| Log Group | `/ecs/meditrack-task` |

## Structure du projet
```
meditrack-infra-greenops/
├── api-backend/
│   ├── package.json          # Dépendances Node.js
│   ├── Dockerfile            # Configuration conteneur
│   ├── index.js              # Code source API
│   └── app.test.js           # Tests Jest
├── task-definition.json      # Définition de la tâche ECS
├── service-config.json       # Configuration du service ECS
├── trust-policy.json         # Politique IAM ecsTaskExecutionRole
├── .github/
│   └── workflows/
│       └── test.yml          # Pipeline CI/CD GitHub Actions
└── README.md
```

## Prérequis
- Compte AWS avec les politiques IAM suivantes :
  - `AmazonEC2FullAccess`
  - `AmazonS3FullAccess`
  - `AmazonRDSFullAccess`
  - `AmazonECS_FullAccess`
  - `AmazonECRFullAccess`
  - `IAMFullAccess`
  - `CloudWatchLogsFullAccess`
  - `ElasticLoadBalancingFullAccess`
- AWS CLI configuré (`aws configure`)
- Docker installé

## Déploiement

### 1. Créer le rôle IAM ECS
```bash
python -c "
import json
policy = {
    'Version': '2012-10-17',
    'Statement': [{
        'Effect': 'Allow',
        'Principal': {'Service': 'ecs-tasks.amazonaws.com'},
        'Action': 'sts:AssumeRole'
    }]
}
with open('trust-policy.json', 'w') as f:
    json.dump(policy, f, indent=2)
"
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

### 2. Créer le dépôt ECR et pusher l'image
```bash
aws ecr create-repository --repository-name meditrack-api --region eu-west-3

cd api-backend
docker build -t meditrack-api:latest .

aws ecr get-login-password --region eu-west-3 | \
  docker login --username AWS --password-stdin 730335232588.dkr.ecr.eu-west-3.amazonaws.com

docker tag meditrack-api:latest \
  730335232588.dkr.ecr.eu-west-3.amazonaws.com/meditrack-api:latest

docker push \
  730335232588.dkr.ecr.eu-west-3.amazonaws.com/meditrack-api:latest
```

### 3. Créer la base de données RDS
```bash
aws rds create-db-instance \
  --db-instance-identifier meditrack-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16 \
  --master-username meditrackadmin \
  --master-user-password 'MotDePasseComplexe123!' \
  --allocated-storage 20 \
  --storage-type gp2 \
  --db-subnet-group-name meditrack-subnet-group \
  --vpc-security-group-ids sg-062150b16dcc1bbc2 \
  --no-publicly-accessible \
  --region eu-west-3
```

### 4. Créer le cluster ECS et déployer
```bash
aws ecs create-cluster --cluster-name meditrack-cluster --region eu-west-3
aws logs create-log-group --log-group-name /ecs/meditrack-task --region eu-west-3
aws ecs register-task-definition --cli-input-json file://task-definition.json --region eu-west-3
aws ecs create-service --cli-input-json file://service-config.json --region eu-west-3
```

## Variables d'environnement (task definition)
| Variable | Description |
|---|---|
| `DB_HOST` | Endpoint RDS |
| `DB_USER` | Utilisateur PostgreSQL |
| `DB_PASSWORD` | Mot de passe PostgreSQL |
| `DB_NAME` | Nom de la base (`postgres`) |
| `DB_PORT` | Port PostgreSQL (`5432`) |
| `DB_SSL` | Activer SSL (`true` en production) |

## Endpoints API
| Méthode | Route | Description |
|---|---|---|
| GET | `/` | Vérifie que l'API tourne |
| GET | `/contacts` | Liste tous les contacts |
| POST | `/contact` | Crée un nouveau contact |

### Exemple POST /contact
```json
{
  "nom": "Test",
  "email": "test@example.com",
  "message": "Hello MediTrack"
}
```

## Tests

### CI/CD — GitHub Actions
Les tests s'exécutent automatiquement à chaque push sur `develop` :
```
✅ GET / retourne 200
✅ GET /contacts retourne un tableau
✅ POST /contact sans nom retourne 400
✅ POST /contact sans email retourne 400
✅ POST /contact valide retourne 201
✅ GET /contacts retourne les bons champs
✅ POST /contact puis GET /contacts — intégration
```

### Tests manuels (PowerShell)
```powershell
# GET /
Invoke-RestMethod -Uri "http://meditrack-alb-788195322.eu-west-3.elb.amazonaws.com/" -Method GET

# GET /contacts
Invoke-RestMethod -Uri "http://meditrack-alb-788195322.eu-west-3.elb.amazonaws.com/contacts" -Method GET

# POST /contact valide
Invoke-RestMethod -Uri "http://meditrack-alb-788195322.eu-west-3.elb.amazonaws.com/contact" -Method POST -ContentType "application/json" -Body '{"nom":"Test","email":"test@example.com","message":"Hello MediTrack"}'

# POST /contact sans nom (doit retourner 400)
Invoke-RestMethod -Uri "http://meditrack-alb-788195322.eu-west-3.elb.amazonaws.com/contact" -Method POST -ContentType "application/json" -Body '{"email":"test@example.com"}'
```

## Sécurité
- Chiffrement SSL des connexions RDS
- Chiffrement des données au repos (AES-256)
- Accès restreint via security groups en cascade (ALB → ECS → RDS)
- Subnets publics pour ECS avec IP publique assignée
- RDS non accessible publiquement (`no-publicly-accessible`)
- Rôle IAM dédié `ecsTaskExecutionRole` avec permissions minimales
- Conformité RGPD/HDS

## Gestion des coûts
Pour éviter les frais inutiles quand tu ne testes pas :
```bash
# Mettre le service en veille
aws ecs update-service --cluster meditrack-cluster --service meditrack-service --desired-count 0 --region eu-west-3

# Arrêter RDS
aws rds stop-db-instance --db-instance-identifier meditrack-db --region eu-west-3

# Relancer
aws ecs update-service --cluster meditrack-cluster --service meditrack-service --desired-count 1 --region eu-west-3
aws rds start-db-instance --db-instance-identifier meditrack-db --region eu-west-3
```

## Dépôt GitHub
https://github.com/romrec/meditrack-infra-greenops
