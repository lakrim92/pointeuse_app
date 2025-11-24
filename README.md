🦊 Pointeuse Crèche – Application Android
===========================================

Application de pointage dédiée à la crèche Les Écureuils, permettant aux salariés d’enregistrer leurs heures et à l’administrateur de gérer l’ensemble du système (absences, exports, etc.).

## 📌 Fonctionnalités principales

✔️ **Pointage des salariés**
* Enregistrement de l’arrivée
* Enregistrement du départ
* Détection automatique de l’état du salarié (présent / sorti)

✔️ **Gestion des absences**
* Types d’absence :
  * Congé
  * Maladie
  * Absence justifiée
  * Autre
* Les absents apparaissent dans tous les exports avec leur motif.

✔️ **Export Excel complet**
* Tous les salariés du mois sélectionné
* Les pointages (arrivée / départ)
* Les absents (avec motif)
* Les salariés non pointés (mention : "Non pointé")
* Fichier lisible par Excel, Google Sheets, LibreOffice…

✔️ **Interface administrateur sécurisée**
* Mot de passe administrateur
* Gestion des salariés
* Gestion des absences
* Visualisation des pointages
* Export du mois
* Sauvegarde / restauration de la base SQLite

✔️ **Fonctionne hors-ligne**
* Base de données locale SQLite
* Aucun besoin d’Internet

✔️ **Splash screen personnalisé**
* logo : autoheal.png
* Effet de fondu
* Fond dégradé
* S’affiche au chargement de l’application

# 📱 Installation sur tablette / téléphone Android

Il existe 2 méthodes :

## 🔹 Méthode 1 — Installation simple via APK (recommandée)

1. Récupérez le fichier :

```
app-release.apk
```

2. Copiez-le sur la tablette (USB / Drive / mail)
3. Ouvrez-le sur la tablette
4. Autorisez l’installation depuis Sources inconnues
4. Cliquez sur Installer

➡️ **L’application est installée et prête.**

## 🔹 Méthode 2 — Installation via USB (ADB)

1️⃣ **Activer les options développeur**

Sur la tablette :
1. Paramètres → À propos
2. Appuyer 7 fois sur Numéro de build
3. Retour → Options développeur
4. Activer :
  * Débogage USB
  * Installation via USB

2️⃣ **Vérifier la connexion**

Sur le PC :

```
adb services
```
Si tout est OK :

```
xxxxxx devive
```

3️⃣ **Installer l’application via ADB**

Placer le terminal dans le dossier contenant l’APK :

```
cd build/app/outputs/flutter-apk/
```

puis installer :

```
adb install -r app-release.apk
```

```-r``` → installe en remplaçant l’ancienne version sans effacer les données.

## 🔨 Compilation (pour mise à jour ou Play Store)

✔️ **Générer un APK**

```
flutter build apk --release
```

→ Fichier obtenu :
```build/app/outputs/flutter-apk/app-release.apk```

## 🔧 Technologies utilisées

- Flutter 3.24
- Dart 2.18
- SQLite (sqflite)
- Provider
- Excel (excel)
- Shared Preferences
- Secure Storage
- Android SDK 35

## 🧩 Code source

Le code complet est disponible sur GitHub :
https://github.com/lakrim92/pointeuse_app

## 🛟 Support et améliorations

Pour toute demande d’amélioration ou assistance :
- Ouvrez une issue sur GitHub
- Ou demandez-moi directement ici 😄
