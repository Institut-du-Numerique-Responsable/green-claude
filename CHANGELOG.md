# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et les
nouvelles versions suivent [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté

- Page de présentation et README : la démarche « numérique responsable by design » et le bon sens paysan qui inspire les règles, illustrés par des règles réelles (ECO-FRONT-01, ECO-ALGO-02, ECO-BACK-01, ECO-BACK-04, ECO-PY-11). Mots-clés `green IT by design`, `responsible digital` et `numérique responsable` ajoutés à `plugin.json`.
- Page de présentation : étape « Le rendre automatique » du tuto mise à jour avec la ligne ciblée pour `CLAUDE.md`, mode économe dans l’encadré sur les tokens, exemple d’audit régénéré (`fichier:ligne`, `--compact`), sections « Adapter Green Claude à votre façon de travailler » et « Questions fréquentes », lien vers les notes de version.
- Découvrabilité : bloc JSON-LD `FAQPage` reprenant la FAQ visible, `SoftwareSourceCode` enrichi (`targetProduct`, `programmingLanguage`, `isAccessibleForFree`), meta description ramenée sous 160 caractères, `theme-color`, `llms.txt` complété (options, mode économe, dernière version), `repository-overview.md` à jour sur le nombre de règles.
- README : section « Charger le skill au bon moment », qui explique comment une ligne dans `CLAUDE.md` fait charger le skill sur les tâches qui décident du coût du code, et pourquoi la limiter à ces tâches.

### Modifié

- `eco-audit.sh` calcule l’extension de chaque fichier une seule fois, au lieu d’une fois par règle. Un fichier d’une ligne lançait environ 155 processus, dont 120 pour ce seul calcul ; il en lance 82. Le hook `PostToolUse` passe de 491 à 353 ms sur un fichier Python à six résultats, et l’audit des scripts et pages du dépôt de 3,9 à 2,3 s. Sortie identique.


### Corrigé

- `test-eco-audit.sh` et `test-audit-entrypoints.sh` échouaient chez un utilisateur qui a activé `GREEN_CLAUDE_LEAN` : ils héritaient de la variable. Ils la retirent maintenant au démarrage.


## [1.6.0] - 2026-11-26

### Ajouté

- Mode économe `GREEN_CLAUDE_LEAN` (bloc `env` de `settings.json`) : `report` coupe le bilan NR-TOK-030 de fin de tâche, `brief` le rappel des trois questions avant une demande de code, `audit` réduit la sortie du hook `PostToolUse` à une ligne par résultat ; `all` coupe les trois. Les valeurs se combinent avec des virgules. La détection ne change pas. Sur un fichier Python à 6 résultats, le hook d’audit passe de 4 470 à 1 811 octets. Ludovic NACHURY a demandé ce mode.
- Section « Options et configuration » dans les README : options de `eco-audit.sh` et `eco-score.sh`, codes de sortie, et toutes les variables d’environnement `GREEN_CLAUDE_*` avec leur valeur par défaut.
- `eco-audit.sh --compact` : une ligne par résultat (`[impact] ID titre — fichier:ligne — recommandation`). `SKILL.md` en fait la commande d’audit par défaut, puis demande l’audit complet sur les fichiers retenus, pour l’exemple corrigé et la `Note`.
- Détecteur `detect-string-concat-loop.awk` pour ECO-PY-07 : il signale `out += c.client.nom` dans le corps d’une boucle quand la variable a reçu une chaîne, et se tait hors boucle comme sur un compteur numérique.
- `eco-audit.sh` cite la ligne de chaque résultat (`File : views.py:12`) et jusqu’à quatre occurrences suivantes (`Also at lines`). Les numéros renvoient au fichier réel, même quand l’audit a retiré des commentaires ou le texte HTML avant la recherche. Claude n’a plus à relancer un grep pour localiser un résultat. `--help` affiche l’usage.
- Dix règles Swift (ECO-SW-06 à ECO-SW-15), tirées de l'Energy Efficiency Guide d'Apple et du RGESN : précision de localisation maximale, localisation laissée en arrière-plan, timer sans tolérance, écran maintenu allumé, tâche de fond lourde qui n'attend pas le secteur, session réseau qui ignore le mode Données réduites, image décodée en pleine taille, `@ObservedObject` créé par la vue, requête Core Data sans limite, `UserDefaults.synchronize()`. Chacune se tait quand le fichier applique déjà la bonne pratique. Le total passe à 137 règles de langage et 287 règles.

### Corrigé

- ECO-HEB-11 ne prend plus une lecture pour une écriture : `open()` à un argument, mode `"r"`, `file_get_contents`, `File.read`, `os.ReadFile`. Écrire un CSV sans compression reste signalé.
- ECO-PY-10 se tait quand le fichier crée une `requests.Session()` ou un client `httpx`/`aiohttp`.
- `install.sh` ne copie plus le skill dans `~/.claude/skills` quand le plugin Claude Code est installé en portée utilisateur : le skill apparaissait deux fois (`green-claude` et `green-claude:green-claude`). Il signale une copie existante et donne la commande pour la retirer. Les hooks d’audit et de pre-commit retrouvent les scripts du plugin.

### Modifié

- `SKILL.md` : la description cite d’abord les déclencheurs implicites (lenteur, requête N+1, pagination, poids du bundle ou des images). La consigne sur le compromis apparaît une fois au lieu de trois, *Common mistakes* rejoint *Reporting what you find*, et les règles de style des réponses passent dans `references/style.md`.
- Sur un fichier inexistant ou une option inconnue (`--help`), `eco-audit.sh` concluait « No ecodesign issue found ». Il nomme maintenant l’argument fautif et sort en code 2 sans rien analyser.
- Faux positifs relevés sur une app macOS en Swift (purge-app, 259 fichiers Swift : 98 signalements avant, 8 après, dont 3 nouveaux et fondés) :
  - ECO-FRONT-05 ne prend plus pour du code mort l'intérieur d'une closure ouverte par un `return` (`return xs.map { x in`) ou par une ligne de suite (`.filter { name in`), une chaîne multiligne `"""`, une suite par `==`, `!=`, `<`, `>`, ni une branche `#else`/`#endif` ou `@unknown default:` ; le code qui suit la fin de l'instruction reste signalé ;
  - ECO-SW-04 ne vise plus que le chargement synchrone d'une ressource web (`Data(contentsOf: URL(string: "https://…"))`) et passe en impact élevé ; lire en entier un petit fichier local (réglages, magasin JSON, ressource du bundle) n'est plus signalé ;
  - ECO-CONT-01 ignore un format d'image passé à une API Swift (`representation(using: .png)`, `UTType.png`, `pngData()`, `jpegData(`) ; un fichier `.png` référencé reste signalé.
- L’archive Claude.ai était refusée à l’import : « Skill name in SKILL.md cannot contain the reserved word 'claude' » (#54). Dans les deux archives (`green-claude-claude-ai.zip`, `green-claude-api.zip`), le skill s’appelle désormais `green-coding`, dans le champ `name` comme pour le dossier racine. Les noms des fichiers zip et le plugin Claude Code ne changent pas. `package-skill.sh` refuse un nom qui contient un mot réservé, et `test-eco-audit.sh` le vérifie.
- Faux positifs sur les scripts qui génèrent des fichiers bureautiques (retour d'usage GPC-ONR) :
  - ECO-HEB-11 ne se déclenche plus quand on lit un JSON ou un CSV (`read_text`, `json.load`, `csv.reader`…), ni quand le fichier écrit dans une archive déjà compressée (`ZIP_DEFLATED`, `zlib`, `lzma`, `bz2`) ;
  - ECO-CONT-01 ignore les PNG et JPEG embarqués dans un document OOXML (`xl/media/`, `word/media/`, `ppt/media/`, `add_picture`), où Office ne lit pas le WebP de façon fiable ;
  - ECO-STRAT-03 ne signale plus un fichier Office produit en même temps qu'un équivalent ouvert (CSV, JSON, ODF).
- Tests de non-régression dans `test-eco-audit.sh`, dans les deux sens : silence sur le cas légitime, détection maintenue sans la bonne pratique.
- Faux positifs relevés en administrant des serveurs (novembre 2026) :
  - ECO-FRONT-05 ne prend plus pour du code mort la ligne de suite d'un `return` qui commence par un opérateur (`&&`, `||`, `.`, `->`, `?`…) ; le code qui suit la fin de l'instruction reste signalé ;
  - ECO-SH-04 ne signale plus qu'un `sleep` placé dans le corps d'une boucle (nouveau détecteur `detect-polling-loop.awk`) : une pause isolée n'est pas une attente active ;
  - ECO-HEB-05 ignore une substitution `sed` qui remplace TLS 1.0/1.1 par TLS 1.2/1.3 ; une configuration obsolète reste signalée.
- Les règles de langage (`rules/langages/`) peuvent désormais utiliser un détecteur multi-lignes, comme les règles générales.

## [1.5.0] - 2026-10-21

### Ajouté

- Page de présentation (`docs/index.html`) refaite aux couleurs de l’INR : public élargi aux product owners, métiers, designers et rédacteurs, tutoriel en cinq étapes pour une première demande sans code (Claude.ai ou Claude Code), demandes à copier par profil, encadré sur la sobriété des tokens. Vidéo de démonstration de 2 minutes intégrée (`docs/assets/video/`, 600 Ko, chargée au clic seulement, affiche de 7 Ko).
- Mention de Caveman (Julius Brussee, Apache 2.0) dans `NOTICE` et les README : quelques idées des règles NR-TOK en viennent, règles remaniées et réécrites par l’INR ; sa licence était indiquée à tort comme MIT.
- Référentiel `rules/tokens.json` : 30 règles NR-TOK de sobriété des tokens pour les agents IA (réponses, contexte, opérations, modèles, qualité et mesure), avec leur priorité (7 obligatoires, 5 conditionnelles) et le format du bilan de session, exigé après toute tâche qui lance des outils ou modifie des fichiers. Consignes courtes et concrètes, vue compacte sous 6 Ko. Affiché par `eco-audit.sh --rules tokens` et inclus dans `--rules all` et `--list-rules`.
- Passage du corpus de 146 à 225 règles : 83 transverses, 127 de langage sur 24 fichiers, 15 pratiques d’usage.
- Quatorze langages et frameworks supplémentaires : Go, Kotlin, Swift, Shell, Scala, Julia, Nim, Zig, React (Preact compris), Vue, Angular, Svelte, Astro, Solid.
- Cadre 3U de l’Institut du Numérique Responsable (utile, utilisable, utilisé) porté par un champ `three_u` sur 29 règles, avec accessibilité (`ECO-UX-08`) et fin de vie (`ECO-STRAT-07`) qui comblaient les deux volets les plus faibles.
- Trois règles en amont du code : le moins de code qui résout le problème (`ECO-ARCH-07`), challenger la demande et le modèle (`ECO-ALGO-08`), poser la question avant de coder (`USAGE-BRIEF-03`).
- Vingt-quatre règles adaptées de green-codex sous CC BY 4.0, chacune citant sa source.
- Exemples avant/après sur les 46 règles à impact élevé détectables, affichés par l’audit sous `Instead of` et `Write`.
- Registre de décisions `.green-claude/decisions.md` : ce que l’équipe a tranché n’est plus resignalé, et l’audit annonce ce qu’il a tu.
- Fichier d’exclusion `.green-claude/ignore` pour les fixtures et catalogues d’exemples, qui contiennent du code fautif sans jamais l’exécuter.
- Hook `UserPromptSubmit` de cadrage (`hooks/green-claude-brief.sh`), qui rappelle les trois règles amont sur une demande de production de code et se tait sur une question.
- Option `eco-audit.sh --rules <famille|langage|fichier|usage|all>` : vue compacte des règles, une ligne par règle (impact, identifiant, titre, recommandation), sans les motifs, exemples et notes destinés à l’audit. Un nom de fichier est résolu par son extension, avec la même table que l’audit.

### Modifié

- Doublons fusionnés : USAGE-CTX-06 (réponses denses), USAGE-CPU-01 (niveau d’effort) et USAGE-CPU-02 (panels d’agents) disparaissent au profit de NR-TOK-001 à 005, 023 et 024, qui reprennent leurs nuances (effort recommandé par le client, comparaison avec une exécution plus simple avant de lancer des sous-agents, contexte gonflé par une réponse délayée). 13 pratiques d’usage, 277 règles.
- `SKILL.md` encadre la rédaction des réponses : pas de tiret quadratin, pas d’annonce, de pseudo-clivée, de présentatif emphatique, d’épanorthose, d’anaphore, d’antithèse binaire ni d’énumération annoncée, et passage par le skill `stop-slop` quand il est installé.
- `SKILL.md` renvoie vers `eco-audit.sh --rules` au lieu de faire lire les fichiers de règles bruts : 1,7 Ko au lieu de 8,8 Ko pour Python, 3 Ko au lieu de 22 Ko pour un `.tsx`, 27 Ko au lieu de 150 Ko pour la checklist complète. Le tableau des extensions disparaît de `SKILL.md`, le script le portant déjà.

- Objectif du skill énoncé en tête de `SKILL.md` et dans les métadonnées des règles : livrer du code qui consomme le moins possible de tokens pendant la session, de temps CPU et de mémoire à l'exécution, d'octets sur le réseau, de stockage, et donc d'énergie.
- Lien tokens/énergie assumé dans sa direction et refusé dans son rapport : moins de tokens traités, c'est moins de calcul, et moins de calcul, c'est moins d'énergie ; convertir un nombre de tokens en watts ou en grammes de CO2 reste interdit sans mesure, le cache de prompt, la taille du modèle, le batching, le matériel et le mix électrique pesant chacun davantage. `USAGE-CTX-01` et `USAGE-CTX-03` portent désormais cette raison, et trois tests vérifient qu'elle ne disparaît pas.

- Règles et sortie de l’audit passées en anglais, pour ouvrir les contributions au-delà des francophones. `gr491_famille` garde son libellé français : c’est le nom officiel d’une famille du référentiel.
- Coût de l’audit divisé par dix-neuf : une passe `jq` unique remplace douze appels par règle, soit 3 processus au lieu de 753 sur un fichier. Suite de tests de 77 s à 19 s avec 79 règles de plus.
- Page de documentation : logo et favicon vectoriels servis par un seul fichier qui suit le thème système, 6,6 Ko transférés en deux requêtes contre 15,7 Ko en trois. Matomo sans cookie, chargé après le rendu.
- Intégration continue : deux jobs fusionnés en un, trois installations réseau de `jq` supprimées puisqu’il est préinstallé sur les runners.

### Corrigé

- `ECO-FRONT-05` ne prend plus pour du code mort les lignes d’un `return` dont l’expression s’étend sur plusieurs lignes (`return $wpdb->get_results(` … `);`, `return array(` … `);`). La zone surveillée commence une fois l’instruction refermée ; le code placé après reste signalé.
- `ECO-BACK-10` ne signale plus la concaténation d’un nom de table (`"… FROM " . $wpdb->prefix . "t"`) : seule une concaténation qui suit un opérateur (`= "` + valeur, `IN ("` + liste) est une valeur injectée dans la requête.
- `ECO-FRONT-06` ne signale plus les modules ES : une instruction `import` ou `export` statique, ou un `<script type="module">`, prouve que les déclarations de premier niveau ne sont pas globales. Tout fichier JS/TS moderne produisait jusque-là un candidat. Dans une page, chaque bloc `<script>` est jugé séparément et le script classique reste signalé.

- Indexation : sitemap aligné sur les URL GitHub Pages, liens vers les pages de documentation, index `llms.txt` enrichi et métadonnées générées depuis la version et les règles ; suppression des notes d'avis non sourcées. Contrôles de synchronisation ajoutés à la CI.

- Règles PHP moins bruyantes : `ECO-PHP-05` ignore un `in_array` sur un tableau littéral, `ECO-PHP-04` ignore `json_decode(file_get_contents())` et `php://input`, `ECO-PHP-02` ne vise plus qu'une relation lue comme propriété (`foreach ($client->commandes as …)`), plus les appels de méthode.
- Cache local réservé aux questions autonomes explicitement préfixées `[cache]` : les demandes ordinaires ne sont plus bloquées par une ancienne réponse.
- Hook pre-commit : audit du contenu indexé, même si le fichier de travail diffère, avec prise en charge des renommages et des noms contenant des espaces.
- Hook Claude : conservation du chemin original pour les décisions acceptées et les exclusions lors de l'audit d'un extrait temporaire.
- Score : échec explicite lorsque l'audit échoue ; aucune densité n'est publiée dans ce cas.
- Extensions auditables communes aux hooks et au score, dérivées des règles de langage et des règles transverses ; tests d'intégration ajoutés à la CI et à la release.

- Règles IA ajoutées après coup : `ECO-ALGO-09`, `10` et `11` partageaient les mêmes motifs et signalaient trois fois en impact élevé tout fichier important PyTorch, sans décrire un seul défaut de son code. Une seule garde une détection, et elle détecte l'absence d'instrumentation de mesure.
- `batch_size = 1` attrapait `batch_size = 16`, `128` et `1024` : le motif n'était pas ancré.
- `ECO-ALGO-25` se déclenchait sur toute fonction nommée `train` ; les motifs nomment désormais les API de fine-tuning.
- `ECO-ALGO-12` recommandait de quantifier `gpt-4` et `claude-3-opus`, que personne consommant une API ne peut quantifier ; la règle est recadrée sur le chargement d'un modèle auto-hébergé.
- `ECO-HOST-07` et `08` se déclenchaient tous deux sur `A100` en disant presque la même chose.
- `ECO-HOST-09` affirmait sans source que `us-east-1` est carboné et une liste de régions européennes propre, et doublait `ECO-HEB-09`.
- Huit règles portaient `exclude_patterns` et `extensions` sans aucun motif : ces champs ne sont jamais lus.
- Vingt-et-un motifs utilisaient `\s`, hors ERE POSIX, là où le reste du dépôt utilise `[[:space:]]`.
- `ECO-HOST-07..10` renumérotées en `ECO-HOST-01..04` : deux règles numérotées `07` coexistaient avec `ECO-HEB`.
- Comptes de règles réalignés : `SKILL.md` annonçait 83 transverses et 225 au total pour 106 et 248 réelles, et c'est le fichier que le modèle charge. Un test compare désormais les chiffres annoncés aux règles présentes.
- Documentation : le hook de cadrage, le registre de décisions et le fichier d'exclusion n'étaient décrits nulle part hors du skill ; `CONTRIBUTING.md` ne documentait ni `example`, ni `three_u`, ni `source_note`, ni l'interdiction de `\s` et des lookaheads.


- `grep` prenait un motif d’exclusion commençant par `--` pour une option : la règle échouait en silence, ce qui ressemble à un fichier propre.
- `set -o pipefail` combiné à `grep -q` produisait des faux négatifs sur les fichiers assez gros pour remplir le tube, donc précisément là où il y a le plus à trouver.
- Résolution d’extension d’un fichier sans point : `Dockerfile` n’était jamais routé vers ses règles.
- Le hook d’audit résout désormais les chemins relatifs depuis le fichier d’origine et non depuis `/tmp`, ce qui supprimait un faux positif systématique sur les règles de liens et d’images.
- `ECO-BACK-10` cherchait `%s` dans `execute()`, qui est la forme correcte : la règle était écrite à l’envers.
- Documentation : le renvoi RGESN est désormais annoncé pour ce qu’il est, précis au critère pour les familles 1 à 4 et à la famille pour les suivantes, au lieu d’un « renvoi aux critères officiels » faux pour 33 règles sur 52.
- Retrait de deux seuils chiffrés sans source dans `ECO-SPEC-05`.
- Suppression de l’attribution non vérifiée des pratiques d’usage à Boris Cherny ; ces recommandations sont désormais assumées par le projet, sans équivalence entre tokens et énergie ni chiffres universels non mesurés.

## [1.4.0] - 2026-08-27

### Ajouté

- 80 règles d'écoconception propres à dix langages, chargées selon l'extension des fichiers.
- Score de densité d'issues, hook pre-commit et workflow d'intégration continue.
- Hook PostToolUse pour auditer automatiquement le code nouvellement écrit.
- Archives natives pour Claude.ai et l'API Skills.
- Métadonnées de citation, `llms.txt`, sitemap et intégration IndexNow pour le site public.

### Modifié

- Skill principal traduit en anglais tout en conservant les déclencheurs français.
- Détecteurs bornés à leur langage et réduction des faux positifs dans la prose, les commentaires, les images et les polices.
- Documentation et site public alignés sur les 52 règles transversales et les 80 règles par langage.

## [1.3.0] - 2026-08-01

### Ajouté

- Détecteurs de code mort, variables globales implicites, images, polices, complexité DOM/CSS/JS, HTTPS/TLS et liens cassés.
- Règles issues des Web Sustainability Guidelines et seuils inspirés de YellowLabTools.
- Notes contextuelles accompagnant les résultats heuristiques.

### Modifié

- Extension de 38 à 52 règles transversales.
- Réduction et clarification des instructions du skill.

## [1.2.0] - 2026-08-01

### Ajouté

- Installation comme plugin Claude Code.
- Câblage automatique des hooks optionnels dans les réglages Claude Code.

### Corrigé

- Détection des boucles imbriquées.
- Invalidation et sauvegarde du cache local selon le dépôt courant.

## [1.0.1] - 2026-07-21

### Corrigé

- Lecture des règles par `eco-audit.sh`, auparavant neutralisée par le découpage jq/TSV.
- Références obsolètes au CLI, liens de documentation et décompte des pratiques d’usage alors désignées par une attribution personnelle désormais retirée.

### Modifié

- Remplacement du wrapper CLI initial par un skill Claude Code et un hook optionnel.
- Ajout du guide de contribution et amélioration du site public.

## [1.0.0] - 2026-07-19

### Ajouté

- Première version du skill Green Claude.
- Règles d'écoconception alignées sur le RGESN 2024 et le GR491.
- Site GitHub Pages et documentation initiale.

[Unreleased]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/green-claude--v1.3.0...v1.4.0
[1.3.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/green-claude--v1.2.0...green-claude--v1.3.0
[1.2.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.0.1...green-claude--v1.2.0
[1.0.1]: https://github.com/Institut-du-Numerique-Responsable/green-claude/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Institut-du-Numerique-Responsable/green-claude/releases/tag/v1.0.0
