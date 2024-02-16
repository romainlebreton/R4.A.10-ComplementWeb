---
title: Routes par attributs
layout: tutorial
lang: fr
---

Ce tutoriel vous montrer comment simplifier la création de routes. Vous allez
ainsi utiliser le même système que les professionels du Web qui utilisent
Symfony. 

1. On commence par rajouter un paquet

    ```bash
    composer require symfony/config
    ```

2. Puis on rajoute une classe `AttributeRouteControllerLoader` dans `src/Lib` : 

    ```php
    // src/Lib/AttributeRouteControllerLoader.php
    <?php

    namespace TheFeed\Lib;

    use Symfony\Component\Routing\Loader\AttributeClassLoader;
    use Symfony\Component\Routing\Route;

    class AttributeRouteControllerLoader extends AttributeClassLoader
    {
        /**
         * Configures the _controller default parameter of a given Route instance.
         */
        protected function configureRoute(Route $route, \ReflectionClass $class, \ReflectionMethod $method, object $annot): void
        {
            $route->setDefault('_controller', $class->getName().'::'.$method->getName());   
        }

    }
    ```

4. Enfin, dans `RouteurURL.php`, on remplace toute la création des routes dans `traiterRequete` par :

    ```php
    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\Routing\Loader\AttributeDirectoryLoader;
    use TheFeed\Lib\AttributeRouteControllerLoader;

    $fileLocator = new FileLocator(__DIR__);
    $attrClassLoader = new AttributeRouteControllerLoader();
    $routes = (new AttributeDirectoryLoader($fileLocator, $attrClassLoader))->load(__DIR__);
    ```

3. Les routes se créent maintenant avec la syntaxe simplifiée suivante : 

    ```php
    class ControleurPublication extends ControleurGenerique
    {

        #[Route('/publications', name:'afficherListe', methods:["GET"])]
        public static function afficherListe(): Response {
            // ...
        }
    }
    ```

    On retrouve le `path`, le nom de la route (pour les appels à
    `$generateurURL->generate()`) et les méthodes autorisées. 
    
    Le tableau qui associait `_controller` à
    `"\TheFeed\Controleur\ControleurUtilisateur::afficherListe"` sera rajouté
    par la méthode ci-dessus `AttributeRouteControllerLoader::configureRoute`,
    qui elle-même sera appelée dans le mécanisme de `AttributeDirectoryLoader`
    de Symfony.