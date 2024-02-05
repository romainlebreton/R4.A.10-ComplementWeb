---
title: TD2 &ndash; Réponses HTTP
subtitle: Réponses HTTP, Moteur de template Twig 
layout: tutorial
lang: fr
---
{% raw %}
<!-- 

xDebug ? Attention .htaccess !

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
* Attention PHP serveur builtin n'est pas apache : pas de .htaccess !

Pour effacer une reidrection permanente qui reste en cache
-> DevTools > Network > cliquer sur la requête > Clear Browser Cache

Format encore plus simple pour les routes : Annotations (bonus ? comme yaml serviceContainer ?)

Session -> flashBag !

Regarder les notes sous Joplin (lecture livres)

Cache Twig

Joplin cours openclassroom api restful

-->

L'objectif de ce TD est d'améliorer nos réponses *HTTP* sur plusieurs points : 
* ajouter un code de réponse HTTP pour indiquer plus clairement l'état du
  serveur. Ceci est indispensable dans l'optique du développement d'une API
  *REST*, qui est l'objectif principal de ces 3 premiers TPs ;
* pouvoir répondre du *JSON*, ce qui est aussi un des fondamentaux des API
  *REST* ;
* utiliser un *template engine* (`Twig`), c'est-à-dire à un langage spécifique pour la
  création de vues.

## La classe `Response`

Nous allons utiliser la classe `Response` du composant `HttpFoundation` de
`Symfony`. Selon la 
[documentation de *Symfony*](https://symfony.com/doc/current/components/http_foundation.html#response), 
un objet `Response` contient toute l'information qui doit être renvoyée au client *HTTP* : des en-têtes, un code de réponse et un corps de réponse. Voici un exemple d'appel au constructeur (tous les arguments sont optionnels) : 

```php
use Symfony\Component\HttpFoundation\Response;

$response = new Response(
    'Corps de la réponse : page Web ou JSON',
    Response::HTTP_OK, // Code 200 OK
    ['content-type' => 'text/html'] // En-tête pour indiquer une réponse HTML
);
```

L'envoi de la réponse au client *HTTP* se fait tout simplement 
```php
$response->send();
```

<!-- 
Response
 Sending the Response
 Setting Cookies
   compatible avec session_start, cookie... (à investiger !)
 Redirecting the User
 Creating a JSON Response
-->

### Des actions qui retournent des `Response`

Nous souhaitons modifier nos actions pour qu'elles retournent toutes une
instance de la classe `Response`. Ceci nous permettra par la suite d'utiliser
toutes les possibilités des réponses *HTTP*, notamment une meilleure redirection
dans l'exercice 2, ou des codes de réponse HTTP personnalisés dans l'exercice 4.

Pour que `ControleurGenerique::afficherVue()` renvoie une `Response`, il faut
que les vues renvoient une chaîne de caractères plutôt que d'écrire directement
la réponse *HTTP*. Pour ceci, nous allons temporairement rediriger la sortie
standard vers un fichier tampon de sortie (*output buffer* ou '*ob*') avec la commande

```php
ob_start();
```

Tant qu'elle est enclenchée, aucune donnée, hormis les en-têtes, n'est envoyée
au navigateur du client HTTP. Quand l'exécution des vues est fini, nous
récupérons le contenu de ce fichier tampon puis l'effaçons avec 

```php
$corpsReponse = ob_get_clean();
```

Il ne reste plus qu'à créer un objet `Response` à partir de ce corps de réponse.

<div class="exercise">

1. Modifiez `ControleurGenerique::afficherVue()` pour renvoyer une `Response` : 

   ```diff
   -    protected static function afficherVue(string $cheminVue, array $parametres = []): void
   +    protected static function afficherVue(string $cheminVue, array $parametres = []): Response
      {
            extract($parametres);
            $messagesFlash = MessageFlash::lireTousMessages();
   +        ob_start();
            require __DIR__ . "/../vue/$cheminVue";
   +        $corpsReponse = ob_get_clean();
   +        return new Response($corpsReponse);
      }
   ```

2. Modifier la première action `ControleurPublication::afficherListe()` pour que
   le fonction renvoie la réponse fournie par `afficherVue()`.

3. Dans `RouteurURL`, récupérer la réponse renvoyée par
   `call_user_func_array()`, puis appelez une méthode vue plus haut pour
   l'envoyer au client *HTTP*.

4. Testez l'URL `web/` qui renvoie vers l'action `afficherListe()`. Cela doit marcher.
   
5. Dans toutes les actions, mettez à jour le code pour que l'action renvoie la
   réponse fournie par `ControleurGenerique::afficherVue()`.

   **Remarque :** Vous devrez peut-être modifier le type de retour des actions
   pour que le site continue de marcher. Notez que les redirections risquent
   d'être cassées temporairement.

</div>


### Des redirections plus propres

Le composant `HttpFoundation` de `Symfony` fournit aussi la classe
`RedirectResponse` qui hérite de `Response`. Cette classe permet de bénéficier
automatiquement d'une redirection plus professionnelle. 

En effet, si vous ouvrez son code source `vendor/symfony/http-foundation/Response.php` dans votre IDE, vous verrez qu'en plus de mettre en place un en-tête `Location :` comme nous le faisions, elle écrit la balise suivante (voir la méthode `setTargetUrl()`)
```html
<meta http-equiv="refresh" content="0;url=url_de_redirection" />
```
Ceci permet une meilleure compatibilité avec différents navigateurs. En effet,
l'en-tête `Location :` n'est pas 
[complètement supportée (59% des navigateurs)](https://caniuse.com/mdn-http_headers_location) (cliquez sur le bouton
`Usage relative` pour améliorer l'affichage du site
[caniuse.com](https://caniuse.com/)). Au contraire, la balise 
`<meta http-equiv="refresh" />` est 
[supportée par 97% des navigateurs actuellement](https://caniuse.com/mdn-html_elements_meta_http-equiv_refresh).

De plus, `RedirectResponse` associe automatiquement le code de réponse `302
Found` qui indique une redirection temporaire. Profitons-en pour remarquer que
la réécriture d'URL indiquée dans le fichier de configuration `.htaccess` de
*Apache* utilisait un code `301 Moved Permanently` de redirection permanente.
Ceci était utilisé par exemple pour rediriger la requête
`web/controleurFrontal.php/connexion` vers `web/connexion`. Une redirection
permanente permet au navigateur d'optimiser la requête : le navigateur garde en
cache la redirection et l'effectue lui-même sans envoyer de requête au serveur.  

<div class="exercise">

1. Modifier le code de `ControleurGenerique::rediriger()` pour renvoyer une
   nouvelle `RedirectResponse` vers l'URL absolue qui vient d'être générée. 

1. Dans toutes les actions, mettez à jour le code pour que l'action renvoie la
   réponse fournie par `ControleurGenerique::rediriger()`.

1. Testez votre site qui doit remarcher complètement.

</div>

### Utilisation des codes de réponses pour les erreurs

Les méthodes `UrlMatcher::match()`, `ControllerResolver::getController()` et
`ArgumentResolver::getArguments()` utilisés dans `RouteurURL` peuvent lever des
exceptions. Nous allons les traiter en envoyant une réponse *HTTP* adéquate, en
faisant particulièrement attention au code de réponse.

<!-- essayer phpdocumentor sinon ? -->

<div class="exercise">

1. Pour découvrir quelle méthode lance quelle exception, il faut lire la
   *PHPDoc*. Pour exemple, pour la méthode `UrlMatcher::match()` : 
   * Avec `PhpStorm`, on accède à la documentation survolant
     `$associateurUrl->match()` avec la souris.  
     Comme la liste des exceptions est documenté dans l'interface
     `UrlMatcherInterface`, il faut cliquer sur `UrlMatcherInterface::match`. On
     trouve alors les 3 exceptions levées par cette méthode.

   <!-- 
   * Avec `PhpStorm`, si vous lisez la documentation de
       `$associateurUrl->match()` dans `RouteurURL`, elle ne mentionne
       malheureusement pas les exceptions. Ceci est dû à un bug de `PhpStorm`
       que nous allons contourner :
     *  faire `Ctrl+Clic` sur `match()` pour afficher son code source ;
     *  Malheureusement, ce code source ne contient pas de PHPDoc qui pourrait nous renseigner ;
     *  il faut remonter à la déclaration de la classe et faire `Ctrl+Clic` sur
        l'interface `UrlMatcherInterface` pour enfin voir la *PhpDoc* qui indique la liste des exceptions. 
   -->

   * Avec `vscode` ou `vscodium`, vous devriez voir la liste des exceptions en
     survolant simplement `$associateurUrl->match()` dans `RouteurURL`.

2. Listez en commentaire du code toutes les exceptions levées par les 3 méthodes
   (5 types d'exception en tout).

</div>


<!-- 
/**
 * @throws NoConfigurationException  If no routing configuration could be found
 * @throws ResourceNotFoundException If the resource could not be found
 * @throws MethodNotAllowedException If the resource was found but the request method is not allowed
 */
// $donneesRoute = $associateurUrl->matchRequest($requete);
$donneesRoute = $associateurUrl->match($requete->getPathInfo());

/**
 * @throws LogicException If a controller was found based on the request but it is not callable
 * @throws BadRequestException when the request has attribute "_check_controller_is_allowed" set to true and the controller is not allowed
 */
$controleur = $resolveurDeControleur->getController($requete);

/**
 * @throws \RuntimeException When no value could be provided for a required argument
 */
$arguments = $resolveurDArguments->getArguments($requete, $controleur);
-->

Nous allons maintenant traiter ces exceptions avec une réponse *HTTP* adaptée.
Les codes de réponse qui signalent une erreur de l'utilisateur sont en `4xx`.
Voici quelques codes de réponse *HTTP* utiles : 
* `400 Bad Request` (attribut `HTTP_BAD_REQUEST` de la classe `Response`)  
   Cette réponse indique que le serveur n'a pas pu comprendre la requête à cause d'une syntaxe invalide.

* `401 Unauthorized` (attribut `HTTP_UNAUTHORIZED`)  
   Bien que le standard HTTP indique « non autorisé », la sémantique de cette réponse correspond à « non authentifié » : le client doit s'authentifier afin d'obtenir la réponse demandée.

* `403 Forbidden` (attribut `HTTP_FORBIDDEN`)  
   Le client n'a pas les droits d'accès au contenu, donc le serveur refuse de
   donner la véritable réponse.

* `404 Not Found` (attribut `HTTP_NOT_FOUND`)  
   Le serveur n'a pas trouvé la ressource demandée. Ce code de réponse est
   principalement connu pour son apparition fréquente sur le web.

* `405 Method Not Allowed` (attribut `HTTP_METHOD_NOT_ALLOWED`)  
   La méthode de la requête est connue du serveur, mais n'est pas prise en charge
   pour la ressource cible. Par exemple, une API peut ne pas autoriser
   l'utilisation du verbe `DELETE` pour supprimer une ressource.
   
* `409 Conflict` (attribut `HTTP_CONFLICT`)  
  Quand la requête entraîne un conflit entre les ressources. L'exemple typique est celle de deux utilisateurs ayant la même adresse mail, alors que ce champ est unique dans la BDD.


<div class="exercise">

1. Changer la méthode `ControleurGenerique::afficherErreur()` pour le code suivant qui permet d'ajouter un code de réponse : 
   ```php
   public static function afficherErreur($messageErreur = "", $statusCode = 400): Response
   {
       $reponse = ControleurGenerique::afficherVue('vueGenerale.php', [
           "pagetitle" => "Problème",
           "cheminVueBody" => "erreur.php",
           "messageErreur" => $messageErreur
       ]);

       $reponse->setStatusCode($statusCode);
       return $reponse;
   }
   ```

2. Parmi les 6 exceptions levées, 2 correspondent à des codes de réponses *HTTP*
   spécifiques. Pour les autres exceptions, nous renverrons le code de réponse
   d'erreur générique `400`.  
   Dans `RouteurURL`, gérez l'exception avec des `catch` successifs qui
   permettent de gérer de l'exception la plus spécifique à l'exception la plus
   générique : 
   ```php
   try {
      $associateurUrl = new UrlMatcher($routes, $contexteRequete);
      $donneesRoute = $associateurUrl->match($requete->getPathInfo());
      $requete->attributes->add($donneesRoute);

      $resolveurDeControleur = new ControllerResolver($conteneur);
      $controleur = $resolveurDeControleur->getController($requete);

      $resolveurDArguments = new ArgumentResolver();
      $arguments = $resolveurDArguments->getArguments($requete, $controleur);

      $reponse = call_user_func_array($controleur, $arguments);
   } catch (TypeExceptionSpecifique1 $exception) {
      // Remplacez xxx par le bon code d'erreur
      $reponse = ControleurGenerique::afficherErreur($exception->getMessage(), xxx);
   } catch (TypeExceptionSpecifique2 $exception) {
      // Remplacez xxx par le bon code d'erreur
      $reponse = ControleurGenerique::afficherErreur($exception->getMessage(), xxx);
   } catch (\Exception $exception) {
      $reponse = ControleurGenerique::afficherErreur($exception->getMessage()) ;
   }
   $reponse->send();
   ```

3. Testez votre code en appelant une route qui n'existe pas. Observez le message
   d'erreur, ainsi que le code de retour avec les outils de développement,
   onglet *Réseau*.

4. Testez votre code en appelant une méthode non prise en charge. Observez le
   message d'erreur, ainsi que le code de retour avec les outils de
   développement.

5. Modifiez, le temps de cette question, votre code pour que l'action `afficherListe()`
   prenne un argument quelconque. Appelez l'URL `web/`. Observez le message
   d'erreur et le code de retour avec les outils de développement.

</div>

## Un langage de gabarit : *Twig*

Le principe des langages de gabarit (*template engines*) est de fournir un langage adapté aux vues.
Voyons les contraintes d'un bon langage de gabarits : 

* **Concision** : Au lieu du code PHP, `<?php echo $var ?>`, *Twig* propose un
  code concis
  ```twig
  {{ var }}
  ```
  
* **Syntaxe adaptée** aux besoins courants : 
  Par exemple, disons que vous voulez itérer sur un tableau et afficher un texte par défaut lorsque le tableau est vide.

   ```twig
   {% for item in items %}
   - {{ item }}
   {% else %}
   No item has been found.
   {% endfor %}
   ```

* **Réutilisation** : 
  L'héritage de gabarit permet de reprendre une mise en page existante (comme `vueGenerale.php`) en spécifiant des parties (le titre, le corps de la page, ...)

* **Sécurité** : La sécurité est activée par défaut, en particulier
  l'échappement des caractères spéciaux du *HTML*. Ceci vise à protéger les
  non-développeurs des menaces web courantes telles que XSS ou CSRF dont ils ne
  sont pas nécessairement conscients.

* **Rapide** : 
  *Twig* compile les gabarits en code PHP simple, ce qui permet leur évaluation à un surcoût minimum.

* Favoriser la **séparation des préoccupations** (*separation of concerns*) :  

  Dans les grands projets Web, des développeurs (*web developer*) travaillent
  sur le code (les contrôleurs et le modèle) et les concepteurs (*web designer*)
  sur l'aspect visuel.

   Un langage de gabarit permet d'écrire des gabarits qui respectent cette
   séparation des préoccupations. Un langage de gabarit doit trouver un bon
   équilibre entre offrir suffisamment de fonctionnalités pour faciliter
   l'implémentation de la logique de présentation, et limiter les
   fonctionnalités avancées pour éviter l'apparition de logique métier dans les
   gabarits. On fournit aux vues la liste des variables qu'elles peuvent
   utiliser. Idéalement, la vue n'accède aux variables qu'en lecture, ce qui
   évite de modifier l'état du système.

   <!-- Les concepteurs de sites web (*web designer*) doivent comprendre Twig et un peu
   de PHP. Mais s'ils doivent comprendre l'architecture MVC et la séparation des préoccupations, alors ce ne sont plus de *web designer*, mais des développeurs de sites web (*web developer*). -->

Sources : 
* [Blog de Fabien Potentier (fondateur de *Symfony*) sur la naissance de *Twig*](http://fabien.potencier.org/templating-engines-in-php.html)
* [Documentation officielle de *Twig*](https://twig.symfony.com/doc/3.x/)






### Initialisation de *Twig*

<!-- 
SRP de RouteurURL loupé : 
* traiterRequete($requete, $contexteRequete)
* Twig, requete, contexteRequete dans un autre fichier (init ? controleurFrontal ?)
-->

<div class="exercise">

1. Installez le paquet *Twig* avec la commande
   ```bash
   composer require twig/twig
   ```

2. Initialisez *Twig* dans `RouteurURL.php`. : 
   ```php
   use Twig\Environment;
   use Twig\Loader\FilesystemLoader;

   $twigLoader = new FilesystemLoader(__DIR__ . '/../vue/');
   $twig = new Environment(
       $twigLoader,
       [
           'autoescape' => 'html',
           'strict_variables' => true
       ]
   );
   Conteneur::ajouterService("twig", $twig);
   ```

   <!-- TODO : autoescape html par défaut ? -->

   **Explication :** Ce code indique le répertoire de base des vues *Twig* à
   l'aide du `FilesystemLoader`. Puis, nous créons l'objet `$twig` en lui
   indiquant [des
   options](https://twig.symfony.com/doc/3.x/api.html#environment-options) :
   échappement automatique des variables pour du *HTML* et signaler avec une
   exception les variables invalides. Enfin, nous stockons ce service dans le
   `Conteneur` pour pouvoir s'en resservir dans une autre partie du code.

3. Dans le `ControleurGenerique`, créez une nouvelle méthode `afficherTwig` : 

    ```php
    protected static function afficherTwig(string $cheminVue, array $parametres = []): Response
    {
        /** @var Environment $twig */
        $twig = Conteneur::recupererService("twig");
        $corpsReponse = $twig->render($cheminVue, $parametres);
        return new Response($corpsReponse);
    }
    ```

   **Explication :** La méthode `render` de *Twig* exécute une vue et renvoie la
   chaîne de caractères produite.

</div>

### Premier gabarit *Twig*, héritage de gabarit

Nous allons créer notre premier gabarit *Twig* qui correspond à
`formulaireConnexion.php`. Pour que cette vue s'insère sans une mise-en-page
générale (anciennement `vueGenerale.php`), nous allons utiliser le mécanisme
d'héritage de gabarit.

<!-- Reprenons l'exemple fourni par la 
[documentation de *Twig*](https://twig.symfony.com/doc/3.x/tags/extends.html) :  -->

Nous allons remplacer `src/vue/vueGenerale.php` par le fichier
`src/vue/base.html.twig` suivant : 

```twig
<!DOCTYPE html>
<html lang="fr">
<head>
    <title>{% block page_title %}The Feed{% endblock %}</title>
    <meta charset="utf-8">
    <link rel="stylesheet" type="text/css" href="{# lien vers le CSS #}">
</head>
<body>
<header>
    <div id="titre" class="center">
        <a href="{# lien #}"><span>The Feed</span></a>
        <nav>
            <a href="{# lien #}">Accueil</a>
            {# si l'utilisateur est connecte #}
            <a href="{# lien #}">Ma page</a>
            <a href="{# lien #}">Déconnexion</a>
            {# sinon #}
            <a href="{# lien #}">Inscription</a>
            <a href="{# lien #}">Connexion</a>
            {# fin si #}
        </nav>
    </div>
</header>
<div id="flashes-container">
    {# boucle sur les types de messages flash #}
        {# boucle sur les messages flash de ce type #}
            <span class="flashes flashes-{# type du message #}">{# message flash #}</span>
        {# fin boucle #}
    {# fin boucle #}
</div>
{% block page_content %}{% endblock %}
</body>
</html>
```

*Remarque :* c'est normal que plusieurs aspects de la page soient cassés (menu,
lien, CSS). Nous implémenterons toutes les fonctionnalités entre commentaire
*Twig* `{# #}` dans la suite.

Les balises *Twig* `{% block page_title %}{% endblock %}` définissent un bloc,
c'est-à-dire une partie de la page qui pourra être remplacée dans une autre vue.
Nous allons justement reprendre cette vue et remplacer le titre et le contenu de
la page dans une nouvelle vue `src/vue/utilisateur/connexion.html.twig` : 

```twig
{% extends "base.html.twig" %}

{% block page_title %}Connexion{% endblock %}

{% block page_content %}
    <main>
        <form action="{# lien vers la page de traitement #}" id="form-access" class="center" method="post">
            <fieldset>
                <legend>Connexion</legend>
                <div class="access-container">
                    <label for="login">Login</label>
                    <input id="login" type="text" name="login" required/>
                </div>
                <div class="access-container">
                    <label for="password">Mot de passe</label>
                    <input id="password" type="password" name="mot-de-passe" required/>
                </div>
                <input id="access-submit" type="submit" value="Se connecter">
            </fieldset>
        </form>
    </main>
{% endblock %}
```

La balise Twig `{% extends %}` permet d'hériter d'un gabarit. On peut alors
remplacer le contenu d'un bloc en le redéfinissant.

<div class="exercise">

1. Créez les vues `src/vue/base.html.twig` et `src/vue/utilisateur/connexion.html.twig` comme précédemment.
1. Changer la méthode `afficherFormulaireConnexion` du `ControleurUtilisateur`
   pour appeler cette vue à l'aide de `afficherTwig`.
  
   *Rappel :* Le chemin de la vue est relatif au dossier `src/vue/` que nous
   avions donné à `FilesystemLoader`.

1. L'URL `web/connexion` doit afficher le formulaire de connexion, mais sans CSS.

</div>

### Syntaxe de base de *Twig*

* L'instruction `{{ donnee }}` permet d'afficher une donnée. Elle sera
  automatiquement échappée pour le *HTML*, c-à-d qu'il appelle automatiquement
  `htmlspecialchars` pour vous.

  On peut accéder à une méthode d'un objet avec `{{ donnee.methode() }}`, et à
  un attribut avec `{{ donnee.attribut }}`. *Twig* essayera d'abord de trouver
  un attribut public `$donnes->attribut`, puis appellera sinon
  `$donnes->getAttribut()`, `$donnes->isAttribut()` et `$donnes->hasAttribut()`
  (*cf.* [documentation de Twig](https://twig.symfony.com/doc/3.x/templates.html#variables)).

* Les variables accessibles dans Twig sont celles qui ont été données en
  paramètres de `$twig->render()` dans la méthode
  `ControleurGenerique::afficherTwig()`. Par exemple, si le fichier
  `exemple.html.twig` contient `{{ variableTwig }}`, alors
  ```php
  $twig->render("exemple.html.twig", ["variableTwig" => "Web4Ever🕸"]);
  ```
  affichera  `Web4Ever🕸`.

* La structure conditionnelle `if` permet de ne générer une partie du document que si une condition est remplie :

   ```twig
   {% if test %}
      Code HTML....
   {% endif %}
   ```

   Il est bien sûr possible de construire des conditions complexes avec les
   opérateurs : `not`, `and`, `or`, `==`, `<`, `>`, `<=`, `>=`, etc... par
   exemple :

   ```twig
   {% if test and (not (user.getName() == 'Smith') or user.getAge() <= 20) %}
      Code HTML....
   {% endif %}
   ```

* La structure conditionnelle `for` permet de parcourir une structure itérative (par exemple, un tableau) :

   ```twig
   {% for data in tab %}
      <p>{{ data }}</p>
   {% endfor %}
   ```

   Comme indiqué dans la présentation de *Twig*, une syntaxe `{% else %}` permet de traiter le cas particulier d'un tableau vide :  

   ```twig
   {% for data in tab %}
      <p>{{ data }}</p>
   {% else %}
   No data has been found.
   {% endfor %}
   ```

<div class="exercise">

1. Créez une nouvelle vue `src/vue/publication/feed.html.twig` avec le contenu suivant : 

   ```twig
   {% extends "base.html.twig" %}

   {% block page_title %}The Feed{% endblock %}

   {% block page_content %}
      <main id="the-feed-main">
         <div id="feed">
               {# si l'utilisateur est connecté #}
                  <form id="feedy-new" action="{# lien #}" method="post">
                     <fieldset>
                           <legend>Nouveau feedy</legend>
                           <div>
                              <textarea required id="message" minlength="1" maxlength="250" name="message"
                                       placeholder="Qu'avez-vous en tête?"></textarea>
                           </div>
                           <div>
                              <input id="feedy-new-submit" type="submit" value="Feeder!">
                           </div>
                     </fieldset>
                  </form>
               {# fin si #}
               {# boucle sur les publications #}
                  <div class="feedy">
                     <div class="feedy-header">
                           <a href="{# lien vers afficherPublications #}">
                              <img class="avatar"
                                    src="{# lien vers l'image de profil de l'auteur de la publication #}"
                                    alt="avatar de l'utilisateur">
                           </a>
                           <div class="feedy-info">
                              <span>{# login de l'auteur de la publication #}</span>
                              <span> - </span>
                              <span>{# date de la publication #}</span>
                              <p>{# message de la publication #}</p>
                           </div>
                     </div>
                  </div>
               {# s'il n'y a pas de publication #}
                  <p id="no-publications" class="center">Pas de publications pour le moment!</p>
               {# fin de boucle #}
         </div>
      </main>
   {% endblock %}
   ```
2. Changer les actions `ControleurPublication::afficherListe()` et
   `ControleurUtilisateur::afficherPublications()` pour appeler cette vue, en
   fournissant en paramètre le tableau des publications.

3. Codez avec la syntaxe *Twig* la boucle des publications, son cas particulier
   quand il n'y a pas de publication, et les affichages liés aux publications
   (sauf la date qui sera affichée dans le prochain exercice).
   
   *Note :* les liens et la gestion de l'utilisateur connecté seront fait plus
   tard. 

</div>


### Les filtres de *Twig*

Les variables peuvent être modifiées par des filtres. Les filtres sont
séparés de la variable par un symbole de pipe `|`. Plusieurs filtres peuvent
être enchaînés, auquel cas la sortie d'un filtre est appliquée au suivant.
Par exemple, 

```twig
{{ donnee|lower|truncate(20) }} {# minuscule puis tronque à 20 caractères #}
```

Le [filtre `escape`](https://twig.symfony.com/doc/3.x/filters/escape.html) (ou
son raccourci `e`) permet d'appliquer un échappement personnalisé :  

```twig
{{ user.username|e('js') }} {# échappement dans un contexte JavaScript #}
{{ user.username|e('css') }} {# contexte CSS #}
{{ user.username|e('url') }} {# contexte bout d'URL, par ex. query string #}
{{ user.username|e('html_attr') }} {# contexte attribut d'une balise HTML #}
```

Le [filtre `date`](https://twig.symfony.com/doc/3.x/filters/date.html) formate
une date avec un [format personnalisé](https://www.php.net/manual/fr/datetime.format.php).
La documentation liste [les filtres de
*Twig*](https://twig.symfony.com/doc/3.x/filters/index.html) fournis par défaut.

<div class="exercise">

1. Affichez la date des publications en utilisant un filtre pour qu'elle soit
   affichée comme suit : `09 March 2023`.

   *Aide :* Allez voir les liens précédents sur la documentation pour trouver le bon format.

   <!-- date('d F Y') -->

</div>

### Étendre la syntaxe de *Twig*

*Twig* peut être étendu de nombreuses façons : vous pouvez ajouter des filtres,
des fonctions, des variables globales. Ou, plus rarement, des balises, des
tests et des opérateurs.

À la [manière de *Symfony*](https://symfony.com/doc/current/reference/twig_reference.html), 
nous allons rajouter des fonctions à *Twig* pour gérer les liens liés aux routes ou aux *assets*.

La syntaxe pour 
[rajouter une fonction](https://twig.symfony.com/doc/3.x/advanced.html#functions) 
est 
```php
use Twig\TwigFunction;

$twig->addFunction(new TwigFunction("route", $callable));
```
où `$callable` est une variable au 
[format `callable`](https://www.php.net/manual/en/language.types.callable.php#example-71) 
(comme avec `call_user_func()` au TD1).
Pour exemple, pour donner la méthode d'un objet, on peut utiliser la syntaxe
```php
$callable = [$objet, "nomMethode"];
```
ou la 
[syntaxe `callable` de première classe](https://www.php.net/manual/fr/functions.first_class_callable_syntax.php) 
apparue avec PHP 8.1
```php
$callable = $objet->nomMethode(...); // Les ... font parti de la syntaxe
```

La fonction est alors disponible dans *Twig*, par exemple comme ceci : 
```twig
{{ route("afficherListe") }}
```

<div class="exercise">

1. Dans `RouteurURL`, ajoutez deux fonctions à *Twig* : 
   * une fonction `route` pour la méthode `$generateurUrl->generate()` ;
   * une fonction `asset` pour la méthode `$assistantUrl->getAbsoluteUrl()` ;

1. Utilisez ces fonctions dans toutes vos vues *Twig* pour réparer tous les
   liens (CSS, menu, action du formulaire), sauf le lien "Ma Page" du menu de
   navigation vers la route paramétrée de l'utilisateur connecté.

   *Aide* : 
   * pour le lien vers la page personnelle de l'auteur d'une publication, vous
   devrez générer la route vers l'action `afficherPublications` en la méthode
   `$generateurUrl->generate()` qui attend un tableau associatif comme deuxième
   argument. Les tableaux associatifs se créent avec la syntaxe JSON
   ```twig
   {'nomCle' : 'valeur'}
   ```
   * pour l'*asset* correspondant à la photo de profil, vous aurez besoin de
     concaténer des chaînes de caractères avec `~` en *Twig*.


2. Testez votre site ; le CSS et les liens doivent remarcher.

</div>

Il ne nous reste plus qu'à restaurer les utilisateurs connectés et les messages
Flash. Pour ceci, nous allons rajouter des variables globales à *Twig* :
```php
$twig->addGlobal('nomVariableTwig', $variablePHP);
```


<div class="exercise">

1. Dans `RouteurURL`, rajoutez une variable globale contenant l'identifiant de
   l'utilisateur connecté (cf. la classe `ConnexionUtilisateur`).

   *Rappel :* Par convention dans notre site, cette variable vaut `null` si
   l'utilisateur n'est pas connecté.

1. Mettez à jour `base.html.twig` et `publication/feed.html.twig` pour prendre
   en compte si l'utilisateur est connecté au niveau de l'interface.

   *Aide :* Pour tester si un objet n'est pas `null`, vous pouvez faire
   ```twig
   {% if objectVariable is not null %}
   ```
   ou 
   ```twig
   {% if objectVariable %}
   ```
   car la conversion d'un objet en booléen est `true` si et seulement l'objet
   est non nul (comme en PHP).

</div>

Pour rajouter les messages Flash, nous pourrions être tentés de faire
```php
$twig->addGlobal('messagesFlash', MessageFlash::lireTousMessages());
```
dans `RouteurURL`. Cependant, nous aimerions que les messages *Flash* soient lus
au moment de l'évaluation des vues, et non pas au début du script PHP. Du coup,
nous proposons de stocker une instance de `MessageFlash` : 
```php
$twig->addGlobal('messagesFlash', new MessageFlash());
```
et d'appeler la méthode `lireMessages()` dans la vue *Twig* avec `messagesFlash.lireMessages()`.

<div class="exercise">

1. Dans `RouteurURL`, rajoutez une variable globale `messagesFlash`.

2. Dans `base.html.twig`, affichez les messages *Flash*.
  
3. Créez la dernière vue manquante
   `src/vue/utilisateur/inscription.html.twig`. Changez l'action
   `ControleurUtilisateur::afficherFormulaireCreation()` pour appeler cette vue.

4. Il ne reste plus qu'à gérer la vue d'erreur, qui est appelée en cas d'exception : 
   * créez une vue d'erreur `src/vue/erreur.html.twig` qui étend
     `base.html.twig` et affiche une variable `messageErreur` qui lui sera donné
     en paramètre.
   * Modifiez la méthode `ControleurGenerique::afficherErreur()` pour appeler
     cette vue.
   * Testez si la vue d'erreur fonctionne en demandant par exemple une route inconnue.

</div>

## Bonus : pour le projet ?



2. Il est facile d'adopter une approche par composant dans les vues,
   c'est-à-dire de définir des bouts de vues facilement réutilisables.

   Allez voir la documentation des 
   [macros](https://twig.symfony.com/doc/3.x/tags/macro.html), 
   de la [fonction `include`](https://twig.symfony.com/doc/3.x/functions/include.html) ou de la 
   [balise `embed`](https://twig.symfony.com/doc/3.x/tags/embed.html). 

3. La compilation des vues *Twig* peut être précalculée et [stockée dans un
   cache](https://twig.symfony.com/doc/2.x/api.html#basics). Utilisez la
   [configuration `auto_reload`](https://twig.symfony.com/doc/3.x/api.html#environment-options)
   lors du développement pour mettre à jour le cache
   à chaque changement de code source des vues.
4. La [fonction `dump`](https://twig.symfony.com/doc/3.x/functions/dump.html)
   facilite le débogage en affichant un résultat similaire à `var_dump()`.

<!-- 

1. Si vous trouvez que la liste des routes s'allonge, vous pouvez 

   https://github.com/symfony/framework-bundle/blob/6.2/Routing/AnnotatedRouteControllerLoader.php

AnnotationRegistry::registerLoader([$loader, 'loadClass']);
$loader = new AnnotationDirectoryLoader(
    new FileLocator(__DIR__ . '/src/Controller/'),
    new AnnotatedRouteControllerLoader(
        new AnnotationReader()
    )
);
$routes = $loader->load(__DIR__ . '/src/Controller/');
https://code.tutsplus.com/tutorials/set-up-routing-in-php-applications-using-the-symfony-routing-component--cms-31231
-->

<!-- 
TODO : formulaire d'inscription sans auto-complétion  (car affichage et traitement séparés 
TODO : afficherPublications renvoie sur feed.html.twig
* if login sur le titre
-->

<!-- 

### Twig reference
Tags
https://twig.symfony.com/doc/3.x/tags/index.html
* Composants : embed / include / extends
  * A block provides a way to change how a certain part of a template is
    rendered but it does not interfere in any way with the logic around it.

    The block inside the for loop is just a way to make it overridable by a
    child template:
    https://twig.symfony.com/doc/3.x/tags/extends.html#how-do-blocks-work 
    
* for : 
  * {% for i in 0..10 %} {% endfor %}
  * {% for user in users %} {% endfor %}
  * If no iteration took place because the sequence was empty, you can render a replacement block by using else:
      <ul>
         {% for user in users %}
            <li>{{ user.username|e }}</li>
         {% else %}
            <li><em>no user found</em></li>
         {% endfor %}
      </ul>

   * if : The rules to determine if an expression is true or false are the same as in PHP; here are the edge cases rules:
     empty string false, /!\ string "0" or '0'	false
     empty array false / non-empty array true
     null false/ object true

   * macro !!!

Filters
https://twig.symfony.com/doc/3.x/filters/index.html

Variables can be modified by filters. Filters are separated from the variable by
a pipe symbol (|). Multiple filters can be chained. The output of one filter is
applied to the next.

* date : format https://www.php.net/manual/fr/datetime.format.php
* 

Functions
https://twig.symfony.com/doc/3.x/functions/index.html
* include function, rather than tag, which outputs the rendered content of that file
  https://twig.symfony.com/doc/3.x/functions/include.html

Tests
https://twig.symfony.com/doc/3.x/tests/index.html
* is equiv to ==
* same as() equiv to ===
* empty

Operators


Twig for Developers
* Environment Options : 
  * debug : the generated templates have a __toString() method
  * cache avec auto_reload
  * autoescape : name (based on the template filename extension), html, js, css, url, html_attr,

Twig Reference for Symfony 
https://symfony.com/doc/current/reference/twig_reference.html
* absolute_url, asset
* csrf_token
* form : Exercice Form rendering using https://symfony.com/doc/current/form/form_customization.html
* path
* url / absolute_url (équivalent de notre route) 
-->


{% endraw %}
