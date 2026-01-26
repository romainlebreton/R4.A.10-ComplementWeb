---
title: Routes par attributs
layout: tutorial
lang: fr
---

Ce tutoriel vous montre comment simplifier la création de routes. Vous allez
ainsi utiliser le même système que les professionnels du Web qui utilisent
Symfony. 

Plutôt que d'ajouter toutes les routes dans la fonction `traiterRequete` de la classe 
`RouteurURL`, on aimerait plutôt pouvoir définir chaque **route** au-dessus de l'action
qui doit être déclenchée par la route. Cela est possible en utilisant le mécanisme 
**d'attributs** (qui vient de `PHP`) qui permet de configurer certaines méta-données au-dessus 
de méthodes, de classes, etc.

L'objectif est d'arriver à quelque-chose comme l'exemple suivant :

```php
class MonControleur extends ControleurGenerique
{

    #[Route(path: '/exemple', name:'routeExemple', methods:["GET"])]
    public static function monAction(): Response {
        // ...
    }
}
```

Ici, on définit une route nommée `routeExemple`, qui a pour chemin `/exemple` et qui est 
seulement accessible via la méthode `GET`. L'action déclenchée par cette route est la
méthode placée sous l'attribut : `monAction`.

Pour faire fonctionner cela dans notre framework maison, il faut suivre quelques étapes.

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

    Cette classe va nous permettre de traiter un **attribut** définissant une route afin d'enregistrer ses informations dans la liste des routes (notamment le contrôleur et la méthode à appeler...).

3. Enfin, dans `RouteurURL.php`, on remplace toute la création des routes dans `traiterRequete` par :

    ```php
    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\Routing\Loader\AttributeDirectoryLoader;
    use TheFeed\Lib\AttributeRouteControllerLoader;

    $fileLocator = new FileLocator(__DIR__);
    $attrClassLoader = new AttributeRouteControllerLoader();
    $routes = (new AttributeDirectoryLoader($fileLocator, $attrClassLoader))->load(__DIR__);
    ```

    Les trois lignes ajoutées permettent de :
    * Initialiser un `FileLocator` qui permet de préciser dans quel répertoire chercher les classes avec des attributs. La valeur `__DIR__` représente le dossier courant (donc `Controleur`).
    * Initialiser notre service `AttributeRouteControllerLoader` créé plus tôt, qui permet de créer une route à partir d'un attribut.
    * Enfin, on explore tous les contrôleurs à la recherche d'attributs qui définissent des routes et on ajoute les routes correspondantes dans la collection. 

4. Les routes se créent maintenant avec la syntaxe simplifiée suivante : 

    ```php
    use Symfony\Component\Routing\Attribute\Route;

    class ControleurPublication extends ControleurGenerique
    {

        #[Route(path: '/publications', name:'afficherListe', methods:["GET"])]
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