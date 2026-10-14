# Futárakadémia – játékosútmutató

Tizenkét témát gyakorolhatsz 36 magyar tanulóküldetésben: kilenc gráfalgoritmust és három keresőfát. A cél megérteni a döntéseket, majd alkalmazni a tervet. Nincs időkorlát; a hibák után javíthatsz.

A **diszpécserkártya** minden képernyőn elmondja, hol tartasz és mit tehetsz most. A hibás döntésnél jelzi, hogy az állapot változatlan, és a részletes visszajelzésből megtudhatod, miért kell újra próbálnod. A laborban hibás válasznál a helyes lépéssel folytatunk, és ezt külön jelezzük. A csomag utazása, az automata futása és szünete is látható állapotot kap. A küldetés végén külön üzenet igazolja a mentést; ha nem sikerül, a **Mentés újrapróbálása** gomb segít. A hang- és mozgásbeállítások változtatását is visszaigazoljuk.

## Új: keresőfák, zene és automata

Az **Új: piros-fekete fa** gombbal közvetlenül eléred az új témát. Lejjebb a főmenüben a **Bináris keresőfa**, **AVL-fa** és **Piros-fekete fa** kártyák is elérhetők, témánként három szinttel. Csomagazonosítókat szúrsz be, választasz az összehasonlítások, forgatások és színjavítások között, majd megkeresel egy kulcsot és elvégzed az inorder bejárást. A harmadik szinten hiányzó kulcsot is keresel. A gyökér, a magasság és az egyensúly/színszabályok láthatók. A P/F betűk színlátástól függetlenül megkülönböztetik a csúcsokat; a kis négyzet fekete NIL-kapcsolat.

A futárküldetés és a famodul **Automata [A]** gombja végigmutatja a helyes lépéseket. A sebesség lassú, normál és gyors lehet. Az **A** ismételt megnyomása szüneteltet; az útmutató megnyitása és a kézi döntés is megállítja az automatát. A futár megvárja a csomag animációját. A bemutató nem ad pontot vagy érmet; újrakezdés után kézzel is megoldhatod a feladatot. A fáknál a visszalépés is pont nélküli gyakorlásra vált. A kézi falekció 1000 pontról indul, hibánként 40, egy döntéshez kért segítségenként 60 pont levonással, legalább 100 ponttal. Hibátlan és segítség nélküli megoldás aranyat, legfeljebb 3 hibás megoldás ezüstöt, egyéb befejezés bronzot ad.

A főmenüben a **Zene** és az **Effektek** külön kapcsolható. A hangerőcsúszka a halk háttérzenét szabályozza, beállításod megmarad. A zene jelenetváltáskor folytatódik. Böngészőben az első kattintás vagy billentyű után indulhat el. Háttérzene: **Floating Cities — Kevin MacLeod**, CC BY 4.0; a teljes forrás és licenc a főmenü alján és a kiadás mellett is megtalálható.

## Első futárküldetés

1. Válaszd a **Folytatás: BFS** gombot. Bármelyik kártyán más témát és nehézséget is választhatsz.
2. Olvasd el az eligazítást: mi a cél, ki a feladó és címzett, mennyi a keret.
3. Kezdd el a tervezést. BFS-nél a sor elején álló állomást dolgozd fel. A jobb oldali adatok és az alsó pszeudokód megmutatják az aktuális szabályt.
4. A kész terv után vedd át a csomagot. Most te kattintasz a következő elérhető állomásra; a költség, az irány és a lezárás valóban számít.
5. A jelentésben hasonlítsd össze a saját költségedet az optimummal, és olvasd el a tanulságot.

Prim/Kruskal esetén a kapcsolatok kiválasztása maga a végrehajtás: minden állomást be kell kötni. Topologikus rendezésnél az összes állomás szabályos feladási sorrendje a cél.

## Szintek és újrajátszás

| Szint | Mit változtat? |
| --- | --- |
| Bevezető | 6 állomás, ajánlott útvonal, megengedőbb keret |
| Önálló | 7 állomás, lezárt sáv, szűkebb keret; az útvonalat az adatokból állítod össze |
| Összetett | 8 állomás, több választás; súlyozott és hálózatépítő feladatban pontos optimum kell |

BFS-nél ugrásszám, Dijkstra/A*/Bellman–Ford/Floyd esetén kredit, Prim/Kruskal esetén teljes építési költség a keret. DFS-nél tágabb ugráskeret segíti a felfedezést, nem kell legrövidebb utat találnod. Topologikus rendezésnél az előfeltételek a korlátok.

A **Következő pálya** a következő nehézséget, majd témát nyitja. Az **Új hálózat ezen a szinten** más költségeket és kapcsolatokat ad. A napi küldetés UTC-nap szerint választ témát és pályaváltozatot. Minden téma és szint mindig elérhető.

## A kilenc szabály

| Algoritmus | Mire figyelj? |
| --- | --- |
| BFS | FIFO: a sor elejéről veszel ki. A legkevesebb ugrást találja; a krediteket nem minimalizálja. |
| DFS | LIFO: a verem tetejéről veszel ki. A talált út nem feltétlenül legrövidebb. Az új szomszédokat a játék fordított betűrendben teszi a verembe. |
| Topologikus rendezés | Nulla fennmaradó előfeltételű állomást válassz. Több helyes sorrend is lehet. |
| Dijkstra | A legkisebb d jön. Hasonlítsd össze a d[u]+w jelöltet a régi d[v]-vel. Nemnegatív költségeket használ. |
| Bellman–Ford | Teljes körökben minden járható élt ellenőrzöl. A negatív jóváírás is számít. Változás nélküli kör után megállhatsz; elérhető negatív kört jelenteni kell. |
| Prim | A bekötött hálózatból kifelé vezető legolcsóbb éllel bővíts. A drágább szabályos él ténylegesen többe kerül. |
| A* | A legkisebb f=g+h jön: g a megtett költség, h a hátralévő költség alsó becslése. Itt h konzisztens; h=0 Dijkstra viselkedését adná. |
| Floyd–Warshall | Minden állomás egyszer legyen köztes pont. A mátrix sora a feladó, oszlopa a címzett. Az összetett küldetés két feladóhoz használja ugyanazt a mátrixot. |
| Kruskal | Súly szerinti sorrendben vizsgáld az éleket. Azonos komponens végpontjai kört alkotnának: azt az élt kihagyjuk. Külön komponenseket egyesítünk. |

Az azonos prioritású helyes választásokat elfogadja a játék. A **Miért?** ablak teljes pszeudokódot és szokásos komplexitást is mutat. A képletek a szokásos algoritmusmegvalósításra vonatkoznak; a játék lépései nem sebességmérések.

## A futártérkép olvasása

- Az állomás betűjele egyezik a gomb és az adattábla jelével; a neve föléhúzáskor látszik.
- A nyíl egyirányú sáv. A szaggatott piros, **×** jelű kapcsolat lezárt.
- Az élcímke kreditköltség; negatív érték Bellman–Ford/Floyd pályán lehet. BFS/DFS kézbesítésnél ugrást számol.
- Arany a keresési frontier; türkiz a feldolgozott állomás. Lila a választható köztes pont vagy hálózati él. A jelöltek közül neked kell a szabályos lépést kiválasztanod.
- A vastag türkiz vonal a saját út vagy megépített kapcsolat. A bevezető szinten, segítség után és a jelentésben ajánlott út is látszik.
- **∞**: egyelőre nincs ismert járható út. Az elődtáblából visszafelé olvashatod ki az útvonalat. A mátrix türkiz cellái most javultak.

Prim és Kruskal kétirányú hálózatot használ. Egyetlen kézbesítési út helyett minden állomást összekötő, körmentes fát építesz.

## Segítség, hibák és érmek

**H** megmagyarázza és ajánlja a következő lépést; ugyanannál a döntésnél ismételt segítség csak egyszer számít. **Z / Backspace** visszaállítja a korábbi adatokat és költséget. A hibás tanulási választások és segítségek száma megmarad.

Hibás tervezési válasz után újra választhatsz, a táblád nem sérül. Kézbesítésnél szabadon választhatsz járható sávot. Zsákutcából vagy túl drága célba érkezésből visszalépéssel vagy **Újratervezem** gombbal javíthatsz. Az újratervezés megtartja a tanult távolságokat; hálózatépítésnél új fát kezdesz.

| Érem | Feltétel |
| --- | --- |
| Arany / Mesterfutár | Optimális eredmény hibás tanulási választás, segítség és újratervezés nélkül; DFS-nél szabályos kézbesítés |
| Ezüst / Biztos tudás | Optimális eredmény, legfeljebb max(1, döntésszám/4) hibás tanulási választással |
| Bronz / Sikeres küldetés | Minden más sikeres teljesítés |

Maximum **1000 XP** jár. Hibás tanulási választás 35, segítség 25, újratervezés 30 pontot von le; nem optimális eredmény további 100-at. A minimum 100 pont. Összes XP a személyes rekordok összege, ezért ismétléssel nem növelhető korlátlanul. A gyengébb eredmény megőrzi a korábbi jobb pontszámot és érmet.

A kampány és a labor eredményei külön mentődnek; a hang és mozgás beállítása közös. Asztali és böngészős mentés különálló. A böngésző webhelyadatainak törlése a webes haladást is törli.

## Futárküldetések billentyűi

**1–9** választás, **Enter/Space** egyetlen felkínált lépés, **H** segítség, **Z/Backspace** vissza, **I** magyarázat, **L** napló, **M** Floyd-mátrix/térkép, **Esc** bezárás vagy akadémia. A csomag animációja alatt a dupla kattintás nem indít második lépést. Hang és kímélő mozgás az akadémián állítható.

## Original lab guide

The academy's **Algoritmuslabor** button opens the retained English visualizer, three-checkpoint missions and unscored practice. Its old scores remain saved. The following lab rules differ from the courier campaign.

You are the newest clerk at the Intergalactic Bureau of Misplaced Mail. Director Zorp wants a report; Gerald brought the wrong map. You have nine algorithms and one parcel to investigate.

## First shift

1. Start with **Continue: BFS** on the mission desk.
2. Read the rule in Mission Control, then send your first dispatch with Space.
3. Follow the amber frontier and cyan processed departments. The queue or cost table appears below the latest dispatch.
4. At each of three checkpoints, predict the next decision. Choose a numbered answer or click a highlighted department.
5. Read the feedback, continue the algorithm, and finish your report.

Mistakes explain the answer and keep the mission moving. There is no countdown. Auto-play pauses at checkpoints so you can decide at your own pace, then resumes automatically after your answer.

## Medals and points

A correct answer earns 100 points plus a streak bonus: +25 on the first consecutive correct answer and +50 thereafter. A perfect mission earns 425 points. A wrong answer earns zero and resets the streak.

A hint explains the rule. It reduces that checkpoint's reward by 25 points if answered correctly; requesting it twice cannot charge twice. Hinted runs can earn silver.

| Medal | Requirement |
| --- | --- |
| Bronze | Finish the mission |
| Silver | At least 2 of 3 correct |
| Gold | All 3 correct without hints |

Best scores and medals persist on this computer or in this browser. A weaker replay keeps the better result. XP is the sum of best scores. Browser and desktop saves are separate; clearing browser site data clears browser progress.

## Learn without scoring

On the desk switch to **Mode: practice** before selecting a mission. Back or Left replays earlier states. Change auto-play speed, restart, or open the guide at any time. The guide pauses auto-play; Space does not advance while it is open.

## Read the map

- **Waiting:** not discovered yet.
- **Amber / In frontier:** waiting in the queue, stack or priority queue.
- **Cyan / Processed:** the algorithm has processed the department.
- **Violet / Click to choose:** one of the possible checkpoint answers.
- **Gold edge:** the most recently examined connection.
- **Cyan route/tree:** the final shortest-path or spanning-tree result.

Wheel zoom centers on your pointer. Middle-button drag pans; F fits every department back into view. The lane policy states whether arrows and signed costs apply.

## Which algorithm next?

BFS and DFS introduce queues and stacks. Topological Sort introduces dependencies. Dijkstra and A* use nonnegative costs. Bellman-Ford and Floyd-Warshall retain the -2 rebate. Prim and Kruskal connect the entire network with a minimum-cost tree.

The desk offers the first unfinished algorithm and a daily assignment rotating through these nine missions. All remain available. Sound and reduced motion can be changed on the desk and save automatically.

Keyboard reference: Space next; 1/2/3 answer; H hint; A auto/pause; R restart; I guide; Left rewind in practice; F fit; Esc close guide or return to desk.
