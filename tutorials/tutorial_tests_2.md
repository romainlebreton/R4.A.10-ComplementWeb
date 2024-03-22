---
title: TD4 &ndash; Injection de dépendances, Conteneur, Tests
subtitle: Services, Configuration, Mocks
layout: tutorial
lang: fr
---

<!-- 
An prochain : 
* Publication::create → Publication::construire
-->

## Les problèmes de dépendances

Comme vous l'avez sûrement déjà remarqué, il y a de gros problèmes avec les tests que nous avons écrits pour tester le service publication. En vrac :

* Dans certains tests, nous devons préciser des utilisateurs réels. Ces tests dépendent donc de l'état actuel de l'application, des utilisateurs inscrits.

* On teste le nombre de publications total et le nombre de publications d'un utilisateur donné. Là aussi, ce nombre peut changer si une nouvelle publication est réalisée !

* Nous n'avons pas pu tester la création "normale" d'une publication. Deux causes à cela. Déjà, nous n'avons pas moyen de récupérer directement la publication créée (la méthode de création de publication ne retourne rien). Deuxièmement, ce test entrainait la création réelle d'une publication dans l'application ! À chaque exécution !

* La base de données doit obligatoirement être allumée pendant l'exécution de tests...

Tout cela est dû au fait que notre classe `PublicationService` est fortement dépendante d'autres classes et notamment d'une classe repository. Il en va de même pour `UtilisateurService`. En fait, nous ne pouvons pas (encore) qualifier nos tests de tests **unitaires** car les nombreuses dépendances entraînent un test plus global des différents modules attachés à cette classe de manière indésirable. De plus, nous agissons sur la base de données (de "production") ce qui n'est pas bon.

Un **test unitaire** doit seulement porter sur une portion de code très précise (typiquement une méthode) et ne doit pas concrètement déclencher l'exécution d'autres services dans l'environnement de l'application (pas d'effet de bord). De plus, le test ne doit pas dépendre de l'état concret de l'application à l'instant du test (typiquement, le test ne doit pas dépendre de l'état de la base de données !).

Pour régler ces problèmes, nous pouvons utiliser deux outils :

* L'application des principes **SOLID** notamment **l'inversion des dépendances** (principe `D`) afin de réaliser de l'injection de dépendances pour faire en sorte que les dépendances des différentes classes soient interchangeables.

* L'utilisation de **mocks** afin de simuler et configurer à souhait les dépendances d'une classe lors des tests unitaires afin de construire un scénario précis. L'idée est de contrôler ce que les différentes dépendances d'une classe vont fournir comme réponse lorsqu'elles sont utilisées lors d'un test unitaire.

### Aparté sur les routes

Si ce n'est pas déjà fait, effectuez les instructions décrites dans [cette note complémentaire]({{site.baseurl}}/tutorials/complement_route_attribut) afin d'alléger le fichier `Routeur.php` en définissant nos routes en utilisant des **attributs** directement au niveau des contrôleurs plutôt que de les définir en PHP. Par la suite, nous allons encore plus alléger ce fichier en déléguant une grande partie de la configuration vers d'autres fichiers plus adaptés.

Assurez-vous de migrer toutes vos routes en utilisant la nouvelle syntaxe avec les attributs au niveau de la méthode correspondante dans vos deux contrôleurs.

### Injection des dépendances et inversion de contrôle

Lorsqu'une classe est amenée à utiliser des instances d'autres classes lors de l'exécution de ses différentes méthodes on dit qu'il existe une dépendance entre ces deux classes (de la classe utilisatrice vers la classe utilisée). En **UML**, cette dépendance se traduit notamment par une flèche pointillée.

Dans un tel contexte, il peut alors être judicieux d'appliquer le concept **d'inversion de contrôle** en favorisant le découplage entre les objets en injectant les dépendances de la classe plutôt que de laisser la classe instancier un objet de la classe cible ou bien utiliser un singleton.

Par exemple, imaginons les classes suivantes :

```php
// Classe "dynamique"
class A {
    public function traitementA() {
        ...
    }
}

// Classe "singleton"
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
        // ...
    }
}

class C {

    public function traitementC() {
        $serviceA = new A();
        $serviceA->traitementA();
        $serviceB = B->getInstance();
        $result = $serviceB->traitementB();
        // ...
    }

}
```

Dans cet exemple, la classe `C` est dépendante des classes `A` et `B`. Il devient alors difficile de réaliser des tests unitaires de la méthode `traitementC` car son exécution déclenchera et dépendra des classes concrètes `A` et `B`.

Plutôt que la méthode `traitementC` utilise directement ces dépendances, on pourrait adopter l'architecture suivante :

```php
class C {

    // Syntaxe PHP 8.0: Class constructor property promotion
    // Déclare un attribut et l'initialise depuis le constructeur
    // https://php.watch/versions/8.0/constructor-property-promotion
    public function __construct(private A $serviceA, private B $serviceB) {}

    public function traitementC() {
        $this->serviceA->traitementA();
        $result = $this->serviceB->traitementB();
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
    // ...
}

interface ServiceBInterface {
    public function traitementB();
}

class B implements ServiceBInterface {
    // ...
}

interface ServiceCInterface {
    public function traitementC();
}

class C implements ServiceCInterface {

    public function __construct(private ServiceAInterface $serviceA, private ServiceBInterface $serviceB) {}

    public function traitementC() {
        $this->serviceA->traitementA();
        $result = $this->serviceB->traitementB();
        ...
    }

}
```

Il est donc maintenant possible de changer les classes concrètes dont dépendra la classe `C`. Nous avons déjà évoqué l'avantage d'un tel procédé dans le cadre de tests mais ce système permet aussi de rendre l'application hautement configurable et flexible. Avec ce système, on pourrait, par exemple, avoir un environnement de "production" utilisant une base de données précise, et un environnement de "développement" ou de "test" utilisant une autre base de données.

Vous aurez remarqué que la classe `C` possède aussi une interface. Même si cette classe n'apparait pas encore comme dépendance d'une autre classe, c'est une bonne pratique de prévoir cela en amont et de systématiquement donner une interface à tous nos services.

Globalement, on peut retenir qu'une bonne architecture implique que :

   * Les différentes classes ne dépendent pas d'instances d'autres classes en particulier, mais plutôt d'une **interface** (ou d'une **classe abstraite**) qui pourra prendre des formes différentes grâce au **polymorphisme** sans avoir besoin de changer le code de la section utilisant ce composant.

   * Les **instances** concrètes sont **injectées** dans les classes qui doivent utiliser un service. Cela peut se faire sous la forme de **setters** ou bien directement comme arguments pour le **constructeur** de l'objet. Cela renforce l'indépendance des classes. La classe n'instancie pas elle-même les composants dont elle a besoin, ils sont **injectés** depuis l'extérieur. On appelle cela **l'inversion de contrôle**.

   * Il est possible d'utiliser la même instance et de l'injecter dans différentes classes. En fait, l'instance n'est initialisé qu'à un seul endroit. Cela facilite donc également sa construction si elle nécessite différents paramètres. Il est également possible de générer plusieurs instances du service et de sélectionner lequel est injecté dans quelle classe.

Notre prochain objectif est donc de remanier les classes des `controleurs`, des `services` et des `repositories` afin de les rendre indépendantes des classes concrètes, en mettant en place une architecture favorisant l'injection de dépendance.

<div class="exercise">

1. Pour commencer, transformez la classe `ConnexionBaseDeDonnees` pour que celle-ci ne soit plus un `singleton` avec le code suivant :
   ```php
   class ConnexionBaseDeDonnees
   {
       private PDO $pdo;
   
       public function getPdo(): PDO
       {
           return $this->pdo;
       }
   
       public function __construct()
       {
           $configurationBDD = new ConfigurationBDDMySQL();
   
           // Connexion à la base de données
           $this->pdo = new PDO(
               $configurationBDD->getDSN(),
               $configurationBDD->getLogin(),
               $configurationBDD->getMotDePasse(),
               $configurationBDD->getOptions()
           );
   
           // On active le mode d'affichage des erreurs, et le lancement d'exception en cas d'erreur
           $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
       }
   }
   ```

2. Nous voulons que la dépendance vers `ConfigurationBDDMySQL` soit injectée via
   le constructeur. 
   ```php
   public function __construct(ConfigurationBDDMySQL $configurationBDD)
   {
       // Connexion à la base de données
       $this->pdo = ...
   } 
   ```
   
3. Comme expliqué précédemment, nous souhaitons plutôt injecter l'interface
   existante `ConfigurationBDDInterface` que son implémentation
   `ConfigurationBDDMySQL`.
   ```php
   public function __construct(ConfigurationBDDInterface $configurationBDD)
   {
       // Connexion à la base de données
       $this->pdo = ...
   } 
   ```

4. <!-- Pour anticiper la suite... Ou déplacer ??? -->
   Créez une interface à partir de la classe `ConnexionBaseDeDonnees` (et
   appliquez-la). Cette opération peut être automatisée avec votre `IDE` :
   `Refactor` → `Extract` → `Interface`.

</div>

<div class="exercise">

4. Modifiez les classes `PublicationRepository` et `UtilisateurRepository` pour éliminer tout appel statique à `ConnexionBaseDeDonnees` et à la place, mettre en place l'injection d'une dépendance correspondant à l'interface créée à la question précédente (il faudra créer un nouvel attribut pour stocker cette dépendance). Cette dépendance sera utilisée dans les différentes méthodes afin d'obtenir l'objet `pdo`. Créez également des `interfaces` pour ces deux classes. Soyez malin et utilisez l'`IDE` à votre avantage (`CTRL+R`). Voici un squelette que vous pouvez reprendre pour `PublicationRepository` :

    ```php
    namespace TheFeed\Modele\Repository;
    
    use TheFeed\Modele\DataObject\Publication;
    
    interface PublicationRepositoryInterface
    {
        public function recuperer(): array;
        
        public function recupererParAuteur($idUtilisateur): array;
    
        public function ajouter(Publication $publication);
    
        public function recupererParClePrimaire($id): ?Publication;
    
        public function mettreAJour(Publication $publication);
    
        public function supprimer(Publication $publication);
    }
    ```

    ```php
    namespace TheFeed\Modele\Repository;

    use TheFeed\Modele\DataObject\Publication;
    use TheFeed\Modele\DataObject\Utilisateur;
    use DateTime;

    class PublicationRepository implements PublicationRepositoryInterface
    {
        public function __construct(private ConnexionBaseDeDonneesInterface $connexionBaseDeDonnees)
        {}

        /**
         * @return Publication[]
         * @throws \Exception
         */
        public function recuperer(): array
        {
            $statement = $this->connexionBaseDeDonnees->getPdo()->prepare(...);
            // ...
        }

        // ...
    }
    ```

    *Astuce :* Utilisez le remplacement de *PhpStorm* (`Ctrl+R`) pour modifier rapidement tous les
    ```php
    ConnexionBaseDeDonnees::getPdo()
    ```
    en 
    ```php
    $this->connexionBaseDeDonnees->getPdo()
    ```

5. Faites une opération similaire au niveau des deux classes `PublicationService` et `UtilisateurService` en injectant les classes `repository` comme dépendances, via le constructeur. Il faudra éliminer toutes les instanciations de repository pour utiliser vos nouvelles dépendances. Là-aussi, mettez en place des interfaces pour ces deux services. Attention `PublicationService` utilise les deux repositories.

6. Rendez tous vos `controleurs` (même le générique) non statiques. C'est-à-dire que toutes les méthodes ne doivent plus être statiques. De même, les appels statiques du type `Controlleur::` doivent être remplacés par `$this->`. Ici aussi, soyez malin et utilisez votre IDE pour effectuer cette tâche rapidement.

6. Au niveau de `ControleurPublication` et `ControleurUtilisateur`, réalisez l'injection des deux services (toujours via leur interface). Dans chaque méthode, au lieu d'instancier un service pour réaliser une opération, vous utiliserez vos nouvelles dépendances.

</div>

Après toutes ces opérations, votre application ne doit plus fonctionner ! Pas de panique, c'est tout à fait normal. En effet, il y a besoin d'indiquer quelque part comment sont construits tous ces services et surtout, réaliser concrètement l'injection des différentes dépendances. Cela va être le rôle de la prochaine section dédiée au `conteneur de services`.

### Le conteneur de services

Comme mentionné précédemment, nous avons besoin d'un outil et d'un endroit dans le code permettant de contenir tous les services et d'injecter les différents instances concrètes à ceux qui ont en besoin. Un tel outil est généralement appelé **conteneur IoC** (conteneur Inversion of Control) ou bien **conteneur de services**. Lors du premier TD de complément web, vous avez créé une ébauche de ce conteneur modélisé par la classe située dans `Lib/Conteneur.php`.

Dans une application web bien construite, la toute première étape avant de transmettre la requête au contrôleur est de se servir du conteneur afin d'enregistrer les services puis résoudre toutes les dépendances et ainsi disposer de tous les objets utiles au traitement de la demande. C'est d'ailleurs ce que vous faites déjà partiellement dans `RouteurURL`.

Nous pourrions continuer avec ce conteneur, mais nous allons plutôt utiliser celui de **Symfony**. Il y a principalement trois avantages à cela : 
1. les dépendances sont gérées en mode `lazy loading`. Cela signifie qu'une dépendance concrète n'est instanciée que si on en a vraiment besoin. 
2. ce conteneur permet de gérer les **dépendances croisées** (c'est-à-dire, si `A` a besoin de `B` et inversement). 
3. le conteneur peut être configuré avec un fichier de configuration `.yml` sans avoir besoin d'écrire de lignes de code en PHP (ou du moins, pas beaucoup). Cette flexibilité permet d'avoir simplement plusieurs configurations possibles pour gérer les différents modules et services de notre application (et donc, avoir plusieurs environnements d'exécution, éventuellement).

Regardons de plus près les méthodes qui vont nous intéresser dans ce conteneur :

```php
//Instanciation
$container = new ContainerBuilder();

//Enregistrement du service "serviceName" qui représente la classe concrète MyService
$container->register('service_name', MyService::class)

//Recuperation de l'instance service :
$myService = $container->get('service_name');

//Enregistrement d'un service qui a besoin de paramètres pour être initialisé.
//Les paramètres sont passés dans l'ordre, via un tableau
//L'injection est faite via le constructeur
$serviceReference = $container->register('service_bis', MyServiceBis::class)
$serviceReference->setArguments([5, "test"]);
// $serviceReference->get('service_bis') renverra new MyServiceBis(5, "test")
```
La méthode `register` renvoie une **référence du service** (et pas une instance du service). Il est donc possible de préciser divers paramètres comme les arguments du constructeur, des méthodes à exécuter après initialisation...

On peut également enregistrer des **paramètres** (variables globales) dans le conteneur :
```php
$container->setParameter('param_one', "hello");
```

Maintenant, quelque chose d'un peu plus avancé :

```php
$serviceReference = $container->register('service_third', MyServiceThird::class)
$serviceReference->setArguments(["%param_one%", new Reference("service_bis")]);
// $serviceReference->get('service_third') renverra in fine
// new MyServiceThird("hello", new MyServiceBis(5, "test"))
```

Dans les paramètres injectés dans le service, on peut :  
   * Faire référence à un paramètre contenu dans le conteneur, en utilisant les marqueurs `%nom_parametre%`  
   * Faire référence à un autre service du conteneur (même s'il n'est pas encore enregistré !). On utilise pour cela un objet `Reference` paramétré avec le nom du service.

Après enregistrement et configuration, à partir du **conteneur**, on peut donc récupérer n'importe quel service grâce à la méthode `get`.

Quand on y regarde de plus près, ce conteneur est en fait une grande **factory** construite dynamiquement et regroupant tous les services de l'application. On passe par elle pour récupérer l'instance qui nous intéresse. Si on veut changer l'instance utilisée pour un service, il suffit alors de changer la classe spécifiée à un seul endroit, lors de la configuration du conteneur.

Dans un premier temps, nous allons enregistrer les services que nous venons de créer puis, plus tard, vous pourrez progressivement supprimer le conteneur que vous aviez défini auparavant.

À noter qu'il est aussi possible d'enregistrer un service déjà instancié (donc, on ne le configure pas et il n'est pas *lazy load*, nous l'instancions nous même dans le code) grâce à la méthode `set` :

```php
$myService = new MyServiceFourth();
$container->set('service_fourth', $myService);
// $serviceReference->get('service_fourth') renverra l'objet déjà instancié...
```

Cette méthode est plus ou moins équivalente au fonctionnement de notre conteneur maison actuel (avec `Conteneur::ajouterService(nom, service)`).

Nous utiliserons cette fonctionnalité pour quelques cas spécifiques, mais, en règle générale, nous utiliserons la configuration par lazy-loading grâce à la méthode `register`.

<div class="exercise">

1. Installez le conteneur de service de symfony :

    ```bash
    composer require symfony/dependency-injection
    ```

2. Dans la méthode `traiterRequete` de `RouteurURL`, au tout début de la méthode, ajoutez les lignes de code suivantes :

    ```php
    use TheFeed\Controleur\ControleurPublication;
    use TheFeed\Controleur\ControleurUtilisateur;
    use TheFeed\Modele\Repository\ConnexionBaseDeDonnees;
    use TheFeed\Modele\Repository\PublicationRepository;
    use TheFeed\Modele\Repository\UtilisateurRepository;
    use TheFeed\Service\PublicationService;
    use TheFeed\Service\UtilisateurService;
    use TheFeed\Configuration\ConfigurationBDDMySQL;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Reference;

    $conteneur = new ContainerBuilder();

    $conteneur->register('configuration_bdd_my_sql', ConfigurationBDDMySQL::class);

    $connexionBaseService = $conteneur->register('connexion_base_de_donnees', ConnexionBaseDeDonnees::class);
    $connexionBaseService->setArguments([new Reference('configuration_bdd_my_sql')]);

    $publicationsRepositoryService = $conteneur->register('publication_repository',PublicationRepository::class);
    $publicationsRepositoryService->setArguments([new Reference('connexion_base_de_donnees')]);

    $utilisateurRepositoryService = $conteneur->register('utilisateur_repository',UtilisateurRepository::class);
    $utilisateurRepositoryService->setArguments([new Reference('connexion_base_de_donnees')]);

    $publicationService = $conteneur->register('publication_service', PublicationService::class);
    $publicationService->setArguments([new Reference('publication_repository'), new Reference('utilisateur_repository')]);

    $publicationControleurService = $conteneur->register('controleur_publication',ControleurPublication::class);
    $publicationControleurService->setArguments([new Reference('publication_service')]);
    ```

    Comme toujours les `use` sont des imports à faire au début de la classe.

    **Attention** : vérifiez bien l'ordre des arguments dans `publication_service` (selon l'ordre que vous avez défini dans le constructeur de `PublicationService`).

    **Prenez le temps de comprendre ces lignes de code!** S'il y a un élément que vous ne comprenez pas, demandez à votre enseignant chargé de TD. Pour le moment, la syntaxe est assez verbeuse, mais nous allons alléger tout cela dans un futur exercice.

2. Pour le moment, remplacez les appels statiques `ControleurGenerique::afficherErreur` par `(new ControleurGenerique())->afficherErreur`. Plus tard, nous utiliserons plutôt un **service** pour faire cela.

3. Nous avons enregistré la partie permettant de gérer les publications. Maintenant, il faut indiquer resolver de contrôleur d'utiliser le contrôleur enregistré dans le conteneur ! Pour cela, remplacez la ligne instanciant un `ControllerResolver` en instanciant un `ContainerControllerResolver` à la place. Il faut donner comme arguments du constructeur de cette nouvelle classe votre conteneur (`$conteneur`).

    *Explication* : La classe `ContainerControllerResolver` ira chercher le service indiqué dans la route dans le conteneur, puis appellera l'action indiquée dans la route.

4. Chargez la page principale de votre application. Vous obtenez alors un message d'erreur qui explique que `ControleurPublication` n'a pas pu être construit... C'est en fait la faute de la classe `TheFeed/Lib/AttributeRouteControllerLoader` ! En effet, si vous observez le code de cette classe, elle configure la route avec le nom du contrôleur. Alors, quand on essaye d'y accéder, le programme va tenter d'appeler la méthode correspondant à la route sur la classe du contrôleur. Il va alors tenter de construire une instance de la classe, mais il ne possède pas les dépendances (les services) requis par le contrôleur...

    Pour régler ce problème, au lieu d'utiliser le nom de la classe, nous allons plutôt utiliser le nom de son `service`! Le nom du service correspond à `controleur_xxx`. Il suffit donc de légèrement adapter le code de cette classe :

    ```php
    class AttributeRouteControllerLoader extends AttributeClassLoader
    {
        /**
        * Configures the _controller default parameter of a given Route instance.
        */
        protected function configureRoute(Route $route, \ReflectionClass $class, \ReflectionMethod $method, object $annot): void
        {
            $route->setDefault('_controller', $this->toSnakeCase($class->getShortName()).'::'.$method->getName());
        }

        private function toSnakeCase($controllerName) : string {
            return ltrim(strtolower(preg_replace('/[A-Z]([A-Z](?![a-z]))*/', '_$0', $controllerName)), '_');
        }

    }
    ```

    On prend le nom "court" du contrôleur (par exemple `ControleurPublication` et non pas `TheFeed\Controleur\ControleurPublication`) et on le convertit en `snake_case` (ce qui donnera `ControleurPublication` → `controleur_publication`).

    Attention, cela dépend bien sûr de votre convention de nommage pour vos services ! Ici, nous avons choisi le `snake_case`. Il faudra donc nous y tenir, et, nommer tous nos contrôleurs : `controleur_xxx`

5. Complétez le code afin d'enregistrer le service puis le contrôleur liés aux utilisateurs dans le conteneur.

6. Chargez la page principale de votre application. Elle devrait fonctionner !

7. Naviguez à travers l'application et vérifiez que tout fonctionne comme avant.

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

  configuration_bdd_my_sql:
    class: TheFeed\Configuration\ConfigurationBDDMySQL

  connexion_base_de_donnees:
    class: TheFeed\Modele\Repository\ConnexionBaseDeDonnees
    arguments: ['@configuration_bdd_my_sql']

  #Repositories
  publication_repository:
      class: TheFeed\Modele\Repository\PublicationRepository
      arguments: ['@connexion_base_de_donnees']

  #Services
  publication_service:
    class: TheFeed\Service\PublicationService
    arguments: ['@publication_repository', '@utilisateur_repository']

  #Controleurs
```

Nous allons donc mettre en place un fichier de configuration pour notre application.

<div class="exercise">

1. Importez les composants suivants :

    ```bash
    composer require symfony/yaml
    ```

2. Dans le dossier `Configuration`, créez un fichier `conteneur.yml` reprenant le début de configuration présenté précédemment. Complétez ce fichier avec tous les services que vous avez déclarés dans `RouteurURL`. Ne vous occupez pas de la déclaration du paramètre concernant le dossier contenant les photos de profil pour le moment.

3. Dans `RouteurURL`, supprimez toutes les lignes de code qui enregistrent vos services dans le conteneur de *Symfony*. À la place, utilisez ces deux lignes de code :

    ```php
    use Symfony\Component\DependencyInjection\Loader\YamlFileLoader;
    use Symfony\Component\Config\FileLocator;
    //On indique au FileLocator de chercher à partir du dossier de configuration
    $loader = new YamlFileLoader($conteneur, new FileLocator(__DIR__."/../Configuration"));
    //On remplit le conteneur avec les données fournies dans le fichier de configuration
    $loader->load("conteneur.yml");
    ```

4. Vérifiez que votre application fonctionne.
</div>

### Remplacer complètement l'ancien conteneur

Actuellement, nous utilisons toujours l'ancien `Conteneur` (celui de `Lib`) dans notre contrôleur générique, notamment. Nous allons faire en sorte de refactorer tout cela en migrant les 3 services restants vers notre nouveau conteneur.

<div class="exercise">

1. Tout d'abord, nous allons définir notre premier paramètre : le `project_root`. Ce paramètre contiendra le chemin absolu de la racine du projet. Il pourra nous servir dans divers contextes dès que nous aurons besoin de construire un chemin au travers des fichiers de l'application. Nous ne pouvons malheureusement pas enregistrer ce paramètre dans le fichier de configuration, car nous avons besoin d'accéder à la valeur `__DIR__`. Par contre, nous pourrons nous en resservir pour construire d'autres paramètres ou pour configurer des services ! Ajoutez donc cette ligne dans `RouteurURL.php` après l'initialisation du conteneur de Symfony :

    ```php
    $conteneur->setParameter('project_root', __DIR__.'/../..');
    ```

2. Importez maintenant dans `conteneur.yml` tout ce qui est relatif à `twig` :

   ```yaml
   services:
     #Twig
     twig_loader:
       class: Twig\Loader\FilesystemLoader
       arguments: ['%project_root%/src/vue/']
     twig:
       class: Twig\Environment
       arguments:
         $loader: '@twig_loader'
         $options:
           autoescape: 'html'
           strict_variables: true
   ```
   Il y a beaucoup de paramètres nécessaires à l'instanciation de ce service, donc, encore une fois, prenez le temps de comprendre ces lignes de code et appeler votre enseignant si besoin. Par exemple, comprenez-vous bien le paramètre `%project_root%/src/vue/` ?   

   Concernant les `arguments` du service `twig`, il s'agit d'une autre manière de les déclarer en utilisant leur `nom` plutôt que l'ordre des paramètres. Cette forme de déclaration est obligatoire dans le cas présent car `options` est un tableau associatif dans le constructeur de `Environment`.

3. Pour pouvoir enregistrer les services `url_generator` (correspondant à `UrlGenerator`) et `url_helper` (correspondant à `UrlHelper`) via notre fichier de configuration, nous avons besoin de trois services :

   * `request_stack`, correspondant à un objet `RequestStack` que nous pouvons simplement déclarer dans `conteneur.yml`.

   * `request_context`, correspondant à un objet `RequestContext` que nous sommes obligés de déclarer directement dans `traiterRequete` car cet objet à besoin d'être configuré avec les données de la requête courante.

   * `routes` : correspondant à la collection contenant nos routes (renvoyée par `$loader->load(...)`). Ici aussi, nous sommes obligés de faire cette déclaration dans `traiterRequete` (car il faut exécuter le code pour récupérer toutes les routes...).

   Faites donc les ajouts nécessaires :

   ```yaml
   #Configuration/conteneur.yml
   services:
     #Services
     request_stack:
       class: Symfony\Component\HttpFoundation\RequestStack
   ```

   ```php
   //Après l'instanciation de l'objet $contexteRequete
   $conteneur->set('request_context', $contexteRequete);
   //Après que les routes soient récupérées
   $conteneur->set('routes', $routes);
   ```

4. Dans votre fichier `conteneur.yml`, déclarez deux nouveaux services : `url_generator` (correspondant à la classe `Symfony\Component\Routing\Generator\UrlGenerator`) et `url_helper` (correspondant à la classe `Symfony\Component\HttpFoundation\UrlHelper`). 
   
   Concernant les `arguments` de ces deux services, utilisez les différents services que nous avons définis lors de la question précédente (normalement, vous pouvez toujours trouvez l'instanciation de ces objets dans `traiterRequete`, si vous souhaitez voir comment cela est fait).

5. Dans `traiterRequete`, supprimez l'instanciation des variables `twigLoader` et `twig`. À la place, récupérez le **service** correspondant à `twig`.

    ```php
    //Remplacer :
    $twig=new Environment(...);
    //Par :
    $twig=$conteneur->get('twig');
    ```

    Supprimez ensuite l'enregistrement de `twig` dans l'ancien `Conteneur` :

    ```php
    //Supprimer :
    Conteneur::ajouterService("twig", $twig);
    ```

6. Poursuivez ce travail de nettoyage en remplaçant le contenu des variables `$generateurUrl` et `$assistantUrl` par un accès au service correspondant dans le conteneur. Vous supprimerez les derniers appels à `Conteneur::ajouterService` dans cette méthode.

</div>

Oh non ! L'application ne marche toujours pas ! En effet, le `ControleurGenerique` utilise toujours notre ancien `Conteneur` ! Il faut donc le déclarer lui aussi comme service et lui injecter tous les services dont il a besoin... Mais, comme tous les contrôleurs héritent de ce contrôleur, il faut donc injecter à tous les sous-contrôleurs les services dont a besoin le contrôleur générique...

Plutôt que de lui injecter les services un par un, nous allons directement lui injecter le conteneur. Ainsi, il piochera dedans pour utiliser les services dont il a besoin. Injecter le conteneur à un autre service (en l'occurrence, ici, un contrôleur) n'est pas une très bonne pratique, notamment pour les tests, mais ce n'est pas très grave dans le cas de `ControleurGenerique`, car cette classe n'a pas vraiment pour but d'être testée (même les contrôleurs, de manière générale). Seul `ControleurGenerique` aura le droit d'utiliser le conteneur (l'attribut sera déclaré privé) et il n'y aura qu'un paramètre à ajouter aux contrôleurs enfants.

<div class="exercise">

1. Ajoutez un **constructeur** à `ControleurGenerique` afin de lui injecter un attribut de type `ContainerInterface` :

    ```php
    use Symfony\Component\DependencyInjection\ContainerInterface;

    public function __construct(private ContainerInterface $container)
    {}
    ```

2. Modifiez le constructeur de `ControleurPublication` en conséquence :

    ```php
    use Symfony\Component\DependencyInjection\ContainerInterface;

    public function __construct(ContainerInterface $container, private PublicationServiceInterface $publicationService)
    {
        parent::__construct($container);
    }
    ```

3. Faites de même pour `ControleurUtilisateur`.

4. Dans `ControleurGenerique`, modifiez tous les appels à `Conteneur::recupererService(...)` en utilisant le nouveau conteneur injecté dans la classe (attention, `generateurUrl` est devenu `url_generator`). Pour accéder à l'attribut `container`, passez toutes les méthodes de statique à dynamique.

5. Dans `traiterRequete` de `RouteurURL`, il faut que le conteneur s'enregistre lui-même dans le conteneur ! On peut faire cela très simplement, comme pour n'importe quel service :

    ```php
    $conteneur->set('container', $conteneur);
    ```
6. Pour rappel, le constructeur de `ControleurPublication` et `ControleurUtilisateur` ont été modifiés ! Il faut donc mettre à jour les liste des `arguments` pour les deux services correspondant dans `conteneur.yml`.

7. Enfin, vous aurez peut-être remarqué que votre `IDE` râle au niveau de la fin de la méthode `traiterRequete`, car il manque un paramètre (le conteneur) pour instancier `ControleurGenerique` afin de gérer nos cas d'erreurs. Pour régler cet ultime problème :

    * Enregistrez un **service** (dans `conteneur.yml`) correspondant au `ControleurGenerique`.

    * Dans la méthode `traiterRequete`, utilisez ce service au lieu d'instancier directement `ControleurGenerique`.

8. Vérifiez que votre application fonctionne de nouveau.
</div>

## À vos tests !

### Les mocks

Maintenant que notre logique métier est (en partie) indépendante de classes concrètes, nous allons pouvoir réaliser de véritables tests unitaires qui n'influent pas sur le reste de l'application. En effet, dorénavant, lorsque nous instancions un **service**, nous pouvons contrôler quelle dépendance nous lui donnons.

Idéalement, nous aimerions pouvoir contrôler ce que les dépendances de chaque service répondent lors de la phase de test afin de construire un scénario de test adéquat. Pour cela, nous pourrions :

* Créer une classe dédiée et la faire hériter de l'interface de la dépendance en question. Ainsi, nous pourrions contrôler ce que les méthodes renvoient. Néanmoins, cela peut vite devenir fastidieux s'il faut créer une nouvelle classe pour chaque scénario...

* Utiliser des **mocks**. Les **mocks** permettent de créer (avec une ligne de code) une "fausse" classe possédant les mêmes méthodes. Il est possible de configurer dynamiquement la classe **mock** par des lignes de code. Un exemple de configuration possible est de préciser un résultat à renvoyer lors de l'appel d'une méthode précise. Ou bien même déclencher une exception. Cette option est bien plus flexible que l'idée de créer une classe dédiée par scénario.

Regardons de plus près l'utilisation de ces **mocks** :

```php
// Dans une méthode d'une classe héritant de TestCase

// Creation d'un mock de type ServiceAInterface
$mockedService = $this->createMock(ServiceAInterface::class);

// On fait en sorte que la méthode traitementA retourne un tableau de deux éléments
$mockedService->method("traitementA")->willReturn([7,8]);

// Il est possible d'aller plus loin et de déclencher une réponse spécifique en fonction des valeurs des paramètres passés à la méthode.
// On peut traduire l'instruction ci-dessous par : quand la méthode 'traitementABis' est appellée avec la valeur 5, retourner 10.
$mockedService->method("traitementABis")->with(5)->willReturn(10);

// On fait en sorte qu'un appel à la méthode traitementSpecial déclenche une exception
$mockedService->method("traitementSpecial")->willThrowException(ExempleException::class);
```

Prenons l'exemple de votre classe `PublicationServiceTest`. Celle-ci ne doit plus bien fonctionner car le `service` manipulé par les tests attend des dépendances (*repositories* utilisateur et publication).

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
        $this->publicationRepositoryMock->method("recuperer")->willReturn($fakePublications);
        //Test
        $this->assertCount(2, $this->service->recupererPublications());
    }
}
```

Un autre aspect très utile des mocks est de pouvoir exécuter un `callback` (une fonction) lorsqu'une méthode est exécutée tout en récupérant les valeurs des paramètres de la méthode exécutée. Cela permet donc d'analyser ce qui a été donné par un service à notre mock lors d'un appel de méthode.

On configure tout cela grâce à la méthode `willReturnCallback` lors de la configuration d'une méthode sur un **mock**.

```php
class ExempleService implements ExempleServiceInterface {

    public function traitement($a, $b) {
        ...
    }
}

class SuperService implements SuperServiceInterface {

    public function __construct(private ExempleServiceInterface $exempleService) {}

    public function superTraitement() {
        // ...
        $this->exempleService->traitement("test", 42);
        // ...
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
            //Portion de code déclenché quand le service appellera la méthode 'traitement' sur notre mock.
            //Ici, on doit réaliser des assertions sur $a et $b...
        });
        $this->service->superTraitement();
    }

}
```

### De véritables tests unitaires

Maintenant que vous connaissez les **mocks**, vous allez pouvoir les utiliser pour écrire de véritables tests unitaires !

<div class="exercise">

1. Reprenez votre classe `PublicationServiceTest` et adaptez-la pour faire fonctionner vos anciens tests en utilisant des **mocks** pour les dépendances du service. Vous pouvez repartir de l'exemple `testNombrePublications` donné dans la section précédente. Dans certains tests, pour la partie concernant les **utilisateurs**, il faudra bien configurer votre mock afin qu'il renvoie un faux utilisateur (parfois **null** et parfois non... Tout dépend du contexte du test !).

2. Créez un test `testCreerPublicationValide`. Le but de ce test est de vérifier que tout fonctionne bien lorsque les spécifications de création d'une publication sont respectées. En utilisant votre **mock** du repository des publications, vous devrez intercepter l'appel à **ajouter** afin de vérifier que les données transmises sont bien conformes.

3. Ajoutez des tests qui vous semblent pertinents !

4. Lancez les tests unitaires (avec couverture) et vérifiez que vous avez bien une couverture de code de **100%** sur votre classe `PublicationService`.

</div>

Bien sûr, notre contexte de test dans ce sujet reste assez simpliste, mais cela vous donne déjà une idée de comment réaliser des tests unitaires assez précis et indépendants du contexte de l'application. Vous l'aurez remarqué, avec cette nouvelle façon de fonctionner, la base de données n'est pas sollicitée et on ne dépend plus des utilisateurs réellement inscrits ou des publications réellement créées. Et on ne risque pas de réellement créer une nouvelle publication après chaque exécution des tests !

### Traitement des requêtes

Dans le cadre de tests futurs (notamment pour l'`API REST` que vous allez créer lors du **TD5**) nous allons modifier la méthode `RouteurURL::traiterRequete` afin que celle-ci prenne une requête en paramètre et renvoie la réponse plutôt que de tout traiter d'un seul bloc en "boîte noire". Par la suite, cela pourra permettre de simuler des requêtes et d'analyse la réponse renvoyée.

<div class="exercise">

1. Ajoutez un paramètre `Request $requete` dans la fonction `RouteurURL::traiterRequete`.

2. Déplacez l'instruction suivante depuis `RouteurURL::traiterRequete` vers le fichier `web/controleurFrontal.php` : 

    ```php
    $requete = Request::createFromGlobals()
    ```

    Et passez cette variable comme paramètre lors de l'appel de `RouteurURL::traiterRequete`.

3. Faites en sorte de déclarer que la fonction `RouteurURL::traiterRequete` retourne un objet de type `Response` puis supprimez le code effectuant un `send` sur la réponse obtenue dans cette fonction. Renvoyez la réponse à la place.

4. Enfin, dans `web/controleurFrontal.php`, récupérez la réponse retournée par `RouteurURL::traiterRequete` et envoyez-la (toujours avec `send`).

5. Vérifiez que votre site fonctionne toujours comme il faut.

</div>

## Concernant la *SAÉ*

Pour en revenir à votre *SAÉ*, le but de ce TD est de vous permettre de réappliquer les concepts que vous venez de voir afin de **retravailler l'architecture** de l'application pour favoriser un système **d'injection de dépendances** via un **conteneur de services** et ainsi réaliser différents **tests unitaires** efficacement, en utilisant des **mocks**.

Un premier objectif à vous fixer serait d'obtenir une couverture de code (proche) de 100%, pour la partie "métier" (classes **modèle** et surtout les **services**) de votre application.

## Extensions

Nous allons maintenant travailler différentes extensions de ce TD afin de pouvoir tester plus d'aspects de l'application, régler des problèmes que vous pourriez rencontrer lors des tests unitaires, améliorer encore plus l'architecture de l'application et l'indépendance de ses classes en transformant plus d'entités en **services**.

### Tester les repositories

Dans nos tests précédents, nous avons supprimé l'interaction avec la base de données en **mockant** nos repositories. Néanmoins, il peut être aussi intéressant de tester ces repositories ! Avoir des tests automatisés permettrait de détecter des éventuelles erreurs dans les requêtes SQL.

Mais comment faire ? Car, comme nous l'avons expliqué précédemment, il n'est pas envisageable d'agir directement sur la base de données réelle de l'application lors de nos tests. La réponse est simple : il nous faut utiliser une base de données dédiée aux tests ! Cela est possible car nous avons fait en sorte que la connexion à la base de données soit injectée comme une dépendance des repositories.

Généralement, pour la base de données de tests, deux choix sont possibles :

* On réalise une copie de la structure de la base, sur le même type de SGBD (dans notre cas, MySQL). Il faut donc que le serveur gérant la base de données soit allumé au moment des tests.

* On réalise nos tests avec une base de données **SQLite** qui est une base de données stockée dans un fichier qui ne nécessite pas de serveur.

Généralement, quand cela est possible, on préfère choisir la seconde option, mais ce n'est pas toujours envisageable, notamment quand la structure de la base de données ou les requêtes utilisent des concepts spécifiques à un SGBD donné.
<!-- (c'est le cas dans votre *SAÉ* avec *PostGIS*).  -->
Dans ce cas, on réalisera une copie locale de la structure de la base, sur le même type de SGBD.

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

    private static MonRepositoryInterface $repository;

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
        $entiteBDD = self::$repository->recupererParClePrimaire($id);
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

2. Téléchargez [ce fichier]({{site.baseurl}}/assets/TD_SAE_Test_Archi/db_test.db) qui contient la structure de la base de données de `The Feed` sous le format `SQLite`. Placez ce fichier dans le dossier `Test`.

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
            return "sqlite:".__DIR__."/db_test.db";
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
                                                            utilisateurs (idUtilisateur, login, mdpHache, email, nomPhotoDeProfil) 
                                                            VALUES (1, 'test', 'test', 'test@example.com', 'test.png')");
            self::$connexionBaseDeDonnees->getPdo()->query("INSERT INTO 
                                                            utilisateurs (idUtilisateur, login, mdpHache, email, nomPhotoDeProfil) 
                                                            VALUES (2, 'test2', 'test2', 'test2@example.com', 'test2.png')");
        }

        public function testSimpleNombreUtilisateurs() {
            $this->assertCount(2, self::$utilisateurRepository->recuperer());
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

Pour la plupart des méthodes de `UtilisateurService`, vous devriez être en mesure d'écrire des tests unitaires comme vous l'avez fait pour `PublicationService`. Néanmoins, il y a un **effet de bord** indésirable qui se produit lors de l'exécution de la méthode `creerUtilisateur`. En effet, même si dans le cadre des tests nous pouvons mocker le repository, cette méthode va placer une image (la photo de profil) dans le dossier `ressources/img/utilisateurs` ! 

Mais pas de panique, nous pouvons utiliser notre `conteneur de services` pour contourner ce problème. L'idée est de transformer le dossier de destination en un paramètre du service qui sera injecté.

<div class="exercise">

1. Dans `UtilisateurService`, ajoutez un paramètre `$dossierPhotoDeProfil` (de type `string`) dans le constructeur, qui devra être défini comme attribut de la classe (donc il faut utiliser la syntaxe avec `private`). Cet attribut contiendra le chemin du répertoire stockant les photos de profil.

2. Dans la méthode `creerUtilisateur`, lors de la construction du chemin du fichier contenant la photo de profil , utilisez votre nouvel attribut.

3. Dans `conteneur.yml`, enregistrez un `paramètre` correspondant au chemin du dossier contenant les photos de profil en utilisant le paramètre `project_root`. Comme pour les services, il est possible d'utiliser un paramètre lors de la définition d'un autre paramètre, ainsi : `%project_root%/chemin/vers/dossier`.

4. Injectez ce nouveau paramètre comme `argument` du `utilisateur_service` en utilisant sa **référence**. Pour rappel, on peut faire référence à un attribut du conteneur avec la syntaxe : `%nom_attribut%`.

5. Vérifiez que l'inscription fonctionne toujours bien (et que l'image arrive là où il faut).

</div>

Maintenant que le répertoire de destination des photos de profil est configurable, vous pouvez en créer un dédié pour vos tests ! (et le vider après l'exécution des tests, avec `tearDown`). Pour vérifier l'existence d'un fichier, il y a une assertion dédiée : `assertFileExists`. La fonction `mkdir` peut vous permettre de créer le dossier contenant les images tandis que la fonction `rmdir` vous permet de le supprimer.

Attention, dans les paramètres de la méthode `creerUtilisateur` de la classe `UtilisateurService`, vous devez fournir en paramètre un tableau `$donneesPhotoDeProfil`. Ce tableau doit essentiellement contenir deux données :

* `name` : Le nom du fichier original sur la machine du client (avec son extension)
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
        private  $dossierPhotoDeProfil = __DIR__."/tmp/";

        private FileMovingServiceInterface $fileMovingService;

        protected function setUp(): void
        {
            parent::setUp();
            $this->utilisateurRepositoryMock = /* TODO */
            $this->fileMovingService = /* TODO */
            mkdir($this->dossierPhotoDeProfil);
            $this->service = new UtilisateurService(/* TODO */);
        }

        public function testCreerUtilisateurPhotoDeProfil() {
            $donneesPhotoDeProfil = [];
            $donneesPhotoDeProfil["name"] = "test.png";
            $donneesPhotoDeProfil["tmp_name"] = "test.png";
            $this->utilisateurRepositoryMock->method("recupererParLogin")->willReturn(null);
            $this->utilisateurRepositoryMock->method("recupererParEmail")->willReturn(null);
            $this->utilisateurRepositoryMock->method("ajouter")->willReturnCallback(function ($utilisateur) {
                /* TODO : Tester l'existence du fichier (et eventuellement d'autres tests) */ 
            });
            $this->service->creerUtilisateur("test", "TestMdp123", "test@example.com", $donneesPhotoDeProfil);
        }

        protected function tearDown(): void
        {
            //Nettoyage
            parent::tearDown();
            foreach(scandir($this->dossierPhotoDeProfil) as $file) {
                if ('.' === $file || '..' === $file) continue;
                unlink($this->dossierPhotoDeProfil.$file);
            }
            rmdir($this->dossierPhotoDeProfil);
        }

    }
    ```
3. Lancez les tests unitaires, vérifiez qu'ils passent.

4. Complétez la classe en écrivant plus de tests unitaires pertinents, au moins jusqu'à atteindre une couverture de code de 100% pour cette classe.
</div>

### Pour aller plus loin

Durant ce TD, nous avons exploré beaucoup d'aspects liés à l'architecture de l'application et la mise en place de tests unitaires. Néanmoins, il reste du travail à effectuer pour correctement finir de refactoriser et tester notre application. Quelques pistes :

* Définir plus de services ! Dès que dans une classe donnée, il y a une instanciation d'une classe concrète ou bien l'utilisation d'une classe de manière statique (par exemple, quand on utilise la plupart des classes du dossier `Lib`) on peut créer un service à la place et l'injecter à la classe qui en a besoin. Par exemple, dans `UtilisateurService`, il y a l'utilisation de la classe `MotDePasse` et aussi `ConnexionUtilisateur` qui pourraient être remplacées par des services. On a aussi `MessageFlash` qui pourrait être transformé en service et en méthode adéquate dans `ControleurGenerique`...

* Tester la classe `PublicationRepository` et même globalement, toutes les classes de services créées.

* Tester les autres classes définies dans `Modele`.

* Augmenter le plus possible la couverture de code.

Vous pouvez donc travailler tous ces aspects pour améliorer la qualité globale de l'application et couvrir plus de scénarios de tests.
