# Prompt till lokala agenten: gångklipp och slag som matchar spelet exakt

Klistra in allt under strecket till agenten.

---

Du gör animationsklipp till spelet Father & Son på den här datorn (repo
`Rebelyouthz/hnt`, gren `claude/gallant-galileo-5ctrmf`). De förra klippen
gick inte att använda: gubben såg annorlunda ut, hade fel storlek, och
gången slutade efter ett halvt steg. Den här gången ska varje klipp vara
exakt som klippen som redan finns i spelet. Följ stegen i ordning och hoppa
inte över något.

## 0. Hämta det nya

```
git checkout claude/gallant-galileo-5ctrmf
git pull
cd tools/local_gpu
venv\Scripts\activate
pip install pillow numpy scipy imageio imageio-ffmpeg
```

Radera alla klipp du gjort tidigare, de är gjorda med den gamla versionen
som sträckte bilden:
`del clips\*.mp4` (eller flytta dem till en annan mapp).

## 1. Vad som räknas som rätt

Spelet har redan klipp för varje karaktär. Ett nytt klipp ska ha:

1. **Samma utseende.** Klippet startar från karaktärens egen bild i spelet
   (`local_wan.py` gör det själv nu, `--start-from game` är standard). Samma
   ansikte, kläder, färger och proportioner hela klippet. Ingen annan
   person, inga nya kläder, ingen morfning.
2. **Samma storlek i pixlar.** Gubben ska bli exakt lika lång som i spelet
   (t.ex. bailiff 198 px, valet 204 px). `finish_clip.py` mäter och skalar.
3. **Exakt ett helt varv i gångar.** Gången är EN hel cykel: vänster ben
   ett steg, höger ben ett steg, och sista bilden leder direkt in i den
   första så att loopen inte hackar. Inte ett halvt steg, inte ett och ett
   halvt. Klippet du genererar ska därför innehålla minst två hela varv
   (fyra steg) i jämn takt, så att skriptet kan skära ut ett perfekt varv.
4. **Exakt lika många bilder som spelet har** för den karaktären och den
   rörelsen (12 eller 16 beroende på karaktär). Skriptet läser antalet ur
   spelet och vägrar annars.
5. **Fötterna på samma golvrad** i varje bild, ingen zoom, ingen kamera som
   rör sig, platt grön bakgrund.

## 2. Generera

```
python local_wan.py --list
python local_wan.py --only bailiff
```

och så vidare för varje karaktär i listan (ordningen står i
`docs/LOCAL_AGENT_CLIPS.md`). Standardinställningarna gäller: 49 bilder
(3 sekunder, räcker för två hela varv), 704x544, start från spelets bild.
Ändra inte storlek eller antal bilder om inte minnet tar slut. Då gäller
`--size 576x448 --frames 49`; sänk aldrig `--frames` under 49 för gångar.

## 3. Färdigställ och kontrollera VARJE klipp

```
python finish_clip.py clips\bailiff_walk_back.mp4
```

(eller `python finish_clip.py clips\*.mp4` för alla). För varje klipp
skriver skriptet antingen

`PASS bailiff_walk_back.mp4 -> bailiff/walk_up: 12 frames @ 12.00 fps, body 198 px (game 198) ...`

eller `FAIL` med skälen. Det skapar i `tools/local_gpu/finished/<who>/`:

- `<clip>.png` + `<clip>.json`: det färdiga spritesheetet i spelets format
- `<clip>_preview.gif`: spelas i spelets hastighet, loopar
- `<clip>_compare.png`: spelets bild till vänster, den nya till höger

**Titta på gif:en och jämförelsebilden för varje PASS:**
- går han ett helt varv (båda benen) och loopar utan hack?
- ser han ut exakt som till vänster i jämförelsebilden, lika stor?
- står fötterna kvar på golvet?

Om något av det inte stämmer, räkna det som FAIL även om skriptet sa PASS.

**Vid FAIL:** radera mp4:an och gör om just den karaktären
(`del clips\bailiff_walk_back.mp4` och `python local_wan.py --only bailiff`).
Varje körning får ett nytt seed. Försök upp till 3 gånger per klipp. Om det
fortfarande blir FAIL, hoppa över klippet och skriv det i rapporten med
skälet skriptet gav.

Vanliga FAIL och vad de betyder:
- `the loop does not close` / `pop at the loop point`: gången är ojämn,
  han ändrar takt eller vänder sig. Gör om.
- `two frames in a row are identical`: han gick för fort eller för kort.
  Gör om.
- `body ... px tall`: han zoomade eller krympte. Gör om.
- `feet jump`: kameran eller gubben hoppar. Gör om.

## 4. Pusha bara det som är godkänt

För varje klipp som fick PASS och såg rätt ut i gif:en:

```
git add tools/local_gpu/clips/<namn>.mp4
git add tools/local_gpu/finished/<who>/<clip>.png tools/local_gpu/finished/<who>/<clip>.json
git add tools/local_gpu/finished/<who>/<clip>_preview.gif tools/local_gpu/finished/<who>/<clip>_compare.png
git commit -m "Finished clips: <lista>"
git pull --rebase
git push origin claude/gallant-galileo-5ctrmf
```

Pusha aldrig klipp med FAIL. Lägg aldrig in något i `assets/sprites` själv
(Claude installerar efter att ha tittat). Committa aldrig token, nycklar,
venv-mappen, modellcachen, `starts/_game` eller `finished/_48fps`.

## 5. Rapport

Skriv en kort lista: vilka klipp som blev PASS (med raden skriptet skrev),
vilka som fick FAIL efter 3 försök och varför, och tid per klipp.
