---
title: Configuration automatique des services
subtitle: Autowire
layout: tutorial
lang: fr
---

Ce tutoriel vous montre comment configurer automatiquement le conteneur de services.

## Explications générales

Le [composant d'injection de dépendances de Symfony](https://symfony.com/doc/current/components/dependency_injection.html)
est capable de détecter automatiquement quelles sont les dépendances de vos services.

Pour configurer les dépendances de notre exemple ainsi que le chargement de
classe, nous avons besoin au moins des paquets *composer* suivants :
`symfony/dependency-injection`, `symfony/config`, `symfony/yaml`.

<!-- TODO avec une interface -->

1. Plaçons-nous dans l'exemple dans lequel nous avons deux classes `A` et `B` avec `B` qui dépend de `A` : 

   ```php
   // src/A.php
   <?php
   namespace App;
   class A
   {
       public function travailler() {
           return "Travail\n";
       }
   }
   ```
   ```php
   <?php
   // src/B.php    
   namespace App;    
   class B
   {
       public function __construct(private readonly \App\A $a) { }
   
       public function metier(){
           return $this->a->travailler();
       }
   }    
   ```

2. Pour créer les services correspondants à `A` et `B` dans le conteneur, nous
   aurions précédemment fait le code suivant 

   ```php
   // script.php
   $container = new ContainerBuilder();
   $container->register("App\A", "App\A"); // "App\A" s'obtient aussi avec A::class
   $container->register("App\B", "App\B")->setArguments([new Reference("App\A")]);   
   $b = $container->get("App\B");
   $b->metier();   
   ```

   ou de manière équivalente en *YAML*

   ```yaml
   # config/services.yaml
   services:
     App\A:
       class: App\A
     App\B:
       class: App\B
       arguments: ["@App\\A"]
   ```

   Remarques : 
   * Nous avons besoin que les noms de services correspondent aux noms des
   classes complets pour que la future configuration automatique marche.
   * Pour rappel, on charge le fichier YAML dans le conteneur avec le code PHP suivant
     ```php
     $container = new ContainerBuilder();
     $loader = new YamlFileLoader($container, new FileLocator(__DIR__ . "/config"));
     $loader->load("services.yaml");     
     ```
   * À partir de maintenant, nous privilégierons la configuration par fichier YAML.
3. Afin de bientôt mettre en place le branchement automatique des services, nous avons
   besoin de compiler le conteneur.
   ```php
   $container = new ContainerBuilder();
   $loader = new YamlFileLoader($container, new FileLocator(__DIR__ . "/config"));
   $loader->load("services.yaml");
   $container->compile(); 

   $b = $container->get("App\B");
   $b->metier();
   ```
4. **Problème :** Ce code lève une exception avec le message (traduit en français)
   > Le service "App\B" a été supprimé lors de la compilation du conteneur. Vous
   > devriez soit le rendre public, soit arrêter d'utiliser le conteneur
   > directement.

   Dis autrement, comme le service `"App\B"` n'était pas utilisé au
   moment de la compilation (c'est-à-dire dans `services.yaml`), il a été
   supprimé lors de la compilation. Pour indiquer au compilateur de ne pas le
   supprimer car nous en aurons besoin plus tard (c'est-à-dire avec
   `$container->get`), il faut déclarer ce service `public`.
   ```yaml
   # config/services.yaml
   services:
     App\A:
       class: App\A
     App\B:
       class: App\B
       public: true
       arguments: ["@App\\A"]
   ```

5. La fonctionnalité de *autowire* (branchement automatique) du conteneur permet
   de détecter automatiquement les dépendances d'un service. Voici le code *YAML* correspondant

   ```yaml
   services:
     App\A:
       class: App\A
       autowire: true # Optionel car pas de dépendances
   
     App\B:
       class: App\B
       public: true
       autowire: true
   ```

   Remarque : Nous n'avons plus utilisé `arguments` dans `App\B` car les
   dépendances du constructeur ont été détectées automatiquement.

### Chargement automatique de services

Le conteneur peut aussi charger automatiquement toutes les classes d'un
répertoire en tant que services dans le conteneur. Voici le code YAML
correspondant

```yaml
services:
  _defaults:
    autowire: true  # Active le branchement automatique pour tous les services

  # Déclare un service par classe de src/ dont le nom est
  # le nom de classe complet avec l'espace de nom
  App\:
    resource: '../src/'

  # Nécessaire pour pouvoir appeler ce service avec $container->get
  App\B:
    public: true 
```


### Gestion des interfaces

Le branchement automatique de services (*autowire*) fonctionne en inspectant le
constructeur de `App\B`. À partir du type des arguments, il devine le nom des
services à brancher. Dans notre cas, le constructeur est 
`\App\B::__construct(private readonly App\A $a)`
donc l'*autowire* branche le service de nom `App\A`.

Cependant, comme vu en TD, la bonne pratique est que les services dépendent
d'interfaces, pas de dépendances concrètes. Un code préférable serait donc  
```php
// src/A_I.php
namespace App;
interface A_I
{
    public function travailler();
}
// src/A.php
namespace App;
class A implements A_I
{
    public function travailler() {
        return "Travail\n";
    }
}
// src/B.php    
namespace App;    
class B
{
    public function __construct(private readonly App\A_I $a) { }

    public function metier(){
        return $this->a->travailler();
    }
}    
```  

Pour des besoins pédagogiques, imaginons qu'il existe une deuxième implémentation de l'interface `A_I`

```php
// src/A2.php
namespace App;
class A2 implements A_I
{
    public function travailler() {
        return "Travail 2\n";
    }
}
```

Du coup, l'*autowire* branche le service de nom `App\A_I` comme argument du
constructeur de `App\B`. Mais il n'existe pas de service de nom `App\A_I` !

Il faut donc le créer. Ceci sera l'occasion d'indiquer quelle classe concrète doit être utilisée pour l'interface `A_I` (ici `App\A`).

```yaml
services:
  _defaults:
    autowire: true  # Active le branchement automatique pour tous les services

  # Utiliser le service de nom App\A pour les dépendances typées avec App\A_I
  App\A_I: '@App\A'

  # Déclare un service par classe de src/ dont le nom est
  # le nom de classe complet avec l'espace de nom
  App\:
    resource: '../src/'

  # Nécessaire pour pouvoir appeler ce service avec $container->get
  App\B:
    public: true 
```

**Cas particulier.** Si une seule classe implémente une interface, alors le
chargement automatique de services lie automatiquement ce service à l'interface.
Dans notre exemple, si `App\A` est la seule implémentation de l'interface
`App\A_I` détectée lors du chargement automatique de services dans le répertoire
`../src/`, alors le chargement automatique rajoute automatiquement la ligne
suivante au fichier de configuration *YAML*.

```yaml
App\A_I: '@App\A'
```


## Mise en place sur les TDs

Nous allons procéder en 3 étapes.

1. Il faut activer le branchement automatique des dépendances, ainsi que le
   chargement automatique pour toutes les classes dans le dossier `src`.

2. Certains services doivent être récupérés avec `$conteneur->get`. Il faut donc
   rendre publics `Twig\Environment`,
   `TheFeed\Controleur\ControleurPublication`,  
   `TheFeed\Controleur\ControleurUtilisateur` et `TheFeed\Controleur\ControleurGenerique`.

   **Remarque :** Le service `Symfony\Component\Routing\Generator\UrlGenerator`
   est aussi récupéré avec `$conteneur->get`. Cependant, ce service est défini à
   l'exécution (c'est-à-dire avec `$conteneur->set`) donc il n'est pas
   nécessaire de le rendre public. En effet, c'est à l'étape de compilation que
   les services non utilisés sont supprimés.
   
3. Il reste enfin à indiquer les services à brancher pour certaines interfaces.

   C'est le cas de `TheFeed\Configuration\ConfigurationBDDInterface`, utilisé
   par `ConnexionBaseDeDonnees`, car il existe plusieurs implémentations. 
   
   C'est aussi le cas de
   `Symfony\Component\DependencyInjection\ContainerInterface`, utilisé par
   `ControleurGenerique`. Dans ce cas, il n'y a pas d'implémentation trouvée
   dans le répertoire `src` de chargement automatique.

Au final, cela donne le fichier *YAML* suivant : 
```yml
services:
  _defaults:
    autowire: true  # Active le branchement automatique pour tous les services

  TheFeed\:
    resource: '..'

  TheFeed\Configuration\ConfigurationBDDInterface: '@TheFeed\Configuration\ConfigurationBDDMySQL'
  Symfony\Component\DependencyInjection\ContainerInterface: '@service_container'

  #Twig
  Twig\Loader\FilesystemLoader:
    class: Twig\Loader\FilesystemLoader
    arguments: ['%project_root%/src/vue/']
  Twig\Environment:
    class: Twig\Environment
    public: true
    arguments:
      $loader: '@Twig\Loader\FilesystemLoader'
      $options:
        autoescape: 'html'
        strict_variables: true
        debug: true

  #Controleurs
  TheFeed\Controleur\ControleurPublication:
    public: true

  TheFeed\Controleur\ControleurUtilisateur:
    public: true

  TheFeed\Controleur\ControleurGenerique:
    public: true
```

### Cas particulier de `ConnexionUtilisateurInterface`

Dans la fin du [TD5]({{site.baseurl}}/tutorials/tutorial3), vous aurez 2
services de connexion utilisateur qui implémentent l'interface
`ConnexionUtilisateurInterface` : le service `ConnexionUtilisateurSession` pour une
connexion basée sur les sessions, et `ConnexionUtilisateurJWT` pour une
connexion basée sur les JWT.

Cela pose un problème au branchement automatique de service (*autowiring*) qui ne sait pas quel service brancher dans le constructeur de `ControleurUtilisateur` : 
```php
public function __construct(
    private ContainerInterface $container,
    private PublicationServiceInterface $publicationService,
    private UtilisateurServiceInterface $utilisateurService,
    private ConnexionUtilisateurInterface $connexionUtilisateurSession,
    private ConnexionUtilisateurInterface $connexionUtilisateurJWT,
)
```

S'il n'y avait eu qu'une seule implémentation de l'interface, le conteneur de services aurait pu la brancher automatiquement, ou vous auriez pu le faire manuellement avec par exemple le code `YAML` suivant :
```yml
TheFeed\Lib\ConnexionUtilisateurInterface: '@TheFeed\Lib\ConnexionUtilisateurSession'
```

Mais il y a deux implémentations, et il faut indiquer quand il faut utiliser l'une et quand il faut utiliser l'autre.

Trois solutions s'offrent à vous :
* soit vous déclarez à la main toutes les dépendances de `ControleurUtilisateur` dans `conteneur.yml` pour outrepasser l'*autowiring* : 
  ```yml
  TheFeed\Controleur\ControleurUtilisateur:
    public: true
    arguments: ['@service_container',
                '@TheFeed\Service\PublicationServiceInterface',
                '@TheFeed\Service\UtilisateurServiceInterface',
                '@TheFeed\Lib\ConnexionUtilisateurSession',
                '@TheFeed\Lib\ConnexionUtilisateurJWT']  
  ```
* soit on configure explicitement l'*autowiring* pour certains paramètres du constructeur :
  ```php
  use Symfony\Component\DependencyInjection\Attribute\Autowire;

  public function __construct(
    private ContainerInterface $container,
    private PublicationServiceInterface $publicationService,
    private UtilisateurServiceInterface $utilisateurService,
    #[Autowire('@TheFeed\Lib\ConnexionUtilisateurSession')] private ConnexionUtilisateurInterface $connexionUtilisateurSession,
    #[Autowire('@TheFeed\Lib\ConnexionUtilisateurJWT')]     private ConnexionUtilisateurInterface $connexionUtilisateurJWT,
  )
  ```
* soit on donne à l'*autowiring* des indications de type **et** de nom de variable dans `conteneur.yml` pour décider du service à brancher : 
  ```yml
  # Si le type du paramètre est ConnexionUtilisateurInterface, on branche la connexion par session
  TheFeed\Lib\ConnexionUtilisateurInterface: '@TheFeed\Lib\ConnexionUtilisateurSession'
  # Si le type du paramètre est ConnexionUtilisateurInterface et le nom du paramètre est $connexionUtilisateurJWT, 
  # on branche la connexion par JWT (règle plus prioritaire)
  TheFeed\Lib\ConnexionUtilisateurInterface $connexionUtilisateurJWT: '@TheFeed\Lib\ConnexionUtilisateurJWT'
  ```


## Affichage du conteneur (Optionnel)

Si vous êtes curieux d'observer le conteneur compilé, vous pouvez
rajouter les lignes suivantes dans `RouteurURL.php` après la compilation :

```php
use Symfony\Component\DependencyInjection\Dumper\PhpDumper;

$conteneur->compile();
# Pensez à donner les droits d'écriture sur cache/container.php
$file = __DIR__ .'/../../cache/container.php';
$dumper = new PhpDumper($conteneur);
file_put_contents($file, $dumper->dump());
```

Vous pourrez aller voir le conteneur compilé dans `cache/container.php`. Ce
fichier ressemble à une *factory*. Pour information, *Symfony* utilise ce
système de cache du conteneur pour ne pas le recompiler à chaque fois.