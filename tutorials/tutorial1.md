---
title: TD1 &ndash; Paquets PHP
subtitle: Composer, Twig
layout: tutorial
lang: fr
---

<!-- 
Faille XSS 
-->

## But du TD

### Point de départ

Dans les 3 premiers TDs centrés sur PHP, nous allons construire un site de type
**réseau social** appelé '**The Feed**'. Ce site contiendra un fil principal de
publications et un système de connexion d'utilisateur.


Code de base sur GitLab

Site de blog : 
* contrôleur `Publication` : 
  * lire les publications : action `feed`
  * écrire une publication : action `submitFeedy`
* contrôleur `Utilisateur` :
  * afficher la page personnelle avec seulement ses publications : action `pagePerso`
  * s'inscrire : 
    * formulaire (action `afficherFormulaireCreation`), 
    * traitement (action `creerDepuisFormulaire`)
  * se connecter : 
    * formulaire (action `afficherFormulaireConnexion`), 
    * traitement (action `connecter`)
  * se déconnecter : action `deconnecter`

## Composer

### Installation

Pour installer `Twig` dans votre application, nous allons utiliser le **gestionnaire de dépendances** `composer`. Il s'agit d'un outil utilisé dans le cadre du développement d'applications PHP pour installer des composants tiers. `Composer` gère un fichier appelé `composer.json` qui référence toutes les dépendances de votre application. 

Quand on installe une application ou un nouveau composant, `composer` place les librairies téléchargées dans un dossier `vendor`. Il n'est pas nécessaire de versionner ou de transporter ce dossier (souvent volumineux) en dehors de votre environnement de travail. En effet, quand vous souhaiterez installer votre application dans un autre environnement (une autre machine), seul le fichier `composer.json` suffit. Lors de l'installation, ce fichier sera lu et les dépendances seront téléchargées et installées automatiquement.

Pour utiliser `composer`, il faut se placer à la **racine du projet**, là où se trouve (ou se trouvera après l'installation de `Twig`) le fichier `composer.json`.

<div class="exercise">

1. Ouvrez un terminal à la racine de votre projet et exécutez la commande suivante :

   ```bash
   composer require twig/twig
   ```

2. Attendez la fin de l'installation. Allez observer le contenu du fichier `composer.json` fraichement créé ainsi que le contenu du dossier `vendor`.
</div>

Quelques conseils :

   * Sur une autre machine (ou dans un nouvel environnement), pour installer les dépendances (et donc initialiser le dossier `vendor`), il suffit d'exécuter la commande :

   ```bash
   composer install
   ```

   * Si vous modifiez le fichier `composer.json` ou que vous souhaitez simplement mettre à jour vos dépendances, vous pouvez exécuter la commande :

   ```bash
   composer update
   ```

### Autoloading

C'est bon, Twig est installé! Nous allons maintenant l'initialiser. Mais tout d'abord, il faut charger **l'autoloader** de `composer`.

Vous l'aurez constaté, il est assez pénible de devoir appeler l'instruction `require_once` pour utiliser une classe dans un fichier. En plus, cela peut devenir vite compliqué car il faut indiquer le chemin relatif du fichier en question, qu'il faudrait donc changer si on déplace le fichier utilisant la classe en question... (pour l'instant, toutes nos classes sont dans le même dossier, mais cela serait plus complexe dans une application avec différentes **couches** et donc une structures avec plusieurs dossiers). 

Fort heureusement, il existe un sytème similaire aux `packages` et aux `imports` de **Java**. Pour chaque classe, on définit un `namespace` (qui est le "package" où elle se trouve). Enfin, quand on veut utiliser la classe, il suffit de l'improter avec l'instruction `use` en précisant son package. Il n'y a plus à se soucier du chemin réel du fichier. Il faut alors d'indiquer à composer où se situe le package d'entrée (quel dossier) puis, son `autoloader` se chargera de faire les imports nécessaires. Pour utiliser l'autoloading, il suffit de le charger dans le script php utilisé, en indiquant son chemin :

```php
require_once __DIR__ . '/vendor/autoload.php';
```

La variable `__DIR__` permet de récupérer le dossier où se trouve le fichier qui utilise cette variable. Dans notre contexte, le fichier d'autoloading se situe dans le sous-dossier `vendor` par rapport au fichier `feed.php`.

Dans l'immédiat, nous n'en avons pas encore besoin d'autolaoding pour nos propres classes (cela viendra) mais `Twig` lui en a besoin.


## Composant `HTTPFoundation`

Le composant `HttpFoundation` défini une couche orientée objet pour la spécification *HTTP*.

En *PHP*, une requête est représentée par des variables globales (`$_GET`,
`$_POST`, `$_FILES`, `$_COOKIE`, `$_SESSION`, ...), et la réponse est générée
par des fonctions (`echo`, `header()`, `setcookie()`, ...).

Le composant `HttpFoundation` de `Symfony` remplace ces variables globales et
fonctions par une couche orientée objet.

[Documentation](https://symfony.com/doc/current/components/http_foundation.html)

## Composant Twig

`Twig` est un **moteur de templates** qui permet de générer tout type de document (pas seulement de l'HTML!) en utilisant des données passées en paramètres. Twig fournit toutes les structures de contrôles utiles (if, for, etc...) et permet de placer les données de manière fluide. Il est aussi possible d'appeler des méthodes sur certaines données (des objets) et d'appliquer certaines fonctions (ou filtres) pour transformer les données (par exemple, mettre en majuscule la première lettre...).

Twig permet également de construire des modèle de templates qui peuvent être étendus et modifiés de manière optimale. Le template va définir des espaces nommés `blocs` qu'il est alors possible de redéfinir indépendamment dans un sous-template. Cela va nous être très utile par la suite!

Il est aussi possible d'installer (ou de définir soi-même) des extensions pour ajouter de nouvelles fonctions de filtrage! On peut aussi définir certaines variables globales accessibles dans tous les templates.

Dans notre contexte, nous utiliserons `Twig` pour générer nos pages HTML car cela présente différents avantages non négligeables :

   * Le langage est beaucoup moins verbeux que du PHP, il est beaucoup plus aisé de placer les données aux endroits désirés de manière assez fluide.
   * En spécifiant un petit paramètre, les pages générées avec `Twig` seront naturellement protégées contre les failles `XSS`! (plus besoin d'utiliser `htmlspecialchars`).
   * Nous allons pouvoir définir des templates globaux pour l'affichage des éléments identiques à chaque page (header, footer, etc...) et ainsi de pas répéter le code à plusieurs endroits.

### Le langage

* L'instruction ```{% raw %}{{ donnee }}{% endraw %}``` permet d'afficher une donnée à l'endroit souhaité (à noter : **les espaces après et avant les accolades sont importants!**). On peut également appeler des méthodes (si c'est un objet) : ```{% raw %}{{ donnee.methode() }}{% endraw %}```. On peut aussi appeler une fonction définie par `Twig` ou une de ses extensions : ```{% raw %}{{ fonction(donnee)) }}{% endraw %}```. Ou bien un filtre, par exemple : ```{% raw %}{{ donnee|upper }}{% endraw %}``` pour passer une chaîne de caractères en majuscule. Il est aussi possible de combiner plusieurs filtres, par exemple ```{% raw %}{{ donnee|lower|truncate(20) }}{% endraw %}```.

* Il est possible de définir une variable locale : 

```twig
{% raw %}
{% set exemple = "coucou" %}
<p>{{exemple}}</p>
{% endraw %}
```

* La structure conditionnelle `if` permet de ne générer une partie du document que si une condition est remplie :

```twig
{% raw %}
{% if test %}
   Code HTML....
{% endif %}
{% endraw %}
```

Il est bien sûr possible de construire des conditions complexes avec les opérateur : `not`, `and`, `or`, `==`, `<`, `>`, `<=`, `>=`, etc... par exemple :

```twig
{% raw %}
{% if test and (not (user.getName() == 'Simith') or user.getAge() <= 20) %}
   Code HTML....
{% endif %}
{% endraw %}
```

* La structure conditionnelle `for` permet de parcourir une structure itérative (par exemple, un tableau) :

```twig
{% raw %}
{% for data in tab %}
   <p>{{ data }}</p>
{% endfor %}
{% endraw %}
```

Si c'est un tableau associatif et qu'on veut accèder aux clés et aux valeurs en même temps :

```twig
{% raw %}
<ul>
{% for key, value in tab %}
   <li>{{ key }} = {{ value }}</li>
{% endfor %}
<ul>
{% endraw %}
```

On peut aussi faire une boucle variant entre deux bornes : 

```twig
{% raw %}
{% for i in 0..10 %}
    <p>{{ i }}ème valeur</p>
{% endfor %}
{% endraw %}
```

Pour créer un `bloc` qui pourra être **redéfini** dans un sous-template, on écrit simplement :

```twig
{% raw %}
{% block nom_block %}
   Contenu du bloc...
{% endblock %}
{% endraw %}
```

Pour **étendre** un template, au début du novueau template, on écrit simplement :

```twig
{% raw %}
{% extends "nomFichier.html.twig" %}
{% endraw %}
```

Par exemple, imaginons le template suivant, `test.html.twig` :

```twig
{% raw %}
<html>
   <head>
      <title>{% block titre %}Test {% endblock %}</title>
   </head>
   <body>
      <header>...</header>
      <main>{% block main %} ... {% endblock %}</main>
      <footer>...</footer>
   </body>
</html>
{% endraw %}
```

Vous pouvez alors créer le sous-template suivant qui copiera exactement le contenu de `test.html.twig` et modifiera seulement le titre et le contenu du main : 

```twig
{% raw %}
{% extends "test.html.twig" %}
{% block titre %}Mon titre custom{% endblock %}
{% block main %} <p>Coucou!</p> {% endblock %}
{% endraw %}
```

Il n'est pas obligatoire de redéfinir tous les blocs quand on étend un template. Dans l'exemple ci-dessus, on aurait pu seulement redéfinir le bloc `main` sans changer le titre de la page, par exemple.

Il est tout à fait possible d'utiliser un bloc de structure à l'intérieur d'un autre bloc de structure. Il est aussi tout à fait possible de créer un bloc rédéfinissable à l'intérieur d'un autre bloc...Il est aussi possible de faire des sous-templates de sous-templater. Voyez ça comme une hiéarchie entre classes! Les blocs sont comme des méthodes de la classe parente qu'il est possible de redéfinir!

Pour en savoir plus sur `Twig`, vous pouvez consulter [La documentation officielle](https://www.branchcms.com/learn/docs/developer/twig).

### Initialisation de Twig

`Twig` s'initialise comme suit :

```php
//Au début du fichier, après avoir chargé l'autodloader
use Twig\Environment;
use Twig\Loader\FilesystemLoader;

//On doit indiquer à Twig où sont situés nos templates. 
$twigLoader = new FilesystemLoader(cheminVersDossierTemplate);

//Permet d'échapper le texte contenant du code HTML et ainsi éviter la faille XSS!
$twig = new Environment($twigLoader, ["autoescape" => "html"]);
```

<div class="exercise">

1. Créez un dossier `templates` à la racine de votre projet.

2. Dans votre fichier `feed.php`, chargez l'autoloader de `composer` au tout début.

3. Importez les classes de `Twig` nécéssaires (avec `use`).

4. Initialisez `Twig`. Vous préciserez que les templates se trouvent dans le sous dossier `templates` par rapport au fichier `feed.php`. Vous pouvez pour cela réeutiliser une syntaxe similaire au chemin utilisé pour charger l'autoloader.

5. Rechargez votre page. S'il n'y a pas d'erreurs, c'est que c'est bon! Nous allons maintenant l'utiliser...

</div>

### Un premier template

Vous allez maintenant utiliser un **template** Twig pour réaliser l'affichage de la page principale de **The Feed**.

Pour générer le résultat obtenu via un **template** Twig, il faut éxécuter le code :

```php
//sousCheminTemplate : Correspond au sous-chemin du template à partir du dossier de template indiqué à twig. S'il se trouve à la racine du dossier de templates, on indique alors seulement son nom

// tableauAssociatif : Un tableau associatif de paramètres passés au template. Par exemple si on lui donne ["message" => $test], une variable "message" sera utilisable dans le template twig.

$page = $twig->render(sousCheminTemplate, tableauAssociatif);

//Puis, pour l'afficher comme réponse
echo $page
```

Par exemple, si je veux charger le fichier `personne.html.twig` situé à la racine du dossier `templates` en lui passant un objet Personne en paramètre, je peux faire :

```php
$personne = ...

$page = $twig->render('personne.html.twig', ["personne" => $personne]);
echo $page
```

Bien sûr, on peut passer plusieurs paramètres (il suffit de les ajouter au tableau associatif).

<div class="exercise">

1. Dans le dossier `templates`, créez un fichier nommé `firstFeed.html.twig`.

2. Déplacez le code HTML (mêlé de PHP) permettant de générer la page dans votre nouveau template. Pour rappel, il devrait avoir cette allure :

   ```php
   <!DOCTYPE html>
   <html lang="fr">
      <head>
         <title>The Feed</title>
         <meta charset="utf-8">
         <link rel="stylesheet" type="text/css" href="styles.css">
      </head>
      <body>
         <header>
               <div id="titre" class="center">
                  <a href="feed.php"><span>The Feed</span></a>
               </div>
         </header>
         <main id="the-feed-main">
               <div id="feed">
                  <form id="feedy-new" action="feed.php" method="post">
                     <fieldset>
                           <legend>Nouveau feedy</legend>
                           <div>
                              <textarea minlength="1" name="message" placeholder="Qu'avez-vous en tête?"></textarea>
                           </div>
                           <div>
                              <input id="feedy-new-submit" type="submit" value="Feeder!">
                           </div>
                     </fieldset>
                  </form>
                  <?php foreach ($publis as $publi) { ?>
                     <div class="feedy">
                           <div class="feedy-header">
                              <img class="avatar" src="anonyme.jpg" alt="avatar de l'utilisateur">
                              <div class="feedy-info">
                                 <span><?php echo $publi->getLoginAuteur() ?> </span>
                                 <span> - </span>
                                 <span><?php echo $publi->getDateFormatee()?></span>
                                 <p><?php echo $publi->getMessage() ?></p>
                              </div>
                           </div>
                     </div>
                  <?php } ?>
               </div>
         </main>
      </body>
   </html>
   ```
3. Adaptez ce code pour utiliser le langage de `Twig` à la place, en remplaçant toutes les parties PHP. Vous pouvez considérer qu'un tableau nommé `publications` est passé en paramètre à ce template. 

4. Dans `feed.php` récupérez la page généré par `Twig` en utilisant ce template en passant en paramètres les `publications` récupérées depuis le repository. Affichez cette page avec `echo`.

5. Rechargez la page et observez qu'elle s'affiche toujours bien, mais cette fois, en étant générée par `Twig`!

</div>


### Division des tâches

Dans notre page, on peut distinguer clairement une partie commune qui sera similaire à toutes nos futures pages et une autre partie spécifique à la page courante. :

* La strucutre de base de la page, une partie du head et le header seront communs à toutes les pages

* Le titre de la page et une partie du body seront spécifiques à la page courante.

<div class="exercise">

1. Créez un template `base.html.twig` dans le dossier `templates`.

2. Dans ce template, reprenez tout le contenu du template `firstFeed.html.twig` sauf le `<main>`.

3. Effacez le titre contenu dans `<title>` et à la place, créez un `block` nommé `page_title`.

4. Au tout début du **body**, créez un `block` nommé `page_content`.

</div>

Vous venez de créer le template "de base". Toutes les pages de notre application vont l'étendre afin de posséder la même structure et injecteront leur propre titre et leur propre contenu dans les blocs correspondants.

<div class="exercise">

1. Dans le dossier `templates`, créez un sous-dossier `Publications`.

2. Créez un template `feed.html.twig` dans le dossier `Publications` et faites en sorte qu'il **étende** le template `base.html.twig`.

3. Dans ce template, redéfinissez les `blocks` **page_title** et **page_content** afin d'y placer respectivement le `titre` de la page et le `main` initialement définis dans `firstFeed.html.twig`.

4. Supprimez le template `firstFeed.html.twig`

5. Modifiez `feed.php` afin qu'il génère la page en utilisant le template `Publications/feed.html.twig`.

6. Rechargez votre page et vérifiez que tout fonctionne bien.

</div>

Pour mieux comprendre l'efficacité de ces templates et vérifier que vous savez les mainpuler, vous allez créer une autre page.

<div class="exercise">

1. Dans le dossier `templates`, créez un sous-dossier `Test`.

2. Créez un template `exemple.html.twig` dans le dossier `Test` et faites en sorte qu'il **étende** le template `base.html.twig`.

3. Dans ce template, redéfinissez les `blocks` **page_title** et **page_content** afin d'y placer respectivement le `titre` "Exemple" et un élément HTML `<main> ... </main>` contenant `<p>Coucou!</p>`.

4. A la racine de votre projet, créez un fichier `exempleTemplate.php`.

5. Dans ce fichier, faites en sorte d'afficher la page générée par le template `exemple.html.twig`.

6. Chargez cette page à l'adresse : 

   [http://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD2/exempleTemplate.php)](http://webinfo.iutmontp.univ-montp2.fr/~mon_login_IUT/TD2/exempleTemplate.php) et observez le résultat!

</div>
