# Champions Style — Application Flutter (native)

## ⚠️ Important à savoir avant de commencer

Ce projet a été écrit **sans pouvoir être compilé ni testé** par l'assistant qui
l'a créé (environnement sans Flutter/Dart installé). Le code suit les
conventions standards de Flutter et a été relu attentivement, mais il est
possible que quelques erreurs de compilation apparaissent à la première
tentative — c'est normal. Si ça arrive, copie le message d'erreur exact
et partage-le pour obtenir une correction.

## Ce que contient cette première version

- Structure complète du projet Flutter (thème Or & Noir identique aux
  autres versions, base de données locale SQLite, navigation)
- **Tableau de bord**
- **Clients** — avec le système de mesures Homme/Femme complet (13/14
  champs selon le sexe, comme sur les versions ordinateur et web)
- **Commandes** — avec changement de statut et facturation automatique
- **Factures**
- Menu latéral + écran "Plus" donnant accès aux modules à venir (Produits,
  Devis, Paiements, Dépenses, Fournisseurs, Stock, Employés, Rapports,
  Corbeille, Paramètres) — actuellement des écrans d'attente, à construire
  dans les prochaines étapes.

---

## 🚀 Méthode recommandée : compiler via GitHub (rien à installer sur ton PC)

Ce projet contient déjà un fichier de configuration (`.github/workflows/build_apk.yml`)
qui permet à **GitHub de compiler l'application à ta place**, gratuitement,
dans le cloud — pas besoin d'installer Flutter ni Android Studio sur ton PC.

### Étape 1 — Créer un dépôt GitHub

1. Va sur **https://github.com/new**
2. Donne un nom au dépôt (ex : `champions-style-flutter`)
3. Laisse-le en **Public** ou **Privé**, peu importe
4. Clique sur "Create repository" (ne coche aucune case d'initialisation)

### Étape 2 — Envoyer ce projet sur GitHub

Dans une invite de commande, à l'intérieur du dossier `champions_style_flutter` :
```
git init
git add .
git commit -m "Version initiale"
git branch -M main
git remote add origin https://github.com/TON-NOM-UTILISATEUR/champions-style-flutter.git
git push -u origin main
```
(Remplace l'adresse par celle de ton propre dépôt, affichée par GitHub après l'étape 1.)

### Étape 3 — Laisser GitHub compiler automatiquement

Dès que le code est envoyé, GitHub démarre la compilation tout seul. Pour suivre :
1. Va sur la page de ton dépôt GitHub
2. Clique sur l'onglet **"Actions"** en haut
3. Tu verras une compilation en cours (rond orange qui tourne), puis ✅ vert si ça réussit, ou ❌ rouge si erreur

### Étape 4 — Télécharger l'application compilée

Une fois le ✅ vert obtenu :
1. Clique sur la compilation terminée
2. Tout en bas de la page, dans la section **"Artifacts"**, télécharge **`champions-style-apk`**
3. Dézippe-le : tu obtiens `app-release.apk`
4. Transfère ce fichier sur ton téléphone Android (par clé USB, WhatsApp, Google Drive...) et installe-le comme n'importe quelle application

### En cas d'erreur (❌ rouge)

Clique sur la compilation en échec, puis sur l'étape qui a un ❌ (probablement "Compiler l'application") pour voir le message d'erreur exact. **Copie-le moi intégralement**, et je corrige le code en conséquence — tu n'auras qu'à refaire un `git add . && git commit -m "correction" && git push` pour relancer une nouvelle compilation automatique.

---

## Méthode alternative : compiler en local

Si tu préfères tout installer sur ton PC plutôt que d'utiliser GitHub :

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installé (canal stable)
- Android Studio installé (pour le SDK Android)
- Un téléphone Android en mode débogage USB, ou un émulateur

### Commandes
```
flutter pub get
flutter run
```
Pour générer directement un fichier `.apk` :
```
flutter build apk --release
```
Le fichier sera dans `build/app/outputs/flutter-apk/app-release.apk`.

