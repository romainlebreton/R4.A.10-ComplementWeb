---
title: TD1 &ndash; Paquets PHP
subtitle: Composer, Routage via l'URL
layout: tutorial
lang: fr
---

<!-- 

Voir notes pour l'an prochain : 
* donner les méthodes GET/POST directement dans le new Route
* rajouter les routes directement à $routes
* utiliser la syntaxe 1st class callable
  ["_controller" => ControleurPublication::afficherListe(...)]
* remplacer call_user_func_array par le spread operator
  _controlleur(...arguments) 

-->

<!-- 

TODO : 
* code de base
* setfacl -m u:www-data:rwx ressources/img/utilisateurs

* SQL avec login et message vérolés HTML
* ? explication .htaccess réécriture d'URL ?
* supprimer mon mot de passe de connexion à la BD

Fournir script SQL pour mise en place BD
ACL sur les photos de profil

Faille XSS 

ESLinter

composer.json
"App\\Covoiturage\\" pour produire la chaine "App\Covoiturage\" en JS (cf test node)
Ce serait différent en PHP ou  "App\\Covoiturage\\" et "App\Covoiturage\\" marcheraient (mais pas "App\Covoiturage\")

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

Route /connexion, ressources cassés (regarder le code source, cliquer sur le lien vers le CSS)

Pour effacer une reidrection permanente qui reste en cache
-> DevTools > Network > cliquer sur la requête > Clear Browser Cache

Format encore plus simple pour les routes : Annotations (bonus ? comme yaml serviceContainer ?)

Màj des liens : src, href, action, link-css

urlGenerator echappe les Url

Session -> flashBag !

Regarder les notes sous Joplin (lecture livres)

-->
Au travers des 5 TDs de ce cours, nous allons développer une API REST en PHP. 
Afin de pouvoir se concentrer sur l'apprentissage des nouvelles notions, nous allons
partir du code existant d'un site Web de type **réseau social** appelé '**The
Feed**'. Ce site contiendra un fil principal de publications et un système de
connexion d'utilisateur.

L'intérêt de ce site est qu'il ne contient que 2 contrôleurs et un petit nombre d'actions : 
* contrôleur `Publication` : 
  * lire les publications : action `afficherListe`
  * écrire une publication : action `creerDepuisFormulaire`
* contrôleur `Utilisateur` :
  * afficher la page personnelle avec seulement ses publications : action `afficherPublications`
  * s'inscrire : 
    * formulaire (action `afficherFormulaireCreation`), 
    * traitement (action `creerDepuisFormulaire`)
  * se connecter : 
    * formulaire (action `afficherFormulaireConnexion`), 
    * traitement (action `connecter`)
  * se déconnecter : action `deconnecter`

## Mise en place du site de base

Ce TD nécessite de faire tourner un serveur Web PHP sous Docker. Si votre
machine a gardé sa configuration du semestre 3, suivez les instructions de
l'exercice 2 suivant (sautez l'exercice 1). Si vous devez installer Docker,
suivez les instructions des exercices 1 et 2 suivants.

<div class="exercise">
**Installer Docker**

Allez sur la page du [dépôt Serveur Web
Docker](https://gitlabinfo.iutmontp.univ-montp2.fr/Enseignants-Web/docker/-/blob/main/README.md),
et faites le tutoriel d’installation et de configuration qui se trouve dans la
partie *Tutoriel > Premier contact*. Vous ne devez normalement pas y passer plus
de 30 minutes.
</div>

<div class="exercise">
**Lancer votre serveur Web Docker**

Démarrer *Docker Desktop*. Dans l'onglet Gauche *Containers*, relancez votre
conteneur à l'aide du bouton Play ![Play](https://gitlabinfo.iutmontp.univ-montp2.fr/Enseignants-Web/docker/-/raw/main/img/BoutonPlay.png).

Pour rappel, ce conteneur exécute un serveur Web PHP. Le port 80 du conteneur est relié par défaut au port 80 de la machine hôte. Le dossier `/var/www/html` du conteneur est relié par défaut au dossier `public_html` de la machine hôte. 

En pratique, une fois le conteneur lancé, vous accédez aux pages Web situées
dans le dossier `public_html` de la machine hôte en naviguant à partir de l'URL
`http://localhost` via votre navigateur Web.

</div>

<div class="exercise">

1. Rendez-vous dans [cet espace](https://gitlabinfo.iutmontp.univ-montp2.fr/r4.a.10-complementweb/etu) et 
trouvez le fork du dépôt `TheFeed` déjà cloné dans un sous-groupe portant votre nom.

2. Sur votre ordinateur, dans le dossier partagé `public_html` utilisé par votre conteneur docker, créez un
nouveau répertoire `ComplementWeb` et clonez le dépôt *Git* `TheFeed` dans ce nouveau répertoire.

3. Sur l'interface de **Docker Desktop**, cliquez sur votre conteneur puis sur l'onglet **Exec**. Un
terminal est alors affiché. Gardez ce terminal ouvert pour le reste du TD, vous allez être amené à y
exécuter plusieurs commandes. Pour une utilisation plus confortable de ce terminal, vous pouvez exécuter 
la commande `bash`.

4. Dans le terminal de votre conteneur, déplacez-vous à la racine du projet, donc dans 
le répertoire `./ComplementWeb/TheFeed`.

5. Il faut donner les droits en lecture / exécution à Apache (utilisateur
   `www-data`). Dans le terminal de votre conteneur **Docker**, exécutez les instructions suivantes :
   ```bash
   chown -R root:www-data .
   chmod g+w ./ressources/img/utilisateurs/
   ```

6. Importez les tables `utilisateurs` et `publications` dans votre base de
   données SQL préférée : 
   * Pour *MySQL* via [phpMyAdmin](https://webinfo.iutmontp.univ-montp2.fr/my/), vous devez : 
     * exécuter le [script d'import MySQL]({{site.baseurl}}/assets/TD1/theFeedTD1DepartMySQL.sql),
     * mettre à jour le fichier de configuration `src/Configuration/ConfigurationBDDMySQL.php` 
       avec votre login et mot de passe.
   * Si vous souhaitez plutôt utiliser la base de données *PostgreSQL* fournie par le département, vous devez : 
     * exécuter le [script d'import PostgreSQL]({{site.baseurl}}/assets/TD1/theFeedTD1DepartPostgreSQL.sql),
     * mettre à jour le fichier de configuration `src/Configuration/ConfigurationBDDPostgreSQL.php` 
       avec votre login et mot de passe,
     * préciser la bonne classe de configuration `ConfigurationBDDPostgreSQL` au
       niveau du constructeur de
       `src/Modele/Repository/ConnexionBaseDeDonnees.php`
     * dans les classes `PublicationRepository` et `UtilisateurRepository`,
       modifier les `$data['nomDeColonne']` pour mettre tous les noms de
       colonnes en minuscule. En effet, *PostgreSQL* passe en minuscule tous les
       identifiants (sauf s'ils sont entourés de guillemets doubles `"`, auquel
       car il faudra toujours y faire référence avec des guillemets doubles).

7. Tentez d'accéder au site. L'URL devrait être [http://localhost/ComplementWeb/TheFeed/web/controleurFrontal.php](http://localhost/ComplementWeb/TheFeed/web/controleurFrontal.php).

8. Créez un nouvel utilisateur via la page d'inscription, connectez-vous et créez une nouvelle publication.  
   *Souvenez-vous* bien de votre identifiant et mot de passe car nous nous en resservirons.* 

9. Faites marcher le site. Explorez toutes les pages. Enfin, déconnectez-vous.
 
</div>

Dans l'optique de développer une *API REST*, nous aurons besoin que les URL des
pages de notre site n'utilisent plus le *query string*.

Par exemple, la route
```
web/controleurFrontal.php?controleur=publication&action=afficherListe
```
va devenir `web/publications`. Et la route
```
web/controleurFrontal.php?controleur=utilisateur&action=afficherFormulaireConnexion
```
deviendra `web/connexion`.

Certaines routes paramétrées seront aussi adaptées. Par exemple, la route
```
web/controleurFrontal.php?controleur=utilisateur&action=afficherListePublications&idUtilisateur=1
```
va devenir `web/utilisateurs/1/publications`.

Pour ceci, nous allons utiliser une bibliothèque PHP existante, et donc un
gestionnaire de bibliothèques : `Composer`.

## Le gestionnaire de paquets `Composer`

`Composer` est utilisé dans le cadre du développement d'applications PHP pour
installer des composants tiers. `Composer` gère un fichier appelé
`composer.json` qui référence toutes les dépendances de votre application. 

### Initialisation et *Autoloading* de `Composer`

`Composer` fournit un *autoloader*, *c.-à-d.* un chargeur automatique de classe,
qui satisfait la spécification `PSR-4`. En effet, cet *autoloader* est très
pratique pour utiliser les paquets que nous allons installer via `Composer`.

Commençons donc par remplacer notre *autoloader* `Psr4AutoloaderClass.php` par celui de `Composer`.

<div class="exercise">

1. Créer un fichier `composer.json` à la racine du votre dossier `TheFeed` avec le contenu suivant

   ```json
   {
      "autoload": {
         "psr-4": {
            "TheFeed\\": "src"
         }
      }
   }
   ```
2. Afin d'installer toutes les dépendances listées dans le fichier `composer.json`, il faut
   exécuter la commande :
   ```bash
   composer install
   ```

   Dans notre cas, cela va nous permettre d'installer **l'autoloader**.

   Toujours dans votre terminal, à la racine de votre projet, sur docker, exécutez cette commande.

   Dans le futur, si vous modifiez le fichier `composer.json` (par exemple pour mettre à jour
   vos dépendances) vous devez exécuter la commande :
   ```bash
   composer update
   ```

2. Quand on installe une application ou un nouveau composant, `composer` place
   les librairies téléchargées dans un dossier `vendor`. Il n'est pas nécessaire
   de versionner ce dossier souvent volumineux.  
   **Rajoutez** donc une ligne `/vendor/` à votre `.gitignore`. **Dites** aussi
   à *Git* d'ignorer son fichier de configuration interne `/composer.lock`.

3. Modifiez le fichier `web/controleurFrontal.php` comme suit :

   ```diff
   -use TheFeed\Lib\Psr4AutoloaderClass;
   -
   -require_once __DIR__ . '/../src/Lib/Psr4AutoloaderClass.php';
   -
   -// initialisation en désactivant l'affichage de débogage
   -$chargeurDeClasse = new Psr4AutoloaderClass(false);
   -$chargeurDeClasse->register();
   -// enregistrement d'une association "espace de nom" → "dossier"
   -$chargeurDeClasse->addNamespace('TheFeed', __DIR__ . '/../src');
   +require_once __DIR__ . '/../vendor/autoload.php';
   ```
   **Aide :** Ce format montre une modification de fichier, similaire à la
   sortie de `git diff`. Les lignes qui commencent par des `+` sont à ajouter, et les lignes avec des `-` à supprimer.

4. Testez votre site qui doit marcher normalement. Si tout est bon, vous pouvez alors supprimer notre 
ancien **autoloader** : `Lib\Psr4AutoloaderClass.php`. 
</div>

### Archivage du routeur par *query string*

Nous allons déplacer le code de routage actuel dans une classe séparée, dans le but de bientôt le remplacer.

<div class="exercise">

1. Créez une nouvelle classe `src/Controleur/RouteurQueryString.php` contenant une méthode statique `traiterRequete`, vide pour le moment:

   ```php
   <?php
   namespace TheFeed\Controleur;

   class RouteurQueryString
   {
      public static function traiterRequete() : void { }
   }
   ```

2. Dans le fichier `web/controleurFrontal.php`, faites le changement suivant.
   Toutes les lignes supprimées de ce fichier doivent être déplacées dans la méthode statique `traiterRequete` de `src/Controleur/RouteurQueryString.php`.

   ```diff
   -// Syntaxe alternative
   -// The null coalescing operator returns its first operand if it exists and is not null
   -$action = $_REQUEST['action'] ?? 'afficherListe';
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
   -    \TheFeed\Controleur\ControleurGenerique::afficherErreur("Erreur de contrôleur");
   -}
   +\TheFeed\Controleur\RouteurQueryString::traiterRequete();
   ```

2. Testez votre site qui doit toujours marcher normalement.

</div>

## Nouveau routeur par Url

<div class="exercise">

1. Créez une nouvelle classe `src/Controleur/RouteurURL.php` vide avec le code
   suivant.

   ```php
   <?php
   namespace TheFeed\Controleur;

   class RouteurURL
   {
      public static function traiterRequete() : void { }
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

### Le composant `HttpFoundation`

Comme le dit sa
[documentation](https://symfony.com/doc/current/components/http_foundation.html),
le composant `HttpFoundation` défini une couche orientée objet pour la
spécification *HTTP*. En *PHP*, une requête est représentée par des variables
globales (`$_GET`, `$_POST`, `$_FILES`, `$_COOKIE`, `$_SESSION`, ...), et la
réponse est générée par des fonctions (`echo`, `header()`, `setcookie()`, ...).
Le composant `HttpFoundation` de `Symfony` remplace ces variables globales et
fonctions par une couche orientée objet.

Pour information, `Symfony` est l'un des 2 principaux *framework* de
développement de site Web professionnels en PHP. Dans ce cours, nous nous
attacherons aux notions derrière `Symfony` plutôt qu'à `Symfony` lui-même.
Ainsi, vos connaissances vous permettront de vous adapter plus facilement à de
nouveaux outils, que ce soit `Symfony` ou autre chose... Pour ces raisons, nous
n'utiliserons que des composants de `Symfony`.


Dans notre cas, nous allons tout d'abord utiliser la classe `Request` de
`HttpFoundation` pour représenter une requête HTTP. Notez que `HttpFoundation`
possède des classes aussi pour les réponses HTTP, les en-têtes HTTP, les
cookies, les sessions (et les messages flash 😉). Les classes liées aux réponses
HTTP seront abordées dans le TD2.

<div class="exercise">

1. Exécutez la commande suivante dans le terminal docker ouvert au niveau de la racine
   de votre projet :

   ```bash
   composer require symfony/http-foundation
   ```

   À l'issue de l'exécution de cette commande, un nouveau composant est ajouté au répertoire
   `vendor`.

</div>

Dans un premier temps, notre site va utiliser des URL comme 
```
web/controleurFrontal.php/publications
web/controleurFrontal.php/connexion
web/controleurFrontal.php/utilisateurs/2/publications
```
La classe `Request` sera intéressante, notamment car elle permet de récupérer la
partie du chemin qui nous intéresse : `/publications`, `/connexion` ou `/utilisateurs/2/publications`.  

Dans la plupart des exercices qui vont suivre, nous allons utiliser des classes qui proviennent des
composants installés grâce à composer. Il faudra donc souvent utiliser la directive `use` afin
d'importer ces classes et pouvoir l'utiliser dans la classe courante. Dans le code donné, nous
vous indiquons les imports à faire. Il faudra systématiquement placer ces imports tout en haut de la classe,
juste après la directive `namespace`.

<div class="exercise">

1. Dans `RouteurURL::traiterRequete()`, initialisez l'instance suivante de la
   classe `Requete`
   ```php
   //A placer en haut de la classe, après "namepsace"
   use Symfony\Component\HttpFoundation\Request;

   //A ajouter dans traiterRequete
   $requete = Request::createFromGlobals();
   ```
   **Explication :** La méthode `createFromGlobals()` récupère les informations de la requête depuis les variables globales `$_GET`, `$_POST`, ... Elle est à peu près équivalente à  
   ```php
   $requete = new Request($_GET,$_POST,[],$_COOKIE,$_FILES,$_SERVER);
   ```

2. La méthode `$requete->getPathInfo()` permet d'accéder au bout d'URL qui nous
   intéresse (`/publications`, `/connexion` ou `/inscription`).
 
   **Affichez** temporairement le contenu de `$requete->getPathInfo()` dans `RouteurURL::traiterRequete()` 
   (par exemple avec `var_dump`) et accédez aux URL précédentes pour voir le chemin s'afficher.

   Par exemple, tentez d'accéder à [http://localhost/ComplementWeb/TheFeed/web/controleurFrontal.php/publications](http://localhost/ComplementWeb/TheFeed/web/controleurFrontal.php/publications).

   Une fois que vous avez terminé, vous pouvez cesser d'afficher le chemin.

</div>

### Le composant `Routing`

Comme l'indique sa
[documentation](https://symfony.com/doc/current/routing.html), le composant
`Routing` de `Symfony` va permettre de faire l'association entre une URL (par
ex. `/publications` ou `/connexion`) et une action, c'est-à-dire une fonction PHP comme
`ControleurPublication::afficherListe`.


<div class="exercise">

1. Exécutez la commande suivante dans le terminal docker ouvert au niveau de la racine
   de votre projet :
   ```bash
   composer require symfony/routing
   ```

2. Créez votre première route avec le code suivant à insérer dans
   `RouteurURL::traiterRequete()` : 

   ```php
   //A placer en haut de la classe, après "namespace", avec les autres "use"

   use Symfony\Component\Routing\Route;
   use Symfony\Component\Routing\RouteCollection;

   //A placer à la suite, dans traiterRequete

   $routes = new RouteCollection();
   // Route afficherListe
   $route = new Route(
      path: "/publications", 
      defaults: [
         "_controller" => "\TheFeed\Controleur\ControleurPublication::afficherListe",
      ]
   );
   $routes->add("afficherListe", $route);
   ```
   **Explication :** Une nouvelle `Route $route` associe au chemin (paramètre `path`) `/publications` la
   méthode `afficherListe()` de `ControleurPublication` (paramètre `defaults`). Puis cette route est ajoutée
   dans l'ensemble de toutes les routes `RouteCollection $routes` sous le nom (unique) `afficherListe`. À noter
   que le nom donné à la route n'a pas besoin d'être le nom de la fonction visée, cela peut être ce que l'on veut.

   Le **nom** associé à la route est important et nous sera assez utile un peu plus loin dans le TD.

   On peut éventuellement simplifier en créant directement une instance de `Route` dans l'appel à `$routes->add` :

   ```php
   $routes->add("afficherListe", new Route(
      path: "/publications", 
      defaults: [
         "_controller" => "\TheFeed\Controleur\ControleurPublication::afficherListe",
      ]
   )); 
   ```

3. Les informations de la requête essentielles pour le routage (méthode `GET` ou
   `POST`, *query string*, paramètres *POST*, ...) sont extraites dans un objet
   séparé : 
   ```php
   use Symfony\Component\Routing\RequestContext;

   $contexteRequete = (new RequestContext())->fromRequest($requete);
   ```
   **Ajoutez** cette ligne (toujours dans `RouteurURL::traiterRequete()`) et 
   affichez temporairement son contenu (avec `var_dump`).

4. Nous pouvons alors rechercher quelle route correspond au chemin de la requête
   courante : 
   ```php
   use Symfony\Component\Routing\Matcher\UrlMatcher;

   $associateurUrl = new UrlMatcher($routes, $contexteRequete);
   $donneesRoute = $associateurUrl->match($requete->getPathInfo());
   ```
   **Ajoutez** ce code et affichez temporairement le contenu de `$donneesRoute`. Où se trouve l'information de la méthode PHP à appeler ?

5. **Ajoutez** le code suivant pour appeler enfin l'action PHP correspondante : 
   ```php
   $donneesRoute["_controller"]();
   ```
   **Explication :** Ce code exécute la fonction dont le nom est stocké dans
   `$donneesRoute["_controller"]`.

6. Votre site doit désormais répondre correctement à une requête à l'URL
   `web/controleurFrontal.php/publications` (vérifiez), sauf les liens vers 
   le CSS et les photos qui deviennent invalides.

</div>

### Réécriture d'URL

Passons à notre deuxième route : `/connexion`.

<div class="exercise">

1. Ajoutez la deuxième route : 

   ```php
   use TheFeed\Controleur\ControleurUtilisateur;

   // Route afficherFormulaireConnexion
   $route = new Route(
      path: "/connexion", 
      defaults: [
         "_controller" => "\TheFeed\Controleur\ControleurUtilisateur::afficherFormulaireConnexion",
         // Syntaxes équivalentes 
         // "_controller" => ControleurUtilisateur::class . "::afficherFormulaireConnexion",
         // "_controller" => [ControleurUtilisateur::class, "afficherFormulaireConnexion"],
      ]
   );
   $routes->add("afficherFormulaireConnexion", $route);
   ```

   Notez les syntaxes équivalentes : 
   * l'attribut statique constant `NomDeClasse::class` d'une classe
   `NomDeClasse` est remplacé par le nom de classe qualifié, c.-à-d. le nom de
   classe précédé du nom de package. Ici, `ControleurUtilisateur::class` a pour
   valeur la chaîne de caractères `\TheFeed\Controleur\ControleurUtilisateur`.
   <!-- au moment de la compilation. -->
   * De manière générale, la valeur associée à `_controller` devra être au
     format
     [`callable`](https://www.php.net/manual/en/language.types.callable.php),
     car c'est ce qui est accepté lorsque l'on fait
     `$donneesRoute["_controller"]()`. Parmi les `callable`, on trouve le format
     `"NomDeClasseQualifie::nomMethodeStatique` ou `["NomDeClasseQualifie",
     "nomMethodeStatique"]` pour les méthodes statiques, ou encore
     `[$instanceDeLaClasse, "nomMethode"]` ou
     `$instanceDeLaClasse->nomMethode(...)` pour les méthodes classiques.

2. Testez la page `web/controleurFrontal.php/connexion` qui doit marcher, sauf
   les liens vers le CSS et les photos qui deviennent invalides. Cherchez
   pourquoi ces liens se sont cassés.

   **Aide :** Dans le code source de la page Web (`Ctrl+U`), cliquez sur ces
   liens cassés pour voir sur quel URL ils renvoient.

    <!-- Ce sont des liens relatifs, et la base a changé de  web/ vers web/controleurFrontal.php  -->

</div>

Nous allons régler ce problème en changeant l'URL de nos pages de
`web/controleurFrontal.php/connexion` vers une URL plus classique
`web/connexion`. Pour ceci, nous allons configurer *Apache* pour rediriger la
requête `web/connexion` (et les autres) vers l'URL `web/controleurFrontal.php/connexion`.

<div class="exercise">

1. Téléchargez [ce fichier de configuration d'*Apache* fourni par
   *Symfony*]({{ site.baseurl }}/assets/TD1/htaccessURLRewrite). 
   Remplacez le contenu de `web/.htaccess` par celui du fichier téléchargé.

2. Testez que la page `web/connexion` marche et que le CSS et les images sont
   revenus. En effet, l'URL de base des liens relatifs est de nouveau `web/`.

   **Remarque :** Si la réécriture d'URL ne marche pas (message d'erreur `Internal Server Error`),
   vous avez peut-être enregistré le fichier dans `.htaccess` à la racine du projet 
   au lieu de `web/.htaccess`.

3. Changez les liens dans `vueGenerale.php` : 

   ```diff
   -<a href="controleurFrontal.php?controleur=publication&action=afficherListe"><span>The Feed</span></a>
   +<a href="./publications"><span>The Feed</span></a>

   -<a href="controleurFrontal.php?controleur=publication&action=afficherListe">Accueil</a>
   +<a href="./publications">Accueil</a>

   -<a href="controleurFrontal.php?action=afficherFormulaireConnexion&controleur=utilisateur">Connexion</a>
   +<a href="./connexion">Connexion</a>
   ```

</div>

<!-- TODO ? 
Explication du .htaccess reprises de mes notes Joplin.

Expliquer ce que fait ce fichier : 
* voir la redirection permanente dans les DevTools avec le code HTTP 301.
* Fichier repris de Symfony
*  -->

### Route selon la méthode HTTP

L'un des avantages de notre routage est qu'il peut rediriger différemment selon
 la méthode *HTTP* employée. Voici ce que nous allons faire :  
* URL `/connexion`, méthode `GET` → action `afficherFormulaireConnexion` du contrôleur utilisateur
* URL `/connexion`, méthode `POST` → action `connecter` du contrôleur utilisateur

Pour limiter une route à certaines méthodes *HTTP*, on peut définir un paramètre `methods` lors de 
la création de l'instance de `Route` :
```php
$route = new Route(
   path: "/chemin", 
   defaults: [
      "_controller" => "...",
   ],
   methods: [Request::METHOD_GET]
);
```

Comme vous pouvez le constater, comme `methods` est un tableau, il est éventuellement possible d'autoriser
plusieurs méthodes pour une même route.

`Request::METHOD_GET` est une **constante** (qui donne la chaîne de caractères `GET`). Il est bien sûr aussi
possible de spécifier directement le nom de la méthode sans passer par la constante, mais cela permet d'éviter
des éventuelles erreurs de saisie. Il existe des constantes pour chaque méthode HTTP.

<div class="exercise">

1. Modifiez votre routeur pour avoir deux routes différentes avec le chemin `/connexion` selon la
   méthode *HTTP* (une avec `GET` pour afficher le formulaire de connexion et une avec `POST` afin 
   d'effectuer la connexion).

   **Attention :** Le nom de chaque route doit être unique (`$routes->add("nomRoute", $route);`).
   Si vous définissez deux routes avec le même nom, la deuxième écrase la première.

2. Corrigez l'URL vers laquelle pointe le formulaire dans `src/vue/utilisateur/formulaireConnexion.php`.

3. Essayez de vous connecter au site : vous devez avoir une erreur `Uncaught
   Symfony\...\NoConfigurationException`. En effet, si la connexion réussit,
   alors elle redirige vers l'ancienne adresse
   `web/?action=afficherListe&controleur=publication`.
   Comme cette adresse est désormais inconnue, Symfony nous renvoie `NoConfigurationException`. 
   
4. Pour régler temporairement le problème des redirections (qui sera traité
   proprement à la fin du TD), rajoutons une route pour l'URL `web/`. Dupliquez
   la route `afficherListe` en changeant le *path* (`/publications` → `/`) et **en
   donnant une autre nom à la route** pour ne pas écraser la précédente.

5. Essayez de vous connecter au site. Cela doit marcher normalement.

</div>

### Ajout des routes manquantes

<div class="exercise">

1. Ajoutez les routes manquantes (sauf celle vers `afficherPublications`) : 
   * Chemin `/deconnexion`, méthode `GET` → action `deconnecter` du contrôleur
     utilisateur
   * Chemin `/inscription`, méthode `GET` → action `afficherFormulaireCreation` du
     contrôleur utilisateur
   * Chemin `/inscription`, méthode `POST` → action `creerDepuisFormulaire` du
     contrôleur utilisateur
   * Chemin `/publications`, méthode `POST` → action `creerDepuisFormulaire` du contrôleur
     publication.  
     Attention : Il y a déjà une autre route associée au chemin `/publications`
     (route `afficherListe`). Il faudra donc spécifier que la route `afficherListe` est
     limité à la méthode `GET`. Pensez-bien à donner des **noms uniques** à vos routes !

2. Modifiez les liens correspondants dans
   *  `src/vue/publication/liste.php`, 
   *  `src/vue/utilisateur/formulaireCreation.php` 
   *  `src/vue/vueGenerale.php`.

   Rappel : un lien comme `controleurFrontal.php?controleur=utilisateur&action=afficherFormulaireCreation` devient
   `./inscription`.

</div>

Vous ne pouvez pas encore mettre à jour les liens vers
`controleurFrontal.php?controleur=utilisateur&action=afficherPublications` car
nous n'avons pas encore créé la route correspondante. C'est ce que nous allons
faire dans la prochaine section.

### Routes variables

Avec l'ancien routeur `RouteurQueryString`, nous pouvions envoyer des
informations supplémentaires dans l'URL, par exemple l'identifiant d'un
utilisateur avec `controleur=utilisateur&action=afficherPublications&idUtilisateur=19`.

Dans notre nouveau système d'URL, certaines parties de l'URL serviront à
récupérer ces informations supplémentaires. Par exemple, nous allons configurer
notre site pour que l'URL `web/utilisateurs/19/publications` renvoie vers la liste des publications
de l'utilisateur d'identifiant `19`. Le routeur fourni par `Symfony` permet des
routes variables `/utilisateurs/{idUtilisateur}/publications` qui permettront d'extraire `$idUtilisateur` de
l'URL et de le passer comme paramètre de la méthode liée à la route dans le contrôleur. 

<div class="exercise">

1. Créez une nouvelle route : 
   * Nom `afficherPublications` (mais cela pourrait être autre chose), 
   URL `/utilisateurs/{idUtilisateur}/publications`, méthode `GET` → action `afficherPublications` du contrôleur utilisateur

2. Modifiez `afficherPublications()` (de la classe `ControleurUtilisateur`) pour qu'il prenne `$idUtilisateur` en argument 
au lieu de le lire depuis le *query string* avec `$_REQUEST['idUtilisateur']`.
   
   ```diff
   -public static function afficherPublications(): void
   +public static function afficherPublications($idUtilisateur): void

   -    if (isset($_REQUEST['idUtilisateur'])) {
   -        $idUtilisateur = $_REQUEST['idUtilisateur'];

   -    } else {
   -        MessageFlash::ajouter("error", "Login manquant.");
   -        ControleurUtilisateur::rediriger("publication", "afficherListe");
   -    }
   ```

   Attention à ne pas supprimer le reste ! La fonction doit toujours faire les autres instructions
   (récupérer l'utilisateur via le repository, charger la vue, etc.). On supprime seulement la partie
   qui récupère l'identifiant de l'utilisateur dans `$_REQUEST` en introduisant un paramètre.

3. Si vous testez la route, vous verrez qu'elle ne marche pas, car
   `$donneesRoute["_controller"]()` appelle `afficherPublications` sans lui donner d'arguments (il
   attend `$idUtilisateur`).

4. Affichez `$donneesRoute` (avec `var_dump`) pour voir comment `UrlMatcher` a extrait `idUtilisateur` de
   l'URL.

</div>

Nous allons résoudre ce problème en introduisant un nouveau composant.

### Le composant `HttpKernel` de `Symfony`

Selon sa
[documentation](https://symfony.com/doc/current/components/http_kernel.html), le
composant `HttpKernel` de `Symfony` fournit un processus structuré pour
convertir une `Request` en `Response`. Sa classe principale `HttpKernel` est
similaire à notre `RouteurURL`, mais en plus évolué. Nous ne nous servirons donc
pas de `HttpKernel` puisque nous recodons une version simplifiée plus
compréhensible. 

Nous allons plutôt nous concentrer sur les classes `ControllerResolver` et
`ArgumentResolver`. La responsabilité du résolveur de contrôleur est de
déterminer le contrôleur et la méthode à appeler en fonction de la requête. La
classe `ControllerResolver` se limite plus ou moins à lire
`$donneesRoute["_controller"]`. Nous pourrions nous en passer, mais elle sera
utile plus tard quand vous aurez des actions qui sont des méthodes non statiques
(*cf.* séance sur les tests avec `PhpUnit`).
 <!-- car ControllerResolver instancie un objet de la classe -->

La classe `ArgumentResolver` va construire la liste des arguments de l'action du
contrôleur. Par exemple, c'est cette classe qui va créer l'argument `$idUtilisateur`
avec la valeur `19` pour la méthode `ControleurUtilisateur::afficherPublications($idUtilisateur)`.


<div class="exercise">

1. Exécutez la commande suivante dans le terminal docker ouvert au niveau de la racine
   de votre projet afin d'importer le composant `HttpKernel`

   ```bash
   composer require symfony/http-kernel
   ```

2. Faites évoluer le code de `RouteurURL` en rajoutant à la fin (juste **avant**
   `$donneesRoute["_controller"]()`)

   ```php
   use Symfony\Component\HttpKernel\Controller\ArgumentResolver;
   use Symfony\Component\HttpKernel\Controller\ControllerResolver;

   $requete->attributes->add($donneesRoute);

   $resolveurDeControleur = new ControllerResolver();
   $controleur = $resolveurDeControleur->getController($requete);

   $resolveurDArguments = new ArgumentResolver();
   $arguments = $resolveurDArguments->getArguments($requete, $controleur);
   ```

   et en modifiant

   ```diff
   -$donneesRoute["_controller"]();
   +$controleur(...$arguments);
   ```

   Notez que les trois points  dans`$controleur(...$arguments)` font partie de la syntaxe.

3. Testez la route `web/utilisateurs/19/publications` en remplaçant `19` par un identifiant
   d'utilisateur ayant quelques publications. La page doit remarcher, mais pas
   le CSS ni les images.

</div>

**Plus d'explications (optionnel) :** 
Revenons sur la classe `ArgumentResolver` pour expliquer [son fonctionnement
(simplifié)](https://symfony.com/doc/current/components/http_kernel.html#4-getting-the-controller-arguments)
sur l'exemple `afficherPublications()` : 
* En utilisant [l'introspection de
  PHP](https://www.php.net/manual/en/book.reflection.php), le code accède à la
  liste des arguments (type et nom)
* pour chaque argument, [on essaye itérativement l'un des résolveurs
  d'arguments](https://symfony.com/doc/current/controller/value_resolver.html)
  pour déterminer la valeur de l'argument.  
  Dans notre exemple, le premier résolveur (classe
  `RequestAttributeValueResolver`) va regarder si le nom de l'argument `idUtilisateur`
  est présent dans `$requete->attributes` (équivalent à `$donneesRoute`). Comme
  c'est le cas alors on renvoie cette valeur.

L'avantage de ce mécanisme est qu'il permet de récupérer beaucoup de types
d'arguments dans le contrôleur : 
* un attribut extrait de la requête (attribut `GET` ou `POST`). Pour ceci, le
  nom de l'attribut doit correspondre,
* la requête `Request $requete` (l'argument doit avoir le type `Request`),
* la valeur par défaut d'une route variable,
* des services du conteneur de service (*cf.* futur TD sur les tests
  avec `PHPUnit`),
* des éléments de la base de données si le type correspond à celui d'une entité
  (`DataObject` dans ce cours)
 

### Générateur d'URL et conteneur global

Les liens vers le style CSS et les images de profil de notre site sont souvent
cassés car elles utilisent des URL relatives. En effet, la base de l'URL varie
selon le chemin demandé : 
* pour le chemin `web/connexion`, les URL relatives utilisent la base `web/`. 
* pour le chemin `web/utilisateurs/19/publications`, les URL relatives utilisent la base
  `web/utilisateurs/19`. Du coup, les liens relatifs sont cassés. 

Nous allons utiliser des classes de `Symfony` pour générer automatiquement des
URL absolues. D'un côté, nous allons utiliser `UrlHelper` pour générer des URL
absolues à partir d'URL relatives : 
```php
use Symfony\Component\HttpFoundation\RequestStack;

$assistantUrl = new UrlHelper(new RequestStack(), $contexteRequete);
$assistantUrl->getAbsoluteUrl("../ressources/css/styles.css");
// Renvoie une URL absolue générée relativement à partir du point d'entrée du site, c'est-à-dire le fichier controleurFrontal.php qui se trouve dans le dosier web, et cela peu importe l'URL courante.
//On obtient donc une URL absolue .../ressources/css/styles.css calculée relativement au point d'entrée du site.
//Dans cet exemple et pour ntore site, on obtient donc l'URL http://localhost/ComplementWeb/TheFeed/ressources/css/styles.css
```

D'un autre côté, la classe `UrlGenerator` génère des URL absolues à partir du
**nom** d'une route. C'est pratique si on doit changer le chemin de la route *a
posteriori*.
```php
use Symfony\Component\Routing\Generator\UrlGenerator;

$generateurUrl = new UrlGenerator($routes, $contexteRequete);
$generateurUrl->generate("afficherListe");
// Renvoie une URL vers la route ".../web/publications", dans notre cas http://localhost/ComplementWeb/TheFeed/web/publications

$generateurUrl->generate("afficherPublications", ["idUtilisateur" => 19]);
// Renvoie une URL vers la route ".../web/utilisateurs/19/publications"
```

Comme nous allons avoir besoin de ces services de génération d'URL dans
différentes vues, il faut pouvoir les initialiser au début de l'application, et
pouvoir y accéder globalement. Dans le cours de [développement Web du semestre
3](http://romainlebreton.github.io/R3.01-DeveloppementWeb/), nous avions fait le
choix d'avoir des classes statiques utilisant le patron de conception
*Singleton*. Ce choix a l'inconvénient de rendre difficile les tests.

En attendant le troisième TD sur les tests avec *PhpUnit*, nous allons utiliser
une classe `Conteneur` pour stocker globalement les services dont nous aurons
besoin.

<div class="exercise">

1. Créez une classe `src/Lib/Conteneur.php` avec le code suivant : 

   ```php
   <?php

   namespace TheFeed\Lib;

   class Conteneur
   {
      private static array $listeServices;

      public static function ajouterService(string $nom, $service) : void {
         Conteneur::$listeServices[$nom] = $service;
      }

      public static function recupererService(string $nom) {
         return Conteneur::$listeServices[$nom];
      }
   }
   ```

   Cette classe va nous permettre d'initialiser des services et de les charger n'importe où dans l'application.
   Dans un futur TD, nous le remplacerons par un conteneur de services importé, beaucoup plus complet et puissant.

2. Initialisez les deux services `$assistantUrl` et `$generateurUrl` dans
   `RouteurUrl` (juste après avoir défini la variable `$contexteRequete`). 
   Puis stockez-les dans le conteneur.

   ```php
   $generateurUrl = new UrlGenerator($routes, $contexteRequete);
   $assistantUrl = new UrlHelper(new RequestStack(), $contexteRequete);

   Conteneur::ajouterService("generateurUrl", $generateurUrl);
   Conteneur::ajouterService("assistantUrl", $assistantUrl);
   ```

3. Récupérez les deux services en haut de la vue `vueGenerale.php`. 

   ```php
   use Symfony\Component\HttpFoundation\UrlHelper;
   use Symfony\Component\Routing\Generator\UrlGenerator;
   use TheFeed\Lib\Conteneur;

   /** @var UrlGenerator $generateurUrl */
   $generateurUrl = Conteneur::recupererService("generateurUrl");
   /** @var UrlHelper $assistantUrl */
   $assistantUrl = Conteneur::recupererService("assistantUrl");
   ```

   Puis utilisez-les dans **toutes les vues** pour passer tous les liens en URL
   absolues, soit à partir du nom d'une route (pour les liens qui pointent vers une action de l'application), 
   soit à partir du chemin relatif d'un `asset` (fichier css, image). 
   
   Globalement, vous devez remplacer :
   * Les différents liens, dans les menus, les formulaires (`action`), les publications...
   * L'import du fichier de style `CSS`.
   * L'image de profil de l'auteur d'une publication...

   À la fin, vous devez avoir corrigé tous les liens : `<a href="">`, `<img src="">`, `<form action="">` et `<link href="">`.

   Par exemple :

   ```php
   <img src="../ressources/img/monImage.png">
   //Devient :
   <img src="<?=$assistantUrl->getAbsoluteUrl('../ressources/img/monImage.png')?>">

   $nomFichier = "...";
   <img src="../ressources/img/$nomFichier">
   //Devient :
   $chemin = "../ressources/img/".rawurlencode($nomfichier);
   <img src="<?=$assistantUrl->getAbsoluteUrl($chemin)?>">

   <a href="./publications">
   //Devient :
   <a href="<?=$generateurUrl->generate('afficherListe')?>">

   //Route /exemple/{idExemple}
   <a href="./exemple/{$objet->getId()}">
   //Devient :
   <a href="<?=$generateurUrl->generate('nomRouteExemple', ['idExemple' => $objet->getId()])?>">
   ```

   **Remarques :** 
   * `$generateurUrl->generate()` échappe les caractères spéciaux des URL. Vous
     devez donc lui donner les données brutes, et non celles échappées par
     `rawurlencode()`.
   * `$assistantUrl->getAbsoluteUrl()` n'échappe pas les caractères spéciaux des
     URL. À vous de le faire (avec `rawurlencode`).
   * Vous pouvez utiliser la syntaxe raccourcie `<?= $var ?>` équivalente à
   `<?php echo $var ?>` pour améliorer la lisibilité de vos vues.
   * Les vues autres que `vueGenerale.php` vont détecter `$generateurUrl` et `$assistantUrl` 
   comme des variables erronées. C'est normal, car elles ne savent pas que ces variables sont 
   déjà déclarées dans `vueGenerale.php`. Vous pouvez éventuellement déclarer le type de ces 
   variables au début de chaque vue ou bien plus simplement ignorer cet avertissement. 
   Nous allons changer notre façon de faire les vues au prochain TD, cela n'a donc pas 
   beaucoup d'importance, cet avertissement n'aura plus lieu d'être prochainement.

</div>

Il ne nous reste qu'à mettre à jour la méthode de redirection et notre site aura
fini sa première migration pour des routes basées sur les URL !

<div class="exercise">

1. Changer la méthode `ControleurGenerique::rediriger()` pour qu'elle prenne en
   entrée le nom d'une route et un tableau associatif (optionnel) de paramètres pour les
   routes variables (mêmes arguments que `$generateurUrl->generate()`) :
   
   ```diff
   -protected static function rediriger(string $controleur = "", string $action = ""): void
   +protected static function rediriger(string $nomRoute, array $parametres = []): void
   ```
   
   Adaptez maintenant le code de cette méthode afin de rediriger vers l'URL absolue correspondant
   au nom de la route donnée en entrée (et aux éventuels paramètres associés à cette route). 
   Pour cela, vous aurez besoin de récupérer un certain service du `Conteneur`.

2. Mettez-à-jour tous les appels à `ControleurGenerique::rediriger()`. Pour vous aider, vous
pouvez vous aider de `PHPSotrm` pour trouver ces appels : Clic droit sur le nom de la méthode puis
`Find Usages`.

3. Testez votre site afin de vérifier que tout fonctionne.

</div>

### Bonus : simplifier la création des routes

À ce stade, vous trouvez peut-être qu'il est plutôt pénible d'ajouter une nouvelle route : 
cela alourdit la fonction `traiterRequete` de `RouteurURL` qui est déjà bien chargée et cela
peut vite devenir un enfer à debugguer (imaginez une application avec une centaine de routes !).

Heureusement, il est possible de simplifier tout cela en mettant en place un système de **création de routes par attribut** comme ce qui est fait dans le framework professionnel Symfony.

En `PHP`, le système d'attribut permet de configurer certaines méta-données au-dessus de méthodes, de classes, etc. On peut alors s'en servir afin de mettre un système en place pour définir nos routes ainsi plutôt que dans `traiterRequete` :

```php
class ControleurPublication extends ControleurGenerique
{

   #[Route(path: '/publications', name:'afficherListe', methods:["GET"])]
   public static function afficherListe(): Response {
      // ...
   }
}
```

Ici, ont créé une route nommée `afficherListe` qui a pour chemin `/publications` et qui est 
seulement accessible en `GET`. La méthode/action exécutée est celle sous lequel l'attribut 
est placé (ici, la méthode `afficherListe`).

Si vous souhaitez simplifier le système de gestion des routes, suivez cette
[note complémentaire]({{site.baseurl}}/tutorials/complement_route_attribut). Il est fortement
recommandé de le faire : cela est plutôt rapide et de toute façon, dans un futur TD, vous devrez
obligatoirement le faire si ce n'est pas déjà fait, alors autant le faire tout de suite !

Une fois que le système est mis en place, vous pourrez migrer toutes vos routes vers
des attributs et ainsi alléger `traiterRequete`.

## Conclusion

Dans ce TD, nous avons découvert comment changer les URL associées à notre site
pour qu'elles soient plus standard. Cela a été l'occasion de plonger dans le
fonctionnement interne d'un routeur professionnel. Ceci vous sera utile si vous
apprenez *Symfony* ou un autre framework *backend* plus tard. Concernant le
cours *Complément Web*, le passage à ces URL est une étape nécessaire dans notre
chemin pour développer une *API REST*.

Enfin, maintenant que vous connaissez les bases de *Composer*, vous pouvez facilement
rajouter des bibliothèques à votre site web *PHP*.

Si vous souhaitez améliorer le système de création des **routes** pour utiliser des
**attributs** au-dessus de chaque action liée à une route (dans les contrôleurs) au 
lieu de tout définir dans `traiterRequete`, vous pouvez lire cette 
[note complémentaire]({{site.baseurl}}/tutorials/complement_route_attribut).