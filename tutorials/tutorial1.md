---
title: TD1 &ndash; Paquets PHP
subtitle: Composer, Routage vie l'URL, Twig
layout: tutorial
lang: fr
---

<!-- 

Fournir script SQL pour mise en place BD
ACL sur les photos de profil

Faille XSS 

ESLinter

composer.json
"App\\Covoiturage\\" pour produire la chaine "App\Covoiturage\" en JS (cf test node)
Ce serait différent en PHP ou  "App\\Covoiturage\\" et "App\Covoiturage\\" marcheraient (mais pas "App\Covoiturage\")

Appel de méthode statique avec
call_user_func("App\Covoiturage\Controleur\ControleurPublication::feed]
call_user_func(["App\Covoiturage\Controleur\ControleurPublication", "feed"]
call_user_func([ControleurPublication::class, "feed"]
call_user_func([new App\Covoiturage\Controleur\ControleurPublication(), "feed"]
méthode dynamique avec 
call_user_func([new App\Covoiturage\Controleur\ControleurPublication(), "feed"]
https://www.php.net/manual/en/function.call-user-func.php
Syntaxe liée aux `callable`
https://www.php.net/manual/en/language.types.callable.php

xDebug pour voir ce qui se passe dans le routeur en direct
*  à l'IUT, avec le PHP builtin webserver
   https://www.php.net/manual/en/features.commandline.webserver.php
   ```
   cp /etc/php/8.1/cli/php.ini .
   emacs php.ini
   php -c php.ini -S localhost:8080 
   ```
   Url avec ?XDEBUG_TRIGGER

* sinon debuggeur du serveur Web interne à phpstorm
  (nécessite php-cgi ?!?)

Route /connexion, assets cassés (regarder le code source, cliquer sur le lien vers le CSS)

Pour effacer une reidrection permanente qui reste en cache
-> DevTools > Network > cliquer sur la requête > Clear Browser Cache

Format encore plus simple pour les routes : Annotations (bonus ? comme yaml serviceContainer ?)

Màj des liens : src, href, action, link-css

urlGenerator echappe les Url

Session -> flashBag !

Regarder les notes sous Joplin (lecture livres)

-->

## But du TD

### Point de départ

Dans les 3 premiers TDs, nous allons développer une API REST en PHP. Afin de
pouvoir se concentrer sur l'apprentissage des nouvelles notions, nous allons
partir du code existant d'un site Web de type **réseau social** appelé '**The
Feed**'. Ce site contiendra un fil principal de publications et un système de
connexion d'utilisateur.

L'intérêt de ce site est qu'il ne contient que 2 contrôleurs et un petit nombre d'actions : 
* contrôleur `Publication` : 
  * lire les publications : action `feed`
  * écrire une publication : action `submitFeedy`
* contrôleur `Utilisateur` :
  * afficher la page personnelle avec seulement ses publications : action `pagePerso`
  * s'inscrire : 
    * formulaire (action `afficherFormulaireCreation`), 
    * traitement (action `creerDepuisFormulaire`)
  * se connecter : 
    * formulaire (action `afficherFormulaireConnexion`), 
    * traitement (action `connecter`)
  * se déconnecter : action `deconnecter`

### Démarrage

Récupérer le code de base sur GitLab (avec 2 images de profils).

Pour faire marche le site, il faut créer 2 tables SQL : description, fichier (avec 2 comptes et 2 + 1 posts).

De plus, il faut donner les droits en lecture / exécution à Apache (utilisateur `www-data`). Enfin, comme le site enregistre une photo de profil pour chaque utilisateur, il faut donner les droits en écriture sur le dossier `web/assets/img/utilisateurs/`.


<div class="exercise">
   Faites marcher le site. Explorez toutes les pages.
</div>

## Routes utilisant l'URL

Dans l'optique de développer une *API REST*, nous aurons besoin que les URL des
pages de notre site n'utilisent plus le *query string*.

Par exemple, la route
```
web/controleurFrontal.php?controleur=publication&action=feed
```
va devenir `web/`. Et la route
```
web/controleurFrontal.php?controleur=utilisateur&action=afficherFormulaireConnexion
```
deviendra `web/connexion`. 

Pour ceci, nous allons utiliser une bibliothèque PHP existante, et donc un gestionnaire de bibliothèques : `Composer`.

### Le gestionnaire de paquets `Composer`

`Composer` est utilisé dans le cadre du développement d'applications PHP pour
installer des composants tiers. `Composer` gère un fichier appelé
`composer.json` qui référence toutes les dépendances de votre application. 

#### Initialisation et *Autoloading* de `Composer`

`Composer` fournit un *autoloader*, *c.-à-d.* un chargeur automatique de classe, qui satisfait la spécification `PSR-4`. En effet, cet *autoloader* est très pratique pour utiliser les paquets que nous allons installer via `Composer`.

Commençons donc par remplacer notre *autoloader* `Psr4AutoloaderClass.php` par celui de `Composer`.

<div class="exercise">

1. Créer un fichier `composer.json` à la racine du site Web avec le contenu suivant

   ```json
   {
      "autoload": {
         "psr-4": {
            "TheFeed\\": "src"
         }
      }
   }
   ```
   Ce contenu 
2. Si vous modifiez le fichier `composer.json`, par exemple pour mettre à jour
   vos dépendances, vous devez exécuter la commande :
   ```bash
   composer update
   ```
3. Modifiez le fichier `web/controleurFrontal.php` comme suit :

   ```diff
   -use TheFeed\Lib\Psr4AutoloaderClass;
   -
   -require_once __DIR__ . '/../src/Lib/Psr4AutoloaderClass.php';
   -
   -// instantiate the loader
   -$loader = new Psr4AutoloaderClass();
   -// register the base directories for the namespace prefix
   -$loader->addNamespace('TheFeed', __DIR__ . '/../src');
   -// register the autoloader
   -$loader->register();
   +require_once __DIR__ . '/../vendor/autoload.php';
   ```
   **Aide :** Ce format montre une modification de fichier, similaire à la
   sortie de `git diff`. Les lignes qui commencent par des `+` sont à ajouter, et les lignes avec des `-` à supprimer.
4. Testez votre site qui doit marcher normalement.
   
</div>

### Archivage du routeur par *query string*

Nous allons déplacer le code de routage actuel dans une classe séparée, dans le but de bientôt la remplacer.

<div class="exercise">

1. Dans le fichier `web/controleurFrontal.php`, faites le changement suivant.
   Toutes les lignes supprimées de ce fichier doivent être déplacées dans la
   méthode statique `traiterRequete` d'une nouvelle classe
   `src/Controleur/RouteurQueryString.php`. 

   ```diff
   -// Syntaxe alternative
   -// The null coalescing operator returns its first operand if it exists and is not null
   -$action = $_REQUEST['action'] ?? 'feed';
   -
   -
   -$controleur = "publication";
   -if (isset($_REQUEST['controleur']))
   -    $controleur = $_REQUEST['controleur'];
   -
   -$controleurClassName = 'TheFeed\Controleur\Controleur' . ucfirst($controleur);
   -
   -if (class_exists($controleurClassName)) {
   -    if (in_array($action, get_class_methods($controleurClassName))) {
   -        $controleurClassName::$action();
   -    } else {
   -        $controleurClassName::afficherErreur("Erreur d'action");
   -    }
   -} else {
   -    TheFeed\Controleur\ControleurGenerique::afficherErreur("Erreur de contrôleur");
   -}
   +TheFeed\Controleur\RouteurQueryString::traiterRequete();
   ```

2. Testez votre site qui doit marcher normalement.

</div>

### Nouveau routeur par Url


<div class="exercise">

1. Créez une nouvelle classe `src/Controleur/RouteurURL.php` vide avec le code
   suivant.

   ```php
   <?php
   namespace TheFeed\Controleur;

   class RouteurURL
   {
      public static function traiterRequete() { }
   }
   ```

2. Appelez ce nouveau routeur en modifiant
   `web/controleurFrontal.php` :

   ```diff
   -TheFeed\Controleur\RouteurQueryString::traiterRequete();
   +TheFeed\Controleur\RouteurURL::traiterRequete();
   ```

</div>

Nous allons maintenant coder ce nouveau routeur.

#### Le composant `HttpFoundation`

Comme le dit sa
[documentation](https://symfony.com/doc/current/components/http_foundation.html),
le composant `HttpFoundation` défini une couche orientée objet pour la
spécification *HTTP*. En *PHP*, une requête est représentée par des variables
globales (`$_GET`, `$_POST`, `$_FILES`, `$_COOKIE`, `$_SESSION`, ...), et la
réponse est générée par des fonctions (`echo`, `header()`, `setcookie()`, ...).
Le composant `HttpFoundation` de `Symfony` remplace ces variables globales et
fonctions par une couche orientée objet.


Dans notre cas, nous allons tout d'abord utiliser la classe `Request` de
`HttpFoundation` pour représenter une requête HTTP. Notez que `HttpFoundation`
possède des classes aussi pour les réponses HTTP, les en-têtes HTTP, les
cookies, les sessions (et les messages flash 😉). Nous utiliserons plus tard les
classes liées aux réponses HTTP : `Response`, `RedirectResponse` pour les redirections et `JsonResponse` pour les réponses au format *JSON*. 

<div class="exercise">

1. Exécutez la commande suivante dans le terminal ouvert au niveau de la racine
   de votre site web 

   ```bash
   composer require symfony/http-foundation
   ```

2. Quand on installe une application ou un nouveau composant, `composer` place
   les librairies téléchargées dans un dossier `vendor`. Il n'est pas nécessaire
   de versionner ce dossier souvent volumineux.  
   **Rajoutez** donc une ligne `vendor/` à votre `.gitignore`. 

</div>

Dans un premier temps, notre site va utiliser des URL comme 
```
web/controleurFrontal.php/
web/controleurFrontal.php/connexion
web/controleurFrontal.php/inscription
```
La classe `Request` sera intéressante notamment car elle permet de récupérer
chemin qui nous intéresse (`/`, `/connexion` ou `/inscription`).  


<div class="exercise">

1. Dans `RouteurURL::traiterRequete()`, initialisez l'instance suivante de la
   classe `Requete`
   ```php
   $requete = Request::createFromGlobals();
   ```
   **Explication :** La méthode `createFromGlobals()` récupère les informations de la requête depuis les variables globales `$_GET`, `$_POST`, ... Elle est à peu près équivalente à  
   ```php
   $requete = new Request($_GET,$_POST,[],$_COOKIE,$_FILES,$_SERVER);
   ```

2. La méthode `$requete->getPathInfo()` permet d'accéder au bout d'URL qui nous
   intéresse (`/`, `/connexion` ou `/inscription`).
 
   **Affichez** cette variable dans `RouteurURL::traiterRequete()` et accédez
   aux URL précédentes pour voir chemin s'afficher. 

</div>

#### Le composant `Routing`

Comme l'indique sa
[documentation](https://symfony.com/doc/current/routing.html), le composant
`Routing` de `Symfony` va permettre de faire l'association entre une URL (par ex. `/` ou `/connexion`) et une action, c'est-à-dire une fonction PHP comme `ControleurPublication::feed`.


<div class="exercise">

1. Exécutez la commande suivante dans le terminal ouvert au niveau de la racine
   de votre site web 
   ```bash
   composer require symfony/routing
   ```

2. Créez votre première route avec le code suivant à insérer dans
   `RouteurURL::traiterRequete()` : 

   ```php
   $routes = new RouteCollection();

   // Route feed
   $route = new Route("/", [
      "_controller" => "\TheFeed\Controleur\ControleurPublication::feed",
   ]);
   $routes->add("feed", $route);
   ```
   **Explication :** Une nouvelle `Route $route` associe au chemin `/` la
   méthode `feed()` de `ControleurPublication`. Puis cette route est ajoutée
   dans l'ensemble de toutes les routes `RouteCollection $routes`. 

3. Les informations de la requête essentielles pour le routage (méthode `GET` ou
   `POST`, *query string*, paramètres *POST*, ...) sont extraites dans un objet
   séparé : 
   ```php
   $contexteRequete = (new RequestContext())->fromRequest($requete);
   ```
   **Ajoutez** cette ligne et affichez temporairement son contenu.

4. Nous pouvons alors rechercher quelle route correspond au chemin de la requête
   courante : 
   ```php
   $associateurUrl = new UrlMatcher($routes, $contexteRequete);
   $donneesRoute = $associateurUrl->match($requete->getPathInfo());
   ```
   **Ajoutez** ce code et affichez temporairement le contenu de `$donneesRoute`. Où se trouve l'information de la méthode PHP à appeler ?

5. **Ajoutez** le code suivant pour appeler enfin l'action PHP correspondante : 
   ```php
   call_user_func($donneesRoute["_controller"]);
   ```
   **Explication :** La fonction `call_user_func($nomFonction)` exécute la
   fonction dont le nom est stocké dans `$nomFonction`. Elle est proche du code
   `$nomFonction()`, mais accepte des entrées plus générales -- nous la
   préférerons donc.

6. Votre site doit désormais répondre correctement à une requête à l'URL
   `web/controleurFrontal.php/`.

<!-- ??

$requete = Request::createFromGlobals();
which is almost equivalent to the more verbose, but also more flexible, __construct() call:

 Copy
$requete = new Request(
    $_GET,
    $_POST,
    [],
    $_COOKIE,
    $_FILES,
    $_SERVER
);

voir aussi 
$requete->getPathInfo(); -->

</div>





Debuggage

On pourrait se passer de `ControllerResolver` actuellement. Mais cette classe est
plus flexible et vous évitera des problèmes plus tard (si l'action n'est pas une méthode statique par exemple).


<div class="exercise">

1. Créez une nouvelle classe `src/Controleur/RouteurURL.php` avec le code suivant.

   ```php
   <?php
   namespace TheFeed\Controleur;

   use Symfony\Component\HttpFoundation\Request;
   use Symfony\Component\HttpKernel\Controller\ArgumentResolver;
   use Symfony\Component\HttpKernel\Controller\ControllerResolver;
   use Symfony\Component\Routing\Matcher\UrlMatcher;
   use Symfony\Component\Routing\RequestContext;
   use Symfony\Component\Routing\Route;
   use Symfony\Component\Routing\RouteCollection;

   class RouteurURL
   {
      public static function traiterRequete() {
         $requete = Request::createFromGlobals();
         $contexteRequete = (new RequestContext())->fromRequest($requete);

         $routes = new RouteCollection();

         // Route feed
         $route = new Route("/", [
               "_controller" => "\App\Covoiturage\Controleur\ControleurPublication::feed",
         ]);
         $routes->add("feed", $route);

         $urlMatcher = new UrlMatcher($routes, $contexteRequete);
         $routeData = $urlMatcher->match($requete->getPathInfo());
         $requete->attributes->add($routeData);

         $controllerResolver = new ControllerResolver();
         $controller = $controllerResolver->getController($requete);

         call_user_func($controller);
      }
   }
   ```

2. Pour faire marcher ce code, nous devons installer de nouveaux paquets PHP.
   Ouvrez un terminal à la racine de votre projet et exécutez la commande
   suivante :

   ```bash
   composer require symfony/http-foundation symfony/routing symfony/http-kernel
   ```

3. Il ne vous reste plus qu'à appeler le nouveau routeur

   ```diff
   -TheFeed\Controleur\RouteurQueryString::traiterRequete();
   +// TheFeed\Controleur\RouteurQueryString::traiterRequete();
   +\TheFeed\Controleur\RouteurURL::traiterRequete();
   ```

**ici** commencer l'explication du nouveau routeur. Debuggage

On pourrait se passer de `ControllerResolver` actuellement. Mais cette classe est
plus flexible et vous évitera des problèmes plus tard (si l'action n'est pas une méthode statique par exemple).




</div>










### Installation

Pour installer `Twig` dans votre application, nous allons utiliser le **gestionnaire de dépendances** 

Rajoutez vendor au .gitignore

En effet, quand vous souhaiterez installer votre application dans un autre environnement (une autre machine), seul le fichier `composer.json` suffit. Lors de l'installation, ce fichier sera lu et les dépendances seront téléchargées et installées automatiquement.

Pour utiliser `composer`, il faut se placer à la **racine du projet**, là où se trouve (ou se trouvera après l'installation de `Twig`) le fichier `composer.json`.

<div class="exercise">

1. Ouvrez un terminal à la racine de votre projet et exécutez la commande suivante :

   ```bash
   composer require twig/twig
   ```

2. Attendez la fin de l'installation. Allez observer le contenu du fichier `composer.json` fraichement créé ainsi que le contenu du dossier `vendor`.
</div>

Quelques conseils :

   * Sur une autre machine (ou dans un nouvel environnement), pour installer les dépendances (et donc initialiser le dossier `vendor`), il suffit d'exécuter la commande :

   ```bash
   composer install
   ```

   * Si vous modifiez le fichier `composer.json` ou que vous souhaitez simplement mettre à jour vos dépendances, vous pouvez exécuter la commande :

   ```bash
   composer update
   ```



## Composant Twig

`Twig` est un **moteur de templates** qui permet de générer tout type de document (pas seulement de l'HTML!) en utilisant des données passées en paramètres. Twig fournit toutes les structures de contrôles utiles (if, for, etc...) et permet de placer les données de manière fluide. Il est aussi possible d'appeler des méthodes sur certaines données (des objets) et d'appliquer certaines fonctions (ou filtres) pour transformer les données (par exemple, mettre en majuscule la première lettre...).

Twig permet également de construire des modèle de templates qui peuvent être étendus et modifiés de manière optimale. Le template va définir des espaces nommés `blocs` qu'il est alors possible de redéfinir indépendamment dans un sous-template. Cela va nous être très utile par la suite!

Il est aussi possible d'installer (ou de définir soi-même) des extensions pour ajouter de nouvelles fonctions de filtrage! On peut aussi définir certaines variables globales accessibles dans tous les templates.

Dans notre contexte, nous utiliserons `Twig` pour générer nos pages HTML car cela présente différents avantages non négligeables :

   * Le langage est beaucoup moins verbeux que du PHP, il est beaucoup plus aisé de placer les données aux endroits désirés de manière assez fluide.
   * En spécifiant un petit paramètre, les pages générées avec `Twig` seront naturellement protégées contre les failles `XSS`! (plus besoin d'utiliser `htmlspecialchars`).
   * Nous allons pouvoir définir des templates globaux pour l'affichage des éléments identiques à chaque page (header, footer, etc...) et ainsi de pas répéter le code à plusieurs endroits.

### Le langage

* L'instruction ```{% raw %}{{ donnee }}{% endraw %}``` permet d'afficher une donnée à l'endroit souhaité (à noter : **les espaces après et avant les accolades sont importants!**). On peut également appeler des méthodes (si c'est un objet) : ```{% raw %}{{ donnee.methode() }}{% endraw %}```. On peut aussi appeler une fonction définie par `Twig` ou une de ses extensions : ```{% raw %}{{ fonction(donnee)) }}{% endraw %}```. Ou bien un filtre, par exemple : ```{% raw %}{{ donnee|upper }}{% endraw %}``` pour passer une chaîne de caractères en majuscule. Il est aussi possible de combiner plusieurs filtres, par exemple ```{% raw %}{{ donnee|lower|truncate(20) }}{% endraw %}```.

* Il est possible de définir une variable locale : 

```twig
{% raw %}
{% set exemple = "coucou" %}
<p>{{exemple}}</p>
{% endraw %}
```

* La structure conditionnelle `if` permet de ne générer une partie du document que si une condition est remplie :

```twig
{% raw %}
{% if test %}
   Code HTML....
{% endif %}
{% endraw %}
```

Il est bien sûr possible de construire des conditions complexes avec les opérateur : `not`, `and`, `or`, `==`, `<`, `>`, `<=`, `>=`, etc... par exemple :

```twig
{% raw %}
{% if test and (not (user.getName() == 'Simith') or user.getAge() <= 20) %}
   Code HTML....
{% endif %}
{% endraw %}
```

* La structure conditionnelle `for` permet de parcourir une structure itérative (par exemple, un tableau) :

```twig
{% raw %}
{% for data in tab %}
   <p>{{ data }}</p>
{% endfor %}
{% endraw %}
```

Si c'est un tableau associatif et qu'on veut accèder aux clés et aux valeurs en même temps :

```twig
{% raw %}
<ul>
{% for key, value in tab %}
   <li>{{ key }} = {{ value }}</li>
{% endfor %}
<ul>
{% endraw %}
```

On peut aussi faire une boucle variant entre deux bornes : 

```twig
{% raw %}
{% for i in 0..10 %}
    <p>{{ i }}ème valeur</p>
{% endfor %}
{% endraw %}
```

Pour créer un `bloc` qui pourra être **redéfini** dans un sous-template, on écrit simplement :

```twig
{% raw %}
{% block nom_block %}
   Contenu du bloc...
{% endblock %}
{% endraw %}
```

Pour **étendre** un template, au début du novueau template, on écrit simplement :

```twig
{% raw %}
{% extends "nomFichier.html.twig" %}
{% endraw %}
```

Par exemple, imaginons le template suivant, `test.html.twig` :

```twig
{% raw %}
<html>
   <head>
      <title>{% block titre %}Test {% endblock %}</title>
   </head>
   <body>
      <header>...</header>
      <main>{% block main %} ... {% endblock %}</main>
      <footer>...</footer>
   </body>
</html>
{% endraw %}
```

Vous pouvez alors créer le sous-template suivant qui copiera exactement le contenu de `test.html.twig` et modifiera seulement le titre et le contenu du main : 

```twig
{% raw %}
{% extends "test.html.twig" %}
{% block titre %}Mon titre custom{% endblock %}
{% block main %} <p>Coucou!</p> {% endblock %}
{% endraw %}
```

Il n'est pas obligatoire de redéfinir tous les blocs quand on étend un template. Dans l'exemple ci-dessus, on aurait pu seulement redéfinir le bloc `main` sans changer le titre de la page, par exemple.

Il est tout à fait possible d'utiliser un bloc de structure à l'intérieur d'un autre bloc de structure. Il est aussi tout à fait possible de créer un bloc rédéfinissable à l'intérieur d'un autre bloc...Il est aussi possible de faire des sous-templates de sous-templater. Voyez ça comme une hiéarchie entre classes! Les blocs sont comme des méthodes de la classe parente qu'il est possible de redéfinir!

Pour en savoir plus sur `Twig`, vous pouvez consulter [La documentation officielle](https://www.branchcms.com/learn/docs/developer/twig).

### Initialisation de Twig

`Twig` s'initialise comme suit :

```php
//Au début du fichier, après avoir chargé l'autodloader
use Twig\Environment;
use Twig\Loader\FilesystemLoader;

//On doit indiquer à Twig où sont situés nos templates. 
$twigLoader = new FilesystemLoader(cheminVersDossierTemplate);

//Permet d'échapper le texte contenant du code HTML et ainsi éviter la faille XSS!
$twig = new Environment($twigLoader, ["autoescape" => "html"]);
```

<div class="exercise">

1. Créez un dossier `templates` à la racine de votre projet.

2. Dans votre fichier `feed.php`, chargez l'autoloader de `composer` au tout début.

3. Importez les classes de `Twig` nécéssaires (avec `use`).

4. Initialisez `Twig`. Vous préciserez que les templates se trouvent dans le sous dossier `templates` par rapport au fichier `feed.php`. Vous pouvez pour cela réeutiliser une syntaxe similaire au chemin utilisé pour charger l'autoloader.

5. Rechargez votre page. S'il n'y a pas d'erreurs, c'est que c'est bon! Nous allons maintenant l'utiliser...

</div>

### Un premier template

Vous allez maintenant utiliser un **template** Twig pour réaliser l'affichage de la page principale de **The Feed**.

Pour générer le résultat obtenu via un **template** Twig, il faut éxécuter le code :

```php
//sousCheminTemplate : Correspond au sous-chemin du template à partir du dossier de template indiqué à twig. S'il se trouve à la racine du dossier de templates, on indique alors seulement son nom

// tableauAssociatif : Un tableau associatif de paramètres passés au template. Par exemple si on lui donne ["message" => $test], une variable "message" sera utilisable dans le template twig.

$page = $twig->render(sousCheminTemplate, tableauAssociatif);

//Puis, pour l'afficher comme réponse
echo $page
```

Par exemple, si je veux charger le fichier `personne.html.twig` situé à la racine du dossier `templates` en lui passant un objet Personne en paramètre, je peux faire :

```php
$personne = ...

$page = $twig->render('personne.html.twig', ["personne" => $personne]);
echo $page
```

Bien sûr, on peut passer plusieurs paramètres (il suffit de les ajouter au tableau associatif).

<div class="exercise">

1. Dans le dossier `templates`, créez un fichier nommé `firstFeed.html.twig`.

2. Déplacez le code HTML (mêlé de PHP) permettant de générer la page dans votre nouveau template. Pour rappel, il devrait avoir cette allure :

   ```php
   <!DOCTYPE html>
   <html lang="fr">
      <head>
         <title>The Feed</title>
         <meta charset="utf-8">
         <link rel="stylesheet" type="text/css" href="styles.css">
      </head>
      <body>
         <header>
               <div id="titre" class="center">
                  <a href="feed.php"><span>The Feed</span></a>
               </div>
         </header>
         <main id="the-feed-main">
               <div id="feed">
                  <form id="feedy-new" action="feed.php" method="post">
                     <fieldset>
                           <legend>Nouveau feedy</legend>
                           <div>
                              <textarea minlength="1" name="message" placeholder="Qu'avez-vous en tête?"></textarea>
                           </div>
                           <div>
                              <input id="feedy-new-submit" type="submit" value="Feeder!">
                           </div>
                     </fieldset>
                  </form>
                  <?php foreach ($publis as $publi) { ?>
                     <div class="feedy">
                           <div class="feedy-header">
                              <img class="avatar" src="anonyme.jpg" alt="avatar de l'utilisateur">
                              <div class="feedy-info">
                                 <span><?php echo $publi->getLoginAuteur() ?> </span>
                                 <span> - </span>
                                 <span><?php echo $publi->getDateFormatee()?></span>
                                 <p><?php echo $publi->getMessage() ?></p>
                              </div>
                           </div>
                     </div>
                  <?php } ?>
               </div>
         </main>
      </body>
   </html>
   ```
3. Adaptez ce code pour utiliser le langage de `Twig` à la place, en remplaçant toutes les parties PHP. Vous pouvez considérer qu'un tableau nommé `publications` est passé en paramètre à ce template. 

4. Dans `feed.php` récupérez la page généré par `Twig` en utilisant ce template en passant en paramètres les `publications` récupérées depuis le repository. Affichez cette page avec `echo`.

5. Rechargez la page et observez qu'elle s'affiche toujours bien, mais cette fois, en étant générée par `Twig`!

</div>


### Division des tâches

Dans notre page, on peut distinguer clairement une partie commune qui sera similaire à toutes nos futures pages et une autre partie spécifique à la page courante. :

* La strucutre de base de la page, une partie du head et le header seront communs à toutes les pages

* Le titre de la page et une partie du body seront spécifiques à la page courante.

<div class="exercise">

1. Créez un template `base.html.twig` dans le dossier `templates`.

2. Dans ce template, reprenez tout le contenu du template `firstFeed.html.twig` sauf le `<main>`.

3. Effacez le titre contenu dans `<title>` et à la place, créez un `block` nommé `page_title`.

4. Au tout début du **body**, créez un `block` nommé `page_content`.

</div>

Vous venez de créer le template "de base". Toutes les pages de notre application vont l'étendre afin de posséder la même structure et injecteront leur propre titre et leur propre contenu dans les blocs correspondants.

<div class="exercise">

1. Dans le dossier `templates`, créez un sous-dossier `Publications`.

2. Créez un template `feed.html.twig` dans le dossier `Publications` et faites en sorte qu'il **étende** le template `base.html.twig`.

3. Dans ce template, redéfinissez les `blocks` **page_title** et **page_content** afin d'y placer respectivement le `titre` de la page et le `main` initialement définis dans `firstFeed.html.twig`.

4. Supprimez le template `firstFeed.html.twig`

5. Modifiez `feed.php` afin qu'il génère la page en utilisant le template `Publications/feed.html.twig`.

6. Rechargez votre page et vérifiez que tout fonctionne bien.

</div>

Pour mieux comprendre l'efficacité de ces templates et vérifier que vous savez les mainpuler, vous allez créer une autre page.

<div class="exercise">

1. Dans le dossier `templates`, créez un sous-dossier `Test`.

2. Créez un template `exemple.html.twig` dans le dossier `Test` et faites en sorte qu'il **étende** le template `base.html.twig`.

3. Dans ce template, redéfinissez les `blocks` **page_title** et **page_content** afin d'y placer respectivement le `titre` "Exemple" et un élément HTML `<main> ... </main>` contenant `<p>Coucou!</p>`.

4. A la racine de votre projet, créez un fichier `exempleTemplate.php`.

5. Dans ce fichier, faites en sorte d'afficher la page générée par le template `exemple.html.twig`.

6. Chargez cette page à l'adresse : 

   [http://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD2/exempleTemplate.php)](http://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD2/exempleTemplate.php) et observez le résultat!

</div>

### Les composants et phases essentiels d'une application web

Si l'architecure logicielle a une place importante dans le cadre du développement d'une application web, d'autres composants sont aussi essentiels à son bon fonctionnement. Comme nous sommes dans le cadre d'une application **client / serveur**, la partie **cliente** (navigateur web) ne peut pas appeler directement la bonne fonction d'un **controller**. Pour cela, une **requête** est transmise et traitée par l'application côté **serveur** avant de trouver le bon controller et la bonne fonction à éxécuter. Ce mécanisme est appellé le **routing**. On va donc généralement avoir besoin :

   * D'un **point d'entrée** qui est le premier fichier éxécuté lors de la reception d'une requête sur votre application. Son rôle est de récupérer les informations utiles de la requête et de la transmettre à votre application.

   * D'un **routeur**, c'est-à-dire une portion de code qui associe des chemins (des **routes**) à des fonctions sur des controllers bien précis et permet donc d'éxécuter le bon code en se basant sur les données fournies par la requête. Par exemple, on pourrait créer une association : `/product/1/details` => `ProductController` => `getProductDetailsAction($idProduct)`. Le rôle du routeur serait alors de reconnaitre ce chemin quand il est présent dans l'URL d'une requête et d'éxécuter la fonction `getProductDetailsAction` qui renverra un nouveau résultat (une page web, des données...).

   * D'un **résolveur d'arguments** qui permet d'extraire des données fournies dans l'URL de la route. Dans l'exemple précédent, nous avions l'id du produit dans l'URL. Le résolveur doit donc permettre d'extraire cette donnée et de la passer à la fonction getProductDetailsAction. A noter que cela ne concerne pas les données envoyées par les méthodes `GET`, `POST` ou autre, qui sont accessibles dans le corps de la requête.

### Un premier controleur et des routes

Maintenant que nous avons quelques actions, il nous faut créer les routes pour y accèder! Pour cela, nous allons nous aider du **composant de routing** de Symfony.

Le fonctionnement de ce composant est assez simple :

   * On initialise un objet `RouteCollection` dont le rôle est d'enregistrer et gérer toutes les routes de notre application.

   * On crée un onjet `Route` en spécifiant :

      * Le chemin de la route (à partir de la racine de notre site), par exemple `/products`, `/users/login`...On peut aussi spécifier des **paramètres** dans le chemin qui seront lus lors du décodage de la route et transmis au controller. Il faut alors que la fonction prenant en charge l'action dans le controller possède un paramètre du même nom. Par exemple : `/products/{id}`. Ici, le chemin possède un paramètre `id`. Les routes correspondantes peuvent donc être `/products/0`, `/products/1`, etc...De son côté, la fonction correspondate dans le **controller** devra possèder un paraètre `$id`. Il est bien sur possibles de préciser plusieurs paramètres à divers endroits du chemin.

      * Le **controller** (en utilisant son namespace, comme pour importer sa `classe`) et le nom de la `fonction` à éxécuter. Ces deux éléments sont séparés par `::`. Par exemple, on pourrait avoir : `MyApp\\Application\\MyController::maFonction` (donc, la fonction `maFonction` du controller MyController).

      * Des valeurs par défaut pour les éventuels paramètres définis dans le chemin.

   * Il faut ensuite ajouter la route dans la **collection de routes** en l'associant avec un **nom**.

   Tout cela peut se résumer avec deux exemples :

   ```php
   use Symfony\Component\Routing\Route;
   use Symfony\Component\Routing\RouteCollection;

   $routes = new RouteCollection();

   $firstRoute = new Route("/hello", [
      "_controller" => "MyApp\\Application\\HelloController::hello" //Le _ devant "controller" est important.
   ]);

   $routes->add('hello_world', $firstRoute);

   $secondRoute = new Route("/products/{id}", [
      "_controller" => "MyApp\\Application\\ProductController::details" //La fonction "details" doit avoir un paramètre $id!
      "id" => 0 // Valeur par défaut...non obligatoire!
   ]);

   $routes->add('product_details', $secondRoute);
   ```

   Par défaut (avec ce que nous allons construire) l'objet `Request` contenant les données de la requête est automatiquement transmis à la fonction du controller qui va s'éxécuter si celle-ci précise un paramètre de type `Request`. On ne le précise donc pas au niveau des routes.

### La classe principale du framework

Nous avons notre **controller** et nos **routes** mais rien pour les faire fonctionner...C'est-à-dire, un bout de code qui puisse permettre de traiter la requête reçue de manière à identifier la route correspondante, extraire les éventuelles données et donc éxécuter la bonne fonction sur le bon controller (avec les bons paramètres!).

Encore une fois, quelques composants et classes de Symfony vont pouvoir nous aider :

   * Un **URL Matcher** : permet d'identifier la route correspondant au chemin visé par l'URL dans un ensemble de routes. On va s'en servir pour spécifier les informations relatives à la route dans les attributs de la requête.

   * Un **résolveur de controller** : permet de récupérer la focntion du controller à utiliser, à partir de la requête.

   * Un **résolveur d'arguments** : permet de récupérer les valeurs des paramètres à passer à la fonction du controller à éxécuter. C'est ce composant qui va notamment permettre de récupèrer les éventuels paramètres spécifiés dans le chemin de la route. Il va également ajouter la requpete elle-même aux paramètres (utile pour récupérer les données dans le corps de la requête transmis par un formulaire, via GET, POST, etc...).

En utilisant ces trois composants, on peut donc récupérer à partir de la requête la fonction à appeler et les paramètres à lui donner. Il suffit alors d'utiliser la fonction PHP : `call_user_func_array($fonction, $parametres)`. Le paramètre `$fonction` est un objet de type `callable`, c'est à dire quelquechose qui peut être appellé, comme une fonction. `$parametres` correspond à un tableau associatif associant chaque nom de paramètre à une valeur. Cette fonction appelle donc la fonction désigné par `$fonction` en lui passant les paramètres définis dans `$parametres`.

Dans notre cas, cette fonction appellera donc une action définie dans un `controller` qui renverra un objet `Response` (contenant, normalement, le code HTML de la page à renvoyer). On peut également y spécifier un **code de réponse** qui indique le **status** de la requpete (success, not found, etc...). Par défaut, si on ne précise rien, le code `200` est utilisé (success == tout va bien).

Dans le cadre de notre **Framework**, nous allons regroupper tout cela dans une classe `AppFramework` qui se chargera de reçevoir une requête, trouver la bonne focntion à éxécuter, récupérer la réponse de l'action déclenchée et la retourner. Notre application se chargera ensuite de transmettre la réponse au client.

### Limiter les méthodes d'une route

Actuellement, quand nous créons une **route**, il est possible de la "déclencher" avec n'importe quel méthode HTTP : GET, POST mais également certaines que nous n'avons pas encore utilisé : PUT, PATCH, DELETE...En effet, le controller ne peut pas faire la différence quand il récupère une donnée dans l'objet `Request` avec la methode `get`. Néamoins, il est tout à fait possible d'iniquer qu'une route n'est accessible qu'avec certaines méthodes.

Pour cela, après avoir créé un objet `Route`, il suffit d'utiliser cette fonction :

```php
$route->setMethods([..., ..., ...]);
```

Comme vous pouvez le constater, cette fonction prend un tableau en entrée. Ce tableau contient simplements le nom des méthodes autorisés sous la forme de chaînes de caractères. Par exemple :

```php
//N'autorise que la méthode "GET" et la méthode "PUT" sur cette route
$route->setMethods(["GET", "PUT"]);
```

Si on souhaite éxécuter deux actions différentes pour deux méthodes différentes pour une même route, il faut créer deux routes avec le même chemin et limiter les méthodes autorisées. Par exemple :

```php
$firstRoute = new Route("/test", [
   "_controller" => "MyApp\\Application\\HelloController::bonjourGet"
]);
$firstRoute->setMethods(["GET"]);

$secondRoute = new Route("/test", [
   "_controller" => "MyApp\\Application\\HelloController::bonjourPost"
]);
$secondRoute->setMethods(["POST"]);
```
