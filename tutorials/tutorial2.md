---
title: TD2 &ndash; Réponses *HTTP*
subtitle: Réponses *HTTP*, Moteur de template Twig 
layout: tutorial
lang: fr
---

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
* utiliser un moteur de *template* (`Twig`), c'est-à-dire à un langage spécifique pour la
  création de vues.

## La classe `Response`

Nous allons utiliser la classe `Response` du composant `HttpFoundation` de
`Symfony`. Selon la 
[documentation de Symfony](https://symfony.com/doc/current/components/http_foundation.html#response), 
un objet `Response` contient toute l'information qui doit être renvoyée au client *HTTP* : des en-têtes, un code de réponse et un corps de réponse. Voici un exemple d'appel au constructeur (tous les arguments sont optionnels) : 

```php
use Symfony\Component\HttpFoundation\Response;

$response = new Response(
    'Content',
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
instance de la classe `Response`. Ceci nous permettra par la suite d'utiliser toutes les possibilités des réponses *HTTP*.

Pour que `ControleurGenerique::afficherVue()` renvoie une `Response`, il faut
que les vues renvoient une chaîne de caractères plutôt que d'écrire directement
la réponse *HTTP*. Pour ceci, nous allons temporairement rediriger la sortie
standard vers un fichier tampon de sortie (*output buffer* ou '*ob*') avec la commande

```php
ob_start();
```

Tant qu'elle est enclenchée, aucune donnée, hormis les en-têtes, n'est envoyée
au navigateur. Quand l'exécution des vues est fini, nous récupérons le contenu
de ce fichier tampon puis l'effaçons avec 

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

2. Modifier la première action `ControleurPublication::feed()` pour qu'elle
   renvoie la réponse de `afficherVue()`.

3. Dans `RouteurURL`, récupérer la réponse renvoyée par
   `call_user_func_array()`, puis appelez une méthode vue plus haut pour
   l'envoyer au client *HTTP*.

4. Testez l'URL `web/` qui renvoie vers l'action `feed()`. Cela doit marcher.
   
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

<!-- 

public const HTTP_BAD_REQUEST = 400;
public const HTTP_UNAUTHORIZED = 401;
public const HTTP_PAYMENT_REQUIRED = 402;
public const HTTP_FORBIDDEN = 403;
public const HTTP_NOT_FOUND = 404;
public const HTTP_METHOD_NOT_ALLOWED = 405;

400 Bad Request
Cette réponse indique que le serveur n'a pas pu comprendre la requête à cause d'une syntaxe invalide.

401 Unauthorized
Bien que le standard HTTP indique « non-autorisé », la sémantique de cette réponse correspond à « non-authentifié » : le client doit s'authentifier afin d'obtenir la réponse demandée.

402 Payment Required Expérimental
Ce code de réponse est réservé à une utilisation future. Le but initial justifiant la création de ce code était l'utilisation de systèmes de paiement numérique. Cependant, il n'est pas utilisé actuellement et aucune convention standard n'existe à ce sujet.

403 Forbidden
Le client n'a pas les droits d'accès au contenu, donc le serveur refuse de donner la véritable réponse.

404 Not Found
Le serveur n'a pas trouvé la ressource demandée. Ce code de réponse est principalement connu pour son apparition fréquente sur le web.

405 Method Not Allowed
La méthode de la requête est connue du serveur mais n'est pas prise en charge pour la ressource cible. Par exemple, une API peut ne pas autoriser l'utilisation du verbe DELETE pour supprimer une ressource.

/**
 * @throws NoConfigurationException  If no routing configuration could be found
 * @throws ResourceNotFoundException If the resource could not be found
 * @throws MethodNotAllowedException If the resource was found but the request method is not allowed
 */
// $donneesRoute = $associateurUrl->matchRequest($requete);
$donneesRoute = $associateurUrl->match($requete->getPathInfo());

/**
 * @throws \LogicException If a controller was found based on the request but it is not callable
 */
$controleur = $resolveurDeControleur->getController($requete);

/**
 * @throws \RuntimeException When no value could be provided for a required argument
 */
$arguments = $resolveurDArguments->getArguments($requete, $controleur);
-->

Les méthodes `UrlMatcher::match()`, `ControllerResolver::getController()` et
`ArgumentResolver::getArguments()` utilisés dans `RouteurURL` peuvent lever des
exceptions. Nous allons les traiter en envoyant une réponse *HTTP* adéquate, en
faisant particulièrement attention au code de réponse.

<!-- essayer phpdocumentor sinon ? -->

<div class="exercise">

1. Pour découvrir quelle méthode lance quelle exception, il faut lire la
   *PHPDoc* : 
   * Avec `PhpStorm`, si vous lisez la documentation de
       `$associateurUrl->match()` dans `RouteurURL`, elle ne mentionne
       malheureusement pas les exceptions. Ceci est dû à un bug de `PhpStorm`
       que nous allons contourner :
     *  faire `Ctrl+Clic` sur `match()` pour afficher son code source ;
     *  Malheureusement, ce code source ne contient pas de PHPDoc qui pourrait nous renseigner ;
     *  il faut remonter à la déclaration de la classe et faire `Ctrl+Clic` sur
        l'interface `UrlMatcherInterface` pour enfin voir la *PhpDoc* qui indique la liste des exceptions.
   * `vscode` ou `vscodium`, vous devriez voir la liste des exceptions en
     survolant simplement `$associateurUrl->match()` dans `RouteurURL`.

2. Listez en commentaire du code toutes les exceptions levées par les 3 méthodes
   (5 types d'exception en tout).

</div>

Nous allons maintenant traiter ces exceptions avec une réponse *HTTP* adaptée.
Les codes de réponse qui signalent une erreur de l'utilisateur sont en `4xx`.
Voici quelques codes de réponse *HTTP* utiles : 
* `400 Bad Request`  (attribut `HTTP_BAD_REQUEST` de la classe `Response`)
   Cette réponse indique que le serveur n'a pas pu comprendre la requête à cause d'une syntaxe invalide.

* `401 Unauthorized` (attribut `HTTP_UNAUTHORIZED`)  
   Bien que le standard HTTP indique « non-autorisé », la sémantique de cette réponse correspond à « non-authentifié » : le client doit s'authentifier afin d'obtenir la réponse demandée.

* `403 Forbidden` (attribut `HTTP_FORBIDDEN`)  
   Le client n'a pas les droits d'accès au contenu, donc le serveur refuse de
   donner la véritable réponse.

* `404 Not Found` (attribut `HTTP_NOT_FOUND`)  
   Le serveur n'a pas trouvé la ressource demandée. Ce code de réponse est
   principalement connu pour son apparition fréquente sur le web.

* `405 Method Not Allowed` (attribut `HTTP_METHOD_NOT_ALLOWED`)  
   La méthode de la requête est connue du serveur mais n'est pas prise en charge
   pour la ressource cible. Par exemple, une API peut ne pas autoriser
   l'utilisation du verbe DELETE pour supprimer une ressource.
   
* `409 Conflict` (attribut `HTTP_CONFLICT`)  
  Quand la requête entraîne un conflit entre les ressources. L'exemple typique est celle de deux utilisateurs ayant la même adresse mail, alors que ce champ est unique dans la BDD.


<div class="exercise">

1. Changer la méthode `ControleurGenerique::afficherErreur()` pour le code suivant qui permet d'ajouter un code de réponse : 
   ```php
   public static function afficherErreur($errorMessage = "", $statusCode = 400): Response
   {
       $reponse = ControleurGenerique::afficherVue('vueGenerale.php', [
           "pagetitle" => "Problème",
           "cheminVueBody" => "erreur.php",
           "errorMessage" => $errorMessage
       ]);

       $reponse->setStatusCode($statusCode);
       return $reponse;
   }
   ```

2. Parmi les 5 exceptions levées, 2 correspondent à des codes de réponses *HTTP*
   spécifiques. Pour les autres exceptions, nous renverrons le code de réponse
   d'erreur utilisateur générique `400`.  
   Dans `RouteurURL`, gérez l'exception avec des `catch` successifs qui
   permettent de gérer de l'exception la plus spécifique à l'exception la plus
   générique : 
   ```php
   try {
      // 3 méthodes qui lèvent des exceptions
   } catch (TypeExceptionSpecifique1 $exception) {
      // Remplacez xxx par le bon code d'erreur
      $reponse = ControleurGenerique::afficherErreur($exception->getMessage(), xxx);
   } catch (TypeExceptionSpecifique2 $exception) {
      // Remplacez xxx par le bon code d'erreur
      $reponse = ControleurGenerique::afficherErreur($exception->getMessage(), xxx);
   } catch (TypeExceptionGenerique $exception) {
      $reponse = ControleurGenerique::afficherErreur($exception->getMessage()) ;
   }
   ```

3. Testez votre code en appelant une route qui n'existe pas. Observez le message
   d'erreur, ainsi que le code de retour avec les outils de développement,
   onglet *Réseau*.

4. Testez votre code en appelant une méthode non prise en charge. Observez le
   message d'erreur, ainsi que le code de retour avec les outils de
   développement.

5. Modifiez, le temps de cette question, votre code pour que l'action `feed()`
   prenne un argument quelconque. Appelez l'URL `web/`. Observez le message
   d'erreur et le code de retour avec les outils de développement.

</div>
