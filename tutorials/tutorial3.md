---
title: TD3 &ndash; Développer une API REST
subtitle: Nommage des URI, verbes HTTP, authentification par JWT
layout: tutorial
lang: fr
---
{% raw %}

## API REST

Les API permettent la communication entre différents composants de votre
application et entre votre application et d’autres développeurs, par
l’utilisation de requêtes et de réponses. Elles donnent un moyen d’accès aux
données de façon réutilisable et standardisée.

Un standard d'API très présent sur le Web est *REST*. Les contraintes imposées
par *REST* sont un peu abstraites ; dans ce TD, nous nous intéresserons qu'à ses
implications concrètes pour un service Web. La motivation est que tous les
services Web *RESTful*, *c-à-d.* qui satisfont les contraintes *REST*, soient
interopérables. Ils doivent donc tous utiliser le même protocole de transfert
(*HTTP*) et les mêmes formats de données (*JSON* ou *XML*).

Les aspects fondamentaux d'un service Web *RESTful* sont : 
* adopter une convention de nommage pour les identifiants de ressources (URI) ;
* utiliser des verbes HTTP ;
* utiliser les codes de réponse *HTTP* pour indiquer si une requête a pu être
  traitée avec succès ;
* échanger des données au format *JSON* (ou *XML*) ;
* être sans état (*Stateless*), ou sans mémoire, c'est-à-dire que chaque
  requête / réponse ne se souvient pas des anciennes. 
* le fonctionnement du service doit pouvoir être découvert, c'est-à-dire que
  l'on fournit des URL sur les actions liées à une ressource.


### Détails supplémentaires

Reprenons ces aspects plus en détail : 

#### Noms des ressources

Prenons un exemple de bon URL : `/client/33245/commandes/8769/categories/1`.

On voit que les ressources utilisent des noms, et pas des verbes, en minuscule.
Les ressources sont regroupées en collection et sont nommées au pluriel. On
utilise les sous-chemins pour indiquer l'appartenance à une sous-ressource. Par
exemple, l'URL précédente fait référence aux produits de la catégori `1` qui appartiennent à la commande `8769` du client `33245`.

#### Verbes HTTP 

Pour indiquer une action sur une ressource, on utilise des verbes HTTP : 
  * `GET` : lire une ressource,
  * `POST` : créer une nouvelle ressource,
  * `PUT` : mettre à jour une ressource complètement en la remplaçant,
  * `PATCH` : mettre à jour une ressource partiellement en la modifiant 
  * `DELETE` : supprimer une ressource,

<!-- https://stackoverflow.com/questions/28459418/use-of-put-vs-patch-methods-in-rest-api-real-life-scenarios -->

#### Les codes de statut *HTTP*

Les codes de réponse *HTTP* servent à indiquer si une requête a pu être traitée
avec succès. Complétons les codes déjà vus avec les 10 codes les plus utilisés : 
  * Codes de succès `2xx` : 
    * `200 OK` (attribut `HTTP_OK` de l'objet *PHP* `Response`)  
      Code de succès générique. Code le plus utilisé.
    * `201 CREATED` (attribut `HTTP_CREATED`)  
      Création d'entité réussie, généralement à la suite d'une requête `POST`.
      Il est courant de fournir un lien vers la ressource créée dans l'en-tête
      `Location :`. Le corps de réponse peut être vide.
    * `204 NO CONTENT` (attribut `HTTP_NO_CONTENT`)  
      Code de succès qui signale un corps de requête vide, généralement à la suite d'une requête `DELETE` ou `PUT`.
  * Codes de redirection `3xx` déjà présentés dans 
    [le TD2]({{site.baseurl}}/R4.A.10-ComplementWeb/tutorials/tutorial2#des-redirections-plus-propres) :
    * `301 MOVED PERMANENTLY` : redirection permanente 
    * `302 FOUND` : redirection temporaire   
  * Codes d'erreur côté client `4xx` déjà présentés dans 
    [le TD2]({{site.baseurl}}/R4.A.10-ComplementWeb/tutorials/tutorial2#utilisation-des-codes-de-réponses-pour-les-erreurs) : 
    * `400 BAD REQUEST` : erreur générique
    * `401 UNAUTHORIZED` : le client doit s'authentifier,
    * `403 FORBIDDEN` : le client authentifié n'a pas les droits
    * `404 NOT FOUND` : ressource inconnue
    * `405 METHOD NOT ALLOWED` : verbe *HTTP* non pris en charge,
    * `409 CONFLICT` : conflit avec une ressource existante,
  * Codes d'erreur côté serveur `5xx` :
    * `500 INTERNAL SERVER ERROR` (attribut `HTTP_INTERNAL_SERVER_ERROR`)  
      Ne devrait jamais être renvoyé intentionnellement. Généralement, ce code provient d'un `try / catch` global sur le serveur qui traite les exceptions inattendues avec un code `500`. 

#### Tableau récapitulatif

| Verbe *HTTP* | CRUD    | Collection entière (par ex. `/customers`)                              | Item spécifique (par ex. `/customers/{id}`)                                           |
| ------------ | ------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `POST`       | Create  | `201` (`Created`). <br> `409` (`Conflict`) si la ressource existe déjà | `405` (`Method Not Allowed`)                                                          |
| `GET`        | Read    | `200` (`OK`), liste de clients.                                        | `200` (`OK`), client particulier.  <br> `404` (`Not Found`), si l'ID est inconnu.     |
| `PUT`        | Replace | `405` (`Method Not Allowed`)                                           | `200` (`OK`) ou `204` (`No Content`).  <br> `404` (`Not Found`), si l'ID est inconnu. |
| `PATCH`      | Modify  | `405` (`Method Not Allowed`)                                           | `200` (`OK`) ou `204` (`No Content`).  <br> `404` (`Not Found`), si l'ID est inconnu. |
| `DELETE`     | Delete  | `405` (`Method Not Allowed`)                                           | `200` (`OK`) ou `204` (`No Content`).  <br> `404` (`Not Found`), si l'ID est inconnu. |
{: .centered .pretty}

## Échange de données en *JSON*

Dans l'optique de développer un API *REST*, nous devrons
échanger des données au format *JSON*.

### Utilisation dans la page Web avec *AJAX*

Commençons en douceur en créant une nouvelle route sans échange de donnée. Cette
route `/web/api/feeds/{idPublication}` associée au verbe *HTTP* `DELETE`
supprimera une publication. Notez que les routes liées à la future API sont
regroupées sous l'URL `/web/api/`.

<div class="exercise">

1. Commençons par la méthode `PublicationService::supprimerPublication()` qui
   appellera la méthode existante `PublicationRepository::remove()`. Comme la
   couche *Service* s'occupe de la validation, notre méthode
   `supprimerPublication()` va s'assurer que toutes les données sont correctes. Sinon, elle lancera une `ServiceException` avec un message et un code d'erreur. Le code d'erreur reprendra les codes de statut *HTTP*.

   **Créez** la méthode
   `supprimerPublication()` et **ajoutez** les codes suivants
   lors des différents lancements d'exceptions : 
   * `Response::HTTP_FORBIDDEN` : l'utilisateur est connecté, mais n'a pas l'autorisation.
   * `Response::HTTP_NOT_FOUND` : la ressource est inconnue.
   * `Response::HTTP_UNAUTHORIZED` : l'utilisateur n'est pas connecté.
  
   ```php
   public function supprimerPublication(int $idPublication, ?string $idUtilisateurConnecte): void
   {
      $publication = $this->publicationRepository->get($idPublication);

      if (is_null($idUtilisateurConnecte))
         throw new ServiceException("Il faut être connecté pour supprimer un feed", Response::XXX);

      if ($publication === null)
         throw new ServiceException("Publication inconnue.", Response::XXX);

      if ($publication->getAuteur()->getIdUtilisateur() !== intval($idUtilisateurConnecte))
         throw new ServiceException("Seul l'auteur de la publication peut la supprimer", Response::XXX);

      $suppressionReussie = $this->publicationRepository->remove($publication);

      if (!$suppressionReussie)
         throw new ServiceException("Publication non supprimée.", Response::XXX);
   }
   ```

2. Créez un nouveau contrôleur `ControleurPublicationAPI.php` et une nouvelle
   action `supprimer($idPublication)` avec le code suivant. Indiquez le bon code
   de réponse en cas de succès.

   ```php
   namespace TheFeed\Controleur;

   use TheFeed\Service\PublicationServiceInterface;
   use TheFeed\Service\Exception\ServiceException;
   use Symfony\Component\HttpFoundation\JsonResponse;
   use Symfony\Component\HttpFoundation\Response;

   class ControleurPublicationAPI
   {

      // Syntaxe PHP 8.0: Class constructor property promotion
      // Déclare un attribut et l'initialise depuis le constructeur
      // https://php.watch/versions/8.0/constructor-property-promotion
      public function __construct (
         private readonly PublicationServiceInterface $publicationService
      ) {}

      public function supprimer($idPublication): Response
      {
         try {
               $idUtilisateurConnecte = ConnexionUtilisateur::getIdUtilisateurConnecte()
               $this->publicationService->supprimerPublication($idPublication, $idUtilisateurConnecte);
               return new JsonResponse('', Response::XXX);
         } catch (ServiceException $exception) {
               return new JsonResponse(["error" => $exception->getMessage()], $exception->getCode());
         }
      }
   }
   ```

   *Note :* Si *PhpStorm* émet un avertissement à propos de `JsonResponse(["error" => ...])`, il faut passer le niveau de langage *PHP* à ⩾ 8.0.

3. Créez une nouvelle route `api/feeds/{idPublication}` de méthode *HTTP*
   `DELETE` pour appeler cette action. Pour cela, il faudra enregistrer
   `ControleurPublicationAPI` dans le conteneur de services. Le nom du service
   enregistré est en effet utilisé dans le champ `_controller` de la route.


   
    <!-- // Route removeFeedyAPI
    $route = new Route("api/feeds/{idPublication}", [
        "_controller" => [ControleurPublicationAPI::class, "supprimer"],
    ]);
    $route->setMethods(["DELETE"]);
    $routes->add("removeFeedyAPI", $route); -->

</div>

### Découverte de Postman

Pour tester ce bout d'API, il faut envoyer une requête de méthode `DELETE`. Pour cela, nous allons utiliser un petit logiciel très pratique quand on développe des `API` : **Postman**.  
Ce logiciel va permettre de paramétrer et d'envoyer des requêtes de manière
interactive et de visualiser le résultat très simplement.

Le logiciel est installé sur les machines de l'IUT. Chez vous, vous pouvez le
[télécharger](https://www.postman.com/downloads/?utm_source=postman-home).

<div class="exercise">

1. Lancez **Postman**. L'application vous propose de créer un compte, mais vous n'en avez pas besoin. Cliquez simplement sur "**Skip signing in and take me straight to the app**" tout en bas.

2. Sur l'interface, créez un nouvel onglet et paramétrez-le ainsi :

    ![Postman config 1](/R4.A.10-ComplementWeb/assets/TD3/postman1.PNG){: .blockcenter}

    * Méthode `DELETE`
    * Adresse : [http://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD3/web/api/feeds](http://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD3/web/api/feeds)

3. Cliquez sur "**Send**" et observez la réponse. Si vous rechargez votre site
   Web, la publication correspondante doit avoir disparue.

</div>

### Bouton JavaScript de suppression

Nous allons maintenant rajouter un bouton *HTML*, auquel sera associé un code
*JavaScript* qui lancera la requête `DELETE`. Nous allons profiter du 
[TP6 de *JavaScript*](https://gitlabinfo.iutmontp.univ-montp2.fr/r4.01-developpementweb/TD6)
 pour utiliser `fetch` et/ou `async/await` à la place de `XMLHttpRequest`.

Pour que le gestionnaire d'évènement sache quelle publication il doit supprimer,
nous allons rajouter l'identifiant de publication dans un attribut de la balise.
Les [attributs `data-*`](https://developer.mozilla.org/fr/docs/Learn/HTML/Howto/Use_data_attributes) ont été conçus à cet effet. Par exemple, si on rajoute les attributs suivants à une balise *HTML*
```html
<article>
  id="voitureelectrique"
  data-columns="3"
  data-index-number="12314"
</article>
```
on peut les récupérer en *JavaScript* avec 
```js
let article = document.getElementById('voitureelectrique');
article.dataset.columns // "3"
article.dataset.indexNumber // "12314"
```
Attention, les tirets dans l'attribut *HTML* `data-index-number` sont convertis
en attribut JS `indexNumber` avec un nommage *camelCase*.

<div class="exercise">

1. Rajouter dans `feed.html.twig` un bouton juste après le paragraphe du
   message. Remplacez les commentaires *Twig* par le code adéquat.

   ```twig
   {# si l'utilisateur connecte est l'auteur de la publication #}
   <button class="delete-feedy" data-id-publication="{# identifiant publication  #}">
       Supprimer
   </button>
   {#  fin si #}
   ```

2. Créez un script `web/assets/js/main.js` avec le contenu suivant. Remplacez
   `XXX` par le code de succès émis par votre API REST (*cf.* Exercice 1.2) : 

   ```js
   /**
    * @param {HTMLElement} button La balise <button> cliquée
    */
   function supprimerFeedy(button) {
      // TODO : récupérer l'identifiant de publication de la balise button
      let idPublication = ; 
      let URL = apiBase + "feeds/" + idPublication;

      fetch(URL, {method: "DELETE"})
         .then(response => {
               if (response.status === XXX) {
                  // Plus proche ancêtre <div class="feedy">
                  let divFeedy = button.closest("div.feedy");
                  divFeedy.remove();
               }
         });
   }
   ```

3. Ajouter un `addEventListener` sur les boutons `<button class="delete-feedy">`
   pour appeler la méthode précédente.

3. Changez `base.html.twig` pour faire appel au script `main.js` et rajouter quelques variables globales dans *JavaScript*.

   ```diff
      <link rel="stylesheet" type="text/css" href="{{ asset("assets/css/styles.css") }}">
   +    <script type="text/javascript" src="{{ asset("assets/js/main.js") }}" defer></script>
   </head>
   <body>
   +<script type="text/javascript">
   +    let siteBase = "{{ asset('.') }}";
   +    let apiBase = siteBase+"/api/"
   +    let pagePersoBase = siteBase+"/utilisateurs/page/";
   +    let imgBase = "{{  asset("assets/img") }}";
   +</script>
   <header>
   ```

4. Testez votre site. Un utilisateur connecté doit pouvoir effacer ses *feedy*
   en cliquant sur le bouton *Supprimer*.

   *Aide :* Si cela ne marche pas, ouvrez l'onglet *Réseau* des outils de
   développement pour observer la requête émise par le clic et le bouton, et la
   réponse renvoyée par le serveur.

</div>

### Réponse en *JSON*

<!-- 
JsonSerialize ou symfony/Serializer ? 
https://symfony.com/doc/current/components/serializer.html
À peu près pareil : 
The JsonEncoder encodes to and decodes from JSON strings, based on the PHP json_encode and json_decode functions. 
-->

<!-- Quelles actions veut-on pour notre API ? -->

Nous avons déjà vu la fonction 
[`json_encode()`](https://www.php.net/manual/fr/function.json-encode.php) pour encoder une variable *PHP*
en une chaîne de caractères au format *JSON*. Quand il encode un objet, le
comportement par défaut de *PHP* est d'encoder uniquement que les attributs
publics. Pour pouvoir personnaliser l'encodage *JSON*, une classe doit implémenter l'interface 
[`JsonSerializable`](https://www.php.net/manual/fr/class.jsonserializable.php), c'est-à-dire fournir une méthode 
```php
public function jsonSerialize();
```

Nous allons utiliser ces notions lors de la création d'une requête qui renvoie les détails d'un utilisateur au format *JSON*.

<div class="exercise">

<!-- 1. Rajoutez et codez la méthode à `UtilisateurService`
   ```php
   public function recupererUtilisateurParId($idUtilisateur) : Utilisateur
   ```
-->

1. Faites en sorte que la classe `Utilisateur` implémente l'interface
   `JsonSerializable` et rajoutez-lui la méthode : 

   ```php
   public function jsonSerialize(): array
   {
      return [
         "idUtilisateur" => $this->getIdUtilisateur(),
         "login" => $this->getLogin(),
         "profilePictureName" => $this->getProfilePictureName()
      ];
   }
   ```

2. Créez un nouveau contrôleur `ControleurUtilisateurAPI` et une nouvelle action
   ```php
   public function afficherDetail($idUtilisateur): Response
   ```
   qui récupère l'utilisateur d'identifiant `$idUtilisateur` et le renvoie au
   format *JSON*. Inspirez-vous de `supprimer`. Vous utiliserez le
   constructeur `new JsonResponse($object)` qui permet de créer une réponse qui
   contient l'encodage *JSON* de `$object`.

3. Rajoutez une route `GET` sur l'URL `api/utilisateurs/{idUtilisateur}` qui
   appelle cette action. Testez votre route directement dans le navigateur avec un identifiant d'utilisateur existant. 
   
4. Dans `UtilisateurService::recupererUtilisateurParId()`, rajoutez le code
   d'erreur *HTTP* adéquat si l'utilisateur est inconnu. Testez la route avec un
   identifiant inconnu (utilisez l'onglet Réseau ou *Postman* pour voir le code
   de réponse).

   <!-- Response::HTTP_NOT_FOUND -->
</div>

<div class="exercise">

1. Appliquez le même procédé pour que la route `GET` d'URL
   `api/feeds/{idPublication}` appelle sur une méthode
   `ControleurPublicationAPI::afficherDetail($idPublication)` qui renvoie une
   réponse JSON. Voici, sur un exemple, les informations sur la publication
   qu'il faut renvoyer : 
   ```json
   {
      "idPublication": 1,
      "message": "Un exemple de publication",
      "date": "30 January 2023",
      "auteur": {
         "idUtilisateur": 1
      }
   }
   ```

   **Rappel :** Vous avez déjà formaté des dates dans la vue Twig
   `feed.html.twig`. En PHP, vous pourrez faire en même avec
   ```php
   $dateTime->format('d F Y');
   ```

2. Testez la route avec un identifiant de publication connu et un inconnu.
</div>


<div class="exercise">

1. Codez enfin une route `GET` d'URL `api/feeds` qui appelle
   `ControleurPublicationAPI::afficherListe()` et renvoie la liste des
   publications au format JSON.

</div>

### Corps de la requête en *JSON*

Nous allons maintenant créer une route pour poster un *feedy*. Comme le message
du *feedy* ne peut pas raisonnablement être inclus dans l'URL, nous allons
l'envoyer dans le corps de la requête. Et quel format de données allons-nous
utiliser : *JSON* bien sûr !

<div class="exercise">

1. Changer votre fonction `PublicationService::creerPublication()` pour le code
   suivant, qui gère le cas `$idUtilisateur=null` et récupère l'identifiant de publication depuis le *repository* : 

   ```php
   public function creerPublication($idUtilisateur, $message): Publication
   {
      if ($idUtilisateur == null) throw new ServiceException("Il faut être connecté pour publier un feed", Response::HTTP_UNAUTHORIZED);
      if ($message == null || $message == "") throw new ServiceException("Le message ne peut pas être vide!", Response::HTTP_BAD_REQUEST);
      if (strlen($message) > 250) throw new ServiceException("Le message ne peut pas dépasser 250 caractères!", Response::HTTP_BAD_REQUEST);

      $auteur = new Utilisateur();
      $auteur->setIdUtilisateur($idUtilisateur);
      $publication = Publication::create($message, $auteur);
      $idPublication = $this->publicationRepository->create($publication);
      $publication->setIdPublication($idPublication);
      return $publication;
   }
   ```

2. Créez la méthode `ControleurPublicationAPI::submitFeedy` avec le code
   suivant, que nous allons compléter par la suite.

   ```php
   public function submitFeedy(Request $request): Response
   {
      try {
         // TODO : récupérer le message inclus dans la requête dans une variable $message

         $idUtilisateurConnecte = ConnexionUtilisateur::getIdUtilisateurConnecte();
         $publication = $this->publicationService->creerPublication($idUtilisateurConnecte, $message);
         return new JsonResponse($publication, Response::XXX);
      } catch (ServiceException $exception) {
         return new JsonResponse(["error" => $exception->getMessage()], $exception->getCode());
      } 
   }
   ``` 
3. Complétez la méthode précédente avec les consignes suivantes : 
   * Indiquez le bon code de réponse en cas de succès.
   * Le corps d'une requête se récupère avec `$request->getContent()`,
   * une chaîne de caractères au format *JSON* se décode avec `json_decode($string)`,
   * si l'objet décodé du *JSON* ne contient pas d'attribut message, assignez la
     valeur par défaut `$message=null`. Pour ceci, utilisez l'une des syntaxes suivantes
     ```php
     $valeur = isset($objet->attribut) ? $objet->attribut : "valeur par défaut";
     // Syntaxe équivalente avec l'opérateur Null coalescent
     // https://www.php.net/manual/fr/migration70.new-features.php
     $valeur = $objet->attribut ?? "valeur par défaut";
     ```

4. En cas de corps de requête malformé, `json_decode` va échouer. Pour traiter
   cette erreur, on demande à `json_decode` de lancer une `JsonException` avec
   la commande
   ```php
   // On utilise les arguments nommés pour raccourcir
   // https://www.php.net/manual/fr/functions.arguments.php#functions.named-arguments
   json_decode($content, flags: JSON_THROW_ON_ERROR);
   ```

   **Appliquez** ce code et traitez l'exception en rajoutant un nouveau `catch`
   ```php
   catch (JsonException $exception) {
        return new JsonResponse(
            ["error" => "Corps de la requête mal formé"],
            Response::HTTP_BAD_REQUEST
        );
    }
    ```

5. Créez une nouvelle route `/web/api/feeds` de méthode `POST` qui appelle
   `submitFeedy`. avec corps de requête contenant le message

</div>

Nous allons maintenant tester notre route avec *Postman*.

<div class="exercise">

5. Créez une nouvelle requête *Postman* (bouton `+`) d'URL `/web/api/feeds` de
   méthode `POST`. Indiquer le corps de requête suivant dans `Body` → `raw` : 
   ```json
   {
      "message": "test API!"
   }
   ```
   **Observez** le corps (erreur au format *JSON*) et le code de statut `401
   Unauthorized` de la réponse *HTTP* en bas de *Postman*.

6. En effet, la route n’est donc accessible qu’aux utilisateurs authentifiés. On
   va donc fournir à *Postman* un identificateur de session. Connectez-vous sur
   votre application puis exécutez le code JavaScript suivant dans la console du navigateur
   (`F12` → `Console`) :
   ```js
   document.cookie
   ```
   Conservez bien ce résultat.

7. Sur *Postman*, cliquez sur l'onglet `Headers` de l’onglet. Ajoutez une
   nouvelle clé `Cookie` puis, comme valeur, collez le résultat précédemment
   récupéré comme valeur.

   ![Postman config 2](/R4.A.10-ComplementWeb/assets/TD3/postman2.PNG){: .blockcenter}

8. Envoyez la requête de nouveau. Le serveur vous renvoie la représentation
   `JSON` de votre nouveau *feedy* ! Vérifiez aussi sur le site que le *feedy* est apparu.

</div>

### Bouton JavaScript pour publier

<div class="exercise">

1. Nous vous fournissons une fonction JavaScript qui renvoie le code *HTML* d'un
   *feedy* dont les données sont données en argument. **Copiez** ce code dans `main.js`.

   ```js
   function templateFeedy(feedy, utilisateur) {
      return `<div class="feedy">
      <div class="feedy-header">
         <a href="${pagePersoBase + feedy.auteur.idUtilisateur}">
               <img alt="profile picture" src="${imgBase}utilisateurs/${utilisateur.profilePictureName}" class="avatar">
         </a>
         <div class="feedy-info">
               <span>${escapeHtml(utilisateur.login)}</span><span> - </span><span>${feedy.date}</span>
               <p>${escapeHtml(feedy.message)}</p>
               <button class="delete-feedy" data-id-publication="${feedy.idPublication}">Supprimer</button>
         </div>
      </div>
   </div>`;
   }
   ```

2. Nous vous fournissons la méthode de base pour soumettre un *feedy*.
   **Copiez** ce code dans `main.js` et remplacez `XXX` par le code de succès
   émis par votre API REST.

   ```js
   async function submitFeedy() {
      const messageElement = document.getElementById('message')
      // On récupère le message 
      let message = messageElement.value;
      // On vide le formulaire
      messageElement.value = "";
      // On utilise la variable globale apiBase définie dans base.html.twig
      let URL = apiBase + "feeds";

      let response = await fetch(URL, {
         // Ajouter la méthode 'POST'

         // Ajouter des en-têtes pour indiquer 
         // * le format du corps de requête
         // * le format de données attendu en retour

         // Ajouter un corps de requête contenant le message
      });
      if (response.status !== XXX)
         // (Hors TD) Il faudrait traiter l'erreur 
         return; 
      let feedy = await response.json();
      // Utilisateur par défaut en attendant la suite
      let utilisateur = {profilePictureName : "anonyme.jpg", login: "Inconnu"};
      let formElement = document.getElementById("feedy-new");
      formElement.insertAdjacentHTML('afterend', templateFeedy(feedy, utilisateur));
   }
   ```
3. Vous allez compléter le deuxième argument
   [`options` de la fonction `fetch()`](https://developer.mozilla.org/en-US/docs/Web/API/fetch#parameters) avec les instructions suivantes : 
   1. indiquez la méthode `POST` dans le champ `method` (voir `supprimerFeedy`), 
   3. le corps de la requête correspondant au champ `body` dont la valeur est
      une chaîne de caractères. Vous devez utiliser `JSON.stringify()` pour créer,
      à partir d'un message `"Vivement le stage !"`, la chaîne de caractères
      ```json
      {
         "message": "Vivement le stage !"
      } 
      ```
   2. les en-têtes s'indiquent dans le champ `headers` : 
      1. l'en-tête `Content-type` indique le format du corps de la requête,
      2. l'en-tête `Accept` indique le format souhaité pour le corps de la
         réponse. Vous pouvez donc indiquer les en-têtes avec 
         ```js
         headers: {
               'Accept': 'application/json',
               'Content-type': 'application/json; charset=UTF-8',
         },
         ```

4. Testez dans la console votre méthode `submitFeedy()`.

5. Rajoutez un `addEventListener` sur `<button id="feedy-new-submit">` pour
   appeler la fonction `submitFeedy`.

</div>

Vous pouvez sauter l'exercice suivant si vous estimez que vous manquez de temps
pour faire les TDs.

<div class="exercise">

1. Modifiez la fonction `submitFeedy()` pour récupérer l'utilisateur dont
   l'identifiant est `feedy.auteur.idUtilisateur` par une requête à l'URL
   `web/api/utilisateur/{idUtilisateur}`.

1. Testez que la publication d'un nouveau *feedy* rempli bien le *login* et
   l'image de profil de l'utilisateur.

1. Publiez le message `<h1>Hack!</h1>' et observez le problème. Rechargez la
   page pour que le *feedy* soit affiché par le serveur et observez la différence.

1. Nettoyer les entrées utilisateurs non fiables à l'aide de la méthode JavaScript : 
   ```js
   function escapeHtml(text) {
      // https://stackoverflow.com/questions/1787322/what-is-the-htmlspecialchars-equivalent-in-javascript
      return text;
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
   }
   ```   

</div>

<!-- 
Idéalement try/catch (~= .catch()) 
pour traiter les erreurs (par. ex. utilisateur déconnecté entre temps)
-->





<!-- Renvoie le lien vers le Tweet créé  -->
<!-- avec Location ? Ne va pas faire une redirection ? Github -> champ "url" ! -->

<!-- 13ème route ! Annotation route plutôt ?? -->


## *Json Web Token* (`JWT`)

### Authentification avec des `JWT`

Rappelons qu'un service Web *RESTful* doit être sans état (*Stateless*). Ceci
signifie que l'échange client–serveur s'effectue sans conservation de l'état de
la session de communication sur le serveur entre deux requêtes successives.
L'état de la session est conservé par le client et transmis à chaque nouvelle
requête. Les requêtes du client contiennent donc toute l'information nécessaire
pour que le serveur puisse y répondre.

Notre `API` ne respecte pas le principe **Stateless** car on utilise des
sessions pour garder en mémoire que l'utilisateur est connecté et ainsi
l'autoriser à accéder à des routes sécurisées ou bien supprimer ses propres
ressources.

Nous allons donc stocker l'identifiant de l'utilisateur côté client dans des
cookies. Mais attention, nous avons vu au 
[semestre 3](http://romainlebreton.github.io/R3.01-DeveloppementWeb/tutorials/tutorial7.html)
que les données stockées dans les cookies sont modifiables par le client. 
Le client pourrait donc se connecter tout seul sans avoir à s'authentifier.

Une solution classique consiste pour le serveur à rajouter une signature
cryptographique dans le cookie. Ainsi, le client n'a plus la possibilité de
modifier son cookie ; sinon il devrait falsifier la signature, ce qui est
pratiquement impossible puisque seul le serveur est en capacité de signer. 
Ce mécanisme est fourni par les *Json Web Token* (`JWT`).

En pratique, le serveur stocke les informations d'authentification dans un jeton
(*token* en anglais). Le serveur dispose d'une *clé privée* secrète avec
laquelle il *signe* le jeton. Puis le serveur dépose le jeton chez le client
dans un cookie. Le client peut librement lire ce jeton `JWT`. Mais il ne pourra pas le
modifier sans que le serveur ne le détecte (grâce au mécanisme de signature).

À chaque requête, le client envoie alors son cookie contenant son jeton `JWT`.
Le serveur le décode et vérifie s'il n'a pas été altéré. Si tout va bien, il
peut donc extraire l'information de ce token et l'utiliser en toute confiance
(il n'a pas été altéré entre temps) sans avoir besoin de `sessions` et de
maintenir un **état** côté serveur.

Attention néanmoins, contrairement aux sessions, il ne faut pas stocker de
donner sensibles dans le `JWT` car tout le monde peut facilement le lire ; sa
sécurité réside dans le fait qu'il ne peut pas être falsifié seulement.

### Présentation du format `JWT`

Expliquons le format sur 
[l'exemple interactif donné par la page `jwt.io`](https://jwt.io/).
Un `JWT` décodé est composé de 3 parties : 
1. des <span style="color:#fb015b">en-têtes</span> au format *JSON* indiquant le type de jeton, ici `JWT`, et
   l'algorithme de signature (plus de détails à venir), ici `HS256` pour HMAC
   SHA256, c'est-à-dire Code d'Authentification de Message à base de Hachage
   (HMAC) qui utilise l'algorithme de hachage cryptographique `SHA256`.
   ```json
   {
      "alg": "HS256",
      "typ": "JWT"
   }
   ```
1. un <span style="color:#d63aff">corps de message</span> contenant des données au format *JSON*, par exemple
   ```json
   {
      "message": "Feed !",
   }
   ```
   (des noms de champs ont des 
   [sens particuliers](https://www.rfc-editor.org/rfc/rfc7519#section-4.1) : 
   `exp` (Expiration Time),
   `iss` (Issuer), ...)

1. la <span style="color:#00b9f1">signature</span> du message

Pour former le jeton final, chaque partie est [encodée en
`base64`](https://fr.wikipedia.org/wiki/Base64), puis concaténée avec des points
`'.'`. Dans l'exemple suivant, <span style="color:#fb015b">la partie
rouge</span> est l'encodage en `base64` de l'en-tête, <span
style="color:#d63aff">la partie violette</span> est l'encodage en `base64` du
corps de message et <span style="color:#00b9f1">la partie bleu ciel</span> est
la signature : 

<pre><div style="padding: 1em;background:white"><span style="color:#fb015b">eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9</span>.<span style="color:#d63aff">eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ</span>.<span style="color:#00b9f1">SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c</span></div></pre>

<div class="exercise">

1. Pour utiliser le `JWT`, nous allons utiliser une bibliothèque externe : 
   ```bash
   composer require firebase/php-jwt
   ```

1. Créez la classe `src/Lib/JsonWebToken.php` avec le code suivant : 
   ```php
   namespace TheFeed\Lib;

   use Firebase\JWT\JWT;
   use Firebase\JWT\Key;

   class JsonWebToken
   {
      private static string $jsonSecret = "votre_secret_ici";

      public static function encoder(array $contenu) : string {
         return JWT::encode($contenu, self::$jsonSecret, 'HS256');
      }

      public static function decoder(string $jwt) : array {
         try {
               $decoded = JWT::decode($jwt, new Key(self::$jsonSecret, 'HS256'));
               return (array) $decoded;
         } catch (\Exception $exception) {
               return [];
         }
      }

   }
   ```

2. Générer votre secret en exécutant la méthode suivante, qui vous avait déjà
   servie pour générer le poivre :  
   ```php
   var_dump(MotDePasse::genererChaineAleatoire());
   ```

</div>

### Connexion utilisateur par `JWT`

Avant de rendre notre API REST sans état, nous devons régler un problème de
conception des précédents TDs. La couche *Service* doit être indépendante de
l'interface, et donc de toute la couche de transfert de donnée *HTTP*. Du coup,
nous n'avons pas le droit d'appeler la classe `ConnexionUtilisateur`, qui est
basée sur les mécanismes Web cookie et session, dans les services. 

Comme `UtilisateurService` appelle plusieurs fois `ConnexionUtilisateur`, nous
allons devoir réusiner le code (*code refactoring* en anglais).

<div class="exercise">

1. Comme `UtilisateurService::deconnecter()` n'est composé que d'appels à
   `ConnexionUtilisateur`, nous allons supprimer cette méthode et transférer son
   code dans `ControleurUtilisateur::deconnecter()`.  
   **Supprimez** `UtilisateurService::deconnecter()` et changez
   `ControleurUtilisateur::deconnecter()` avec le code suivant : 
   ```php
   public function deconnecter(): Response
   {
       if (!ConnexionUtilisateur::estConnecte()) {
           MessageFlash::ajouter("error", "Utilisateur non connecté.");
           return ControleurPublication::rediriger('feed');
       }
       ConnexionUtilisateur::deconnecter();
       MessageFlash::ajouter("success", "L'utilisateur a bien été déconnecté.");
       return ControleurUtilisateur::rediriger('feed');
   }
   ```

1. Concernant la méthode `UtilisateurService::connecter()`, nous allons
   seulement déplacer son appel à `ConnexionUtilisateur::connecter` ; à la fin de la méthode, changez

   ```diff
    if (!MotDePasse::verifier($password, $utilisateur->getPassword()))
       throw new ServiceException("Mot de passe incorrect.", Response::HTTP_BAD_REQUEST);

   - ConnexionUtilisateur::connecter($utilisateur->getIdUtilisateur());
   + return $utilisateur->getIdUtilisateur();
    }
   ```
   
   **Adaptez** `ControleurUtilisateur::connecter()` en conséquence. Vu que `UtilisateurService::connecter()` ne connecte plus, nous vous proposons de la **renommer** `UtilisateurService::verifierIdentifiantUtilisateur` (clic droit → *Refactor* → *Rename* ou `Maj+F6` sous *PhpStorm*).

</div>

Notre site va donc proposer deux mécanismes d'authentification : 
1. un mécanisme basé sur les sessions qui ne sera utilisé que sur le site Web
   (`ControleurUtilisateur` et `ControleurPublication`),
2. un mécanisme basé sur les `JWT`. Ce mécanisme sera utilisé à la fois dans
   l'API REST (pour devenir *Stateless*), et dans le site classique pour que les
   fonctionnalités JavaScript puissent appeler l'API REST.

Qui dit deux codes pour le même problème, dit héritage et en particulier interface.

<div class="exercise">

1. Modifiez la classe `ConnexionUtilisateur` pour passer tous ses attributs et
   méthodes en dynamique (pas statique). Corrigez les appels internes à ces
   attributs et méthodes.  
   Renommes le fichier en `ConnexionUtilisateurSession.php`, ce qui aura pour
   effet de renommer la classe (sous *PhpStorm*, clic droit sur le fichier →
   *Refactor* → *Rename* ou `Maj+F6`).

1. Utiliser *PhpStorm* pour créer une interface `ConnexionUtilisateurInterface`
   à partir de la classe `ConnexionUtilisateurSession` (clic droit sur le nom de classe
   → *Refactor* → *Extract Interface*). Rajouter l'instruction qui indique que `ConnexionUtilisateurSession` implémente `ConnexionUtilisateurInterface`.

1. Créez une nouvelle classe `src/Lib/ConnexionUtilisateurJWT.php` avec le code suivant : 
   ```php
   namespace TheFeed\Lib;

   use TheFeed\Modele\HTTP\Cookie;

   class ConnexionUtilisateurJWT implements ConnexionUtilisateurInterface
   {

      public function connecter(string $idUtilisateur): void
      {
         Cookie::enregistrer("auth_token", JsonWebToken::encoder(["idUtilisateur" => $idUtilisateur]));
      }

      public function estConnecte(): bool
      {
         return !is_null($this->getIdUtilisateurConnecte());
      }

      public function deconnecter(): void
      {
         if (Cookie::existeCle("auth_token"))
               Cookie::supprimer("auth_token");
      }

      public function getIdUtilisateurConnecte(): ?string
      {
         if (Cookie::existeCle("auth_token")) {
               $jwt = Cookie::lire("auth_token");
               $donnees = JsonWebToken::decoder($jwt);
               return $donnees["idUtilisateur"] ?? null;
         } else
               return null;
      }
   }
   ```

   *Remarque :* nous stockons notre `JWT` dans un cookie `auth_token` pour qu'il soit automatiquement envoyé par le navigateur à chaque requête.

1. Nous souhaitons injecter les deux services de connexion utilisateur dans les contrôleurs : 
   1. Enregistrez des services `ConnexionUtilisateurSession` et
      `ConnexionUtilisateurJWT` dans le conteneur de services.
   1. Rajouter un service `ConnexionUtilisateurInterface $connexionUtilisateur` à tous les contrôleurs, sauf à `ControleurUtilisateur` qui possède deux tels services : 
      ```php
      public function __construct(
         private readonly PublicationServiceInterface $publicationService,
         private readonly UtilisateurServiceInterface $utilisateurService,
         private readonly ConnexionUtilisateurInterface $connexionUtilisateurSession,
         private readonly ConnexionUtilisateurInterface $connexionUtilisateurJWT,
      )
      {

      }
      ```
   1. Modifiez l'enregistrement des services liés aux contrôleurs pour y rajouter une référence : 
      * au service lié à `ConnexionUtilisateurSession` dans `ControleurPublication`,
      * aux services liés à `ConnexionUtilisateurSession` et `ConnexionUtilisateurJWT` dans `ControleurPublication` (attention à l'ordre),
      * au service lié à `ConnexionUtilisateurJWT` dans `ControleurPublicationAPI` et `ControleurUtilisateurAPI`.
   2. Dans `ControleurUtilisateur` et `ControleurPublication`, remplacez les
      appels aux méthodes statiques `ConnexionUtilisateurSession` par des appels
      dynamiques au service.
   3. Dans `ControleurUtilisateurAPI` et `ControleurPublicationAPI`, remplacez les
      appels aux méthodes statiques `ConnexionUtilisateurSession` par des appels
      dynamiques au service (qui sera `ConnexionUtilisateurJWT`).

2. Changez le code de `ControleurUtilisateur::connecter()` pour connecter
   l'utilisateur avec les deux mécanismes. Faites de même pour que `ControleurUtilisateur::connecter()` déconnecte deux fois l'utilisateur.

3. Il reste un dernier endroit où `ConnexionUtilisateurSession` appelle une
   méthode statique : dans l'ajout d'une variable globale
   `idUtilisateurConnecte` à *Twig*. Puisque nous ne voulons pas appeler
   systématique `ConnexionUtilisateurSession`, qui a pour effet de lancer la
   session, changez le code suivant dans `RouteurURL` : 

   ```diff
   - $twig->addGlobal('idUtilisateurConnecte', ConnexionUtilisateurSession::getIdUtilisateurConnecte());
   + $twig->addGlobal('connexionUtilisateur', new ConnexionUtilisateurSession());
   ```
   Et **changez** toutes les `idUtilisateurConnecte` en
   `connexionUtilisateur.idUtilisateurConnecte` dans `base.html.twig` et
   `feed.html.twig`.

3. Testez votre site Web. Vérifiez que la connexion utilisateur sur le site marche
   bien. Vérifiez que les fonctionnalités *AJAX* marchent toujours.

</div>

<div class="exercise">

4. Pour qu'un utilisateur de l'API puisse s'authentifier sans passer par le site
   Web, créez une nouvelle route `/api/auth` de méthode `POST` qui appellera une nouvelle action dans `ControleurUtilisateurAPI` (à compléter) : 
   ```php
   public function connecter(Request $request): Response
   {
       try {
           // TODO : Récupération du login et mot de passe 
           // depuis le corps de requête au format JSON
           $idUtilisateur = $this->utilisateurService->verifierIdentifiantUtilisateur($login, $password);
           // TODO : Appel du service connexionUtilisateur 
           // pour connecter l'utilisateur avec son identifiant
           return new JsonResponse();
       } catch (ServiceException $exception) {
           return new JsonResponse(["error" => $exception->getMessage()], $exception->getCode());
       } catch (\JsonException $exception) {
           return new JsonResponse(
               ["error" => "Corps de la requête mal formé"],
               Response::HTTP_BAD_REQUEST
           );
       }
   }
    ```   

5. Testez l'authentification en appelant dans *Postman* la route précédente avec
   le corps de requête
   ```json
   {
      "login": "Romain1",
      "password" : "Romain1Romain1"
   }
   ```
   Observez que la réponse dépose un seul cookie `auth_token` comme voulu

</div>

## Bilan sur les API REST

En se basant sur le protocole de transfert *HTTP* et le format de donnée *JSON*,
les API REST permettent l'interopérabilité en services Web *Restful*. Quelques
avantages clés des API REST sont les suivants :
* la séparation du client et du serveur : il est plus facile de fournir de nouvelles interfaces (par ex. une application mobile),
* le fait d’être *Stateless* permet la mise en cache, qui permet aux clients
  d'économiser des requêtes aux serveurs. 
* Dans le cas d'un site Web déployé sur plusieurs serveurs, l'élimination des
  sessions évite de devoir synchroniser ces informations de sessions entre
  serveurs, et les problèmes difficiles qui en découlent.

Dans ce TD, nous n'avons pas eu le temps d'évoquer quelques aspects importants : 
* un service Web *Restful* doit être un service découvrable, c'est-à-dire qu'il
  fournit des liens dans ses réponses qui permettent de découvrir les
  fonctionnalités du service sans documentation.  
  Par exemple, 
  * lors de la création d'une ressource, on renvoie des liens sur les actions liées à
    la ressource créée (lire, modifier, supprimer),
  * lors de la lecture d'une collection, chaque entité renvoie ses liens d'actions,
  * toujours lors de la lecture d'une collection, des liens `first`, `last`,
    `next` et `prev` sont un minimum pour permettre de pouvoir naviguer
    facilement dans la collection,
* un service Web *RESTful* professionnel devrait aussi supporter le format `XML`
  et passer de l'un à l'autre en fonction de l'en-tête 
  [*HTTP Accept*](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept).
*  Le filtrage, la recherche et le tri sont des moyens d’ajouter de la
   complexité à vos requêtes API. La pagination aide vos clients et utilisateurs
   API à éviter d’être submergés par trop de données. Le versionnage vous permet
   de continuer à mettre à jour votre API sans casser le code des personnes qui
   en dépendent déjà.

Sources du TD :
[OpenClassrooms](https://openclassrooms.com/fr/courses/6573181-adoptez-les-api-rest-pour-vos-projets-web/), [Wikipedia](https://fr.wikipedia.org/wiki/Representational_state_transfer), [RestAPITutorial.com](https://www.restapitutorial.com/lessons/restquicktips.html) et [ChatGPT](https://chat.openai.com/chat)



<!--
## Sources
Rappelez-vous, une API REST est stateless (sans état), c’est-à-dire qu’à chaque appel, elle a complètement oublié ce qui a pu se passer à l’appel précédent, nous ne pouvons donc pas stocker les informations de l’utilisateur en session.

La solution pour pallier ce problème va être de faire un premier appel pour s’authentifier. Ce premier appel va retourner un token, encodé, qui va contenir les informations sur la personne qui vient de s’authentifier. 

À l’appel suivant, dans le header Authorization, il suffira de renvoyer ce token pour dire à l’application “Je suis authentifié, voici la preuve grâce à ce token.” 

Ceci peut se faire grâce à `JWT`, qui signifie JSON Web Token, et qui est un standard qui définit les diverses étapes pour échanger les informations d’authentification de manière sécurisée. 

https://openclassrooms.com/fr/courses/7709361-construisez-une-api-rest-avec-symfony/7795148-authentifiez-et-autorisez-les-utilisateurs-de-l-api-avec-jwt

Authorization: <auth-scheme> <authorization-parameters>

Bearer
See RFC 6750, bearer tokens to access OAuth 2.0-protected resources

https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization


composer require firebase/php-jwt
https://jwt.io/libraries?language=PHP



https://packagist.org/packages/firebase/php-jwt

JWT dans les cookies pour que le JS ne puisse pas le lire : 
* Utilisez des cookies HttpOnly et Secure : Lorsque vous utilisez des cookies pour stocker des JWT, veillez à activer les drapeaux HttpOnly et Secure. L'indicateur HttpOnly empêche les scripts côté client d'accéder au cookie et l'indicateur Secure garantit que le cookie n'est envoyé que sur des connexions HTTPS.

  En gros, un utilisateur malicieux qui exécuterait du JS dans votre site (via injection HTML), pourrais lire les cookies autrement avec document.cookie

* On peut quand même lancer des requêtes qui envoient le cookie
  avec fetch par exemple 
* rajouter SameSite=strict pour ne pas pouvoir qu'un utilisateur malicieux envoie une requête sur un autre site (honeypot ? voir N. Aragon https://www.root-me.org/fr/Challenges/ )
  https://stackoverflow.com/questions/61062419/where-and-how-save-token-jwt-best-practice
* stocker juste idUtilisateur signé côté client, et le reste côté serveur (pourquoi ?)
  https://dev.to/rdegges/please-stop-using-local-storage-1i04

Du coup, reprendre le setcookie  "access_token", "auth_token", "jwt_token", or simply "token" de Malo !


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

/!\ Actuellement document.cookie renvoie le cookie PHPSESSID

The Symfony HttpFoundation component has a very powerful and flexible session subsystem which is designed to provide session management that you can use to store information about the user between requests through a clear object-oriented interface using **a variety of session storage drivers**.

```php
$storage = new NativeSessionStorage([
    'cookie_secure' => 'auto',
    'cookie_samesite' => Cookie::SAMESITE_LAX,
]);
$session = new Session($storage);
```
https://symfony.com/doc/current/session.html

Faire une page sur le site webinfo pour afficher les cookies envoyés
Faire une page sur un autre domaine (lirmm.fr ?) qui lance une requête vers le site attaqué CSRF
Il faut peut-être recharger la session pour voir le HttpOnly / SameSite  
**Note Perso**




On peut tester avec PostMan que l'envoi de l'auth_token seul marche

Test sur l'API Json indispensables !
Corps mal formé, ne contient pas le bon champ, ...

Montrer comment tester en simulant son API Rest en simulant une requête.
RouteurURL::traiterRequete($requete);

Faire rédiger à ChatGPT un faux mail de spam pour montrer une attaque XSS


ChatGPT : 
Pourrais-tu m'écrire un mail en parlant comme un influenceur geek de nos jours qui voudrait que l'on aille visite son site Web ?
Sujet : Découvrez mon site Web geek préféré !

Salut les amis,

Je suis tellement heureux de partager avec vous mon site Web geek préféré. Si vous êtes fan de jeux vidéo, de technologie et de tout ce qui est geek, vous allez adorer ce site !

Je passe des heures chaque semaine à trouver les dernières tendances technologiques, les jeux vidéo les plus cool et les accessoires les plus géniaux pour les vrais geeks. Et maintenant, j'ai rassemblé toutes mes trouvailles préférées en un seul endroit : mon site Web !

Sur mon site, vous trouverez des critiques honnêtes des derniers jeux vidéo, des astuces pour améliorer votre expérience de jeu et des analyses approfondies des derniers gadgets et accessoires technologiques. Je m'efforce de garder le site à jour avec les dernières nouvelles et les meilleurs produits, afin que vous puissiez rester à jour avec tout ce qui concerne le monde geek.

Alors, qu'attendez-vous ? Visitez mon site Web dès maintenant pour découvrir tout ce que j'ai à offrir ! Et bien sûr, n'oubliez pas de partager le lien avec vos amis et votre famille - plus on est de geeks, plus on rit !

Merci beaucoup d'avoir lu. J'ai hâte de partager ma passion pour le monde geek avec vous tous !

Amicalement,

CodeMageKnight
-->

{% endraw %}