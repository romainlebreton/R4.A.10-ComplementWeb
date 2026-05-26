---
title: TD3 &ndash; Tests unitaires, Couche Service
subtitle: PHPUnit, Architecture
layout: tutorial
lang: fr
---

L'objectif de cette séance est de vous former à la mise en place de tests unitaires sur une application web PHP.

Nous allons voir que pour qu'une application soit testable efficacement, il faut que celle-ci présente une architecture réfléchie permettant de véritablement tester une partie du code (une classe) de manière indépendante. Pour cela,
il faudra appliquer les différents principes **SOLID** que vous avez étudié cette année, notamment dans le cours de **qualité de développement**.

Pour illustrer tout cela, nous allons donc repartir du code de l'application **The Feed** obtenu à l'issue du 
[TD2 de complément web]({{site.baseurl}}/tutorials/tutorial2). Vous devez donc avoir terminé ce TD avant de commencer celui-ci.

Il est fortement recommandé de réaliser le TP sur **PHPStorm** afin de profiter des différentes fonctionnalités de couplage avec PHPUnit qu'offre cet IDE.

**Note importante** : Lors du TD, vous utiliserez diverses dépendances dans vos classes. Parfois, il vous sera explicitement cité la ligne d'import de cette dépendance (avec un `use`). Si ce n'est pas le cas, il faudra importer vous-même la bonne classe. Dans ce cas, `PHPStorm` peut vous aider ! La classe dont l'import est manquant apparaîtra en surbrillance avec un fond jaune. Vous pouvez alors passer votre curseur sur le nom de la classe et cliquer sur `Import class`.

## Découverte de PHPUnit

**PHPUnit** est une librairie PHP permettant de réaliser des tests unitaires sur une application PHP. Son fonctionnement est similaire à **JUnit** que vous utilisez notamment en cours de Tests.

PHPUnit intègre par défaut les outils nécessaires à l'utilisation de **mocks** ainsi que l'analyse de la **couverture de code**. Nous aurons l'occasion de revenir sur ces notions au cours du TD.

### Installation et configuration

Comme toute librairie PHP, **PHPUnit** s'installe à l'aide de **composer**.

<div class="exercise">

1. Exécutez la commande suivante dans le **terminal docker** ouvert au niveau de la racine
   de votre projet :

   ```bash
   composer require phpunit/phpunit
   ```

   S'il vous est demandé si vous préférez placer le package dans `require-dev`, vous pouvez répondre `yes`. Cela permet de différencier dans le `composer.json` les dépendances liées au fonctionnement global de l'application (celles de la section `require`) et celles exclusivement liées à la phase de développement, aux tests, etc. (comme `phpunit`). La commande `composer install` installe toutes les dépendances, mais si on utilise l'option `--no-dev`, seules les dépendances de `require` seront installées.
   
2. Nous allons maintenant configurer `PHPUnit` et créer les dossiers nécessaires à son fonctionnement. Commencez par créer un fichier `phpunit.xml` à la racine du projet et complétez-le avec le contenu suivant :

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
           bootstrap="vendor/autoload.php"
           cacheDirectory=".phpunit.cache"
           executionOrder="depends,defects"
           displayDetailsOnPhpunitDeprecations="true"
           failOnRisky="true"
           failOnWarning="true">

       <testsuites>
           <testsuite name="unit">
               <directory>./tests/unit</directory>
           </testsuite>
       </testsuites>

       <source ignoreIndirectDeprecations="true" restrictNotices="true" restrictWarnings="true">
           <include>
               <directory>src</directory>
           </include>
       </source>

       <coverage>
           <report>
               <clover outputFile="reports/coverage/coverage.xml"/>
           </report>
       </coverage>
   </phpunit>
   ```

    Analysons un peu le contenu de ce fichier de configuration :

    * Le paramètre `bootstrap` permet d'indiquer où se trouve le fichier d'autoloading, nécessaire pour charger le bon fichier à partir de son `namespace`.

    * Le paramètre `cacheDirectory` permet de définir la localisation du dossier de cache utilisé par `PHPUnit`.

    * La section `testsuites` nous permet de configurer plusieurs batteries de tests : tests unitaires, tests d'intégration, etc. Pour ce TD, nous n'utiliserons que des tests unitaires. On configure le dossier de test **en dehors du code source du projet** dans un dossier `tests/units`.

    * La section `source` permet d'indiquer où se situe le code source de notre projet (le code qui sera testé). Ici, on indique donc `src`.

    * Enfin, la section `coverage` permet de définir où sera généré le rapport concernant la **couverture de code** (dont nous reparlerons plus tard).

3. À la racine de votre projet, créez un dossier `tests` puis, à l'intérieur, un dossier `unit`. Ensuite, afin de bénéficier d'un *namespace* en *CamelCase* (pour plus de confort) comme pour le reste du projet, modifiez le fichier `composer.json` dans le but de spécifier le bon *namespace* dans la section `autoload` :

   ```json
   {
        "autoload": {
            "psr-4": {
                "TheFeed\\": "src",
                "Tests\\Unit\\": "tests/unit" //A ajouter
            }
        },
        ...
   }
   ```

   Ensuite, exécutez la commande suivante (toujours dans le terminal docker ouvert au niveau de la racine
   de votre projet), afin de mettre à jour le fichier `autoloader.php` :

   ```bash
   composer dump-autoload
   ```

4. Toujours dans ce même terminal, exécutez la commande suivante, qui permet d'exécuter les tests :

   ```bash
   php -d xdebug.mode=coverage ./vendor/bin/phpunit
   ```

    Avec le projet sous Docker, cela peut éventuellement prendre du temps à s'exécuter.

    Il n'y a pas de résultat pour le moment, mais c'est normal, vous n'avez pas encore de tests !

5. Deux dossiers ont été générés : `reports` et `.phpunit.cache`. Ces répertoires ne doivent pas être versionnés, excluez-les donc dans votre fichier `.gitignore`.
</div>

Il est bien sûr possible de configurer votre **IDE** pour lancer les tests depuis l'interface plutôt qu'en ligne de commande, mais la **conteneurisation** du projet rend cela un peu plus compliqué à mettre en place. Pour ce TD, nous nous contenterons donc de lancer les tests avec une commande.

### Une première classe de test

Un **test unitaire** se traduit par une fonction dans une classe dédiée qui exécute différents tests sur des objets de l'application. Il s'agit de vérifier, par exemple, si le retour d'une fonction avec un paramétrage spécifique est bien conforme aux attentes et aux spécifications. On peut aussi tester si l'exécution d'un code déclenche des exceptions.

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
 
Cette liste est bien sûr non exhaustive et vous pourrez explorer plus en détail toutes les assertions disponibles sur la [documentation officielle](https://docs.phpunit.de/en/10.5/assertions.html).

Une autre méthode bien pratique est aussi `expectException(exceptionClass)`. Cette méthode est à utiliser avant 
d'exécuter un bout de code et permet de vérifier que l'exception précisée a bien été levée. On peut aussi utiliser `expectExceptionMessage(message)` ou bien `expectExceptionCode(code)` pour vérifier le message et le code de l'exception levée.

Enfin, dans chaque classe de test, il est possible de redéfinir deux méthodes bien utiles :

* `setUp` : cette méthode est exécutée avant chaque méthode de test. Elle permet, par exemple, de configurer
certaines variables afin de les rendre vierges avant d'exécuter chaque test.

* `tearDown` : cette méthode est exécutée après chaque méthode de test. Elle doit permettre de nettoyer les effets de bord occasionnés par chaque test (par exemple : nettoyer la base de données de tests).

Il existe également deux versions **statiques** de ces méthodes : `setUpBeforeClass` et `tearDownAfterClass` qui sont exécutées respectivement avant l'exécution du premier test et après l'exécution du dernier test (donc, une seule fois).

Prenons l'exemple de la classe suivante :

```php
namespace TheFeed\Lib;

use Exception;

class Ensemble {

    private array $tableauEnsemble;

    public function __construct() {
        $this->tableauEnsemble = [];
    }

    public function contient(mixed $valeur): bool {
        return in_array($valeur, $this->tableauEnsemble);
    }

    public function ajouter(mixed $valeur) : void {
        if(!$this->contient($valeur)) {
            $this->tableauEnsemble[] = $valeur;
        }
    }

    public function getTaille(): int {
        return count($this->tableauEnsemble);
    }

    public function estVide(): bool {
        return $this->getTaille() == 0;
    }

    public function pop(): mixed {
        if($this->estVide()) {
            throw new Exception("L'ensemble est vide!");
        }
        return array_pop($this->tableauEnsemble);
    }
}
```

On pourrait alors écrire la classe de test suivante :

```php
namespace Tests\Unit;

use Exception;
use PHPUnit\Framework\TestCase;
use TheFeed\Lib\Ensemble;

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

1. Dans le dossier `src/Lib`, créez la classe `Ensemble` puis, dans `test\unit` la classe `EnsembleTest` en copiant le code donné ci-dessus.

2. Lancez les tests unitaires (avec la commande donnée précédemment, toujours dans le terminal docker à la racine de votre projet) et observez les résultats.

3. Glissez une erreur dans le code de la classe `Ensemble` et relancez les tests. Observez la sortie. Remettez tout en ordre (enlevez le bug).

</div>

**Attention** ! Le nom de toutes vos classes de tests doit se terminer par `Test` ! (Sinon la classe ne sera pas prise en compte lors de l'exécution de tests). Aussi, chaque nom de méthode de test doit soit débuter par `test` soit posséder l'attribut `#[Test]` :

```php
namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\Test;

//Le nom termine par "Test"
class MonTest extends TestCase {

    //Sera exécuté, car est préfixé par "test"
    public function testCoucou() {

    }

    //Ne sera pas exécuté
    public function coucou1() {

    }

    //Sera exécuté, car possède l'attribut #[Test]
    #[Test]
    public function coucou2() {

    }
   
}
```

<!-- Afin de prendre en main l'outil, vous allez créer une classe simple puis une classe de test permettant de la tester.

<div class="exercise">

1. Créez une classe `Calculatrice` dans le dossier `Test`. Cette classe doit gérer un attribut `$resultat` initialisé à `0` (qui représente le résultat courant). Les différentes méthodes de cette classe devront permettre de modifier ce résultat.

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
focaliser sur l'écriture de tests. Si vous avez des difficultés, n'hésitez pas à demander des précisions à votre enseignant.  -->

## La couche Service

Nous avons réalisé des premiers tests simples afin de comprendre le fonctionnement de **PHPUnit**. Maintenant, nous allons mettre en œuvre cet outil de manière plus concrète en testant notre application web. Néanmoins, vous allez constater un problème majeur : l'application n'est pas testable en l'état.

En effet, pour tester, nous avons besoin de faire des **assertions** sur des résultats (ou des comportements) spécifiques obtenus lors de l'exécution d'une fonctionnalité. Actuellement, les fonctionnalités sont réalisées par les **contrôleurs**.
Or, les différentes fonctions des contrôleurs renvoient un objet `Response` qui n'est pas bien exploitable. Cet objet contient le code complet de la page `HTML` renvoyée au client, ce qui n'est donc pas (ou difficilement) testable en l'état. Ce problème est lié au fait que les **contrôleurs** ont beaucoup trop de responsabilités et ne répartissent pas le travail. De l'extérieur, ils agissent comme une boîte noire et il est alors difficile de récupérer des données intéressantes pour les tests. Il semble aussi difficile de fournir des données aux contrôleurs car ceux-ci se servent directement des données de la requête HTTP.

Une **application web** comme tout **logiciel** peut être organisé selon une architecture qui sépare de manière optimisée les classes du programme en **couches** selon leur **rôle**.

Dans un logiciel, on peut trouver différents types de **couche**. Par exemple (sans être exhaustif) :

* La couche **présentation** qui permet de gérer les différentes parties graphiques et surtout l'interaction avec l'utilisateur. Pour une application web, cela va correspondre à la partie contenant les **vues**, c'est-à-dire les fichiers responsables de générer le code HTML (et également les ressources JavaScript, CSS, etc.)

* La couche **métier** qui contient le cœur de l'application, à savoir les différentes **entités** manipulées (essentiellement, les classes dans `DataObject`) ainsi que des classes de **services** qui permettent de manipuler ces entités et d'implémenter la **partie logique** de votre application.

* La couche **application** qui permet de faire le lien entre la couche **présentation** et la couche **métier**. Elle contient les différents **contrôleurs** dont le rôle est de gérer les **évènements** de l'interface, de vérifier les droits d'accès, d'interagir avec la couche **métier** et de transmettre les résultats obtenus à l'IHM. Dans une application web, les événements sont les requêtes reçues par l'application web (et ses paramètres, via l'URL). Une requête est décomposée puis la bonne méthode du contrôleur est exécutée avec les paramètres correspondants.

* La couche **de persistance** (stockage) qui permet de gérer la **persistance des données** à travers une forme de stockage configurée (base de données, fichier...). Son rôle va donc être de sauvegarder et charger les données des différentes entités de la couche **métier**. C'est cette couche qui va contenir les différents **repositories**.

* Parfois, une couche **réseau** dans le cadre d'une application **client/serveur**. Cette couche va gérer la transmission des données entre deux programmes (avec des sockets, etc.). Dans une application web, il n'y a pas besoin de gérer explicitement cette couche qui est prise en charge par le protocole **HTTP** ou **HTTPS**.

Bref, ces différentes couches permettent de définir et de séparer les zones d'activités du logiciel. Tout l'intérêt est de faire communiquer ces couches entre elles.

La connaissance de ces couches ne donne pas encore la structure de l'application : il faut choisir une architecture qui permet de les structurer, de les exploiter et de définir comment elles communiquent concrètement. Il en existe plusieurs, et pour une application web (comme celle manipulée dans ce TP) on peut choisir l'architecture `MVC` que vous connaissez déjà.

Cette architecture permet de séparer les entités, les vues et les contrôleurs de l'application et de les faire communiquer :

* La partie **modèle** (M) stocke les différentes **entités** (nos `DataObject`) que l'on retrouve dans la couche **métier** ainsi que des classes liées à la couche **stockage** (les classes type `Repository`) et encapsule la **logique métier** (vérification des données, déclenchement d'opérations...). 

* Les différentes **vues** (V) correspondent à la couche **présentation**.

* Les différents **contrôleurs** (C) gèrent la couche **application** : ils reçoivent les requêtes, vérifient les droits d'accès (est-ce que l'utilisateur courant a le droit d'exécuter cette requête ?), communique avec la partie "modèle" afin de déclencher des opérations, effectuer des validations, récupérer des données, puis se sert de la partie "vues" pour retourner un résultat à l'utilisateur (par exemple, la page web).

Néanmoins, il n'est pas explicitement fait mention des **services** dans cette architecture. En fait, dans notre implémentation du `MVC` que nous avons réalisée jusqu'ici, le **contrôleur** a le rôle des **services** et effectue une grande partie (voir la totalité) de la logique métier et déborde ainsi un peu trop sur la partie modèle. Cela peut vite créer des contrôleurs énormes (aussi appelés **fat controllers)** ayant beaucoup trop de responsabilités. C'est pourquoi il est possible de venir placer une couche **service** entre les **contrôleurs**, les **entités** et la couche **stockage**. Ainsi, le contrôleur n'effectue pas de logique métier et on a une séparation plus forte.

Dans cette logique, la couche **métier** serait alors séparée entre la partie contenant nos **entités** et les **services** qui manipulent ces entités. Ainsi, les différents **contrôleurs** n'interagissent pas directement avec les entités, mais plutôt avec des **services**. On pourrait alors qualifier les services de **couche de validation** voir de **couche logique** (car elle effectue d'autres opérations en plus de la validation des données).

Les interactions se dérouleraient alors dans ce sens : Vue ↔ Contrôleur ↔ Services ↔ Modèle (entités, repositories) au lieu de Vue ↔ Contrôleur ↔ Modèle.

Dans ce cas, on étend l'architecture classique `MVC` et on pourrait alors parler de `MVCS` où le `S` désignerait les **services**. Il n'y a pas de règles précise quant à l'utilisation de telle ou telle architecture, mais dans le cas de notre application, nous allons plutôt tendre vers une architecture utilisant les services. Créer une telle séparation permettra alors de pouvoir tester la logique métier indépendamment au travers des tests unitaires sur les **services** plutôt que sur les **contrôleurs**. D'une part, il sera alors possible de passer des données à ces services autrement que par une requête HTTP, et d'autre part, on pourra également obtenir un résultat exploitable et pas une page web complète.

### Un service pour gérer les publications

Nous allons commencer à extraire la logique métier de notre application en créant un **service** pour gérer les différentes **publications**. Au-delà d'alléger le contrôleur des publications du code métier, nous allons aussi pouvoir considérablement réduire la partie dédiée à la gestion des erreurs !

<div class="exercise">

1. Créez un dossier `Service` dans `src`.

2. Dans ce nouveau dossier, créez une classe `PublicationService`.

3. Créez une méthode 
   ```php
   public function recupererPublications(): array
   ```
   qui permet de récupérer toutes les publications depuis le *repository* correspondant **et de les renvoyer**. Vous pouvez directement copier le code correspondant depuis la méthode `afficherListe` de `ControleurPublication`.

4. Modifiez le code de la méthode `afficherListe` de `ControleurPublication` pour utiliser votre nouveau **service** au lieu de faire appel au *repository*.

5. Vérifiez que votre site fonctionne toujours bien.

</div>

Bien, vous avez créé votre premier service ! Mais l'intérêt d'avoir séparé ce petit bout de code n’apparaît pas encore clairement. Nous allons donc pousser les choses un peu plus loin lors de la prochaine étape.

Nous allons nous intéresser à la création des publications. Actuellement, dès qu'il détecte une erreur dans la formation du message, le **contrôleur** ajoute un message flash d'erreur et redirige l'utilisateur. Ces vérifications font partie de la logique **métier** et peuvent être gérées à l'aide d'exceptions. La logique à appliquer serait plutôt la suivante :

* Le contrôleur vérifie les droits d'accès (est-ce que l'utilisateur est connecté, est-ce qu'il a le droit d'accéder à cette route ?) puis récupère les valeurs des paramètres depuis la requête et les passe au service.
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

2. Dans `PublicationService`, créez une méthode `creerPublication` qui prend en paramètre un **idUtilisateur** et un **message**. La méthode doit déplacer et réadapter (en grande partie) le code de la méthode `creerDepuisFormulaire` de `ControleurPublication` :

   ```php
   public function creerPublication(?int $idUtilisateur, ?string $message) {
       $utilisateur = new UtilisateurRepository()->recupererParClePrimaire($idUtilisateur);
       if(is_null($utilisateur)) {
           MessageFlash::ajouter("error", "Utilisateur inexistant!");
           return ControleurPublication::rediriger('afficherListe');
       }
       if (is_null($message) || $message == "") {
           MessageFlash::ajouter("error", "Le message ne peut pas être vide!");
           return ControleurPublication::rediriger('afficherListe');
       }
       if (strlen($message) > 250) {
           MessageFlash::ajouter("error", "Le message ne peut pas dépasser 250 caractères!");
           return ControleurPublication::rediriger('afficherListe');
       }

       $publication = Publication::construire($message, $utilisateur);
       (new PublicationRepository())->ajouter($publication);
   }
   ```

    **Note :** Si vous avez une erreur de l'IDE *`rediriger` has protected
    visibility*, ce n'est pas grave, elle sera réglée avec la prochaine question.

    Vous aurez aussi probablement des erreurs liées à ce que retourne la méthode, mais n'y prêtez pas attention pour l'instant.

3. Dans la nouvelle méthode `creerPublication`, remplacez toutes les lignes qui ajoutent un message flash et redirigent l'utilisateur par le déclenchement d'une **ServiceException** contenant le message flash initialement prévu comme message flash. La syntaxe est la suivante :

   ```php
   throw new ServiceException("Mon message d'erreur!");
   ```

   Enfin, vous pourrez changer le type de retour de la méthode par `void`.

4. Modifiez la méthode `creerDepuisFormulaire` de `ControleurPublication` afin d'utiliser le service de publications et de gérer l'exception. Dans le cas où une **ServiceException** est interceptée, vous devez ajouter le message de l'exception comme message flash puis rediriger l'utilisateur vers la route `afficherListe`. Globalement, cela doit ressembler à quelque chose comme ça :

   ```php
   public static function creerDepuisFormulaire() : Response
   {
       //La gestion des droits d'accès aux routes est de la responsabilité du contrôleur
       if(!ConnexionUtilisateur::estConnecte()) {
            MessageFlash::ajouter("error", "Il faut être connecté pour publier!");
            return ControleurPublication::rediriger('afficherFormulaireConnexion');
        }
       $idUtilisateurConnecte = ConnexionUtilisateur::getIdUtilisateurConnecte();
       $message = $_POST['message'];
       try {
           //Utilisation du service
           //Les règles métiers liées aux publications sont gérées dans le service correspondant
       }
       catch(ServiceException $e) {
           //Ajout du message flash
       }

       return ControleurPublication::rediriger('afficherListe');
   }
   ```

    *Aide :* Allez voir si nécessaire la 
    [documentation de la classe `Exception`](https://www.php.net/manual/fr/class.exception.php).

5. Comme d'habitude, vérifiez votre application pour vous assurer que rien n'a été cassé.
</div>

Ici, la séparation entre la couche **service** et **application** est bien visible ! Le contrôleur récupère les éléments nécessaires depuis la requête et le service, lui n'interagit pas directement avec les données de la requête (pas d'accès à `$_POST`) et ne s'intéresse pas aux notions liées à la couche **présentation** (pas de redirection, pas de sélection de vue, pas de messages flash...). Il agit comme un module quasi indépendant des autres couches.

Concernant les droits d'accès simples (par exemple, vérifier que l'utilisateur est connecté, qu'il a un rôle suffisant pour visualiser la page souhaitée, etc), cela relève de la **responsabilité du contrôleur** qui prend en charge la requête. C'est lui qui vérifie que l'utilisateur a le droit d'accéder à une **route** donnée. Cependant, selon la situation, certains droits peuvent aussi être vérifiés du côté des services, si cela dépend de la logique métier. Par exemple, si on avait une fonctionnalité permettant de **supprimer une publication**, il faudrait vérifier que l'utilisateur est bien propriétaire de la publication (ou bien qu'il est administrateur et qu'il a donc tous les droits...). Cette vérification pourrait alors plutôt se faire du côté du **service**, dans la méthode qui permet de supprimer une publication.

En résumé :
* Si un droit d'accès ne relève que de l'accès à une route donnée, on gère cela au niveau du contrôleur (comme dans `creerDepuisFormulaire` de `ControleurPublication`).
* Si le droit d'accus relève plutôt de la logique métier (ex : vérifier que l'utilisateur qui modifie une ressource en est bien le propriétaire, ou qu'il est administrateur), cela peut se faire du côté du service.

Du côté de Symfony (que vous étudierez l'année prochaine), un système sophistiqué de "**voters**" permet de déléguer la gestion des droits d'accès à des services de vérification de droits dédiés qui sont généralement appelés dans le contrôleur et les vues, mais qui peuvent aussi être utilisés ailleurs.

Concernant `ServiceException`, pour ne pas allourdir le TP, nous allons quasi-exclusivement l'utiliser pour gérer toutes les erreurs. Mais en réalité, il faudrait créer toute une **famille d'exceptions spécialisées** (qui héritent de `ServiceException`, par exemple) pour permettre de mieux cibler le problème remonté (par exemple `ContentTooLongException`, `RessourceNotFoundException`, etc). On pourrait aussi leur associer un **code d'erreur** unique.

### Un service pour gérer les utilisateurs

Nous allons continuer dans notre lancée et extraire la partie **métier** du contrôleur gérant les fonctionnalités liées aux utilisateurs.

Pour les fonctions qui permettent d'afficher la page de connexion ou d'inscription, il n'y a pas besoin de créer une fonctionnalité sur un service, car il s'agit juste d'un affichage de page simple.

Débutons avec la création d'un nouvel utilisateur. 

<div class="exercise">

1. Créez une classe `UtilisateurService` dans le dossier `Service`.

2. Ajoutez une méthode `creerUtilisateur` qui prend en paramètre un *login*, un *mot de passe*, une *adresse mail* et enfin un tableau de *données de l'image de profil*. Cette méthode reprendra en grande partie le code de `creerDepuisFormulaire` du contrôleur `ControleurUtilisateur`.

    Comme d'habitude, **il ne faudra pas faire appels aux variables liées à la requête dans cette méthode** (`$_POST`, `$_FILES`, etc.). Ces données vous sont fournies par le contrôleur et peuvent être `null`. Il faudra d'ailleurs penser à vérifier si ces valeurs sont nulles ou non. La méthode ne doit rien retourner (simplement créer l'utilisateur) et lever des `ServiceException` si différentes contraintes sont violées (taille du login, mot de passe, format de l'adresse mail, etc.). Le paramètre `$donneesPhotoDeProfil` correspond au tableau obtenu par lecture de `$_FILES["..."]`.

   ```php
   public function creerUtilisateur(?string $login, ?string $motDePasse, ?string $email, ?array $donneesPhotoDeProfil) : void {
       //TO-DO
       //Verifier que les attributs ne sont pas null
       //Verifier la taille du login
       //Verifier la validité du mot de passe
       //Verifier le format de l'adresse mail
       //Verifier que l'utilisateur n'existe pas déjà
       //Verifier que l'adresse mail n'est pas prise
       //Verifier extension photo de profil
       //Enregistrer la photo de profil
       //Chiffrer le mot de passe
       //Enregistrer l'utilisateur...
   }
   ```

3. Adaptez la méthode `creerDepuisFormulaire` de `ControleurUtilisateur` pour utiliser votre nouveau service. Attention, il ne faut plus vérifier ici le fait qu'une donnée est nulle ou non (on doit pouvoir passer une donnée nulle au service). En remplacement, vous pouvez utiliser l'**expression** suivante :

   ```php
   // Si $_POST["donnee"] n'existe pas, $donnee prend la valeur null.
   $donnee = $_POST["donnee"] ?? null; 
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
       //Rediriger sur la page d'accueil (route afficherListe)
   }
   ```

   Comme tout le monde peut s'inscrire, il n'y a pas de droits d'accès à gérer ici.

4. Comme toujours, vérifiez l'état de votre application.

</div>

Maintenant, passons au cas de la fonctionnalité permettant d'afficher une page personnelle.

Afin de diminuer le **couplage** entre nos classes, nous allons progressivement faire en sorte que seuls les **services** utilisent les **repositories** et que les contrôleurs utilisent les **services** (et donc ne se servent plus des repositories).

La méthode `afficherPublications` effectue deux actions : récupération de l'utilisateur concerné d'une part (pour afficher son login) et, d'autre part, récupération des publications de l'utilisateur. Il va donc y avoir deux actions à effectuer, dans deux services différents.

<div class="exercise">

1.  Dans la classe `UtilisateurService`, créez une méthode `recupererUtilisateurOuNullParId` qui prend en paramètre un identifiant d'utilisateur et renvoie l'utilisateur ciblé par cet identifiant (en se servant du *repository*), ou `null`, s'il n'existe pas :

    ```php
    public function recupererUtilisateurOuNullParId(?int $idUtilisateur) : ?Utilisateur {
        $utilisateur = ...
        return $utilisateur;
    }
    ```

    On utilisera cette méthode dans le cas où on accepte que l'utilisateur recherché n'existe pas et que la fonction renvoie donc `null`, sans déclencher d'exception.


2. Toujours dans `UtilisateurService`, créez une méthode `recupererUtilisateurExistantParId` qui prend en paramètre un identifiant d'utilisateur et renvoie l'utilisateur ciblé par cet identifiant. Si l'utilisateur n'existe pas, une `ServiceException` est levée qui doit signaler que l'utilisateur n'existe pas. Évitez la duplication de code ou vous servant de la méthode codée lors de la question précédente :

   ```php
   public function recupererUtilisateurExistantParId(?int $idUtilisateur) : Utilisateur {
       $utilisateur = ...
       //Lève une exception si l'utilisateur n'existe pas...
       return $utilisateur;
   }
   ```

   Dans la plupart des cas où on souhaite absolument vérifier que l'utilisateur recherché existe avant de poursuivre le traitement, on utilisera cette méthode.

3. Mettez à jour le code de `creerPublication` de `Publicationservice` afin de ne plus utiliser `UtilisateurRepository`, mais plutôt `UtilisateurService` et sa méthode `recupererUtilisateurExistantParId`.

4. La partie qui a pour but de récupérer des publications d'un utilisateur doit plutôt être codée au niveau de la classe `PublicationService`. Ajoutez donc une méthode `recupererPublicationsUtilisateur(?int $idUtilisateur) : array` à ce service qui reprend en partie le code de `afficherPublications` qui récupère les publications en faisant appel au repository. La méthode doit :
    * Récupérer l'utilisateur ciblé par l'identifiant (grâce à `UtilisateurService`) afin d'être sûr qu'il existe.
    * Récupérer les publications de l'utilisateur ciblé.

4. {% raw %}
    **Si vous n'aviez pas fait le bonus du dernier TD** : ajoutez une vue `utilisateur/page_perso.html.twig` qui étend le template `publication/feed.html.twig` et modifie simplement `{% block page_title %}` pour que le titre de la page devienne soit `Page perso de login_de_l_utilisateur`.
   {% endraw %}

5. Remplacez le code de `afficherPublications` de `ControleurUtilisateur` afin d'utiliser vos nouvelles méthodes `recupererPublicationsUtilisateur` de `PublicationService` pour récupérer les publications de l'utilisateur ciblé puis `recupererUtilisateurParId` de `UtilisateurService` pour obtenir les données de l'utilisateur. Enfin, vous devrez passer le login de l'utilisateur récupéré à la vue `utilisateur/page_perso.html.twig`, en plus des publications, afin que le titre de la page personnelle s'affiche correctement. Veillez à bien traiter une éventuelle `ServiceException`.

6. Vérifiez que tout fonctionne bien. Notamment, vérifiez qu'un message flash est bien affiché quand on essaye de visiter la page personnelle d'un utilisateur qui n'existe pas.

</div>

Si tout marche bien, vous commencez à maîtriser le processus ! Terminons donc le travail avec ce contrôleur avant de passer à la seconde phase de tests.

<div class="exercise">

1. En vous inspirant du travail réalisé lors des questions précédentes, adaptez la méthode de l'action `connecter` du contrôleur afin de faire migrer une partie de la logique du code vers une méthode `authentifier` de la classe `UtilisateurService` :

    ```php
    public function authentifier(?string $login, ?string $motDePasse) : Utilisateur {

    }
    ```
    Cette méthode (qui a pour but d'être appelée par le contrôleur) doit faire les diverses vérifications requises (utilisateur existant, mot de passe, etc) et lever une `ServiceException` si une vérification échoue. Si tout se passe bien, elle renvoie l'utilisateur correspondant au login donné en paramètre.

    Attention, l'appel à `ConnexionUtilisateur::connecter` doit toujours se faire du côté de l'action `connecter` du contrôleur : en effet, cette fonction va permettre de stocker l'identifiant de l'utilisateur connecté dans la session, ce qui n'est à priori pas de la logique métier (on ne va pas faire de tests dessus).

2. Généralement, ce n'est pas une bonne pratique d'indiquer qu'un login n'existe pas lorsqu'un utilisateur tente de se connecter avec un compte qui n'est pas enregistré. Dans la majorité des sites professionnels, on va plutôt indiquer que **les identifiants sont invalides** si le login n'existe pas et/ou que le mot de passe ne correspond pas. Faites les modifications nécessaires dans `authentifier` pour implémenter ce comportement.

3. Vérifiez le fonctionnement de l'application.

</div>

### Premiers tests sur l'application

Maintenant que la partie **métier** de notre application est (partiellement) extraite, nous allons pouvoir faire nos premiers tests.

<div class="exercise">

1. Créez une classe de test `PublicationServiceTest` (qui étend `TestCase`) dans le répertoire `tests\unit` :

    ```php
    namespace Tests\Unit;

    use PHPUnit\Framework\Attributes\AllowMockObjectsWithoutExpectations;
    use PHPUnit\Framework\TestCase;

    #[AllowMockObjectsWithoutExpectations]
    class PublicationServiceTest extends TestCase
    {

    }
    ```

    L'attribut `AllowMockObjectsWithoutExpectations` nous permettra d'ignorer des warnings liés à l'utilisation de mocks "simples" (qui ne sont pas totalement exploités/configurés) lors des tests.

2. Ajoutez un attribut `service` qui sera ré-instancié par un `PublicationService` avant chaque test (via le `setUp`).

3. Créez un test `testCreerPublicationUtilisateurInexistant` qui teste de créer une publication en précisant un identifiant d'un utilisateur qui n'est pas enregistré dans la base (par exemple, l'identifiant `-1`). Votre test doit vérifier qu'une `ServiceException` est bien levée et que le message d'erreur correspond bien à celui attendu (vous pouvez aller voir le test `testPop` de `EnsembleTest` pour voir comment faire). 

4. Créez un test `testCreerPublicationVide` qui teste de créer une publication sans aucun contenu. Attention, ici, il faut préciser un identifiant d'utilisateur valide (qui est enregistré dans la base). Comme à la question précédente, votre test doit vérifier qu'une `ServiceException` est bien levée et que le message d'erreur correspond bien à celui attendu.

5. Créez un test `testCreerPublicationTropGrande` qui teste de créer une publication avec un contenu dépassant 250 caractères. Pour vous faciliter la tâche, vous pouvez utiliser la fonction `str_repeat(chaine, nb)` qui permet d'obtenir une chaîne de caractères correspondant à `nb` répétitions de la chaîne de caractères `chaine`. Mêmes vérifications à faire que précédemment.

6. Créez un test `testNombrePublications` qui teste la récupération toutes les publications (via le service) et vérifie le nombre de publications récupérées (rappel : une méthode `assertCount` permet de tester la taille d'une collection/tableau). Il faudra donc compter combien de publications il y a dans votre base au préalable.

7. Créez un test `testNombrePublicationsUtilisateur` qui teste la récupération de toutes les publications d'un utilisateur. Il faudra préciser un identifiant d'utilisateur existant et vérifier que le compte est bon.

8. Enfin, créez un test `testNombrePublicationsUtilisateurInexistant` qui teste la récupération de toutes les publications d'un utilisateur inexistant (par exemple, `-1`). Ici aussi, une exception doit être levée (car l'utilisateur est inexistant).

9. Si ce n'est pas déjà fait, lancez les tests unitaires et vérifiez que tous les tests passent !

</div>

Relisez les tests que vous venez d'écrire. Ne remarquez-vous pas quelques éléments étranges et même dérangeants ? Pensez sur le long terme. Nous reviendrons sur tout cela assez vite et nous n'écrirons pas de tests sur le service des utilisateurs pour le moment.

Dans les tests que nous venons d'effectuer, nous vérifions le message de l'exception soulevée, notamment, car un même appel de méthode peut lever différentes `ServiceException`, ce qui nous permet donc de les différencier. Une meilleure approche serait de créer plusieurs types de `ServiceException` selon le type d'erreur et/ou ajouter un **code d'erreur** à l'exception. La classe `Exception` (dont hérite `ServiceException`) permet de définir un code d'erreur lors de l'initialisation de l'exception (via le constructeur). Pour plus de qualité, on pourrait donc adapter `ServiceException` dans ce sens puis appeler `expectExceptionCode` et/ou créer des familles d'exceptions plus spécialisées. Dans le dernier TD, nous gérerons justement des codes d'erreurs sur `ServiceException` afin que notre API puisse répondre avec un code de status HTTP adéquat.

### Couverture de code et portée des tests

Il est temps pour vous de découvrir un outil fort utile pour pouvoir mesurer (en partie) la qualité de vos tests : la **couverture de code**. Cet outil permet de réaliser des statistiques sur les portions de code que vos tests permettent de tester. Après l'exécution des tests, on peut alors visualiser le pourcentage de code testé sur une classe et on peut même aller dans le détail en visualisant les lignes de code qui ont été franchies par les tests et celles qui n'ont jamais été franchies.

Il est difficile de savoir jusqu'où tester une application. Le but des tests n'est en réalité pas de vérifier que tout fonctionne, mais plutôt de trouver des dysfonctionnements. Le nombre et la variété des tests à produire dépendent donc fortement du contexte. Néanmoins, une couverture de code de **100%** (donc, des tests qui passent au moins une fois par chaque ligne de code du programme) est un premier indicateur de la qualité des tests. Dans ce cas, on peut alors considérer qu'il y a un nombre assez important de tests et qu'ils sont assez variés. Néanmoins, cela ne signifie pas nécessairement qu'il faut s'arrêter de tester à partir de là. Il faut prévoir le plus de scénarios possibles (deux scénarios différents peuvent déclencher les mêmes lignes de code).

Il faut également se poser la question de **la portée** des tests. Doit-on (peut-on ?) tout tester ? Par exemple, est-il pertinent d'écrire des tests unitaires pour les contrôleurs dans leur état actuel vu que leur rôle se limite à la réalisation d'un pont entre la couche présentation (les vues, la requête HTTP) et la couche service ? Cela relève plutôt de tests réalisés directement sur l'interface (ce que vous faisiez jusqu'ici). Il est possible de mettre en place des tests unitaires sur à peu près tous les éléments du programme, mais généralement, on va plutôt se concentrer sur la partie métier avec les **services** puis la partie **modèle**. Obtenir une couverture proche de 100% sur ces parties constitue un premier critère de qualité.

<!--
<div class="exercise">

1. Si vous travaillez sur votre machine, vérifiez que l'extension `xdebug` est installée. Pour cela, cliquez sur `Run` puis `Edit Configurations`. Au niveau de la configuration de `Tests Unitaires`, vérifiez que la case `Prefered Covered Engine` est bien réglée sur `XDdebug`. Si un message d'erreur "XDebug extension is not installed" est présent, il va donc falloir installer cette extension. Pour obtenir les détails d'installation pour votre machine, vous pouvez notamment utiliser [cette page](https://xdebug.org/wizard).

2. Lancez vos tests unitaires **avec couverture de code**. Pour cela, rendez-vous dans le menu `Run` puis `Run ... with  Coverage`.

   *Aide :* Si `Run ... with  Coverage` tourne longtemps puis s'arrête avec une erreur `Memory exhausted`, il faut dans *PHPStorm* faire clic droit sur le dossier `src/` → `Mark Directory As` → `Sources Root`.

3. Un panneau d'analyse s'ouvre à droite. Explorez son contenu. Si rien n'est affiché sur ce panneau, cliquez sur "show uncommited files".

4. Parcourez les différents fichiers de l'application (notamment `PublicationService`) et observez les lignes de code. Au niveau des numéros de lignes, une section verte indique que la ligne a été parcourue (et bien sûr, une section rouge indique l'inverse).

</div>
-->

<div class="exercise">

1. Après chaque lancement des tests unitaires, un fichier de **couverture de code** est généré par PHPUnit. Il s'agit du fichier `reports/coverage.xml`. En l'état, ce fichier est assez illisible, mais **PHPStorm** va nous permettre d'en analyser les données facilement. Si vous n'utilisez pas **PHPStorm**, rendez-vous au point 6 pour une solution alternative.

2. Sur **PHPStorm**, ouvrez le menu de couverture de code en cliquant sur `View` → `Tool Windows` → `Coverage`. Un panneau s'ouvre à droite (il peut être fermé et rouvert grâce à l'icône de bouclier). À l'intérieur de ce menu, cliquez sur **Import a report collected in CI from disk**. Choisissez ensuite le fichier `reports/coverage/coverage.xml`.

3. **PHPStorm** fait un rapport vis-à-vis du contenu du fichier. Explorez son contenu. Il est notamment indiqué les fichiers qui ont été sollicités par les tests, le pourcentage de lignes de codes couvertes, etc.

4. Parcourez les différents fichiers de l'application (notamment `PublicationService`) et observez les lignes de code. Au niveau des numéros de lignes, une section verte indique que la ligne a été parcourue (et bien sûr, une section rouge indique l'inverse).

5. Après exécution des tests, il faut réimporter le fichier `coverage.xml` afin de mettre à jour l'analyse menée par **PHPStorm**. pour cela, vous pouvez utiliser le troisième bouton situé en haut du panneau d'analyse de la couverture de code. 

6. Si vous n'utilisez pas **PHPStorm**, il est sans doute possible de faire quelque-chose de similaire avec votre IDE. Il est aussi possible de générer un rapport en HTML (pour afficher un mini-site) en ajoutant la section suivante dans la partie `coverage` de `phpunit.xml` :

   ```xml
   <coverage>
       <report>
           ...
           <html outputDirectory="reports"/>
       </report>
   </coverage>
   ```

    Après exécution des tests, le site web sera généré dans `reports` et il est accessible en ouvrant le fichier `index.html` avec un navigateur.

</div>

Maintenant, prenez l'habitude de vérifier la couverture de code de vos tests !