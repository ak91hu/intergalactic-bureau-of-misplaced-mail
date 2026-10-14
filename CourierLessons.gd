class_name CourierLessons
extends RefCounted

const NAMES: Array[String] = ["BFS", "DFS", "Topologikus rendezés", "Dijkstra", "Bellman–Ford", "Prim", "A*", "Floyd–Warshall", "Kruskal"]
const TITLES: Array[String] = [
	"A legkevesebb ugrás", "Felfedezés mélységben", "Előbb az előfeltételek",
	"A legolcsóbb kézbesítés", "Jóváírás a csillagködben", "Építs postahálózatot",
	"Iránytű a célhoz", "Minden címhez egy térkép", "Kapcsolatok, körök nélkül"
]
const RULES: Array[String] = [
	"A sor elejéről választunk. A közelebbi állomásokat előbb vizsgáljuk meg.",
	"A verem tetejéről választunk. Először egy ágat követünk végig.",
	"Csak olyan állomás jöhet, amelynek minden előfeltétele elkészült.",
	"A legkisebb ismert összköltségű állomás következik. Az élsúlyok nemnegatívak.",
	"Minden élt ellenőrzünk. Ha d[u] + w kisebb d[v]-nél, javítjuk d[v]-t.",
	"A már bekötött hálózat legolcsóbb kifelé vezető élével bővítünk.",
	"A legkisebb f = g + h következik: megtett költség + becsült hátralévő költség.",
	"Próbáld az állomásokat köztes pontként: d[i,j] = min(d[i,j], d[i,k] + d[k,j]).",
	"Az éleket súly szerint vizsgáljuk. Külön komponenseket összekötő élt tartunk meg."
]
const OBJECTIVES: Array[String] = [
	"Találd meg a legkevesebb élből álló útvonalat, majd kézbesíts a megadott ugráskereten belül.",
	"Kövess egy ágat a veremmel. Figyeld meg: a DFS találhat utat, de nem ígéri a legrövidebbet.",
	"Készíts szabályos feladatsorrendet. A csomag csak az előfeltételek teljesítése után indulhat tovább.",
	"Számítsd ki a legolcsóbb utat, majd a saját útvonaladat tartsd a kreditkereten belül.",
	"Használd a negatív jóváírásokat is. Előbb számolj, aztán kézbesíts a valódi előjeles költségekkel.",
	"Kösd be az összes állomást egy összefüggő, körmentes hálózatba. A teljes építési költség számít.",
	"Tanuld meg a g, h és f szerepét. Tervezd meg és járd végig a legolcsóbb kézbesítési utat.",
	"Készíts teljes távolságmátrixot. Az összetett pályán két különböző feladónak is kézbesítesz.",
	"Építs minimális feszítőfát. A hálózat több különálló részből is összeállhat."
]
const TAKEAWAYS: Array[String] = [
	"A BFS élszámot minimalizál, nem a krediteket. A sor biztosítja a szintenkénti bejárást.",
	"A DFS mélységben keres. A visszalépés a módszer része; a talált út nem feltétlenül optimális.",
	"Több helyes sorrend is lehet. Mindegyikben az él kiindulópontja előbb szerepel, mint a végpontja.",
	"A legkisebb d érték kiválasztása csak nemnegatív élsúlyok mellett véglegesíti biztonságosan a költséget.",
	"Negatív él megengedett. A feladóból elérhető negatív körből elérhető címzetthez nincs véges minimum; a kört jelenteni kell.",
	"A feszítőfa a teljes hálózat költségét minimalizálja. Ez más cél, mint egyetlen csomag legrövidebb útja.",
	"A heurisztika segít a cél felé keresni. Itt konzisztens alsó becslést használunk, ezért nem veszítjük el az optimumot.",
	"A mátrix minden feladó–címzett párt tárol. A köztes pontok sorrendje változhat, a végső távolságok nem.",
	"Azonos komponens két pontját összekötő él kört hozna létre. A Prim és a Kruskal minimumköltsége megegyezik."
]
const PSEUDOCODE: Array[Array] = [
	["sorba(feladó)", "u = sor.elejéről()", "új szomszéd: d[v] = d[u] + 1", "előd[v] = u; sorba(v)", "ha u a címzett: kész az út"],
	["verembe(feladó)", "u = verem.tetejéről()", "új szomszédok fordított sorrendben", "előd[v] = u; verembe(v)", "ha u a címzett: találtunk utat"],
	["bejövő[v] = előfeltételek száma", "válassz: bejövő[u] = 0", "sorrendhez(u)", "minden u → v: bejövő[v] -= 1", "minden állomás kész? átadás"],
	["d[feladó] = 0; többi = ∞", "u = legkisebb d a várakozók közül", "új = d[u] + súly(u,v)", "ha új < d[v]: d[v] = új; előd[v] = u", "u végleges; címzett esetén kész"],
	["d[feladó] = 0; többi = ∞", "legfeljebb |V|−1 teljes kör", "minden u → v: új = d[u] + súly", "ha új < d[v]: javít; előd[v] = u", "változás nélkül: korai megállás", "utolsó ellenőrzés: van negatív kör?"],
	["hálózat = {feladó}", "vizsgáld a kifelé vezető éleket", "válaszd a legolcsóbbat", "él és új állomás a fába", "|V|−1 él után kész"],
	["g[feladó] = 0; f = g + h", "u = legkisebb f a nyílt halmazban", "új g = g[u] + súly(u,v)", "ha javul: előd[v] = u; f[v] = g[v]+h[v]", "címzett kivételekor kész az út"],
	["d[i,i]=0; közvetlen élek betöltése", "válassz még nem használt köztes k-t", "minden i,j: új = d[i,k] + d[k,j]", "ha új < d[i,j]: javít; előd frissül", "minden k után kész a mátrix"],
	["élek rendezése súly szerint", "válaszd a következő legolcsóbb élt", "azonos komponens? kihagyás", "külön komponens? él megtartása", "komponensek egyesítése; |V|−1 él: kész"]
]
const TIERS: Array[String] = ["Bevezető", "Önálló", "Összetett"]
const COLORS: Array[Color] = [Color("71b7ff"), Color("71b7ff"), Color("be9dff"), Color("ffc876"), Color("ffc876"), Color("57e6ce"), Color("ff97cb"), Color("71d9ff"), Color("57e6ce")]
const COMPLEXITY: Array[String] = ["O(V + E)", "O(V + E)", "O(V + E)", "O((V + E) log V), bináris kupaccal", "O(V × E)", "O(E log V), bináris kupaccal", "O((V + E) log V), konzisztens h-val és kupaccal", "O(V³), O(V²) memória", "O(E log E)"]

static func is_network(algorithm: int) -> bool:
	return algorithm in [5, 8]

static func is_weighted(algorithm: int) -> bool:
	return algorithm in [3, 4, 6, 7]

static func key(algorithm: int, tier: int) -> String:
	return "%d:%d" % [algorithm, tier]
