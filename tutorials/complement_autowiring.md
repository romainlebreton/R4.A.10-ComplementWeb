---
title: Configuration automatique des services
subtitle: Autowire
layout: tutorial
lang: fr
---

Ce tutoriel vous montre comment configurer automatiquement le conteneur de services.

Le [composant d'injection de dépendances de Symfony](https://symfony.com/doc/current/components/dependency_injection.html)
est capable de détecter automatiquement quelles sont les dépendances de vos services.

<!-- TODO avec une interface -->


1. Pour configurer les dépendances de notre exemple ainsi que le chargement de
   classe, nous partirons avec le `composer.json` suivant

   ```json
   {
     "require": {
       "symfony/dependency-injection": "^7.0",
       "symfony/config": "^7.0",
       "symfony/yaml": "^7.0"
     },
     "autoload": {
       "psr-4": {
         "App\\": "src"
       }
     }
   }
   ```

   Exécutez la commande suivante pour installer les paquets 

   ```bash
   composer install
   ```

2. Plaçons-nous dans l'exemple où nous avons deux classes `A` et `B` avec `B` qui dépend de `A` : 

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

3. Pour créer les services correspondants à `A` et `B` dans le conteneur, nous
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

4. La fonctionnalité de *autowire* (branchement automatique) du conteneur permet
   de détecter automatiquement les dépendances d'un service. Voici le code PHP correspondant.

   ```php
   // script.php
   $container = new ContainerBuilder();
   $container->register(A::class, A::class)->setAutowired(true)->setPublic(true);
   // Les services doivent être publics pour pouvoir activer l'autowire
   $container->register(B::class, B::class)->setAutowired(true)->setPublic(true);
   // Il faut compiler de conteneur qu'il détecte les dépendances    
   $container->compile();   
   $b = $container->get(B::class);
   $b->metier(); 
   ```

   ou de manière équivalente en *YAML*

   ```yaml
   services:
     App\A:
       class: App\A
       autowire: true
       public: true
   
     App\B:
       class: App\B
       autowire: true
       public: true
   ```

   Remarque : Nous n'avons pas utilisé `setArguments` / `arguments` car les
   paramètres du constructeur sont détectées automatiquement.

4. Le conteneur peut aussi charger automatiquement toutes les classes d'un
   répertoire en tant que services dans le conteneur. Voici le code YAML
   correspondant

   ```yaml
   services:
     # default configuration for services in *this* file
     _defaults:
       autowire: true      # Automatically injects dependencies in your services.
       public: true
   
     # makes classes in src/ available to be used as services
     # this creates a service per class whose id is the fully-qualified class name
     App\:
       resource: '../src/'
   ```