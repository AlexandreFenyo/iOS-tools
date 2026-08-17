# Étape 0 — Phase 1 : actions App Store Connect, sans build

Cinq actions, aucune ne nécessite de soumettre une version. Ordre imposé : le point 1 est un
**garde-fou binaire** — s'il révèle un problème, tout le reste est inutile tant qu'il n'est pas corrigé.

Référence : `ASO/Diagnostic ASO & plan d'action.pdf`, section 7 phase 1.

---

## 1. Vérifier le palier Store Services européen — 2 minutes, à faire en premier

**Où** : App Store Connect → **Business** → **Contrats** (Agreements, Tax and Banking).

**Ce qu'il faut voir** : le palier *Store Services* du DMA européen doit être **Tier 2**.

**Pourquoi c'est un garde-fou** : depuis juin 2025, le **Tier 1** (5 % de commission) supprime la
découverte App Store dans l'UE — recherche limitée à la correspondance exacte, plus de recommandations,
plus d'avis. Si tu es en Tier 1, aucune optimisation de mots-clés ne peut fonctionner en Europe.

**Ce que dit l'analyse** : tu es *probablement* en Tier 2, écarté par déduction — tu reçois 16 256
impressions en Allemagne et 11 479 en France sur 14 mois, tu as des avis européens actifs et l'ensemble
des données Analytics, trois choses que le Tier 1 supprime. Mais ça n'a pas été lu directement dans ton
contrat, et l'enjeu est binaire. **Vérifie.**

- [x] Palier confirmé le 17/08/2026 : **conditions standard, pas d'Alternative Terms Addendum**
  → équivalent Tier 2, la découverte App Store n'est pas coupée dans l'UE. Garde-fou levé.

⚠️ Deux points relevés au passage dans Business → Contrats, à traiter :
- **DAC7 : informations à renseigner** (27 pays) — peut bloquer des versements. À faire rapidement.
- Les deux contrats (apps payantes, apps gratuites) expirent le **7 octobre 2026** — surveiller le
  renouvellement. Noter que le contrat « applications gratuites » actif depuis le 5 août 2026 est
  un prérequis déjà en place pour le passage en gratuit + déverrouillage (phase 3a).

---

## 2. Réécrire le texte promotionnel — 5 minutes

**Où** : App Store Connect → l'app → **Version en vente** (ou n'importe quelle version) →
champ **Texte promotionnel** (Promotional Text), pour **chacune des 3 localisations**.

**Pourquoi maintenant** : c'est le **seul champ modifiable à tout moment sans passer par la validation
Apple**, il s'affiche **en tête de la fiche**, au-dessus de la description — et il contient aujourd'hui
une note de version : *« Visual update for iOS 26: the app adopts Apple's new Liquid Glass design. »*
C'est la première phrase que lit un acheteur potentiel. C'est aussi ton emplacement d'A/B test gratuit :
réversible en 5 minutes, sans build.

### Textes prêts à coller

**en-US** — 158 / 170 caractères

```
No subscription, no ads, no account. Walk through your home, tap to measure, and see exactly where your WiFi falls apart — room by room, on your iPhone alone.
```

**fr-FR** — 159 / 170 caractères

```
Sans abonnement, sans pub, sans compte. Parcourez votre logement, appuyez pour mesurer, voyez où votre WiFi décroche — pièce par pièce, avec votre seul iPhone.
```

**es-ES** — 161 / 170 caractères

```
Sin suscripción, sin anuncios, sin cuenta. Recorre tu casa, toca para medir y ve exactamente dónde falla tu WiFi — habitación por habitación, solo con tu iPhone.
```

Le tiret est un cadratin `—` (U+2014), pas un trait d'union : à conserver au copier-coller.

**La logique du texte** : il ouvre sur les trois refus qui te différencient (pas d'abonnement, pas de pub,
pas de compte) — c'est un argument de vente réel dans une catégorie où 21 des ~25 concurrents relevés sont
en abonnement. Puis il décrit le geste concret (*marcher, appuyer*) plutôt que la technologie, ce qui
répond directement aux avis négatifs. Et il pose « sur votre seul iPhone », l'équivalent du
*« No extra hardware! »* qui est le crochet dominant de la catégorie et que tu n'écris nulle part.

- [x] en-US remplacé (17/08/2026, via API)
- [x] fr-FR remplacé (17/08/2026, via API)
- [x] es-ES remplacé (17/08/2026, via API)
- [x] Date du changement notée dans le journal (§ dernière section)

---

## 3. Ouvrir un compte Apple Ads et activer le rapport de termes de recherche — 15 minutes

**Où** : <https://ads.apple.com> → créer un compte (gratuit) → **Insights** → rapport mensuel de
classement des termes de recherche.

**Coût** : zéro. Aucune campagne à créer, aucun budget à engager. La campagne payante, c'est la phase 4,
et seulement **après** le passage en gratuit — payer pour envoyer du trafic vers une fiche à 3,99 $ serait
du gaspillage.

**Pourquoi c'est indispensable** : ce rapport te donne, gratuitement et rétroactivement depuis juillet
2024, **les termes réellement tapés par les utilisateurs de ta catégorie et ton rang sur chacun**. C'est
aujourd'hui la seule source fiable : l'indice de popularité d'Apple Search Ads est cassé depuis octobre
2025 (des dizaines de milliers de mots-clés ramenés à la valeur plancher en quatre jours, sans annonce),
et tous les outils ASO tiers en dépendent.

**Conséquence directe sur la suite** : les mots-clés de l'étape 1 reposent aujourd'hui sur la *préférence
révélée* — ce que les apps à fort volume mettent dans leurs propres nom et sous-titre — et non sur des
volumes mesurés. Ce rapport est ce qui permettra de les corriger avec des données de première main.
**Fais-le maintenant**, les données mettent quelques jours à apparaître.

- [ ] Compte créé
- [ ] Rapport de termes de recherche activé
- [ ] Premier export récupéré (noter la date)

---

## 4. Ouvrir les organigrammes de crash — 20 minutes

**Où** : Xcode → **Window → Organizer → Crashes**, ou App Store Connect → l'app → **Métriques → Crashs**.

**Semaines à examiner** : celle du **22 juin 2026** (21 crashs) et celle du **3 août 2026** (13 crashs).

**Ce qu'on cherche** : 34 crashs sur 8 semaines pour ~15 sessions hebdomadaires, c'est un profil de
*beaucoup de crashs concentrés sur peu d'appareils* — typiquement une ou deux personnes bloquées dans une
**boucle de crash au lancement**. Vérifier le nombre d'appareils distincts touchés : si c'est 1 ou 2, le
diagnostic est confirmé.

**Pourquoi c'est urgent malgré le faible volume** : c'est exactement le scénario qui a produit les 8 avis
1★ « crashes on launch » de l'automne 2024. Avec seulement 11 ventes/mois, **un seul avis 1★ pèse
aujourd'hui très lourd** sur une note moyenne construite sur 61 notes. À régler avant toute campagne
d'acquisition — sinon on paie pour amener des gens vers un crash.

- [ ] Semaine du 22/06/2026 examinée — appareils distincts : ____
- [ ] Semaine du 03/08/2026 examinée — appareils distincts : ____
- [ ] Pile d'appel identifiée : ____________________
- [ ] Correctif à intégrer à la 6.2 : ☐ oui ☐ non

---

## 5. Répondre aux avis négatifs sans réponse — 30 minutes

**Où** : App Store Connect → l'app → **Notes et avis** → filtrer par note croissante → bouton *Répondre*.

**Pourquoi ça compte** : les réponses sont **publiques et lues** par les acheteurs suivants. Sur 21 avis
rédigés, 57 % sont négatifs, et ce sont les textes — pas la note chiffrée — que lit quelqu'un qui hésite.
Une réponse factuelle transforme un avis à charge en démonstration de sérieux. Apple autorise une réponse
par avis, modifiable ensuite.

**Deux familles à traiter différemment.**

### Famille A — les crashs de sept.–oct. 2024 (8 avis) · bug corrigé depuis novembre 2024

Réponse type, à adapter :

> Thanks for reporting this — and sorry it cost you the price of the app. This launch crash was fixed in
> November 2024; the current version starts normally. If you still hit it, please write to
> <support@fenyo.net> with your device model and iOS version and I will look into it directly.

Version française :

> Merci du signalement, et désolé que ça vous ait coûté le prix de l'app. Ce plantage au lancement a été
> corrigé en novembre 2024 et la version actuelle démarre normalement. Si vous le rencontrez encore,
> écrivez-moi à <support@fenyo.net> avec votre modèle et votre version d'iOS, je regarde directement.

### Famille B — la promesse non tenue · **la plus importante**

Ces avis décrivent tous le même décalage : *les gens attendent de marcher dans leur logement et de voir
une carte se dessiner*. Point crucial pour la rédaction des réponses : **le mode pas-à-pas répond déjà en
grande partie à ce reproche** — il propose 5 plans prédéfinis (aucun dessin nécessaire), lance la sonde de
mesure tout seul, et chaque tap sur le plan enregistre une mesure. Ce mode existe et personne ne le trouve.
C'est un problème de découvrabilité, pas seulement de produit.

**« I was hoping to wander around in my flat and create a heat map… instead you have to draw / upload
your floor plan yourself »** (DEU, 2★, nov. 2025) — et **« N'est absolument pas intuitif… Dessiner une
heat map est galère »** (FRA) :

> You are right that the advanced interface asks too much up front. There is a second mode that does what
> you describe: on the welcome screen, choose "Step-by-step easy mode", pick one of the five ready-made
> floor plans — nothing to draw — then just walk and tap where you are. The map builds as you go. That
> mode should be what the app opens on, and making it the default is what I am working on next. Thanks for
> the honest feedback.

> Vous avez raison : l'interface avancée demande trop de choses d'entrée. Il existe un second mode qui fait
> exactement ce que vous décrivez : sur l'écran d'accueil, choisissez « Step-by-step easy mode », prenez
> l'un des cinq plans tout faits — rien à dessiner — puis marchez et appuyez à l'endroit où vous êtes. La
> carte se construit au fur et à mesure. Ce mode devrait être celui sur lequel l'app s'ouvre, et le rendre
> prioritaire est ce sur quoi je travaille. Merci pour ce retour franc.

**« I wanted to check the WiFi signal strength around the house »** (AUS) :

> Fair point, and here is the honest answer: iOS gives no app access to Wi-Fi signal strength — Apple
> exposes no public API for it, which is why professional tools need external hardware. So this app maps
> the thing it *can* measure at each spot: real throughput and latency. That is also how NetSpot and every
> other hardware-free app on iOS works. Showing real dBm without extra hardware is something I am working
> on through a documented Shortcuts bridge.

**« REVIEWS ARE FAKE!!! NO HEATMAP!! There's NO survey, no imaging, NOTHING »** (USA) et **« Every app on
Android is automatic. This one requires you to read a novel to do a single scan »** (USA) :

> The heat map is real, but you were clearly dropped into the wrong screen — that is my fault, not yours.
> From the welcome screen, tap "Step-by-step easy mode", pick a ready-made floor plan, then walk and tap.
> No configuration, no reading. Android apps can be more automatic because Android lets apps read Wi-Fi
> signal strength; iOS does not. Happy to walk you through it at <support@fenyo.net>.

**« Can not build a heatmap, I have selected my floor plan, added probe, started TCP flood chargen, but
it keeps telling me to start TCP flood chargen »** (HKG) — ⚠️ **ce n'est pas un malentendu, c'est un bug** :

Le message d'instruction ne disparaît que si la boucle chargen alimente effectivement le débit ; si la
boucle se termine (timeout, `ECONNRESET`), le bouton heatmap disparaît et le débit retombe à 0 sans que
l'utilisateur en soit informé. **À reproduire et à corriger**, indépendamment de la réponse :

> That is a real bug, not a misunderstanding — thank you for the precise description. If the chargen
> connection drops, the app keeps asking you to start it instead of telling you it stopped. I am fixing
> it. In the meantime, "Step-by-step easy mode" from the welcome screen sets up the measurement for you.

- [ ] Avis 1 répondu · [ ] Avis 2 · [ ] Avis 3 · [ ] Avis 4 · [ ] Avis 5 · [ ] Avis 6
- [ ] Bug HKG reproduit et consigné pour la 6.2

⚠️ Remplace `support@fenyo.net` par ton adresse de support réelle avant de publier quoi que ce soit.

---

## Journal de bord — à ouvrir maintenant

L'absence de ce journal est précisément ce qui rend le décrochage d'avril 2026 impossible à trancher
aujourd'hui. Relève ces chiffres **toutes les deux semaines** et note la date de chaque changement en face.

| Indicateur | Où le lire | Aujourd'hui | Objectif 90 j | Objectif 12 mois |
|---|---|---|---|---|
| **Impressions / mois** *(indicateur maître)* | Analytics → Métriques | 2 886 | 8 000 | 25 000 |
| Vues de fiche produit / mois | Analytics → Métriques | 229 | 700 | 2 000 |
| Téléchargements / mois | Analytics → Métriques | 11 | 150 *(fiche gratuite)* | 600 |
| CA brut / mois | Ventes et tendances | 48 $ | 180 $ | 900 $ |
| Nombre de notes | Notes et avis | ≈ 61 | 120 | 350 |
| Note moyenne US | Notes et avis | 3,96 ★ | 4,2 ★ | 4,5 ★ |
| Part de l'Allemagne dans les ventes | Analytics → par vitrine | 13 % | 20 % | 25 % |
| Crashs / mois | Métriques → Crashs | 3 – 21 | < 3 | < 3 |

Tant que les impressions ne remontent pas, rien d'autre ne peut remonter.

| Date | Changement effectué |
|---|---|
| 17/08/2026 | Texte promotionnel remplacé sur la 6.1 en vente (en-US, fr-FR, es-ES) — premier changement visible |
| 17/08/2026 | Vérification contrats : conditions standard (pas de Tier 1) ; DAC7 à renseigner ; contrats expirent le 07/10/2026 |
| | |
