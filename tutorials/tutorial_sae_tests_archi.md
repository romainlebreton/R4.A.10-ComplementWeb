---
title: Seance *SAÉ* &ndash; Tests unitaires, Architecture, Injection de dépendances
subtitle: PHPUnit, Services, Conteneur, Mocks
layout: tutorial
lang: fr
---

## Introduction

L'objectif de cette séance *SAÉ* est de vous former à la mise en place de tests unitaires sur une application web PHP.

Nous allons voir que pour qu'une application soit testable efficacement il faut qu celle-ci présente une architecture réfléchie permettant de véritablement tester une partie du code (une classe) de manière indépendante. Pour cela,
il faudra appliquer les différents principes **SOLID** que vous avez étudié cette année, notamment dans le cours de **qualité de développement**.

Pur illustrer tout cela, nous allons donc repartir du code de l'application **The Feed** obtenu à l'issu du 
[TD2 de complément web]({{site.baseurl}}/tutorials/tutorial2). Vous devez donc avoir terminé ce TD avant de commencer celui-ci.

Le TD devra être obligatoirement réalisé sur **PHPStorm** afin de profiter des différentes fonctionnalités de couplage avec PHPUnit qu'offre cet IDE.

**Note importante** : Lors du TD, vous utiliserez diverses dépendances dans vos classes. Parfois, il vous sera explicitement cité la ligne d'import de cette dépendance (avec un `use`). Si ce n'est pas le cas, il faudra importer vous-même la bonne classe. Dans ce cas, `PHPStorm` peut vous aider ! La classe dont l'import est manquant apparaitra en surbrillance avec un fond jaune. Vous pouvez alors passer votre curseur sur le nom de la classe et cliquer sur `Import class`.

## Découverte de PHPUnit

**PHPUnit** est une librairie PHP permettant de réaliser des tests unitaires sur une application PHP. Son fonctionnement est similaire à **JUnit** que vous utilisez notamment en cours de Tests.

PHPUnit intègre par défaut les outils nécessaires à l'utilisation de **mocks** ainsi que l'analyse de la **couverture de code**. Nous aurons l'occasion de revenir sur ces notions au cours du TD.

### Installation et configuration

Comme toute librairie PHP, **PHPUnit** s'installe à l'aide de **composer**. Nous allons utiliser une version légèrement antérieure pour pouvoir profiter facilement des options d'analyse de couverture de code.

<div class="exercise">

1. À la racine de votre projet, exécutez la commande suivante :

    ```bash
    composer require phpunit/phunit:9.0
    ```
   
2. Dans le dossier `src`, créez un dossier `Test`.

3. Sur votre IDE, cliquez sur `Run` puis `Edit Configurations`. Ajoutez une nouvelle configuration (bouton `+`) et sélectionnez `PHPUnit`.

4. Nommez la nouvelle configuration **Tests unitaires**. Au niveau de l'option `Test Scope` sélectionnez `Directory` puis indiquez le chemin du dossier `Test` créé précédemment. Concernant l'option `Prefred Coverage Engine` sélectionnez `PHPDBG` et enfin, au niveau de la case `Interpreter`, veillez à bien indiquer `PHP 8.1`. Appliquez et validez.

5. Exécutez le projet en choisissant la configuration `Tests unitaires` (bouton "play" en haut à droite). Vous devriez obtenir un message vous informant qu'aucun test n'a été exécuté (c'est normal, pour le moment !)

</div>

### Une première classe de test

Un `Test Unitaire` se traduit par une fonction dans une classe dédiée qui exécute différents tests sur des objets de l'application. Il s'agit de vérifier, par exemple, si le retour d'une fonction avec un paramétrage spécifique est bien conforme aux attentes et aux spécifications. On peut aussi tester si l'exécution d'un code déclenche des exceptions.

Les possibilités sont très riches. Pour créer une classe de test, il suffit d'étendre la classe `TestCase`. À partir de
là, le développeur a accès à une grande variété de méthodes internes pour réaliser des **assertions**. Une **assertion** est simplement une vérification qui est faite (sur un résultat, sur un comportement...). Si cette vérification échoue (résultat différent de ce qui est attendu) le test échoue alors.

Parmi les méthodes d'assertion, on peut citer :

* `assertEquals(resultatAttendu, resultat, message)` : permet de vérifier l'égalité entre un résultat attendu, et un résultat (obtenu après l'exécution d'une méthode, par exemple). Le troisième paramètre est un message (optionnel) qui permet de donner plus détail en cas d'échec du test (ce message sera affiché en sortie).

* `assertTrue(resultat, message)` : permet de vérifier qu'un résultat vaut **true**. Il existe également 
`assertFalse(resultat, message)`.

* `assertCount(tailleAttendue, structure, message)` : permet de vérifier la taille d'une structure de données
(typiquement, un tableau).

* `assertEmpty(structure, message)` : permet de vérifier qu'une structure de données est bien vide.

* `assertNull(resultat, message)` : permet de vérifier qu'un résultat est bien **null**. Il existe aussi
`assertNotNull(resultat, message)`.
 
Cette liste est bien sûr non exhaustive et vous pourrez explorer plus en détail toutes les assertions disponibles.

Une autre méthode bien pratique est aussi `expectException(exceptionClass)`. Cette méthode est à utiliser avant 
d'exécuter un bout de code et permet de vérifier que l'exception précisée à bien été levée. On peut aussi utiliser `expectExceptionMessage(message)` pour vérifier le message de l'exception levée.

Enfin, dans chaque classe de test, il est possible de redéfinir quatre méthodes bien utiles :

* `setUp` : cette méthode est exécutée avant chaque méthode de test. Elle permet, par exemple, de configurer
certaines variables afin de les rendre vierges avant d'exécuter chaque test.

* `tearDown` : cette méthode est exécutée après chaque méthode de test. Elle doit permettre de nettoyer les effets de bord occasionnés par chaque test (par exemple : nettoyer la base de données de tests).

Il existe également deux versions **statiques** de ces méthodes : `setUpBeforeClass` et `tearDownAfterClass` qui sont exécutées respectivement avant l'exécution du premier test et après l'exécution du dernier test (donc, une seule fois).

Prenons l'exemple de la classe suivante :

```php
namespace TheFeed\Test;

use Exception;

class Ensemble {

    private array $tableauEnsemble;
    
    public function __construct() {
        $this->tableauEnsemble = [];
    }
    
    public function contient($valeur) {
        return in_array($this->tableauEnsemble, $valeur);
    }

    public function ajouter($valeur) {
        if(!$this->contient($valeur)) {
            $this->tableauEnsemble[] = $valeur;
        }
    }
    
    public function getTaille() {
        return count($this->tableauEnsemble);
    }
    
    public function estVide() {
        return $this->getTaille() == 0;
    }
    
    public function pop() {
        if($this->estVide()) {
            throw new Exception("L'ensemble est vide!");
        }
        return array_pop($this->tableauEnsemble);
    }
}
```

On pourrait alors écrire la classe de test suivante :

```php
namespace TheFeed\Test;

use PHPUnit\Framework\TestCase;

class EnsembleTest extends TestCase {

    private $ensembleTeste;
    
    //On réinitialise l'ensemble avant chaque test
    protected function setUp(): void
    {
        parent::setUp();
        $this->ensembleTeste = new Ensemble();
    }
    
    public function testVideDepart() {
        $this->assertEquals(0, $this->ensembleTeste->getTaille());
    }
    
    public function testAjout() {
        $this->assertFalse($this->ensembleTeste->contient(7));
        $this->ensembleTeste->ajouter(7);
        $this->assertTrue($this->ensembleTeste->contient(7));
        $this->assertEquals(1, $this->ensembleTeste->getTaille());
        //On n'ajoute pas deux fois dans un ensemble, donc la taille doit rester à 1
        $this->ensembleTeste->ajouter(7);
        $this->assertEquals(1, $this->ensembleTeste->getTaille());
    }
    
    public function testPop() {
        $this->ensembleTeste->ajouter(1);
        $this->ensembleTeste->ajouter(2);
        $this->ensembleTeste->ajouter(3);
        $this->assertEquals(3, $this->ensembleTeste->pop());
        $this->assertEquals(2, $this->ensembleTeste->pop());
        $this->assertEquals(1, $this->ensembleTeste->pop());
        $this->expectException(Exception::class);
        $this->expectExceptionMessage("L'ensemble est vide!");
        $this->ensembleTeste->pop();
    }
}
```

<div class="exercise">

1. Dans le dossier `Test`, créez les classes `Ensemble` et `EnsembleTest` en copiant le code donné ci-dessus.

2. Lancez les tests unitaires et observez les résultats.

3. Glissez une erreur dans le code de la classe `Ensemble` et relancez les tests. Observez la sortie. Remettez tout en ordre (enlevez le bug).

</div>

**Attention** ! Le nom de toutes vos classes de tests doit se terminer par `Test` ! (Sinon la classe ne sera pas prise en compte lors de l'exécution de tests). Aussi, chaque nom de méthode de test doit débuter par `test`.

Afin de prendre en main l'outil, vous allez créer une classe simple puis une classe de test permettant de la tester.

<div class="exercise">

1. Créez une classe `Calculatrice` dans le dossier `Test`. Cette classe doit gérer un attribut `$resultat` initialisé à 0 (qui représente le résultat courant). Les différentes méthodes de cette classe devront permettre de modifier ce résultat.

2. Ajoutez les méthodes suivantes :

   * `additionner($nombre)` : ajoute le nombre passé en paramètre au résultat.
   * `multipler($nombre)` : multiplie le résultat par le nombre passé en paramètre.
   * `soustraire($nombre)` : soustrait le nombre passé en paramètre au résultat.
   * `diviser($nombre)` : divise le résultat par le nombre passé en paramètre. Si le nombre passé en paramètre vaut 0, il faut lever une `Exception`.
   * `reset()` : remet le résultat à 0.
   * `getResultat()` : un getter pour le résultat.

3. Créez une classe `CalculatriceTest` dans le dossier `Test`. Cette classe a pour but de tester votre classe 
`Calculatrice`. À vous d'écrire les tests qui vous semblent adéquat. Il faut penser à tester les enchainements d'appels de méthodes.

1. Lancez les tests unitaires. 
</div>

Veillez à bien comprendre cette étape. L'exemple choisi est volontairement simpliste pour vous permettre de vous
focaliser sur l'écriture de tests. Si vous avez des difficultés, n'hésitez pas à demander des précisions à votre enseignant. 

## La couche Service

Nous avons réalisé des premiers tests simples afin de comprendre le fonctionnement de **PHPUnit**. Maintenant, nous allons mettre en œuvre cet outil de manière plus concrète en testant notre application web. Néanmoins, vous allez constater un problème majeur : l'application n'est pas testable en l'état.

En effet, pour tester, nous avons besoin de faire des **assertions** sur des résultats (ou des comportements) spécifiques obtenus lors de l'exécution d'une fonctionnalité. Actuellement, les fonctionnalités sont réalisées par les **contrôleurs**.
Or, les différentes fonctions des contrôleurs renvoient un objet `Response` qui n'est pas bien exploitable. Cet objet contient le code complet de la page `HTML` renvoyée au client, ce qui n'est donc pas (ou difficilement) testable en l'état. Ce problème est lié au fait que les **contrôleurs** ont beaucoup trop de responsabilités et ne répartissent pas le travail. De l'extérieur, ils agissent comme une boîte noire et il est alors difficile de récupérer des données intéressantes pour les tests. Il semble aussi difficile de fournir des données aux contrôleurs car ceux-ci se servent directement des données de la requête HTTP.

Une **application web** comme tout **logiciel** peut être organisé selon une architecture qui sépare de manière optimisée les classes et programmes selon leur **rôle**.

Dans un logiciel, on retrouve généralement **5 couches principales** :

* La couche **IHM** qui permet de gérer les différentes parties graphiques et surtout l'interaction avec l'utilisateur. Pour une application web cela va correspondre à la partie contenant les **vues**, c'est-à-dire les fichiers responsables de générer le code HTML (et également les ressources JavaScript, CSS, etc.)

* La couche **métier** qui contient le cœur de l'application, à savoir les différentes **entités** manipulées (essentiellement, les classes dans `DataObject`) ainsi que des classes de **services** qui permettent de manipuler ces entités et d'implémenter la **partie logique** de votre application.

* La couche **application** qui permet de faire le lien entre la couche **ihm** et la couche **métier**. Elle contient les différents **contrôleurs** dont le rôle est de gérer les **évènements** qui surviennent sur l'interface et d'envoyer des **requêtes** auprès de la couche **métier** et de transmettre les résultats obtenus à **l'ihm**. Dans une application web, les événements sont les requêtes reçues par l'application web (et ses paramètres, via l'URL). Une requête est décomposée puis la bonne méthode du contrôleur est exécutée avec les paramètres correspondants.

* La couche **stockage** qui permet de gérer la **persistance des données** à travers une forme de stockage configurée (base de données, fichier...). Son rôle va donc être de sauvegarder et charger les données des différentes entités de la couche **métier**. C'est cette couche qui va contenir les différents **repositories**. Cette couche est généralement utilisée par les différents classes de **services**. Globalement, les interactions se déroulent dans ce sens : IHM <-> Application <-> Services <-> Stockage.

* Éventuellement, la couche **réseau** dans le cadre d'une application **client/serveur**. Cette couche va gérer la transmission des données entre deux programmes (avec des sockets, etc.). Dans une application web, il n'y a pas besoin de gérer explicitement cette couche qui est prise en charge par le protocole **HTTP** ou **HTTPS**.

Comme vous le savez, l'architecture actuelle de l'application est une architecture `MVC`. Cette architecture permet de séparer les entités, les vues et les contrôleurs de l'application et de les faire communiquer.

Néanmoins, il n'est pas explicitement fait mention des **services** dans cette architecture. En fait, dans une architecture `MVC` classique, le **contrôleur** a le rôle des services et effectue une partie de la logique métier. Néanmoins, cela peut vite créer des contrôleurs ayant beaucoup trop de responsabilités en plus du décodage des paramètres de la requête. C'est pourquoi il est possible de venir placer la couche **service** entre les **contrôleurs**, les **entités** et la couche **stockage**. Ainsi, le contrôleur n'effectue pas de logique métier et on a une séparation plus forte.

Ici, la couche **métier** créée donc une séparation entre la partie "model" (**entités**) et les **services** qui manipulent ces entités. Ainsi, les différents **contrôleurs** n'interagissent pas directement avec les entités, mais plutôt avec des **services**. On pourrait qualifier les services de **couche de validation**.

Dans ce cas, on sort un peu de l'architecture classique `MVC` et on pourrait presque parler de `MVCS` où le `S` désignerait les **services**. Il n'y a pas de règles précise quant à l'utilisation de telle ou telle architecture, mais dans le cas de notre application, nous allons plutôt tendre vers une architecture utilisant les services. Créer une telle séparation permettra alors de pouvoir tester la logique métier indépendamment au travers des tests unitaires sur les **services** plutôt que sur les **contrôleurs**. D'une part, il sera alors possible de passer des données à ces services autrement que par une requête HTTP, et d'autre part, on pourra également obtenir un résultat exploitable et pas une page web complète.

### Un service pour gérer les publications

Nous allons commencer à extraire la logique métier de notre application en créant un **service** pour gérer les différentes **publications**. Au-delà d'alléger le contrôleur des publications du code métier, nous allons aussi pouvoir considérablement réduire la partie dédiée à la gestion des erreurs !

<div class="exercise">

1. Créez un dossier `Service` dans `src`.

2. Dans ce nouveau dossier, créez une classe `PublicationService`.

3. Créez une méthode `recuperPublications` qui permet de récupérer toutes les publications depuis le repository correspondant **et de les renvoyer**. Vous pouvez directement copier le code correspondant depuis la méthode `feed` de `ControleurPublication`.

4. Modifiez le code de la méthode `feed` de `ControleurPublication` pour utiliser votre nouveau **service** au lieu de faire appel au repository.

5. Vérifiez que votre site fonctionne toujours bien.

</div>

Bien, vous avez créé votre premier service ! Mais l'intérêt d'avoir séparé ce petit bout de code n'apparait pas encore clairement. Nous allons donc pousser les choses un peu plus loin lors de la prochaine étape.

Nous allons nous intéresser à la création des publications. Actuellement, dès qu'il détecte une erreur dans la formation du message, le **contrôleur** ajoute un message flash d'erreur et redirige l'utilisateur. Ces vérifications font parti de la logique **métier** et peuvent être gérées à l'aide d'exceptions. La logique à appliquer serait plutôt la suivante :

* Le contrôleur récupère les valeurs des paramètres depuis la requête et les passe au service.
* Le service a pour but de réaliser une action (et éventuellement d'envoyer un résultat). S'il y a un problème (notamment par rapport aux paramètres), il lève une exception.
* Le contrôleur attrape les éventuelles exceptions et redirige l'utilisateur en conséquence.

<div class="exercise">

1. Dans le dossier `Service`, créez un sous-dossier `Exception` puis à l'intérieur de ce nouveau répertoire, une classe `ServiceException` :

```php
<?php

namespace TheFeed\Service\Exception;

use Exception;

class ServiceException extends Exception
{

}
```

2. Dans `PublicationService`, créez une méthode `creerPublication` qui prend en paramètre un **idUtilisateur** et un **message**. La méthode doit déplacer en grande partie le code de la méthode `submitFeedy` de `ControleurPublication` :

    ```php
    public function creerPublication($idUtilisateur, $message) {
        $utilisateur = (new UtilisateurRepository())->get($idUtilisateurConnecte);

        if ($utilisateur == null) {
            MessageFlash::ajouter("error", "Il faut être connecté pour publier un feed");
            return ControleurPublication::rediriger('connecter');
        }
                
        if ($message == null || $message == "") {
            MessageFlash::ajouter("error", "Le message ne peut pas être vide!");
            return ControleurPublication::rediriger('feed');
        }
        if (strlen($message) > 250) {
            MessageFlash::ajouter("error", "Le message ne peut pas dépasser 250 caractères!");
            return ControleurPublication::rediriger('feed');
        }

        $publication = Publication::create($message, $utilisateur);
        (new PublicationRepository())->create($publication);
    }
    ```

3. Dans la nouvelle méthode `creerPublication`, remplacez toutes les lignes qui ajoutent un message flash et redirigent l'utilisateur par le déclenchement d'une **ServiceException** contenant le message flash initialement prévu comme message flash. La syntaxe est la suivante :

```php
throw new ServiceException("Mon message d'erreur!");
```

4. Modifiez la méthode `submitFeedy` de `ControleurPublication` afin d'utiliser le service de publications et de gérer l'exception. Dans le cas où une **ServiceException** est interceptée, vous devez ajouter le message de l'exception comme message flash puis rediriger l'utilisateur vers la route `feed`. Globalement, cela doit ressembler à quelque chose comme ça :

    ```php
    public static function submitFeedy() : Response
    {
        $idUtilisateurConnecte = ConnexionUtilisateur::getIdUtilisateurConnecte();
        $message = $_POST['message'];
        try {
            //Utilisation du service
        }
        catch(ServiceException $e) {
            //Ajout du message flash
        }

        return ControleurPublication::rediriger('feed');
    }

    ```
5. Comme d'habitude, vérifiez votre application pour vous assurer que rien n'a été cassé.
</div>

Ici, la séparation entre la couche **service** et **application** est bien visible ! Le contrôleur récupère les éléments nécessaires depuis la requête et le service, lui n'interagit pas directement avec les données de la requête (pas d'accès à `$_POST`) et ne s'intéresse pas aux notions liées à la couche **ihm** (pas de redirection, pas de sélection de vue, pas de messages flash...). Il agit comme un module quasi indépendant des autres couches.

### Un service pour gérer les utilisateurs

Nous allons continuer dans notre lancée et extraire la partie **métier** du contrôleur gérant les fonctionnalités liées aux utilisateurs.

Pour les fonctions qui permettent d'afficher la page de connexion ou d'inscription, il n'y a pas besoin de créer une fonctionnalité sur un service car il s'agit juste d'un affichage de page simple.

Débutons avec la création d'un nouvel utilisateur. 

<div class="exercise">

1. Créez une classe `UtilisateurService` dans le dossier `Service`.

2. Ajoutez une méthode `creerUtilisateur` qui prend en paramètre un `login`, un `mot de passe`, une `adresse mail` et enfin un tableau de `données de l'image de profil`. Cette méthode reprendra en grande partie le code de `creerDepuisFormulaire` du contrôleur `ControleurUtilisateur`.

Comme d'habitude, il ne faudra pas faire appels aux variables de liées à la requête dans cette méthode (`$_POST`, `$_FILES`, etc.). Ces données vous sont fournies par le contrôleur et peuvent être nulles. Il faudra d'ailleurs penser à vérifier si ces valeurs sont nulles ou non. La méthode ne doit rien retourner (simplement créer l'utilisateur) et lever des `ServiceException` si différentes contraintes sont violées (taille du login, mot de passe, format de l'adresse mail, etc.). Le paramètre `$profilePictureData` correspond au tableau obtenu par lecture de `$_FILES["..."]` 

```php
public function creerUtilisateur($login, $password, $adresseMail, $profilePictureData) {
    //TO-DO
    //Verifier que les attributs ne sont pas nuls
    //Verifier la taille du login
    //Verifier la validité du mot de passe
    //Verifier le format de l'adresse mail
    //Verifier que l'utilisateur n'existe pas déjà
    //Verifier que l'adresse mail n'est pas prise
    //Verifier extension photo de profil
    //Chiffrer le mot de passe
    //Enregistrer la photo de profil
    //Enregistrer l'utilisateur...
}
```

3. Adaptez la méthode `creerDepuisFormulaire` de `ControleurUtilisateur` pour utiliser votre nouveau service. Attention, il ne faut plus vérifier ici le fait qu'une donnée est nulle ou non (on doit pouvoir passer une donnée nulle au service). En remplacement, vous pouvez utiliser l'**expression** suivante :

```php
$donnee = $_POST["donnee"] ?? null; //Si $_POST["donnee"] n'existe pas, $donnee prend la valeur null.
```

Le nouveau code aura donc cette allure :

```php
public static function creerDepuisFormulaire(): Response {
    //Recupérer les différentes variables (login, mot de passe, adresse mail, données photo de profil...)
    try {
        //Enregistrer l'utilisateur via le service
    }
    catch(ServiceException $e) {
        //Ajouter message flash d'erreur
        //Rediriger sur le formulaire de création
    }
    //Ajouter un message flash de succès (L'utilisateur a bien été créé !)
    //Rediriger sur la page d'accueil (route feed)
}
```

4. Comme toujours, vérifiez l'état de votre application.

</div>

Maintenant, passons au cas de la fonctionnalité permettant d'afficher une page personnelle.

La méthode `pagePerso` effectue deux actions : récupération de l'utilisateur concerné d'une part (pour afficher son login) et, dautre part, récupération des publications de l'utilisateur. Il va donc y avoir deux actions à effectuer, dans deux services différents.

<div class="exercise">

1. Dans la classe `UtilisateurService`, créez une méthode `recuperUtilisateur` qui prend en paramètre un identifiant d'utilisateur **et un booléen** `autoriserNull`. Ce booléen a pour but de préciser si une exception doit être levée ou non si l'utilisateur sélectionné n'existe pas (dans certains cas, on veut simplement récupérer la valeur `null` sans lever d'exceptions). La méthode doit donc renvoyer, à l'issu, l'utilisateur ciblé par l'identifiant (en se servant du repository). Si `autoriserNull` vaut `false` et que l'utilisateur récupéré est `null`, il faut lever une `ServiceException` (l'utilisateur n'existe pas !).

```php
public function recuperetUtilisateur($idUtilisateur, $autoriserNull = true) {
    $utilisateur = ...
    if(!$allowNull && ...) {
        ...
    }
    return $utilisateur;
}
```

2. La partie qui a pour but de récupérer des publications doit plutôt être codée au niveau de la classe `PublicationService`. Ajoutez donc une méthode `recuperPublicationsUtilisateur($idUtilisateur)` à ce service en reprenant la partie du code de `pagePerso` qui récupère les publications.

3. Remplacez le code de `pagePerso` afin d'utiliser les deux méthodes (`recuperetUtilisateur` et `recuperPublicationsUtilisateur` de `UtilisateurService` et `PublicationService`). Il ne faudra pas autoriser le fait de récupérer un utilisateur `null`. Veillez à bien traiter une éventuelle `ServiceException`.

4. Vérifiez que tout fonctionne bien.

</div>

Si tout marche bien, vous commencez à maîtriser le processus ! Terminons donc le travail avec ce contrôleur avant de passer à la seconde phase de tests.

<div class="exercise">

1. En vous inspirant du travail réalisé lors des questions précédentes, adaptez la méthode `connecter` afin de faire migrer une partie de la logique du code dans une méthode adaptée dans la classe `UtilisateurService`.

2. Faites de même pour la méthode `déconnecter`.

3. Vérifiez le fonctionnement de l'application.

</div>

### Premiers tests sur l'application

Maintenant que la partie **métier** de notre application est (partiellement) extraite, nous allons pouvoir faire nos premiers tests.

<div class="exercise">

1. Créez une classe `PublicationServiceTest` dans le répertoire `Test`.

2. Ajoutez un attribut `service` qui sera ré-instancié par un `PublicationService` avant chaque test (via le `setUp`).

3. Créez un test `testCreerPublicationUtilisateurInexistant` qui teste de créer une publication en précisant un identifiant d'utilisateur qui n'est pas enregistré dans la base (par exemple, `-1`). Votre test doit vérifier qu'une `ServiceException` est bien levée et que le message d'erreur correspond bien à celui attendu.

4. Créez un test `testCreerPublicationVide` qui teste de créer une publication sans aucun contenu. Attention, ici, il faut préciser un identifiant d'utilisateur valide (qui est enregistré dans la base). Comme à la question précédente, votre test doit vérifier qu'une `ServiceException` est bien levée et que le message d'erreur correspond bien à celui attendu.

5. Créez un test `testCreerPublicationTropGrande` qui teste de créer une publication avec un contenu dépassant 250 caractères. Pour vous faciliter la tâche, vous pouvez utiliser la fonction `str_repeat(chaine, nb)` qui permet d'obtenir une chaîne de caractères correspondant à `nb` répétitions de la chaîne de caractères `chaine`. Mêmes vérifications à faire que précédemment.

6. Créez un test `testNombrePublications` qui teste la récupération toutes les publications (via le service) et vérifie le nombre de publications récupérées. Il faudra donc compter combien de publications il y a dans votre base au préalable.

7. Créez un test `testNombrePublicationsUtilisateur` qui teste la récupération de toutes les publications d'un utilisateur. Il faudra préciser un identifiant d'utilisateur existant et vérifier que le compte est bon.

8. Enfin, créez un test `testNombrePublicationsUtilisateurInexistant` qui teste la récupération de toutes les publications d'un utilisateur inexistant (par exemple, `-1`). Le compte des publications doit être de 0 dans ce cas.

9. Si ce n'est pas déjà fait, lancez les tests unitaires et vérifiez que tous les tests passent !

</div>

Relisez les tests que vous venez d'écrire. Ne remarquez-vous pas quelques éléments étranges et mêmes dérangeants ? Pensez sur le long terme. Nous reviendrons sur tout cela assez vite et nous n'écrirons pas de tests sur le service des utilisateurs pour le moment.

### Couverture de code et portée des tests

Il est temps pour vous de découvrir un outil fort utile pour pouvoir mesurer (en partie) la qualité de vos tests : la **couverture de code**. Cet outil permet de réaliser des statistiques sur les portions de code que vos tests permettent de tester. Après l'exécution des tests, on peut alors visualiser le pourcentage de code testé sur une classe et on peut même aller dans le détail en visualisant les lignes de code qui ont été franchies par les tests et celles qui n'ont jamais été franchies.

Il est difficile de savoir jusqu'où tester une application. Le but des tests n'est en réalité pas de vérifier que tout fonctionne mais plutôt de trouver des dysfonctionnements. Le nombre et la variété des tests à produire dépendent donc fortement du contexte. Néanmoins, une couverture de code de **100%** (donc, des tests qui passent au moins une fois par chaque ligne de code du programme) est un premier indicateur de la qualité des tests. Dans ce cas, on peut alors considérer qu'il y a un nombre assez important de tests et qu'ils sont assez variés. Néanmoins, cela ne signifie pas nécessairement qu'il faut s'arrêter de tester à partir de là. Il faut prévoir le plus de scénarios possibles (deux scénarios différents peuvent déclencher les mêmes lignes de code).

Il faut également se poser la question de **la portée** des tests. Doit-on (peut-on ?) tout tester ? Par exemple, est-il pertinent d'écrire des tests unitaires pour les contrôleurs dans leur état actuel vu que leur rôle se limite à la réalisation d'un pont entre la couche IHM (les vues, la requête HTTP) et la couche service. Cela relève plutôt de tests réalisés directement sur l'interface (ce que vous faisiez jusqu'ici). Il est possible de mettre en place des tests unitaires sur à peu près tous les éléments du programme, mais généralement, on va plutôt se concentrer sur la partie métier avec les **services** puis la partie **modele**. Obtenir une couverture proche de 100% sur ces parties constitue un premier critère de qualité.

<div class="exercise">

1. Lancez vos tests unitaires **avec couverture de code**. Pour cela, rendez-vous dans `Run` puis `Run ... with  Coverage`.

2. Un panneau d'analyse s'ouvre à droite. Explorez son contenu.

3. Parcourez les différents fichiers de l'application (notamment `PublicationService`) et observez les lignes de code. Au niveau des numéros de lignes, une section verte indique que la ligne a été parcourue (et bien sûr, une section rouge indique l'inverse).

</div>

Maintenant, prenez l'habitude de toujours lancer vos tests avec la couverture de code activée !

## Les problèmes de dépendances

Comme vous l'avez sûrement déjà remarqué, il y a de gros problèmes avec les tests que nous avons écrits pour tester le service publication. En vrac :

* Dans certains tests, nous devons préciser des utilisateurs réels. Ces tests dépendent donc de l'état actuel de l'application, des utilisateurs inscrits.

* On teste le nombre de publications total et le nombre de publications d'un utilisateur donné. Là aussi, ce nombre peut changer si une nouvelle publication est réalisée !

* Nous n'avons pas pu tester la création "normale" d'une publication. Deux causes à cela. Déjà, nous n'avons pas moyen de récupérer directement la publication créée (la méthode de création de publication ne retourne rien). Deuxièmement, ce test entrainait la création réelle d'une publication dans l'application ! À chaque exécution !

* La base de données doit obligatoirement être allumée pendant l'exécution de tests...

Tout cela est dû au fait que notre classe `PublicationService` est fortement dépendante d'autres classes et notamment d'une classe repository. Il en va de même pour `UtilisateurService`. En fait, nous ne pouvons pas (encore) qualifier nos tests de tests **unitaires** car les nombreuses dépendances entraînent un test plus global des différents modules attachés à cette classe de manière indésirable. De plus, nous agissons sur la base de données (de "production") ce qui n'est pas bon.

Un **test unitaire** doit seulement porter sur une portion de code très précise (typiquement une méthode) et ne doit pas concrètement déclencher l'exécution d'autres services dans l'environnement de l'application (pas d'effet de bord). De plus, le test ne doit pas dépendre de l'état concret de l'application à l'instant du test (typiquement, le test ne doit pas dépendre de l'état de la base de données !).

Pour régler ces problèmes, nous pouvons utiliser deux outils :

* L'application des principes **SOLID** notamment **l'inversion de contrôle** afin de réaliser de l'injection de dépendances pour faire en sorte que les dépendances des différentes classes soient interchangeables.

* L'utilisation de **mocks** afin de simuler et configurer à souhait les dépendances d'une classe lors des tests unitaires afin de construire un scénario précis. L'idée est de contrôler ce que les différentes dépendances d'une classe vont fournir comme réponse lorsqu'elles sont utilisées lors d'un test unitaire.

### Injection des dépendances et inversion de contrôle

Lorsqu'une classe est amenée à utiliser des instances d'autres classes lors de l'exécution de ses différentes méthodes on dit qu'il existe une dépendance entre ces deux classes (de la classe utilisatrice vers la classe utilisée). En **UML**, cette dépendance se traduit notamment par une flèche pointillée.

Dans un tel contexte, il peut alors être judicieux d'appliquer le concept **d'inversion de contrôle** en favorisant l'injection des dépendances de la classe plutôt que de laisser la classe instancier un objet de la classe cible ou bien utiliser un singleton.

Par exemple, imaginons les classes suivantes :

```php
class A {
    public function traitementA() {
        ...
    }
}

class B {

    private static $instance = null;

    private function __construct() {}

    public static function getInstance() {
        if(self::$instance == null) {
            self::$instance = new B();
        }
        return self::$instance;
    }

    public function traitementB() {
        ...
        return ...
    }
}

class C {

    public function traitementC() {
        $serviceA = new A();
        $serviceA.traitementA();
        $serviceB = B.getInstance();
        $result = $serviceB.traitementB();
        ...
    }

}
```

Dans cet exemple, la classe `C` est dépendante des classes `A` et `B`. Il devient alors difficile de réaliser des tests unitaires de la méthode `traitementC` car son exécution déclenchera et dépendra des classes concrètes `A` et `B`.

Plutôt que la méthode `traitementC` utilise directement ces dépendances, on pourrait adopter l'architecture suivante :

```php
class C {

    private A $serviceA;

    private B $serviceB;

    public function __construct(A $serviceA, B $serviceB) {
        $this->serviceA = $serviceA;
        $this->serviceB = $serviceB;
    }

    public function traitementC() {
        $this->serviceA.traitementA();
        $result = $this->serviceB.traitementB();
        ...
    }

}
```

Ici, nous avons mis en place l'`injection de dépendances` des services `A` et `B`. La méthode `traitementC` ne se charge plus de la création de ses services. Ils sont créés à l'extérieur puis passé en paramètres au constructeur. Néanmoins, ce **refactoring** est encore incomplet. En effet, malgré le fait que les dépendances soient injectées, il s'agit toujours de dépendances **concrètes**. On ne pourrait pas remplacer les classes `A` ou `B` par d'autres classes (notamment, pour changer le comportement de ces dépendances lors des tests).

Pour régler ce problème, il suffit de créer des `interfaces` pour nos dépendances. Ainsi, une nouvelle architecture donnerait :

```php
interface ServiceAInterface {
    public function traitementA();
}

class A implements ServiceAInterface {
    public function traitementA() {
        ...
    }
}

interface ServiceBInterface {
    public function traitementB();
}

class B implements ServiceBInterface {

    private static $instance = null;

    private function __construct() {}

    public static function getInstance() {
        if(self::$instance == null) {
            self::$instance = new B();
        }
        return self::$instance;
    }

    public function traitementB() {
        ...
        return ...
    }
}

interface ServiceCInterface {
    public function traitementC();
}

class C implements ServiceCInterface {

    private ServiceAInterface $serviceA;

    private ServiceBInterface $serviceB;

    public function __construct(ServiceAInterface $serviceA, ServiceBInterface $serviceB) {
        $this->serviceA = $serviceA;
        $this->serviceB = $serviceB;
    }

    public function traitementC() {
        $this->serviceA.traitementA();
        $result = $this->serviceB.traitementB();
        ...
    }

}
```

Il est donc maintenant possible de changer les classes concrètes dont sera dépendante la classe `C`. Nous avons déjà évoqué l'avantage d'un tel procédé dans le cadre de tests mais ce système permet aussi de rendre l'application hautement configurable et flexible. Avec ce système, on pourrait, par exemple, avoir un environnement de "production" utilisant une base de données précise, et un environnement de "développement" ou de "test" utilisant une autre base de données.

Vous aurez remarqué que la classe `C` possède aussi une interface. Même si cette classe n'apparait pas encore comme dépendance d'une autre classe, c'est une bonne pratique de prévoir cela en amont et de systématiquement donner une interface à tous nos services.

Globalement, on peut retenir qu'une bonne architecture implique que :

   * Les différentes classes ne dépendent pas d'instances d'autres classes en particulier, mais plutôt d'une **interface** (ou d'une **classe abstraite**) qui pourra prendre des formes différentes grâce au **polymorphisme** sans avoir besoin de changer le code de la section utilisant ce composant.

   * Les **instances** concrètes sont **injectées** dans les classes qui doivent utiliser un service. Cela peut se faire sous la forme de **setters** ou bien directement comme arguments pour le **constructeur** de l'objet. Cela renforce l'indépendance des classes. La classe n'instancie pas elle-même les composants dont elle a besoin, ils sont **injectés** depuis l'extérieur. On appelle cela **l'inversion de contrôle**.

   * Il est possible d'utiliser la même instance et de l'injecter dans différentes classes. En fait l'instance n'est initialisé qu'à un seul endroit. Cela facilite donc également sa construction nécessite différents paramètres. Il est également possible de générer plusieurs instances du service et de sélectionner lequel est injecté dans quelle classe.

Notre prochain objectif est donc de remanier les classes des `controleurs`, des `services` et des `repositories` afin de les rendre indépendantes des classes concrètes, en mettant en place une architecture favorisant l'injection de dépendance.

<div class="exercise">

1. Pour commencer, transformez la classe `ConnexionBaseDeDonnees` pour que celle-ci ne soit plus un `singleton` (ne plus avoir de variable `instance` ni de méthode `getInstance`, rendre le constructeur `public` et changer la méthode `getPDO` pour qu'elle ne soit plus `static`)

2. Faites en sorte d'injecter une dépendance de type `ConfigurationBDDInterface` via le constructeur. Cette dépendance sera celle utilisée pour initialiser l'objet `PDO`.

3. Créez une interface à partir de la classe `ConnexionBaseDeDonnees` (et appliquez-la). Cette opération peut être automatisée avec votre `IDE` : `Refactor` -> `Extract` -> `Interface`.

4. Modifiez les classes `PublicationRepository` et `UtilisateurRepository` pour éliminer tout appel statique à `ConnexionBaseDeDonnees` et à la place, mettre en place l'injection d'une dépendance correspondant à l'interface créée à la question précédente (il faudra créer un nouvel attribut pour stocker cette dépendance). Cette dépendance sera utilisée dans les différentes méthodes afin d'obtenir l'objet `pdo`. Créez également des `interfaces` pour ces deux classes (et appliquez-les). Voici un squelette que vous pouvez reprendre pour `PublicationRepository` :

    ```php
        namespace TheFeed\Modele\Repository;

        use TheFeed\Modele\DataObject\Publication;

        interface PublicationRepositoryInterface
        {
            public function getAll(): array;

            public function getAllFrom($idUtilisateur): array;

            public function create(Publication $publication);

            public function get($id): ?Publication;

            public function update(Publication $publication);

            public function remove(Publication $publication);
        }
    ```

    ```php
    namespace TheFeed\Modele\Repository;

    use TheFeed\Modele\DataObject\Publication;
    use TheFeed\Modele\DataObject\Utilisateur;
    use DateTime;

    class PublicationRepository implements PublicationRepositoryInterface
    {

        private ConnexionBaseDeDonneesInterface $connexionBaseDeDonnees;

        public function __construct(ConnexionBaseDeDonneesInterface $connexionBaseDeDonnees)
        {
            $this->connexionBaseDeDonnees = $connexionBaseDeDonnees;
        }

        /**
         * @return Publication[]
         * @throws \Exception
         */
        public function getAll(): array
        {
            $statement = $this->connexionBaseDeDonnees->getPdo()->prepare(...);
            ...
        }

        ...
    }
    ```

5. Faites une opération similaire au niveau des deux classes `PublicationService` et `UtilisateurService` en injectant les classe `repository` comme dépendances, via le constructeur. Il faudra éliminer toutes les instanciations de repository pour utiliser vos nouvelles dépendances. Là-aussi, mettez en place des interfaces pour ces deux services. Attention `UtilisateurService` utilise les deux repositories.

6. Au niveau de vos deux `controleurs`, réalisez l'injection des deux services (toujours via leur interface). Il faudra alors rendre toutes les fonctions non statiques. Dans chaque méthode, au lieu d'instancier un service pour réaliser une opération, vous utiliserez vos nouvelles dépendances.

</div>

Après toutes ces opérations, votre application ne doit plus fonctionner ! Pas de panique, c'est tout à fait normal. En effet, il y a besoin d'indiquer quelque part comment sont construits tous ces services et surtout, réaliser concrètement l'injection des différentes dépendances. Cela va être le rôle de la prochaine section dédiée au `conteneur de services`.

### Le conteneur de services

Comme mentionné précédemment, nous avons besoin d'un outil et d'un endroit dans le code permettant de contenir tous les services et d'injecter les différents instances concrètes à ceux qui ont en besoin. Un tel outil est généralement appelé **conteneur IoC** (conteneur Inversion of Control) ou bien **conteneur de services**. Lors du premier TD de complément web, vous avez créé une ébauche de ce conteneur modélisé par la classe située dans `Lib/Conteneur.php`.

Dans une application web bien construite, la toute première étape avant de transmettre la requête au contrôleur est de se servir du conteneur afin d'enregistrer les services puis résoudre toutes les dépendances et ainsi disposer de tous les objets utiles au traitement de la demande. C'est d'ailleurs ce que vous faite déjà partiellement dans `RouteurURL`.

Nous pourrions continuer avec ce conteneur, mais nous allons plutôt utiliser celui de **symfony**. Il y a principalement trois avantages à cela. Tout d'abord, les dépendances sont gérées en mode `lazy loading`. Cela signifie qu'une dépendance concrète n'est instanciée que si on en a vraiment besoin. Deuxièmement, ce conteneur permet de gérer les **dépendances croisées** (c'est-à-dire, si `A` a besoin de `B` et inversement). Enfin, le conteneur peut être configuré avec un fichier de configuration `.yml` sans avoir besoin d'écrire de lignes de code en PHP (ou du moins, pas beaucoup). Cette flexibilité permet d'avoir simplement plusieurs configurations possibles pour gérer les différents modules et services de notre application (et donc, avoir plusieurs environnements d'exécution, éventuellement).

Regardons de plus près les méthodes qui vont nous intéresser dans ce conteneur :

```php
//Instanciation
$container = new ContainerBuilder();

//Enregistrement du service "serviceName" qui représente la classe concrète MyService
$container->register('service_name', MyService::class)

//Recuperation de l'instance service :

$myService = $container->get('service_name');

//Enregistrement d'un service qui a besoin de paramètres pour être intialisé.
//Les paramètres sont passés dans l'ordre, via un tableau
//L'injection est faite via le constructeur
$serviceReference = $container->register('service_bis', MyServiceBis::class)
$serviceReference->setArguments([5, "test"]);
//Le constructeur de MyServiceBis attend donc un entier et une chaîne de caractères...!
```
La méthode register renvoie une **référence du service** (et pas une instance du service). Il est donc possible de préciser divers paramètres comme les arguments du constructeur, des méthodes à exécuter après initialisation...

On peut également enregistrer des **paramètres** (variables globales) dans le conteneur :
```php
$container->setParameter('param_one', "hello");
```

Maintenant, quelque chose d'un peu plus avancé :

```php
$serviceReference = $container->register('service_third', MyServiceThird::class)
$serviceReference->setArguments(["%param_one%", new Reference("service_bis")]);
```

Dans les paramètres injectés dans le service, on peut :  
   * Faire référence à un paramètre contenu dans le conteneur, en utilisant les marqueurs `%nom_parametre%`  
   * Faire référence à un autre service du conteneur (même s'il n'est pas encore enregistré !). On utilise pour cela un objet `Reference` paramétré avec le nom du service.

Après enregistrement et configuration, à partir du **conteneur**, on peut donc récupérer n'importe quel service grâce à la méthode `get`.

Quand on y regarde de plus près, ce conteneur est en fait une grande **factory** construite dynamiquement et regroupant tous les services de l'application. On passe par elle pour récupérer l'instance qui nous intéresse. Si on veut changer l'instance utilisée pour un service, il suffit alors de changer la classe spécifiée à un seul endroit, lors de la configuration du conteneur.

Dans un premier temps, nous allons enregistrer les services que nous venons de créer puis, plus tard, vous pourrez progressivement supprimer le conteneur que vous aviez défini auparavant.

<div class="exercise">

1. Installez le conteneur de service de symfony :

    ```bash
    composer require symfony/dependency-injection
    ```

2. Dans la méthode `traiterRequete` de `RouteurURL`, juste après le dernier enregistrement d'un service dans votre classe `Conteneur`, ajoutez les lignes de code suivantes :

    ```php
    use TheFeed\Controleur\ControleurPublication;
    use TheFeed\Controleur\ControleurUtilisateur;
    use TheFeed\Modele\Repository\ConnexionBaseDeDonnees;
    use TheFeed\Modele\Repository\PublicationRepository;
    use TheFeed\Modele\Repository\UtilisateurRepository;
    use TheFeed\Service\PublicationService;
    use TheFeed\Service\UploadedFileMovingService;
    use TheFeed\Service\UtilisateurService;
    use TheFeed\Configuration\ConfigurationBDDMySQL;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Reference;

    $conteneur = new ContainerBuilder();

    $conteneur->register('config_bdd', ConfigurationBDDMySQL::class);

    $connexionBaseService = $conteneur->register('connexion_base', ConnexionBaseDeDonnees::class);
    $connexionBaseService->setArguments([new Reference('config_bdd')]);

    $publicationsRepositoryService = $conteneur->register('publication_repository',PublicationRepository::class);
    $publicationsRepositoryService->setArguments([new Reference('connexion_base')]);

    $utilisateurRepositoryService = $conteneur->register('utilisateur_repository',UtilisateurRepository::class);
    $utilisateurRepositoryService->setArguments([new Reference('connexion_base')]);

    $publicationService = $conteneur->register('publication_service', PublicationService::class);
    $publicationService->setArguments([new Reference('publication_repository'), new Reference('utilisateur_repository')]);

    $publicationControleurService = $conteneur->register('publication_controleur',ControleurPublication::class);
    $publicationControleurService->setArguments([new Reference('publication_service')]);
    ```

    Attention, vérifiez bien l'ordre des arguments dans `publication_service` (selon l'ordre que vous avez défini dans le constructeur de `PublicationService`).

3. Nous avons enregistré la partie permettant de gérer les publications. Maintenant, il faut indiquer aux routes et au resolver de contrôleur d'utiliser le contrôleur enregistré dans le conteneur ! Pour cela :

    * Au niveau des routes remplacez `ControleurPublication::class` par le nom du service correspondant, c'est-à-dire, `publication_controleur`.

    * Remplacez la ligne instanciant un `ControlerResolver` en instanciant un `ContainerControllerResolver` à la place. Il faut donner comme arguments du constructeur de cette nouvelle classe votre conteneur (`$conteneur`).

4. Chargez la page principale de votre application. Elle devrait fonctionner !

5. Complétez le code afin d'enregistrer le service puis le contrôleur liés aux utilisateurs dans le conteneur. Enfin, mettez à jour les routes correspondantes.

6. Naviguez à travers l'application et vérifiez que tout fonctionne comme avant.

</div>

### Les mocks

Maintenant que notre logique métier est (en partie) indépendante de classes concrètes, nous allons pouvoir réaliser de véritables tests unitaires sans avoir besoin ou influer sur le reste de l'application. En effet, dorénavant, lorsque nous instancions un **service**, nous pouvons contrôler quelle dépendance nous lui donnons.

Idéalement, nous aimerions pouvoir contrôler ce que les dépendances de chaque service répond lors de la phase de test afin de construire un scénario de test adéquat. Pour cela, nous pourrions :

* Créer une classe dédiée et la faire hériter de l'interface de la dépendance en question. Ainsi, nous pourrions ce que les méthodes renvoient. Néanmoins, cela peut vite devenir fastidieux s'il faut créer une nouvelle classe pour chaque scénario...

* Utiliser des **mocks**. Les **mocks** permettent de créer (avec une ligne de code) une "fausse" classe possédant les mêmes méthodes qu'il est possible de configurer dynamiquement par des lignes de code. Un exemple de configuration possible et de préciser un résultat à renvoyer lors de l'appel d'une méthode précise. Ou bien même déclencher une exception. Cette option est bien plus flexible que l'idée de créer une classe dédiée par scénario.

Regardons de plus près l'utilisation de ces **mocks** :

```php

//Dans une méthode d'une classe héritant de TestCase

//Creation d'un mock de type ServiceAInterface
$mockedService = $this->createMock(ServiceAInterface::class);

//On fait en sorte que la méthode traitementA retourne un tableau de deux éléments
$mockedService->method("traitementA")->willReturn([7,8]);

//Il est possible d'aller plus loin et de déclencher une réponse spécifique en fonction des valeurs des paramètres passés àa la méthode.
//On peut traduire l'instruction ci-dessous par : quand la méthode 'traitementABis' est appellée avec la valeur 5, retourner 10.
$mockedService->method("traitementABis")-with(5)->willReturn(10);

//On fait en sorte qu'un appel à la méthode traitementSpecial déclenche une exception
$mockedService->method("traitementSpecial")->willThrowException(ExempleException::class);
```

Prenons l'exemple de votre classe `PublicationServiceTest`. Celle-ci ne doit plus bien fonctionner le `service` manipulé par les tests attend des dépendances (repositories utilisateur et publication).

Nous pourrions réécrire le test `testNombrePublications` comme suit :

```php
class PublicationServiceTest extends TestCase
{

    private $service;

    private $publicationRepositoryMock;

    private $utilisateurRepositoryMock;

    protected function setUp(): void
    {
        parent::setUp();
        $this->publicationRepositoryMock = $this->createMock(PublicationRepositoryInterface::class);
        $this->utilisateurRepositoryMock = $this->createMock(UtilisateurRepositoryInterface::class);
        $this->service = new PublicationService($this->publicationRepositoryMock, $this->utilisateurRepositoryMock);
    }

    public function testNombrePublications() {
        //Fausses publications, vides
        $fakePublications = [new Publication(), new Publication()];
        //On configure notre faux repository pour qu'il renvoie nos publications définies ci-dessus
        $this->publicationRepositoryMock->method("getAll")->willReturn($fakePublications);
        //Test
        $this->assertCount(2, $this->service->recuperPublications());
    }
}
```

Un autre aspect très utile des mocks est de pouvoir exécuter un `callback` (une fonction) lorsqu'une méthode est exécutée tout en récupérant les valeurs des paramètres de la méthode exécutée. Cela permet donc d'analyser ce qui a été donné par un service à notre mock, lors d'un appel de méthode.

On configure tout cela grâce à la méthode `willReturnCallback` lors de la configuration d'une méthode sur un **mock**.

```php
class ExempleService implements ExempleServiceInterface {

    public function traitement($a, $b) {
        ...
    }
}

class SuperService implements SuperServiceInterface {

    private ExempleServiceInterface $exempleService;

    public function __construct(ExempleServiceInterface $exempleService) {
        $this->exempleService = $exempleService;
    }

    public function superTraitement() {
        ...
        $this->exempleService->traitement("test", 42);
        ...
    }

}

class SuperServiceTest extends TestCase {

    private SuperServiceInterface $service;

    private ExempleServiceInterface $mock;

    public function __construct() {
        $this->mock = $this->createMock(ExempleServiceInterface::class);
        $this->service = new SuperService($this->mock);
    }

    public testSuperTraitement() {
        $this->mock->method("traitement")->willReturnCallback(function($a, $b) {
            //Portion de code déclenché quand le service appaellera la méthode 'traitement' sur notre mock.
            //Ici, on doit réaliser des assertions sur $a et $b...
        });
        $this->service->superTraitement();
    }

}
```

### De véritables tests unitaires

Maintenant que vous connaissez les **mocks**, vous allez pouvoir les utiliser pour écrire de véritables tests unitaires !

<div class="exercise">

1. Reprenez votre classe `PublicationServiceTest` et adaptez-la pour faire fonctionner vos anciens tests en utilisant des **mocks** pour les dépendances du service. Vous pouvez repartir de l'exemple de classe donné dans la section précédente quand nous avions remanié le test `testNombrePublications`. Dans certains tests, pour la partie concernant les **utilisateurs**, il faudra bien configurer votre mock afin qu'il renvoie un faux utilisateur (parfois **null** et parfois non... Tout dépend du contexte du test !).

2. Créez un test `testCreerPublicationValide`. Le but de ce test est de vérifier que tout fonctionne bien lorsque les spécifications de création d'une publication sont respectées. En utilisant votre **mock** du repository des publications, vous devrez intercepter l'appel à **create** afin de vérifier que les données transmisses sont bien conformes.

3. Ajoutez des tests qui vous semblent pertinents !

4. Lancez les tests unitaires (avec couverture) et vérifiez que vous avez bien une couverture de code de **100%** sur votre classe `PublicationService`.

</div>

Bien sûr, notre contexte de test dans ce sujet reste assez simpliste, mais cela vous donne déjà une idée de comment réaliser des tests unitaires assez précis et indépendants du contexte de l'application. Vous l'aurez remarqué, avec cette nouvelle façon de fonctionner, la base de données n'est pas sollicitée et on ne dépend plus des utilisateurs réellement inscrits ou des publications réellement créées. Et on n'indique par de réellement créer une nouvelle publication après chaque exécution des tests !

## Concernant la *SAÉ*

Pour en revenir à votre *SAÉ*, le but de cette séance est de vous permettre de réappliquer les concepts que vous venez de voir afin de **retravailler l'architecture** de l'application pour favoriser un système **d'injection de dépendances** via un **conteneur de services** et ainsi réaliser différents **tests unitaires** efficacement, en utilisant des **mocks**.

Un premier objectif à vous fixer serait d'obtenir une couverture de code (proche) de 100%, pour la partie "métier" de votre application.

## Extensions

Nous allons maintenant travailler différentes extensions de ce TD afin de pouvoir tester plus d'aspects de l'application, régler des problèmes que vous pourriez rencontrer lors des tests unitaires, améliorer encore plus l'architecture de l'application et l'indépendance de ses classes en transformant plus d'entités en **services**.

### Tester les repositories

Dans nos tests précédents, nous avons supprimé l'interaction avec la base de données en **mockant** nos repositories. Néanmoins, il peut être aussi intéressant de tester ces repositories ! Avoir des tests automatisés permettrait de détecter des éventuelles erreurs dans les requêtes SQL.

Mais comment faire ? Car, comme nous l'avons expliqué précédemment, il n'est pas envisageable d'agir directement sur la base de données réelle de l'application lors de nos tests. La réponse est simple : il nous faut utiliser une base de données dédiée aux tests ! Cela est possible car nous avons fait en sorte que la connexion à la base de données soit injectée comme une dépendance des repositories.

Généralement, pour la base de données de tests, deux choix sont possibles :

* On réalise une copie de la structure de la base, sur le même type de SGBD (dans notre cas, MySQL). Il faut donc que le serveur gérant la base de données soit allumé au moment des tests.

* On réalise nos tests avec une base de données **SQLite** qui est une base de données stockée dans un fichier qui ne nécessite pas de serveur.

Généralement, quand cela est possible, on préfère choisir la seconde option, mais ce n'est pas toujours envisageable, notamment quand la structure de la base de données ou les requêtes utilisent des concepts spécifiques à un SGBD donné (c'est le cas dans votre *SAÉ*). Dans ce cas, on réalisera une copie locale de la structure de la base, sur le même type de SGBD.

En tout cas, dans le contexte de l'application **The Feed**, il vous faudra créer un fichier de configuration dédié ou bien un mock de `ConfigurationBDDInterface`.

Dans le cas de tests unitaires sur des repositories, on peut imaginer que la fonction `setUp` va remplir la base avec différentes données initiales et que la fonction `tearDown` va nettoyer la base (la vider). Par exemple :

```php
class ConfigurationBDDTestUnitaire implements ConfigurationBDDInterface {

    public function getLogin(): string
    {
        return ...
    }

    public function getMotDePasse(): string
    {
        return ...
    }

    public function getDSN() : string{
        return ...
    }
    public function getOptions() : array {
        return ...
    }
}


class ExempleRepositoryTest extends TestCase {

    private static MonReposiotryInterface $repository;

    private static ConnexionBaseDeDonneesInterface $connexion;

    //On instancie une fois le repositoy, pas besoin de le ré-instancier à chaque test
    public static function setUpBeforeClass() {
        self::$connexion = new ConnexionBaseDeDonnees(new ConfigurationBDDTestUnitaire());
        self::$repository = new MonRepository(self::$connexion);
    }

    public function setUp() {
        //On remplit la base de test avant chaque test
        self::$connexion->getPdo()->query("INSERT INTO ...");
        self::$connexion->getPdo()->query("INSERT INTO ...");
        self::$connexion->getPdo()->query("INSERT INTO ...");
        ...
    }

    public function testExemple() {
        $entite = new Entite(...);
        $id = self::$repository->create($entite);
        $this->assert(...)
        $entiteBDD = self::$repository->getById($id);
        $this->assert(...)
    }

    public function tearDown() {
        //On vide la base après chaque test
        self::$connexion->getPdo()->query("DELETE FROM ...");
    }

}
```

Nous allons réaliser une première classe de test pour le repository des **utilisateurs**. Une base **SQLite** sera utilisée.

<div class="exercise">

1. **Si vous travaillez sur votre serveur local** veillez à activer l'extension `pdo_sqlite` au niveau de votre fichier `php.ini` (il faut décommenter la ligne `;extension=pdo_sqlite`).

2. Téléchargez [ce fichier]({{site.baseurl}}/assets/TD_SAE_Test_Archi/database_test) qui contient la structure de la base de données de `The Feed` sous le format `SQLite`. Placez ce fichier dans le dossier `Test`.

3. Toujours dans le dossier `Test`, créez un fichier `ConfigurationBDDTestUnitaire` avec le contenu suivant :

    ```php
    namespace TheFeed\Test;

    use TheFeed\Configuration\ConfigurationBDDInterface;

    class ConfigurationBDDTestUnitaire implements ConfigurationBDDInterface
    {
        public function getLogin(): string
        {
            return "";
        }

        public function getMotDePasse(): string
        {
            return "";
        }

        public function getDSN(): string
        {
            return "sqlite:".__DIR__."/database_test";
        }

        public function getOptions(): array
        {
            return array();
        }
    }
    ```

4. Créez une classe de test `UtilisateurRepositoryTest` avec le contenu suivant :

    ```php
    namespace TheFeed\Test;

    use PHPUnit\Framework\TestCase;
    use TheFeed\Modele\Repository\ConnexionBaseDeDonnees;
    use TheFeed\Modele\Repository\ConnexionBaseDeDonneesInterface;
    use TheFeed\Modele\Repository\UtilisateurRepository;
    use TheFeed\Modele\Repository\UtilisateurRepositoryInterface;

    class UtilisateurRepositoryTest extends TestCase
    {
        private static UtilisateurRepositoryInterface  $utilisateurRepository;

        private static ConnexionBaseDeDonneesInterface $connexionBaseDeDonnees;

        public static function setUpBeforeClass(): void
        {
            parent::setUpBeforeClass();
            self::$connexionBaseDeDonnees = new ConnexionBaseDeDonnees(new ConfigurationBDDTestUnitaire());
            self::$utilisateurRepository = new UtilisateurRepository(self::$connexionBaseDeDonnees);
        }

        protected function setUp(): void
        {
            parent::setUp();
            self::$connexionBaseDeDonnees->getPdo()->query("INSERT INTO 
                                                            utilisateurs (idUtilisateur, login, password, adresseMail, profilePictureName) 
                                                            VALUES (1, 'test', 'test', 'test@example.com', 'test.png')");
            self::$connexionBaseDeDonnees->getPdo()->query("INSERT INTO 
                                                            utilisateurs (idUtilisateur, login, password, adresseMail, profilePictureName) 
                                                            VALUES (2, 'test2', 'test2', 'test2@example.com', 'test2.png')");
        }

        public function testSimpleCountGetAll() {
            $this->assertCount(2, self::$utilisateurRepository->getAll());
        }

        protected function tearDown(): void
        {
            parent::tearDown();
            self::$connexionBaseDeDonnees->getPdo()->query("DELETE FROM utilisateurs");
        }

    }
    ```

5. Comprenez ce que fait cette classe. Prenez le temps de bien l'étudier.

6. Complétez cette classe en écrivant plusieurs autres tests unitaires.

</div>

Bien sûr, si vous testez plusieurs repositories, il est possible de mutualiser les lignes de code de la méthode `setUp` dont le but est de remplir la base de données (avec de l'héritage, par exemple). On pourrait aussi avoir un système où on définit un script de remplissage de la base qui est chargé et exécuté avant chaque test.

### Tester le service utilisateur

Pour la plupart des méthodes de `UtilisateurService`, vous devriez être en mesure d'écrire des tests unitaires comme vous l'avez fait pour `PublicationService`. Néanmoins, il y a un **effet de bord** indésirable qui se produit lors de l'exécution de la méthode `creerUtilisateur`. En effet, même si dans le cadre des tests nous pouvons mocker le repository, cette méthode va placer une image (la photo de profil) dans le dossier `web/assets/img/utilisateurs` ! 

Mais pas de panique, nous pouvons utiliser notre `conteneur de services` pour contourner ce problème. L'idée est de transformer le dossier de destination en un paramètre du service qui sera injecté.

<div class="exercise">

1. Dans `UtilisateurService`, créez un attribut `$profilePictureFolder` et faites en sorte de l'initialiser par le constructeur. Cet attribut contiendra le chemin du répertoire stockant les photos de profil.

2. Dans la méthode `creerUtilisateur`, lors de la construction du chemin du fichier contenant la photo de profil puis lors de l'appel à la fonction `move_uploaded_file`, utilisez votre nouvel attribut.

3. Dans la méthode `traiterRequete` de `RouteurURL`, enregistrez le dossier de destination des photos de profil comme un **paramètre** du conteneur (utilisez la méthode `setParameter`). Attention, à partir de ce fichier, le chemin est toujours `__DIR__."/../../web/assets/img/utilisateurs/"`.

4. Injectez cet attribut comme argument du service des utilisateurs en utilisant sa référence. Pour rappel, on peut faire référence à un attribut du conteneur avec la syntaxe : `%nom_attribut%`.

5. Vérifiez que l'inscription fonctionne toujours bien (et que l'image arrive là où il faut).

</div>

Maintenant que le répertoire de destination des photos de profil est configurable, vous pouvez en créer un dédié pour vos tests ! (et le vider après l'exécution des tests, avec `tearDown`). Pour vérifier l'existence d'un fichier, il y a une assertion dédiée : `assertFileExists`. La fonction `mkdir` peut vous permettre de créer le dossier contenant les images tandis que la fonction `rmdir` vous permet de le supprimer.

Attention, dans les paramètres de la méthode `creerUtilisateur` de la classe `UtilisateurService`, vous devez fournir en paramètre un tableau `$profilePictureData`. Ce tableau doit essentiellement contenir deux données :

* `name` : Le nom du fichier uploadé base (avec son extension)
* `tmp_name` : Le nom temporaire du fichier (donné par *PHP*, quand il est uploadé). Dans le cadre des tests, cette donnée sera la même que pour `name`.

Dans vos tests, il vous faudra remplir ce tableau. On vous recommande donc de créer un dossier `assets` dans `Test` dans l'objectif est de contenir différents fichiers utiles pour les tests (notamment, ici, une photo de profil de test).

Néanmoins, il y a un autre problème ! Avez-vous remarqué l'instruction `move_uploaded_file` dans `creerUtilisateur` ? Cette fonction permet de déplacer un fichier qui a été uploadé vers un nouveau dossier. Or, dans nos tests, nous ne pouvons pas uploader de fichiers ! Nous allons donc transformer cette partie du code en **service** !

Dans le contexte concret de l'application, ce service exécutera la fonction `move_uploaded_file`. Dans nos tests, on exécutera une fonction pour copier la photo contenu dans notre dossier `assets` (de test) vers un dossier temporaire.

<div class="exercise">

1. Dans le dossier `Service`, créez l'interface suivante :

    ```php

    namespace TheFeed\Service;

    interface FileMovingServiceInterface
    {
        public function moveFile($fileName, $pathDestination);
    }
    ```

2. Toujours dans `Service`, créez une classe `UploadedFileMovingService` implémentant cette interface :

    ```php
    namespace TheFeed\Service;

    class UploadedFileMovingService implements FileMovingServiceInterface
    {
        public function moveFile($fileName, $pathDestination)
        {
            move_uploaded_file($fileName, $pathDestination);
        }
    }
    ```

3. Enfin, dans le dossier `Test`, créez une classe `TestFileMovingService` comme suit :

    ```php
    namespace TheFeed\Test;

    use TheFeed\Service\FileMovingServiceInterface;

    class TestFileMovingService implements FileMovingServiceInterface
    {
        private static string $ASSETS_FOLDER = __DIR__."/assets/";

        public function moveFile($fileName, $pathDestination)
        {
            copy(self::$ASSETS_FOLDER.$fileName, $pathDestination);
        }
    }
    ```

4. Faites en sorte d'injecter et d'utiliser un service de type `FileMovingServiceInterface` dans `UtilisateurService` à la place de l'instruction `move_uploaded_file` (vous devriez savoir comment faire, maintenant).

5. N'oubliez pas d'enregistrer votre nouveau service dans votre conteneur (en utilisant la classe concrète `UploadedFileMovingService`) et pensez bien à passer ce service comme argument du service gérant les utilisateurs.

6. Vérifiez que l'inscription fonctionne toujours comme attendu.

</div>

Maintenant que nous avons réglé tous les problèmes liés aux effets de bord de la méthode `creerUtilisateur`, nous pouvons commencer à tester !

<div class="exercise">

1. Créez un dossier `assets` dans `Test` puis placez-y une photo de profil quelconque au format `PNG` et renommez-la `test.png`.

2. Créez une classe `UtilisateurServiceTest` avec le squelette de code suivant et complétez-le :

    ```php
    namespace TheFeed\Test;

    use PHPUnit\Framework\TestCase;
    use TheFeed\Modele\Repository\UtilisateurRepositoryInterface;
    use TheFeed\Service\FileMovingServiceInterface;
    use TheFeed\Service\UtilisateurService;

    class UtilisateurServiceTest extends TestCase
    {

        private $service;

        private $utilisateurRepositoryMock;

        //Dossier où seront déplacés les fichiers pendant les tests
        private  $profilePictureFolder = __DIR__."/tmp/";

        private FileMovingServiceInterface $fileMovingService;

        protected function setUp(): void
        {
            parent::setUp();
            $this->utilisateurRepositoryMock = /* TODO */
            $this->fileMovingService = /* TODO */
            mkdir($this->profilePictureFolder);
            $this->service = new UtilisateurService(/* TODO */);
        }

        public function testCreerUtilisateurPhotoDeProfil() {
            $profilePictureData = [];
            $profilePictureData["name"] = "test.png";
            $profilePictureData["tmp_name"] = "test.png";
            $this->utilisateurRepositoryMock->method("getByLogin")->willReturn(null);
            $this->utilisateurRepositoryMock->method("getByAdresseMail")->willReturn(null);
            $this->utilisateurRepositoryMock->method("create")->willReturnCallback(function ($utilisateur) {
                /* TODO : Tester l'existence du fichier (et eventuellement d'autres tests) */ 
            });
            $this->service->creerUtilisateur("test", "TestMdp123", "test@example.com", $profilePictureData);
        }

        protected function tearDown(): void
        {
            //Nettoyage
            parent::tearDown();
            foreach(scandir($this->profilePictureFolder) as $file) {
                if ('.' === $file || '..' === $file) continue;
                unlink($this->profilePictureFolder.$file);
            }
            rmdir($this->profilePictureFolder);
        }

    }
    ```
3. Lancez les tests unitaires, vérifiez qu'ils passent.

4. Complétez la classe en écrivant plus de tests unitaires pertinents, au moins jusqu'à atteindre une couverture de code de 100% pour cette classe.
</div>

### Fichier de configuration du conteneur de services

Plutôt que d'utiliser du code `PHP` pour initialiser nos services, nous allons utiliser un fichier de configuration au format `YAML` !

Le fichier de configuration se présente ainsi :

```yaml
parameters:
  nom_parametre1: "..."
  nom_parametre2: "..."

services:
  nom_service1:
    class: Exemple\MaClasse
    arguments: ['...', '...']

  nom_service2:
    class: Exemple\MaClasse2
    arguments: ['...']
```

La section `parameters` correspond aux paramètres du conteneur. On peut ensuite y faire référence dans les `arguments` avec `%nom_parametre%`.

La section `services` liste les services de l'application. On y retrouve :

* Le nom du service
* Le chemin de sa classe (même format que pour le `use`).
* Sa liste d'arguments (injection de dépendances, pour son constructeur). Cela peut être des arguments simples, ont bien des références à des paramètres du conteneur (`%nom_parametre%`) ou bien des références à d'autres services (`@nom_service`).

Par exemple, un début de fichier de configuration pour notre application donnerait :

```yaml
parameters:

services:

  config_bdd:
    class: TheFeed\Configuration\ConfigurationBDDMySQL

  connexion_base:
    class: TheFeed\Modele\Repository\ConnexionBaseDeDonnees
    arguments: ['@config_bdd']

  publication_repository:
      class: TheFeed\Modele\Repository\PublicationRepository
      arguments: ['@connexion_base']

  publication_service:
    class: TheFeed\Service\PublicationService
    arguments: ['@publication_repository', '@utilisateur_repository']
```

Nous allons donc mettre en place un fichier de configuration pour notre application.

<div class="exercise">

1. Importez les composants suivants :

    ```bash
    composer require symfony/yaml symfony/config
    ```

2. Dans le dossier `Configuration`, créez un fichier `config.yml` reprenant le début de configuration présenté précédemment. Complétez ce fichier avec tous les services que vous avez déclarés dans `RouteurURL`. Ne vous occupez pas de la déclaration du paramètre concernant le dossier contenant les photos de profil pour le moment. (vous pouvez / devez quand même y faire référence dans les arguments lors de la déclaration du service gérant les utilisateurs)

3. Dans `RouteurURL`, supprimez toutes les lignes de code qui enregistrent vos services dans le conteneur de *Symfony*. À la place, utilisez ces deux lignes de code :

    ```php
    use Symfony\Component\DependencyInjection\Loader\YamlFileLoader;
    use Symfony\Component\Config\FileLocator;
    //On indique au FileLocator de chercher à partir de la racine du projet
    $loader = new YamlFileLoader($conteneur, new FileLocator(__DIR__."/../"));
    //On remplit le conteneur avec les données fournies dans le fichier de configuration
    $loader->load("src/Configuration/config.yml");
    ```

4. Vérifiez que votre application fonctionne.

5. Nous ne pouvons pas simplement enregistrer le paramètre gérant le répertoire des photos de profil car dans le fichier `config.yml`, nous ne pouvons pas utiliser `__DIR__`. Nous allons donc adopter la méthode suivante :

    * Avant de charger la configuration dans le conteneur, enregistrer un paramètre `project_root` ayant pour valeur `__DIR__."/../../"` (pointe vers la racine du projet). Ce paramètre pourra nous servir dans divers contextes dès que nous aurons besoin de construire un chemin au travers des fichiers de l'application.

    * Dans `config.yml`, enregistrer un `paramètre` correspondant au chemin du dossier contenant les photos de profil en utilisant le paramètres `project_root`. Comme pour les services, il est possible d'utiliser un paramètre lors de la définition d'un autre paramètre, ainsi : `%project_root%/chemin/vers/dossier`.

    Faites les modifications nécessaires pour charger ce paramètre du côté du fichier `config.yml` et plus au niveau du PHP.

6. Comme d'habitude, vérifiez que rien n'est cassé !
</div>

### Pour aller plus loin

Durant ce TD, nous avons exploré beaucoup d'aspects liés à l'architecture de l'application et la mise en place de tests unitaires. Néanmoins, il reste du travail à effectuer pour correctement finir de refactoriser et tester notre application. Quelques pistes :

* Définir plus de services ! Dès que dans une classe donnée, il y a une instanciation d'une classe concrète ou bien l'utilisation d'une classe de manière statique (par exemple, quand on utilise la plupart des classes du dossier `Lib`) on peut créer un service à la place et l'injecter à la classe qui en a besoin. Par exemple, dans `UtilisateurService`, il y a l'utilisation de la classe `MotDePasse` et aussi `ConnexionUtilisateur` qui pourraient être remplacées par des services.

* Supprimer la classe `Conteneur` de `Lib` et migrer les deux services enregistrés dans ce conteneur dans le nouveau conteneur, de *Symfony*. Il faudra alors retravailler la classe `ControleurGenerique` et faire en sorte d'injecter les deux dépendances dans chaque contrôleur. On pourrait aussi éventuellement passer le conteneur directement aux constructeurs afin qu'ils aillent directement récupérer le service dont ils ont besoin (on peut utiliser cette méthode si un contrôleur utilise beaucoup de services, pour ne pas à avoir à les injecter un par un).

* Tester la classe `PublicationRepository` et même globalement, toutes les classes de services créées.

* Tester les autres classes définies dans `Modele`.

* Augmenter le plus possible la couverture de code.

Vous pouvez donc travailler tous ces aspects pour améliorer la qualité globale de l'application et couvrir plus de scénarios de tests.