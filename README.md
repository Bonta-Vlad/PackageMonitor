# Package Monitor Extended. Analiza și organizarea operațiilor dpkg

## Descriere generală: 
Package Monitor Extended este o suită de instrumente de analiză și monitorizare pentru sistemele bazate pe Debian/Ubuntu. Scopul principal este de a transforma fișierul de log brut /var/log/dpkg.log într-o bază de date structurată și interogabilă.
Acest proiect extinde funcționalitățile unui sistem de tip *PackageMonitor*,
automatizează extragerea datelor din /var/log/dpkg.log și le organizează într-o structură ierarhică de directoare, oferind o interfață rapidă de interogare a stării pachetelor (instalate vs. șterse).

Sistemul funcționează în două etape: Parsare/Organizare și Interogare.

## Componente
  1. Backend(`monitor.sh`): Motorul de procesare. Citește log-urile, curăță datele, elimină duplicatele și populează structura de fișiere.
  2. Frontend (`pkgmonext.sh`): Interfața CLI (Command Line Interface). Permite utilizatorului să interogheze baza de date creată de backend.
  3. Stocare (`Packages/`): Structură ierarhică unde fiecare pachet are propriul director și istoric (ops.txt).

## Cerințe și instalare

  - OS: Linux (distribuții bazate pe Debian/Ubuntu care folosesc dpkg).
  - Bash
  - Permisiuni: Drepturi de citire pe /var/log/dpkg.log.
  - Dependențe: bash, awk, grep, sort, xargs, dpkg-query.

## Configurare
  1. Clonare/Copiere: Salvați scripturile monitor.sh și pkgmonext.sh în același director.
  2. Permisiuni de execuție:
        ```Bash
         chmod +x monitor.sh pkgmonext.sh
  3. Inițializare (Rulare Backend): Înainte de a folosi comenzile de interogare, trebuie generată baza de date.
        ```Bash
         ./monitor.sh
  Notă: Această comandă va crea directorul `Packages/` și fișierul `Cache.txt`.


### Structura datelor generate

```
.
├── monitor.sh
├── pkgmonext.sh
└── Packages/
    ├── apt/
    │   └── ops.txt
    ├── curl/
    │   └── ops.txt
    └── ...
```

Directorul `Packages/` este generat automat și conține câte un subdirector pentru fiecare pachet detectat
în fișierul de log.

## Ghid de utilizare
Scriptul de interogare se apelează folosind sintaxa: ./pkgmonext.sh [COMANDĂ] [ARGUMENT_OPȚIONAL]

| Comandă | Argument | Descriere | Exemplu |
| :--- | :--- | :--- | :--- |
| **Status Pachete** | | | |
| `installed` | - | Listează toate pachetele instalate curent. | `./pkgmonext.sh installed` |
| `removed` | - | Listează toate pachetele care au fost șterse. | `./pkgmonext.sh removed` |
| `half-installed` | - | Identifică pachetele cu instalare eșuată/incompletă. | `./pkgmonext.sh half-installed` |
| **Analiză & Istoric** | | | |
| `history` | `<nume_pachet>` | Afișează tot istoricul operațiilor pentru un pachet. | `./pkgmonext.sh history vim` |
| `lst10days` | - | Afișează toate operațiile din ultimele 10 zile. | `./pkgmonext.sh lst10days` |
| `is-first-installed`| `<nume_pachet>` | Verifică dacă pachetul e la prima instalare absolută. | `./pkgmonext.sh is-first-installed zip` |
| `undo` | - | Arată ultimele 5 pachete șterse (ref rapidă). | `./pkgmonext.sh undo` |
| **Metrici** | | | |
| `size` | `<nume_pachet>` | Afișează dimensiunea unui pachet instalat (KB). | `./pkgmonext.sh size nano` |
| `total-size` | - | Calculează spațiul total ocupat de pachete. | `./pkgmonext.sh total-size` |

## Rulare

### Logica de parsare (monitor.sh)
  - Extragerea Numelor: Scriptul folosește `awk` cu `split($5,a,":")` pentru a gestiona formatul `nume:arhitectură` (ex: `gzip:amd64` devine `gzip`). Aceasta asigură că directoarele sunt create corect.
  - Filtrare Contextuală: Se folosește o verificare strictă `($0 ~ " "name":")` în bucla de populare pentru a evita potrivirile parțiale (ex: căutarea pachetului `zip` nu va returna rezultate pentru `gzip`).
  - Unicitate (`sort -u`): Ordonează alfabetic și elimină duplicatele. Aceasta este crucială pentru performanță: dacă un pachet apare de 50 de ori în log, `mkdir` va fi executat o singură dată.
  - Cache LRU (Least Recently Used): Fișierul `Cache.txt` este generat prin sortarea descrescătoare a timpului (`sort -r`) și extragerea primelor 5 linii, simulând o stivă de "Undo" pentru operațiile de ștergere.

Primul script analizează fișierul /var/log/dpkg.log și identifică operațiile relevante asupra pachetelor,
  precum:
  
    - instalare(installed)
    - dezinstalare(uninstall)
    - instalare parțială(half-installed)
    
  Pentru fiecare pachet identificat, scriptul creează un director și salvează operațiilr asociate într-un
  fișier ops.txt
  
  Variabile:
  
    - L_FILE: calea către fișierul de log dpkg.log
    
  Flux de execuție:
  
    Se filtrează liniile relevante din dpkg.log
     
    Se extrag numele pachetelor
    
    Se creează directoare unice pentru fiecare pachet
    
    Se salvează istoricul operațiilor în fișiere separate
    
  Comenzi utilizate:
  
    - `awk`: procesarea și filtrarea fișierului de log
      - Logica: `/ status remove | ... / ` acționează ca un selector de linii (regex)
      - Funcția `split($5,a,":")`: o folosim deoarece numele pachetelor în `dpkg.log` apar adesea sub forma `nume-pachet:arhitectură`. Folosim `split` pentru a extrage doar `nume-pachet`, asigurând
      consistența directoarelor create
    - `sort -u`: eliminarea intrărilor duplicate. Garantează că comanda `mkdir` este apelată o singură dată pentru fiecare pachet unic, evitând erorile de procesare redundante.
    - `xargz -I %`: transformă lista de nume de pachete primită prin pipe în argumente pentru comanda `mkdir`. Placeholder-ul `%` permite injectarea numelui pachetului exact acolo unde este nevoie în structura de fișiere (`Packages/%`)
    - `mkdir`: crearea structurii de directoare
    - `grep`: filtrarea operațiilor pentru fiecare pachet

### Determinarea stării (pkgmonext.sh)
Acest modul nu modifică date, ci le interpretează folosind logică condițională și aritmetică.

Acest script funcționează ca un interpretor de comenzi (switch/case), analizând structura de fișiere creată de backend. Iată analiza tehnică pentru fiecare funcție disponibilă:

A. Determinarea Stării (`installed` / `removed`)
Aceste două funcții reprezintă nucleul logic al scriptului. Ele nu se bazează pe starea curentă a sistemului (care poate fi alterată manual), ci pe cronologia evenimentelor din log.
  - Logica: Iterează prin toate directoarele din Packages/ și extrage ultimele linii relevante folosind grep ... | tail -1.

  - Algoritm:

    1. Extrage timestamp-ul ultimei instalări (`lastin`).

    2. Extrage timestamp-ul ultimei ștergeri (`lastrem`).

    3. Folosește `readarray` pentru a segmenta linia și a izola data/ora.

    4. Compară string-urile:

    5. Pentru installed: Condiția este `if [[ Data_Install > Data_Remove ]]`.

    6. Pentru removed: Condiția este `if [[ Data_Install <= Data_Remove ]]`.

B. Istoricul Brut (`history`)
  - Funcționalitate: Afișează toate operațiile înregistrate pentru un pachet specific.

  - Implementare: Verifică simplu existența fișierului Packages/$2/ops.txt. Dacă există, folosește cat pentru a-l afișa la standard output (stdout).

C. Filtrare Temporală (`lst10days`)
  - Funcționalitate: Identifică orice activitate (instalare sau dezinstalare) din ultimele 10 zile.

  - Implementare:

      1. Calcularea Pragului: Variabila $limit este setată folosind date -d "10 days ago".

      2. Motorul de Căutare: Se folosește awk cu variabila externă limit.

      3. Optimizare: Comparația substr($0,1,19) >= limit se face direct pe șiruri de caractere (format ISO), fiind mult mai rapidă decât conversia fiecărei linii în Unix Timestamp.

D. Analiza Dimensiunii (`size`)
  - Funcționalitate: Interoghează baza de date dpkg a sistemului pentru dimensiunea pachetului.

  - Implementare:

          - Comanda: dpkg-query -W -f='${Installed-Size} KB\n'.

          - Gestionearea Erorilor: Folosește operatorul || (OR). Dacă dpkg-query returnează eroare (cod de ieșire diferit de 0, adică pachetul nu e găsit), scriptul execută echo "Pachetul nu este instalat", prevenind oprirea abruptă a execuției.

E. Agregarea Datelor (`total-size`)
Calculează spațiul total ocupat pe disc de către pachetele monitorizate care sunt încă instalate.

1. Inițializează variabila total=0.

2. Parcurge fiecare pachet și îi verifică starea (folosind logica de la punctul A: if [[ "$lastin" > "$lastrem" ]]).

3. Doar dacă pachetul este confirmat ca instalat, interoghează dimensiunea.

4. Aritmetică: Folosește expansiunea aritmetică $((total + size)) pentru a suma valorile.

5. Persistență: Rezultatul este afișat și salvat simultan în total_size.db folosind tee.

F. Detectarea Erorilor (`half-installed`)

Identifică pachetele a căror instalare a fost întreruptă sau a eșuat.

Implementare: Compară timestamp-ul evenimentului installed cu cel al evenimentului half-installed. Dacă half-installed este cel mai recent eveniment, pachetul necesită atenție (posibilă rulare dpkg --configure -a).

G. Cache și Restaurare (`undo`)

Afișează o listă a celor mai recente 5 pachete șterse, utilă pentru a re-instala rapid ceva șters din greșeală.

Implementare: Nu face procesare în timp real. Doar citește (cat) fișierul Cache.txt care a fost pre-calculat și optimizat de scriptul de backend (monitor.sh).

H. Analiza Primei Instalări (`is-first-installed`)

Determină dacă un pachet este la prima sa apariție pe sistem sau dacă a mai fost instalat și șters în trecut.

Implementare:
    - Folosește grep -q " remove " pe fișierul de operații.
    - Flag-ul -q (quiet) este crucial: nu afișează nimic, doar returnează codul de ieșire (0 dacă a găsit, 1 dacă nu).
    - Dacă se găsește un remove, scriptul deduce că pachetul a existat anterior.



  Argumente interogabile:
  
    `installed`: Afișează pachetele pentru care ultima operație înregistrată este o instalare
    
    `removed`: Afișează pachetele pentru care ultima operație este o dezinstalare
    
     `history <nume_pachet>`: Afișează istoricul complet al operațiilor pentru pachetul specificat
    
  Flux de execuție:
  
    - Se parcurg directoarele din `Packages/`
    - Se identifică ultimele operații de tip install și remove
    - Se compară datele operațiilor pentru determinarea stării finale
    - Se afișează rezultatul corespunzător cererii utilizatorului
    
  Comenzi utilizate:
  
    - `case`: utilizată pentru a selecta comportamentul scriptului în funcție de primul argument 
    primit din linia de comandă (`$1`), permițând implementarea mai multor funcșionalități într-un           singur script.
    - `for`: Bucla `for` este folosită pentru a parcurge toate directoarele corespunzătoare 
    pachetelor din
    directorul `Packages/`, permițând procesarea individuală a fiecărui pachet.
    - `ls`: utilizată pentru a lista subdirectoarele din `Packages/`, fiecare subdirector reprezentând
    un pachet monitorizat
    - `grep`: folosită pentru a filtra liniile din fișierul `ops.txt` corespunzătoare operațiilor de tip 
    `installed` sau `remove`. Opțiunea implicită permite selectarea doar a liniilor relevante pentru
    analiza stării pachetului
    - `tail`: Comanda `tail -1` este utilizată pentru a selecta ultima apariție a unei operații
    de tip `installed` sau `remove`, considerată cea mai recentă operație pentru pachetul respectiv.
    - `if`: Structura condițională `if` este utilizată pentru a compara datele ultimei instalări și ale 
    ultimei dezinstalări, determinând starea finală a pachetului (instalat sau eliminat).
    - `cat`: Comanda `cat` este utilizată în cazul opțiunii `history` pentru afișarea completă a 
    istoricului operațiilor unui pachet.
    - `Variabila `$1``: reprezintă opțiunea selectată de utilizator (ex. `installed`, `removed`)
    - `Variabila `$2``: reprezintă numele pachetului pentru care se solicită istoricul



    
