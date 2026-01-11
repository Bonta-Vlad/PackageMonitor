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
       ### Bash
         ./monitor.sh
     Notă: Această comandă va crea directorul `Packages/` și fișierul `Cache.txt`.


## Structura datelor generate

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

## Rulare
### Script 1 (monitor.sh)
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

### Script 2 (pkgmonext.sh)
  Al doilea script oferă un front-end simplu pentru interogarea informațiilor generate de primul script.
  
  Acesta primește argumente din linia de comandă și afișează starea sau istoricul pachetelor.
  
  Scriptul se bazează exclusiv pe structura creată în monitor.sh

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
    
    
