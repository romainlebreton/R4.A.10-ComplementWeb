---
title: TD5 &ndash; Développer une API REST
subtitle: Nommage des URI, verbes HTTP, authentification par JWT
layout: tutorial
lang: fr
---

## API REST

Les API permettent la communication entre différents composants de votre
application et entre votre application et d’autres développeurs, par
l’utilisation de requêtes et de réponses. Elles donnent un moyen d’accès aux
données de façon réutilisable et standardisée.

Un standard d'API très présent sur le Web est *REST*. Les contraintes imposées
par *REST* sont un peu abstraites ; dans ce TD, nous nous intéresserons à ses
implications concrètes pour un service Web. La motivation est que tous les
services Web *RESTful*, *c.-à-d.* qui satisfont les contraintes *REST*, soient
interopérables. Ils doivent donc tous utiliser le même protocole de transfert
(*HTTP*) et les mêmes formats de données (*JSON* ou *XML*).

Les aspects fondamentaux d'un service Web *RESTful* sont : 
* adopter une convention de nommage pour les identifiants de ressources (URI) ;
* utiliser des verbes HTTP ;
* utiliser les codes de réponse *HTTP* pour indiquer si une requête a pu être
  traitée avec succès ;
* échanger des données au format *JSON* (ou *XML*) ;
* être sans état (*Stateless*), ou sans mémoire, c'est-à-dire que chaque
  requête / réponse ne se souvient pas des anciennes,
* le fonctionnement du service doit pouvoir être découvert, c'est-à-dire que
  l'on fournit des URL sur les actions liées à une ressource.


### Détails supplémentaires

Reprenons ces aspects plus en détail : 

#### Noms des ressources

Prenons un exemple de bonne URL : `/clients/33245/commandes/8769/categories/1`.

On voit que les ressources utilisent des noms, et pas des verbes, en minuscule.
Les ressources sont regroupées en collection et sont nommées au pluriel. On
utilise les sous-chemins pour indiquer l'appartenance à une sous-ressource. Par
exemple, l'URL précédente fait référence aux produits de la catégorie `1` qui appartiennent à la commande `8769` du client `33245`.

#### Verbes HTTP 

Pour indiquer une action sur une ressource, on utilise des verbes HTTP : 
  * `GET` : lire une ressource,
  * `POST` : créer une nouvelle ressource,
  * `PUT` : mettre à jour une ressource complètement en la remplaçant,
  * `PATCH` : mettre à jour une ressource partiellement en la modifiant 
  * `DELETE` : supprimer une ressource.

<!-- https://stackoverflow.com/questions/28459418/use-of-put-vs-patch-methods-in-rest-api-real-life-scenarios -->

#### Les codes de statut *HTTP*

Les codes de réponse *HTTP* servent à indiquer si une requête a pu être traitée
avec succès. Complétons les codes déjà vus : 
  * Codes de succès `2xx` : 
    * `200 OK` (attribut `HTTP_OK` de l'objet *PHP* `Response`)  
      Code de succès générique. Code le plus utilisé.
    * `201 CREATED` (attribut `HTTP_CREATED`)  
      Création d'entité réussie, généralement à la suite d'une requête `POST`.
      Il est courant de fournir un lien vers la ressource créée dans l'en-tête
      `Location :`. Le corps de réponse peut être vide.
    * `204 NO CONTENT` (attribut `HTTP_NO_CONTENT`)  
      Code de succès qui signale un corps de réponse vide, généralement à la suite d'une requête `DELETE` ou `PUT`.
  * Codes de redirection `3xx` déjà présentés dans 
    [le TD2]({{site.baseurl}}/tutorials/tutorial2#des-redirections-plus-propres) :
    * `301 MOVED PERMANENTLY` : redirection permanente 
    * `302 FOUND` : redirection temporaire   
  * Codes d'erreur côté client `4xx` déjà présentés dans 
    [le TD2]({{site.baseurl}}/tutorials/tutorial2#utilisation-des-codes-de-réponses-pour-les-erreurs) : 
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
route `web/api/publications/{idPublication}` associée au verbe *HTTP* `DELETE`
supprimera une publication. Notez que les routes liées à la future API sont
regroupées sous l'URL `web/api/`.

<div class="exercise">

1. Commençons par la méthode `supprimerPublication` dans `PublicationService` qui
   appellera la méthode existante `supprimer` dans l'instance de `PublicationRepository` injectée dans ce service. Comme la
   couche *Service* s'occupe de la validation, notre méthode
   `supprimerPublication` va s'assurer que toutes les données sont correctes. Sinon, elle lancera une `ServiceException` avec un message et un code d'erreur. Le code d'erreur reprendra les codes de statut *HTTP*.

   **Créez** la méthode
   `supprimerPublication()` et **ajoutez** les codes suivants
   lors des différents lancements d'exceptions : 
   * `Response::HTTP_FORBIDDEN` : l'utilisateur est connecté, mais n'a pas l'autorisation.
   * `Response::HTTP_NOT_FOUND` : la ressource est inconnue.
   * `Response::HTTP_UNAUTHORIZED` : l'utilisateur n'est pas connecté.
  
   ```php
   use Symfony\Component\HttpFoundation\Response;

   public function supprimerPublication(int $idPublication, ?string $idUtilisateurConnecte): void
   {
      $publication = $this->publicationRepository->recupererParClePrimaire($idPublication);

      if (is_null($idUtilisateurConnecte))
         throw new ServiceException("Il faut être connecté pour supprimer une publication", Response::XXX);

      if ($publication === null)
         throw new ServiceException("Publication inconnue.", Response::XXX);

      if ($publication->getAuteur()->getIdUtilisateur() !== intval($idUtilisateurConnecte))
         throw new ServiceException("Seul l'auteur de la publication peut la supprimer", Response::XXX);

      $this->publicationRepository->supprimer($publication);
   }
   ```

   Mettez également à jour **l'interface** `PublicationServiceInterface` afin d'y inclure la signature de cette nouvelle méthode.

2. Créez un nouveau contrôleur `ControleurPublicationAPI` et une nouvelle
   action `supprimer($idPublication)` avec le code suivant. Indiquez le bon code
   de réponse en cas de succès.

   ```php
   namespace TheFeed\Controleur;

   use Symfony\Component\DependencyInjection\ContainerInterface;
   use TheFeed\Lib\ConnexionUtilisateur;
   use TheFeed\Service\PublicationServiceInterface;
   use TheFeed\Service\Exception\ServiceException;
   use Symfony\Component\HttpFoundation\JsonResponse;
   use Symfony\Component\HttpFoundation\Response;

   class ControleurPublicationAPI extends ControleurGenerique
   {

      public function __construct (
         ContainerInterface $container,
         private readonly PublicationServiceInterface $publicationService
      ) 
      {
         parent::__construct($container);
      }

      public function supprimer($idPublication): Response
      {
         try {
               $idUtilisateurConnecte = ConnexionUtilisateur::getIdUtilisateurConnecte();
               $this->publicationService->supprimerPublication($idPublication, $idUtilisateurConnecte);
               return new JsonResponse('', Response::XXX);
         } catch (ServiceException $exception) {
               return new JsonResponse(["error" => $exception->getMessage()], $exception->getCode());
         }
      }
   }
   ```

3. Pour pouvoir faire référence à la nouvelle action `supprimer()` dans les
   routes, il faut d'abord enregistrer `ControleurPublicationAPI` dans le
   conteneur de services  (`Configuration/conteneur.yml`).  
   **Enregistrez** un service `controleur_publication_api` lié à la classe
   `ControleurPublicationAPI`. Ce service injectera les services
   `container` et `publication_service` au contrôleur.

   *Aide :* Inspirez-vous de la déclaration du service
   `controleur_publication`.

4. Affectez la route `/api/publications/{idPublication}` de méthode *HTTP*
   `DELETE` à votre action, au niveau de sa déclaration dans le contrôleur.
   N'oubliez pas de nommer cette route.

</div>

### Découverte de *Postman*

Pour tester ce bout d'API, il faut envoyer une requête de méthode `DELETE`. Pour cela, nous allons utiliser un petit logiciel très pratique quand on développe des `API` : **Postman**.  
Ce logiciel va permettre de paramétrer et d'envoyer des requêtes de manière
interactive et de visualiser le résultat très simplement.

Le logiciel est installé sur les machines de l'IUT. Chez vous, vous pouvez le
[télécharger](https://www.postman.com/downloads/?utm_source=postman-home).

<div class="exercise">

1. Lancez **Postman**. L'application vous propose de créer un compte, mais vous n'en avez pas besoin. Cliquez simplement sur "**Skip signing in and take me straight to the app**" tout en bas.

2. Sur l'interface, créez un nouvel onglet et paramétrez-le ainsi :

    ![Postman config 1](/R4.A.10-ComplementWeb/assets/TD5/postman1.PNG){: .blockcenter}

    * Méthode `DELETE`
    * Adresse : [https://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD5/web/api/publications/3](https://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD5/web/api/publications/3)

3. Cliquez sur "**Send**" et observez la réponse. Vous devriez obtenir le message d'erreur "Il faut être connecté pour supprimer une publication" car vous n'êtes en effet pas connecté !

4. Comme notre route n’est accessible qu’aux utilisateurs authentifiés. On
   va donc fournir à *Postman* un identificateur de session. Connectez-vous sur
   votre application (depuis votre navigateur) puis exécutez le code JavaScript 
   suivant dans la console du navigateur
   (`F12` → `Console`) :
   ```js
   document.cookie
   ```
   Copiez la valeur associée à la clé `PHPSESSID=`. Conservez bien ce résultat.

5. Sur *Postman*, cliquez sur le bouton **Cookies** à proximité du bouton **SEND**.
   Dans la fenêtre qui s'ouvre, cliquez sur le cookie `PHPSESSID`.
   Remplacez ensuite la valeur associé à la clé `PHPSESSID` par la valeur copiée à l'étape précédente.

   ![Postman config 2](/R4.A.10-ComplementWeb/assets/TD5/postman2.PNG){: .blockcenter}

6. Envoyez la requête de nouveau (vérifiez d'être bien connecté sur le site avant).
   Si vous rechargez votre site Web, la publication correspondante doit avoir disparue.

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
<article
  id="voitureelectrique"
  data-columns="3"
  data-index-number="12314"
>
```
on peut les récupérer en *JavaScript* avec 
```js
let article = document.getElementById('voitureelectrique');
article.dataset.columns // "3"
article.dataset.indexNumber // "12314"
```
Attention, les tirets dans l'attribut *HTML* `data-index-number` sont convertis
en attribut JS `indexNumber` avec un nommage *camelCase*.

{% raw %}

<div class="exercise">

1. Rajouter dans `feed.html.twig` un bouton juste après le paragraphe contenant
   le message lors de l'affichage des publications. 
   Remplacez les commentaires *Twig* par le code adéquat.

   ```twig
   {# si l'utilisateur connecte est l'auteur de la publication #}
   <button class="delete-feedy" data-id-publication="{# identifiant publication  #}">
       Supprimer
   </button>
   {#  fin si #}
   ```

2. Créez un script `ressources/js/main.js` avec le contenu suivant. Remplacez
   `XXX` par le code de succès émis par votre API REST (*cf.* Exercice 1.2) : 

   ```js
   /**
    * @param {HTMLElement} button La balise <button> cliquée
    */
   function supprimerPublication(button) {
      // TODO : récupérer l'identifiant de publication de la balise button
      let idPublication = ; 
      let URL = apiBase + "publications/" + idPublication;

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

   Ne vous souciez pas encore du warning sur `apiBase`, nous allons définir cette variable prochainement.

3. Ajouter un `addEventListener` sur les boutons `<button class="delete-feedy">`
   pour appeler la méthode précédente lors d'un clic (en lui fournissant le bouton 
   sur lequel est déclenché l'événement).

3. Changez `base.html.twig` pour faire appel au script `main.js` et rajouter quelques variables globales dans *JavaScript*.

   ```diff
      <link rel="stylesheet" type="text/css" href="{{ asset("../ressources/css/styles.css") }}">
   +    <script type="text/javascript" src="{{ asset("../ressources/js/main.js") }}" defer></script>
   </head>
   <body>
   +<script type="text/javascript">
   +    let siteBase = "{{ asset('.') }}";
   +    let apiBase = siteBase+"/api/"
   +    let pagePersoBase = siteBase+"/utilisateurs/";
   +    let imgBase = "{{  asset("../ressources/img") }}";
   +</script>
   <header>
   ```

4. Testez votre site. Un utilisateur connecté doit pouvoir effacer ses publications
   en cliquant sur le bouton *Supprimer*.

   *Aide :* Si cela ne marche pas, ouvrez l'onglet *Réseau* des outils de
   développement pour observer la requête émise par le clic et le bouton, et la
   réponse renvoyée par le serveur.

</div>

{% endraw %}

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
comportement par défaut de *PHP* est d'encoder uniquement les attributs
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
         "nomPhotoDeProfil" => $this->getNomPhotoDeProfil()
      ];
   }
   ```

2. Créez un nouveau contrôleur `ControleurUtilisateurAPI` étendant
   `ControleurGenerique`. Son constructeur devra donc aussi construire la partie "parent" `ControleurGenerique`, et donc injecter un objet `ContainerInterface` via le constructeur.

   Il faudra aussi injecter une instance de `UtilisateurServiceInterface`.

3. Dans votre nouveau contrôleur, ajoutez une nouvelle action
   ```php
   public function afficherDetail($idUtilisateur): Response
   ```
   qui récupère l'utilisateur d'identifiant `$idUtilisateur` et renvoie l'utilisateur au
   format *JSON*. Inspirez-vous de `supprimer` de `ControleurPublicationAPI`. 
   Vous utiliserez le constructeur `new JsonResponse($object)` qui permet de créer une 
   réponse qui contient l'encodage *JSON* de `$object`.

   *Note* : il n'y a pas besoin d'appeler explicitement `json_encode`! Comme notre 
   objet `Utilisateur` est du type `JsonSerializable`, l'appel à `new JsonResponse($object)` effectue
   implicitement un appel à cette méthode.

4. Enregistrez votre nouveau contrôleur dans le **conteneur de service** (`Configuration/conteneur.yml`).

5. Configurez une route `GET` sur l'URL `/api/utilisateurs/{idUtilisateur}` au niveau de la déclaration de cette action.
   Testez votre route directement dans le navigateur avec un identifiant d'utilisateur existant.
   N'oubliez pas de nommer votre route. 
   
6. Dans la méthode `recupererUtilisateurParId` de `UtilisateurService`, rajoutez le code
   d'erreur *HTTP* adéquat si l'utilisateur est inconnu. Testez la route avec un
   identifiant inconnu (utilisez l'onglet Réseau ou *Postman* pour voir le code
   de réponse).

   <!-- Response::HTTP_NOT_FOUND -->
</div>

<div class="exercise">

1. Dans `PublicationService`, ajoutez la méthode suivante :

   ```php
   /**
    * @throws ServiceException
    */
   public function recupererPublicationParId($idPublication, $autoriserNull = true) : ?Publication {
      $publication = $this->publicationRepository->recupererParClePrimaire($idPublication);
      if(!$autoriserNull && $publication == null) {
         throw new ServiceException("La publication n'existe pas.", Response::HTTP_NOT_FOUND);
      }
      return $publication;
   }
   ```

   Mettez aussi à jour l'interface de ce service en conséquence.

1. Faites en sorte que la route `GET` d'URL
   `/api/publications/{idPublication}` appelle sur une action
   `afficherDetail($idPublication)` dans `ControleurPublicationAPI` et qui renvoie une
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

   N'oubliez pas de nommer votre nouvelle route. 

   **Rappel :** Vous avez déjà formaté des dates dans la vue Twig
   `feed.html.twig`. En PHP, vous pourrez faire en même avec
   ```php
   $dateTime->format('d F Y');
   ```

2. Testez la route avec un identifiant de publication connu et un inconnu.
</div>

L'exercice précédent a montré un autre avantage de la couche service. Le code de
`PublicationService::recupererPublicationParId` est utilisé à la fois par
`ControleurPublicationAPI` et par `ControleurPublication`. Seule l'interface
change entre l'API et la page Web classique, tandis que le code *métier* reste
le même.

<div class="exercise">

1. Définissez une route `GET` d'URL `/api/publications` qui appelle
   une action `afficherListe` (définie dans `ControleurPublicationAPI`) 
   et renvoie la liste des publications au format JSON. N'oubliez pas de nommer votre route. 
   
2. Testez.

</div>

### Corps de la requête en *JSON*

Nous allons maintenant créer une route pour poster une publication. Comme le message
d'une publication ne peut pas raisonnablement être inclus dans l'URL, nous allons
l'envoyer dans le corps de la requête. Et quel format de données allons-nous
utiliser : *JSON* bien sûr !

<div class="exercise">

1. Changer votre fonction `creerPublication()` dans `PublicationService` pour le code
   suivant, qui gère le cas `$idUtilisateur==null` et récupère l'identifiant de publication depuis le *repository* : 

   ```php
   public function creerPublication($idUtilisateur, $message): Publication
   {
      if ($idUtilisateur == null) throw new ServiceException("Il faut être connecté pour publier un feed", Response::HTTP_UNAUTHORIZED);
      if ($message == null || $message == "") throw new ServiceException("Le message ne peut pas être vide!", Response::HTTP_BAD_REQUEST);
      if (strlen($message) > 250) throw new ServiceException("Le message ne peut pas dépasser 250 caractères!", Response::HTTP_BAD_REQUEST);

      $auteur = new Utilisateur();
      $auteur->setIdUtilisateur($idUtilisateur);
      $publication = Publication::create($message, $auteur);
      $idPublication = $this->publicationRepository->ajouter($publication);
      $publication->setIdPublication($idPublication);
      return $publication;
   }
   ```

   Attention : on a changé le type de retour de la méthode. Il faut donc mettre à jour l'interface.

2. Créez la méthode `posterPublication` dans `ControleurPublicationAPI` avec le code
   suivant, que nous allons compléter par la suite.

   ```php
   use Symfony\Component\HttpFoundation\Request;

   public function posterPublication(Request $request): Response
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
   * une chaîne de caractères au format *JSON* (celle obtenue à l'étape d'avant) se décode avec `json_decode($string)`,
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

5. Affectez à votre action une nouvelle route `/api/publications` de méthode `POST` (et du nom que vous souhaitez).

</div>

Nous allons maintenant tester notre route avec *Postman*.

<div class="exercise">

1. Créez une nouvelle requête *Postman* (bouton `+`) pointant vers la route 
`/api/publications` de votre application avec une méthode `POST`. 
Indiquer le corps de requête suivant dans `Body` → `raw` : 
   ```json
   {
      "message": "test API!"
   }
   ```

2. Envoyez la requête.
   Le serveur vous renvoie la représentation `JSON` de votre nouvelle publication ! 
   Vérifiez aussi sur le site que la publication est apparue.

   Si vous avez une erreur, vérifiez que votre **cookie** de session est toujours 
   bien configuré sur *Postman* et que vous êtes bien toujours connecté sur le site.

3. Testez aussi les cas d'erreur où le corps de requête est mal formé, ou
   le message est vide.

</div>

### Bouton JavaScript pour publier

<div class="exercise">

1. Nous vous fournissons une fonction JavaScript qui renvoie le code *HTML* d'une
   publication dont les données sont données en argument. **Copiez** ce code dans `main.js`.

   ```js
   function templatePublication(publication, utilisateur) {
      return `<div class="feedy">
      <div class="feedy-header">
         <a href="${pagePersoBase + publication.auteur.idUtilisateur}">
               <img alt="profile picture" src="${imgBase}/utilisateurs/${utilisateur.nomPhotoDeProfil}" class="avatar">
         </a>
         <div class="feedy-info">
               <span>${utilisateur.login}</span><span> - </span><span>${publication.date}</span>
               <p>${publication.message}</p>
               <button class="delete-feedy" data-id-publication="${publication.idPublication}" onclick="supprimerPublication(this)">Supprimer</button>
         </div>
      </div>
   </div>`;
   }
   ```

2. Nous vous fournissons également la méthode de base pour soumettre une publication.
   **Copiez** ce code dans `main.js` et remplacez `XXX` par le code de succès
   émis par votre API REST.

   ```js
   async function soumettrePublication() {
      const messageElement = document.getElementById('message')
      // On récupère le message 
      let message = messageElement.value;
      // On vide le formulaire
      messageElement.value = "";
      // On utilise la variable globale apiBase définie dans base.html.twig
      let URL = apiBase + "publications";

      let response = await fetch(URL, {
         // Ajouter la méthode 'POST'

         // Ajouter un corps de requête contenant le message

         // Ajouter des en-têtes pour indiquer 
         // * le format du corps de requête
         // * le format de données attendu en retour
      });
      if (response.status !== XXX)
         // (Hors TD) Il faudrait traiter l'erreur 
         return; 
      let publication = await response.json();
      // Utilisateur par défaut en attendant la suite
      let utilisateur = {nomPhotoDeProfil : "anonyme.jpg", login: "Inconnu"};
      let formElement = document.getElementById("feedy-new");
      formElement.insertAdjacentHTML('afterend', templatePublication(publication, utilisateur));
   }
   ```
3. Vous allez compléter le deuxième argument
   [`options` de la fonction `fetch()`](https://developer.mozilla.org/en-US/docs/Web/API/fetch#parameters) avec les instructions suivantes : 
   1. indiquez la méthode `POST` dans le champ `method` (voir `supprimerPublication`), 
   2. le corps de la requête correspondant au champ `body` dont la valeur est
      une chaîne de caractères. Vous devez utiliser `JSON.stringify()` pour convertir l'objet `JSON` (construit à partir du
      message récupéré par la méthode) en chaîne de caractères :
      ```js
      body: JSON.stringify({message: message}),
      ```
   3. les en-têtes s'indiquent dans le champ `headers` : 
      1. l'en-tête `Content-type` indique le format du corps de la requête,
      2. l'en-tête `Accept` indique le format souhaité pour le corps de la
         réponse. 
      3. Vous pouvez donc indiquer les en-têtes avec 
         ```js
         headers: {
               'Accept': 'application/json',
               'Content-type': 'application/json; charset=UTF-8',
         },
         ```

4. Rajoutez un `addEventListener` sur `<button id="feedy-new-submit">` pour
   appeler la fonction `soumettrePublication`.

5. Testez dans votre navigateur. La nouvelle publication doit s'afficher sans rechargement de la page.
   Pour le moment, le login et la photo de profil ne s'affichent pas, c'est normal.  
   On a ajouté un attribut `onclick` sur le `<button class="delete-feedy">` du template afin de faire en sorte qu'une nouvelle publication puisse être supprimée. C'est un patch nécessaire, car le `addEventListener` que vous avez codé n'a pu enregistrer la gestion de cet événement car la publication n'existait pas encore lors du chargement de la page !

   Plutôt que la méthode `templatePublication`, il serait préférable (dans une implémentation optimale) d'utiliser [la balise template](https://developer.mozilla.org/fr/docs/Web/HTML/Element/template). Avec cette méthode, on pourrait aussi attacher l'événement de clic sur le bouton de suppression plus proprement (pour les nouvelles publications ajoutées dynamiquement).

</div>

Vous pouvez sauter l'exercice suivant si vous estimez que vous manquez de temps
pour faire les TDs.

<div class="exercise">

1. Modifiez la fonction `soumettrePublication()` pour récupérer l'utilisateur dont
   l'identifiant est `publication.auteur.idUtilisateur` par une requête à l'URL
   `/api/utilisateurs/{idUtilisateur}`.

2. Testez que la soumission d'une nouvelle publication remplit bien le *login* et
   l'image de profil de l'utilisateur.

3. Publiez le message `<h1>Hack!</h1>` et observez le problème. Rechargez la
   page pour que la publication soit affichée par le serveur et observez la différence.

4. Nettoyer les entrées utilisateurs non fiables à l'aide de la méthode JavaScript : 
   * le texte de la page HTML et les attributs des balises HTML doivent être échappés avec
     ```js
     function escapeHtml(text) {
        // https://stackoverflow.com/questions/1787322/what-is-the-htmlspecialchars-equivalent-in-javascript
        return text
           .replace(/&/g, "&amp;")
           .replace(/</g, "&lt;")
           .replace(/>/g, "&gt;")
           .replace(/"/g, "&quot;")
           .replace(/'/g, "&#039;");
     }
     ```
   * Dans une URL, la partie dangereuse provenant de l'utilisateur doit être encodée avec [encodeURIComponent](https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent) comme vu lors du Cours 2 de JavaScript.

</div>

<!-- 
Idéalement try/catch (~= .catch()) 
pour traiter les erreurs (par. ex. utilisateur déconnecté entre temps)
-->


<!-- Renvoie le lien vers le Tweet créé  -->
<!-- avec Location ? Ne va pas faire une redirection ? Github -> champ "url" ! -->


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
sécurité réside seulement dans le fait qu'il ne peut pas être falsifié.

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

2. Créez la classe `src/Lib/JsonWebToken.php` avec le code suivant : 
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
   **Supprimez** `UtilisateurService::deconnecter()` (et mettez à jour son interface) 
   puis changez `ControleurUtilisateur::deconnecter()` avec le code suivant : 
   ```php
   public function deconnecter(): Response
   {
       if (!ConnexionUtilisateur::estConnecte()) {
           MessageFlash::ajouter("error", "Utilisateur non connecté.");
           return ControleurPublication::rediriger('afficherListe');
       }
       ConnexionUtilisateur::deconnecter();
       MessageFlash::ajouter("success", "L'utilisateur a bien été déconnecté.");
       return ControleurUtilisateur::rediriger('afficherListe');
   }
   ```

2. Concernant la méthode `UtilisateurService::connecter()`, nous allons
   seulement déplacer son appel à `ConnexionUtilisateur::connecter` ; à la fin de la méthode, changez

   ```diff
    if (!MotDePasse::verifier($motDePasse, $utilisateur->getPassword()))
       throw new ServiceException("Mot de passe incorrect.", Response::HTTP_BAD_REQUEST);

   - ConnexionUtilisateur::connecter($utilisateur->getIdUtilisateur());
   + return $utilisateur->getIdUtilisateur();
    }
   ```

   Changez donc aussi le type de retour de la méthode (pour `int`) et mettez aussi à jour l'interface.
   
   **Adaptez** `ControleurUtilisateur::connecter()` en conséquence. Vu que `UtilisateurService::connecter()` ne connecte plus, nous vous proposons de la **renommer** `UtilisateurService::verifierIdentifiantUtilisateur` (clic droit → *Refactor* → *Rename* ou `Maj+F6` sous *PhpStorm*).

</div>

Notre site va donc proposer deux mécanismes d'authentification : 
1. un mécanisme basé sur les sessions, qui ne sera utilisé que sur le site Web
   (`ControleurUtilisateur` et `ControleurPublication`),
2. un mécanisme basé sur les `JWT`. Ce mécanisme sera utilisé à la fois dans
   l'API REST (pour devenir *Stateless*), et dans le site classique pour que les
   fonctionnalités JavaScript puissent appeler l'API REST.

Qui dit deux codes pour le même problème, dit héritage et en particulier interface.

<div class="exercise">

1. Modifiez la classe `ConnexionUtilisateur` pour passer tous ses attributs et
   méthodes en dynamique (pas statique). Corrigez les appels *internes* à ces
   attributs et méthodes.  
   Renommez le fichier en `ConnexionUtilisateurSession.php`, ce qui aura pour
   effet de renommer la classe (sous *PhpStorm*, clic droit sur le fichier →
   *Refactor* → *Rename* ou `Maj+F6`).

2. Utiliser *PhpStorm* pour créer une interface `ConnexionUtilisateurInterface`
   à partir de la classe `ConnexionUtilisateurSession` (clic droit sur le nom de classe
   → *Refactor* → *Extract Interface*). Rajouter l'instruction qui indique que `ConnexionUtilisateurSession` implémente `ConnexionUtilisateurInterface`.

3. Créez une nouvelle classe `src/Lib/ConnexionUtilisateurJWT.php` avec le code suivant : 
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

4. Nous souhaitons injecter les deux services de connexion utilisateur dans les contrôleurs : 
   1. Enregistrez des services liés à `ConnexionUtilisateurSession` et
      `ConnexionUtilisateurJWT` dans le conteneur de services (via `conteneur.yml`).

   2. Rajouter un service `ConnexionUtilisateurInterface $connexionUtilisateur` à tous les contrôleurs (excepté le **générique**), sauf à `ControleurUtilisateur` qui possède deux tels services : 
      ```php
      public function __construct(
         private readonly PublicationServiceInterface $publicationService,
         private readonly UtilisateurServiceInterface $utilisateurService,
         private readonly ConnexionUtilisateurInterface $connexionUtilisateurSession,
         private readonly ConnexionUtilisateurInterface $connexionUtilisateurJWT,
      )
      {
         ...
      }
      ```
   3. Modifiez l'enregistrement des services liés aux contrôleurs pour y rajouter une référence : 
      * au service lié à `ConnexionUtilisateurSession` dans `ControleurPublication`,
      * aux services liés à `ConnexionUtilisateurSession` et `ConnexionUtilisateurJWT` dans `ControleurUtilisateur` (attention à l'ordre),
      * au service lié à `ConnexionUtilisateurJWT` dans `ControleurPublicationAPI` et `ControleurUtilisateurAPI`.
   4. Dans `ControleurUtilisateur` et `ControleurPublication`, remplacez les
      appels aux méthodes statiques `ConnexionUtilisateurSession` par des appels
      dynamiques au service.
   5. Dans `ControleurUtilisateurAPI` et `ControleurPublicationAPI`, remplacez les
      appels aux méthodes statiques `ConnexionUtilisateurSession` par des appels
      dynamiques au service (qui sera `ConnexionUtilisateurJWT`).

5. Changez le code de `ControleurUtilisateur::connecter()` pour connecter
   l'utilisateur avec les deux mécanismes. Faites de même pour que `ControleurUtilisateur::deconnecter()` déconnecte l'utilisateur à la fois dans au niveau de la session, mais aussi au niveau du service gérant la connexion par `jwt`.

6. Il reste un dernier endroit où `ConnexionUtilisateurSession` appelle une
   méthode statique : dans l'ajout d'une variable globale
   `idUtilisateurConnecte` à *Twig*. Puisque nous ne voulons pas appeler
   systématiquement `ConnexionUtilisateurSession`, qui a pour effet de lancer la
   session, changez le code suivant dans `RouteurURL` : 

   ```diff
   - $twig->addGlobal('idUtilisateurConnecte', ConnexionUtilisateurSession::getIdUtilisateurConnecte());
   + $twig->addGlobal('connexionUtilisateur', new ConnexionUtilisateurSession());
   ```
   Et **changez** toutes les `idUtilisateurConnecte` en
   `connexionUtilisateur.idUtilisateurConnecte` dans `base.html.twig` et
   `feed.html.twig`.

7. Testez votre site Web. Vérifiez que la connexion utilisateur sur le site marche
   toujours. Vérifiez aussi que les fonctionnalités dynamiques *AJAX* marchent toujours.

</div>

<div class="exercise">

1. Pour qu'un utilisateur de l'API puisse s'authentifier sans passer par le site
   Web, créez une nouvelle route `/api/auth` de méthode `POST` et nommée `api_auth` affectée à une nouvelle action dans `ControleurUtilisateurAPI` (à compléter) : 
   ```php
   public function connecter(Request $request): Response
   {
       try {
           // TODO : Récupération du login et mot de passe (password)
           // depuis le corps de requête au format JSON
           $jsonObject = json_decode($request->getContent(), flags: JSON_THROW_ON_ERROR);
           //$login = ...
           //$password = ...
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

2. Modifiez la méthode `verifierIdentifiantUtilisateur` de `UtilisateurService` afin de rajouter les codes d'erreurs HTTP adéquats lors de la levée de `SerrviceException`.

3. Testez l'authentification en appelant dans *Postman* la route précédente avec
   le corps de requête
   ```json
   {
      "login": "votre_login",
      "password" : "votre_mot_de_passe"
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
* Nous avons construit une sorte d'hybride entre site web et API. Cependant, une API s'implémente généralement de façon indépendante (comme nous le verrons l'année prochaine). Dans ce cas, lors de la connexion, l'API renvoie le JWT qu'il faudra envoyer à chaque requête dans un en-tête particulier (`Authorization`) tant qu'il n'a pas expiré. Il existe aussi un mécanisme de rafraichissement des `JWT` dont nous parlerons aussi l'an prochain lors de l'utilisation du framework `Symfony` et de l'outil `API Platform`.

Sources du TD :
[OpenClassrooms](https://openclassrooms.com/fr/courses/6573181-adoptez-les-api-rest-pour-vos-projets-web/), [Wikipédia](https://fr.wikipedia.org/wiki/Representational_state_transfer), [RestAPITutorial.com](https://www.restapitutorial.com/lessons/restquicktips.html) et [ChatGPT](https://chat.openai.com/chat)

## Pour finir (bonus)

Il y a quelques petites choses que nous pouvons encore améliorer :

* Migrer les différentes classes restantes dans `Lib` vers le **conteneur**, en tant que **services**.

* Refactoriser pour introduire un `ControleurGeneriqueSession` et un `ControleurGeneriqueAPI`...

Si le temps vous le permet, vous pouvez donc essayer d'encore plus optimiser l'application avec ces pistes !