# OOL
Implementazione di OOL a ereditarietà singola in linguaggio funzionale LISP

UNIMIB
Linguaggi di Programmazione A.A. 2014/2015

================================ INTRODUZIONE =================================

Lo scopo del progetto era implementare, in linguaggio COMMON LISP, 
un Object-Oriented-Language con eredità singola.
Il progetto mirava ad evidenziare i tipici aspetti di linguaggi
di questo tipo: la gestione dell'ereditarietà, la rappresentazione e 
la manipolazione dei metodi.

Per l'implementazione, come suggerito da specifica di progetto, è stato
necessario utilizzare una hash table e due funzioni d'appoggio per la sua
gestione, in particolare per aggiungervi istanze e poi successivamente
recuperarle.

Abbiamo quindi definito una hash table chiamata *classes-specs*, tramite la 
funzione make-hash-table, e definito le due funzioni add-class-spec e
get-class-spec.

La specifica prevedeva, poi, la definizione di 3 funzioni primitive la cui
implementazione, con riferimenti alle relative funzioni ausiliarie, sarà qui 
descritta.


============================== 1 - DEFINE-CLASS ===============================

Oltre alla definizione della funzione primitiva, abbiamo implementato le
seguenti funzioni d'appoggio:

(check-define (class parent slot-values) ...)
(check-slot (slot-values) ...)
(process-slots (slot-values) ...)
(method-process (method-name method-spec) ...)
(rewrite-method-code (method-spec) ...)


La definizione della primitiva si presenta così:

(defun define-class (class-name parent &rest slot-values) ...)

I 3 parametri in ingresso corrispondono, ovviamente, a quelli descritti dalla
specifica del progetto. Per implementare gli SLOT-VALUES abbiamo deciso di
utilizzare &rest, creando quindi una lista con le coppie (KEY . VALUE).

Nel corpo della funzione abbiamo, in primo luogo, implementato due
controlli:
1- la chiamata di una funzione ausiliaria CHECK-DEFINE
i cui parametri sono gli stessi della funzione define-class.
La funzione controlla la legalità dell'input, in particolare se CLASS-NAME 
e PARENT sono simboli e se la lista SLOT-VALUES è formata da un numero di 
elementi pari compatibile con le coppie (Key . Value). 
Se non vengono riscontrati errori, viene chiamata la funzione CHECK-SLOTS 
che restituisce T in caso di lista vuota, se non lo è, controlla che 
gli elementi della lista SLOT-VALUES in posizione dispari siano simboli
restituendo un errore in caso contrario;
2- la verifica della non presenza di un'eventuale precedente definizione della classe
tramite GET-CLASS-SPEC, questa restituisce un errore in caso di definizione già presente;

Da questo punto in poi, un'istruzione di selezione fa in modo che venga analizzato in modo
corretto il parametro PARENT:
1 - PARENT == NIL --> aggiungo le specifiche della classe che vado a definire
alla hash table globale e chiamo la funzione PROCESS-SLOTS, che elaborerà gli
slots.
2 - PARENT != NIL --> verifico, tramite GET-CLASS-SPEC, che PARENT sia
effettivamente definita e poi mi comporto come al punto 1, se no restituisco errore.

La sopracitata funzione PROCESS-SLOTS è responsabile dell' elaborazione di 
metodi e attributi. La funzione effettua un primo controllo testando se 
la lista sia vuota o meno, se è vuota viene semplicemente restituita,
se non lo è, prosegue scansionando la prima coppia (Key . Value) alla ricerca 
di Value contenente la parola 'method (in prima posizione).
Trovare elementi di questo tipo significherebbe che si sta cercando di definire
dei metodi, i quali richiedono una particolare elaborazione.
Quindi, se lo trovo, chiamo la funzione METHOD-PROCESS (il suo input sarà il 
nome dello slot-value e il suo corpo).
Se invece la coppia è un semplice attributo, lo lascio così com'è e richiamo
ricorsivamente PROCESS-SLOTS.

La funzione destinata al processo dei metodi è METHOD-PROCESS. 
Questa ricevendo in input lo slot (KEY . VALUE), dove KEY è nome di un
metodo e VALUE il suo  corpo, definisce una funzione COMMON LISP (tramite la
funzione predefinita fdefinition) che abbia il nome del metodo e le associa una
Lambda Expression che esegue il corpo vero e proprio del futuro metodo.
Il corpo viene recuperato grazie alla funzione GET-SLOT, che riceve in input
la parola chiave this (che sarà parametro della lambda) e il nome del metodo 
(e quindi dello slot-value).
La lambda, dunque, applicherà (tramite apply) la funzione che sarà restituita
dalla GET-SLOT, avendo come parametri 'this' e eventuali parametri del metodo. 

L'ultima istruzione di questa funzione crea una lista del metodo stesso
tramite la funzione REWRITE-METHOD-CODE, la quale concatena le due parole chiave 
'lambda' e 'this' alle specifiche del metodo appena definito.

================================ 2 - GET-SLOT =================================

Oltre alla definizione della funzione primitiva, abbiamo implementato le 
seguenti funzioni di appoggio:

(find-slot (slots slot-name) ...)
(find-slot-ancestor (ancestor slot-name) ...)

La definizione della primitiva si presenta così:

(defun get-slot (instance slot-name) ...)

dove i due parametri corrispondono a quelli descritti dalle specifiche
di progetto.

La funzione effettua due test preliminari, verificando che INSTANCE non sia 
nullo e che SLOT-NAME sia un simbolo, in caso contrario restituisce errore.
Se la funzione non restituisce errore allora utilizza le due funzioni ausiliarie
per cercare il valore associato a SLOT-NAME in INSTANCE.
In particolare, la funzione FIND-SLOT ricerca il valore associato allo slot-name
tra quelli definiti direttamente nell'istanza; mentre la funzione 
FIND-SLOT-ANCESTOR ricerca il valore associato allo slot-name tra quelli 
definiti nella classe genitore. Nel caso in cui la ricerca abbia esito negativo sia
nella classe genitore che nell'istanza viene restituito un errore.
 
================================== 3 - NEW ====================================

La definizione della primitiva si presenta così:

(defun new (class-name &rest slot-values) ... )

dove i parametri corrispondono a quelli descritti dalla specifica di progetto.
Per implementare gli SLOT-VALUES abbiamo deciso di utilizzare &rest, creando
quindi una lista con le coppie (KEY . VALUE).

La funzione effettua una serie di controlli:
- la verifica che CLASS-NAME sia un simbolo;
- la verifica (tramite la funzione GET-CLASS-SPEC sopra descritta) che la classe 
della quale sto creando un'istanza sia stata precedentemente definita;
- la verifica che la lista SLOT-VALUES abbia un numero di elementi pari e che 
sia stata definita legalmente (tramite la funzione CHECK-SLOTS sopra descritta).
Se anche uno solo dei controlli fallisce, la funzione restituisce un errore.

Se non vengono riscontrate anomalie, viene chiamata la funzione PROCESS-SLOTS
sopra descritta,che effettuerà eventuali override di attributi e metodi.

==================================== END ======================================
