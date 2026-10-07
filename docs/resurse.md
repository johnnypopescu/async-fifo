# Resurse — FIFO asincron, cod Gray, CDC

## Citit, în ordinea recomandată

**1. Cummings, SNUG 2002 — „Simulation and Synthesis Techniques for Asynchronous FIFO Design”**
Lucrarea de referință. Designul din acest repo o urmează: pointeri binar/Gray,
sincronizatoare cu 2 bistabile, bit suplimentar, condiții de full și empty.
- Bibliotecă oficială (cere cont): <https://www.paradigm-works.com/papers/> (fostul sunburst-design.com)
- Copie publică: <https://www.researchgate.net/publication/252160343_Simulation_and_Synthesis_Techniques_for_Asynchronous_FIFO_Design>
- Mirror universitar: <https://twins.ee.nctu.edu.tw/courses/ip_core_04/resource_pdf/cummings1_final.pdf>

> Atenție: Cummings are două lucrări cu titluri aproape identice. Cea de care ai nevoie e
> asta, cu pointeri **sincronizați**. Cealaltă, „with Asynchronous Pointer Comparisons”,
> descrie un stil greu de verificat cu analiză de timing statică și cu DFT.

**2. ZipCPU — „Crossing clock domains with an Asynchronous FIFO”**
Cea mai citibilă explicație, construită de jos în sus: sincronizatoare, apoi Gray, apoi flag-uri.
- Articol: <https://zipcpu.com/blog/2018/07/06/afifo.html>
- Cod: <https://github.com/ZipCPU/website/blob/master/examples/afifo.v>

**3. Intel/Altera — „Understanding Metastability in FPGAs” (wp-01082)**
Formula MTBF, de unde vine exponențiala, cifre reale. Exemplu: 200 ps în plus la timpul
de stabilizare cresc MTBF-ul de peste 50 de ori.
- <https://cdrdv2-public.intel.com/650346/wp-01082-quartus-ii-metastability.pdf>

**4. Doulos — „Asynchronous signals and Metastability”**
Mai scurt și mai prietenos, pe același subiect.
- <https://www.doulos.com/media/1155/metastability-us.pdf>

**5. Cummings, SNUG Boston 2008 — „Clock Domain Crossing (CDC) Design & Verification Techniques”**
Imaginea de ansamblu: handshake, trecerea unui bit, impulsuri, reconvergență.
- <https://www.paradigm-works.com/papers/>

**6. VLSI Verify — Asynchronous FIFO**
Recapitulare rapidă, cu cod, pe o singură pagină. Bun înainte de interviu, nu pentru prima lectură.
- <https://vlsiverify.com/verilog/verilog-codes/asynchronous-fifo/>

## Video

FIFO asincron:
- <https://www.youtube.com/watch?v=UNoCDY3pFh0> — CDC + RTL, cu linkuri către lucrarea Cummings
- <https://www.youtube.com/watch?v=0LVHPRmi88c> — explicația conceptuală
- <https://www.youtube.com/watch?v=4CITOSUUMRI> — cod Verilog și testbench
- <https://www.youtube.com/watch?v=NkA4QmdCPKo> — dedicat codului Gray în FIFO

Metastabilitate și sincronizatoare:
- <https://www.youtube.com/watch?v=U6i9ogyKQzY> — sincronizator dual-flop și MTBF
- <https://www.youtube.com/watch?v=78thKVhcp-M> — format întrebări de interviu
- <https://www.youtube.com/watch?v=YS-LHzb4djg> — bazele CDC
- <https://www.youtube.com/watch?v=bbf69FtAIpY> — de ce cedează un bistabil
- <https://www.youtube.com/watch?v=QyXBYpZqBZo> — hazarde la sincronizator (nod combinațional vs. registru)

FIFO sincron (pentru `sync_fifo.sv`):
- <https://www.youtube.com/watch?v=Nnl-ayl3W-Q>

## Desenele din acest proiect

| Fișier | Ce explică |
|---|---|
| `async_fifo_block.svg` | Schema bloc a FIFO-ului asincron |
| `sync_fifo_block.svg` | Schema bloc a FIFO-ului sincron |
| `bin2gray.svg` | Circuitul de conversie binar → Gray |
| `metastability.svg` | Metastabilitatea și sincronizatorul cu 2 bistabile |
| `sampling_gray.svg` | Eșantionarea: binar vs. Gray |
| `binary_pointer_crossing.svg` | De ce un pointer binar registrat tot dă valori false |
| `glitch_register.svg` | De ce pointerul Gray trebuie să iasă din registru |

## Ordinea în care se înțelege subiectul

1. **Metastabilitate** — un bit eșantionat prea aproape de front rămâne nedecis.
   Soluție: sincronizator cu 2 bistabile, care îi dă o perioadă întreagă să se stabilizeze.
2. **Coerența unei magistrale** — fiecare bit are lanțul lui de sincronizare și se decide
   independent, deci se pot amesteca biți vechi cu biți noi. Soluție: cod Gray, un singur bit
   în tranziție.
3. **Hazarde** — un nod combinațional trece prin valori intermediare. Soluție: peste graniță
   trimiți doar ieșiri de registru.
4. **Pesimismul flag-urilor** — fiecare domeniu vede pointerul celuilalt cu întârziere, deci
   `full` și `empty` greșesc doar în direcția sigură.
