---
title: Déboguer PHP avec Docker et PhpStorm
layout: tutorial
lang: fr
---

Ce tutoriel vous montre comment configurer un environnement de débogage pas-à-pas pour du code PHP exécuté dans un conteneur Docker, avec PhpStorm comme IDE. Vous allez ainsi utiliser un outil professionnel de développement avec Xdebug.

## Architecture du débogage

Le débogage pas-à-pas repose sur trois éléments :

- Un **exécuteur** : ici, une requête HTTP initiée par un navigateur.
- Un **runtime** : le serveur PHP dans le conteneur Docker qui exécute le code PHP.
- Une **interface de débogage** : PhpStorm sur votre machine hôte, qui affiche en temps réel l'exécution du code.

L'objectif est que le runtime (PHP + Xdebug dans Docker) se connecte automatiquement à PhpStorm (sur la machine hôte) pour signaler les points d'arrêt atteints dans le code. La communication s'établit via le port **9003** et le nom d’hôte **`host.docker.internal`**.

## Ajout de la résolution `host.docker.internal` sur Linux

Sous Linux, le nom `host.docker.internal` n’est pas résolu automatiquement. 

Si votre machine hôte n'est pas sur Linux et que le `Dockerfile` de l'image de votre conteneur ne contient pas le code suivant
```python
# Dans votre Dockerfile
RUN echo "172.17.0.1 host.docker.internal" >> /etc/hosts
```
alors, il faut donc ajouter manuellement l’entrée dans le fichier `/etc/hosts` du conteneur. Exécutez le code suivant dans le terminal de votre conteneur Docker
```bash
echo "172.17.0.1 host.docker.internal" | tee -a /etc/hosts
```

Cela permettra au serveur PHP (dans Docker) de contacter PhpStorm (sur la machine hôte) via `host.docker.internal:9003`.

## Installer une extension Xdebug pour navigateur

Dans votre navigateur (Firefox ou Chrome), installez une extension Xdebug :

* [Xdebug Helper (Chrome)](https://chromewebstore.google.com/detail/xdebug-helper-by-jetbrain/aoelhdemabeimdhedkidlnbkfhnhgnhm)
* [Xdebug Helper (Firefox)](https://addons.mozilla.org/fr/firefox/addon/xdebug-helper-for-firefox/)

Cette extension sert à signaler à Xdebug que vous souhaitez démarrer une session de débogage pour une requête donnée.

## Activer le débogage depuis le navigateur

Une fois l’extension installée :

1. Cliquez sur l’icône de l’extension.
2. Activez le mode **Debug**.
3. L’icône devient verte : cela signifie que les requêtes HTTP envoyées contiennent un cookie spécial (`XDEBUG_SESSION`), qui activera le débogueur dans le serveur PHP.

## Écouter les connexions de Xdebug dans PhpStorm

Dans PhpStorm :

1. Cliquez sur l’icône du téléphone en haut à droite de l’interface ("Start Listening for PHP Debug Connections").
2. Assurez-vous que PhpStorm écoute bien sur le port **9003** (c’est le port par défaut pour Xdebug v3).

## Configurer le path mapping

Le serveur PHP dans Docker connaît les chemins internes comme `/var/www/html/path_to/script.php`, alors que PhpStorm connaît le chemin sur la machine hôte, par exemple `~/public_html/path_to/script.php`.

Il faut donc configurer un "path mapping" dans PhpStorm :

### Option 1 : configuration via l’interface

1. Allez dans **Settings > PHP > Servers**.
2. Créez un nouveau serveur avec les options suivantes :

   * **Name** : `docker`
   * **Host** : `localhost`
   * **Port** : `80` (ou le port exposé par Docker)
   * **Debugger** : `Xdebug`
   * **Use path mappings** : activé
   * Mappez `~/public_html/chemin_vers_votre_site` → `/var/www/html/chemin_vers_votre_site`

### Option 2 : configuration via fichier XML

Dans le dossier `.idea` de votre projet, créez (ou modifiez) le fichier `deployment.xml` :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="PublishConfigData">
    <serverData>
      <server name="docker">
        <deployment>
          <option name="externalMappings">
            <map>
              <entry key="/var/www/html" value="~/public_html"/>
            </map>
          </option>
        </deployment>
      </server>
    </serverData>
  </component>
</project>
```

## Placer un point d’arrêt

Dans PhpStorm, ouvrez le fichier PHP que vous souhaitez déboguer, et cliquez dans la marge gauche à côté d’une ligne de code. Un rond rouge apparaît : c’est un **point d’arrêt**.

## Déclencher une requête

Dans le navigateur, déclenchez l’exécution du script PHP (ex : en rechargeant une page). Si tout est bien configuré :

* Xdebug intercepte la requête.
* Il contacte PhpStorm via `host.docker.internal:9003`.
* PhpStorm s’ouvre automatiquement et s’arrête sur le point d’arrêt défini.

> Si cela ne fonctionne pas, vérifiez que PhpStorm "écoute", que le port 9003 est ouvert et que Xdebug est bien activé.

## Références utiles

* Documentation PhpStorm : [Zero-configuration debugging](https://www.jetbrains.com/help/phpstorm/2025.1/zero-configuration-debugging.html?php.debugging.zero_configuration&keymap=GNOME)

