# async-fifo

FIFO asincron parametrizabil pentru transfer de date între două domenii
de ceas necorelate. SystemVerilog, verificat cu testbench pe clase.

## Interfață

| Semnal | Dir | Lățime | Descriere |
|---|---|---|---|
| wr_clk, wr_rst_n | in | 1 | Domeniul de scriere |
| wr_en, wr_data | in | 1, WIDTH | Scriere validă dacă wr_en && !full |
| full | out | 1 | Pesimist: se ridică devreme |
| ... | | | |

Parametri: `WIDTH` (implicit 8), `DEPTH` (implicit 8, putere a lui 2)

## Cum se rulează

```bash
make sim      # Icarus Verilog
make wave     # deschide GTKWave
make cov      # raport de coverage
```

## Cum funcționează

[Schemă bloc]

Pointerii sunt pe log2(DEPTH)+1 biți. Bitul suplimentar distinge
gol de plin: pointeri identici complet = gol, identici pe adresă
dar diferiți pe bitul suplimentar = plin.

### De ce cod Gray și nu binar

Un sincronizator cu două flip-flopuri protejează un singur bit.
Pointerul are 4 biți care nu ajung simultan în celălalt domeniu —
la trecerea de la 0111 la 1000 se pot citi valori care n-au existat
niciodată. În cod Gray se schimbă un singur bit între valori
consecutive, deci eșantionarea în timpul tranziției dă ori valoarea
veche, ori pe cea nouă.

### De ce flag-urile sunt pesimiste

Din cauza celor două cicluri de sincronizare, `full` poate rămâne
ridicat scurt timp după ce s-a eliberat spațiu. Pierdere de
performanță, acceptabilă. Inversul — `full` care se lasă prea
târziu — înseamnă date pierdute.

## Verificare

- Model de referință: coadă software comparată cu DUT-ul
- Stimuli constrained random, rate de scriere/citire variabile
- Coverage: plin, gol, aproape-plin, aproape-gol, rate relative
- Assertions: fără scriere pe full, fără citire pe empty, ordine păstrată
- **Bug hunting**: ramura `injected-bugs` conține 3 defecte
  intenționate (sincronizator cu un registru, pointeri binari,
  comparație greșită la full) — toate prinse de testbench

## Ce aș face diferit

Memoria e inferată ca registre, nu ca block RAM. Pentru adâncimi
mari ar trebui instanțiat explicit un bloc RAM.