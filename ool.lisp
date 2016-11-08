; Università degli Studi di Milano-Bicocca
; A.A. 2014/2015
; Dipartimento di Informatica Sistemistica e Comunicazione
; Facoltà di Informatica
; Linguaggi di Programmazione
; Progetto Gennaio 2015: OOL in Common Lisp

;================================== BEGIN =====================================

; ASSOCIATION LIST TRAMITE (MAKE-HASH-TABLE)
; Crea un'Hash Table contenente le specifiche delle classi definite
; mediante la funzione primitiva DEFINE-CLASS e utilizza due funzioni
; d'appoggio per la loro gestione.

; DEFPARAMETER *CLASSES-SPECS*
; Crea l'Hash Table per memorizzare le specifiche delle classi.
(defparameter *classes-specs* (make-hash-table))

; ADD-CLASS-SPEC
; Aggiunge la classe e le sue specifiche alla Hash Table.
(defun add-class-spec (name class-spec)
  (setf (gethash name *classes-specs*) 
	class-spec)                    
  (car (list name)))

; GET-CLASS-SPEC
; Restituisce le specifiche di una classe.
(defun get-class-spec (name)
  (gethash name *classes-specs*))


; FUNZIONE PRIMITIVA (DEFINE-CLASS <CLASS-NAME> <PARENT> <SLOT-VALUE>*)
; Definisce una classe, dal nome <CLASS-NAME>, controllando che <PARENT> (se
; non è NIL) sia una classe già definita precedentemente e gestisce eventuali 
; errori di input.
(defun define-class (class-name parent &rest slot-values)
  (if (check-define class-name parent slot-values)  
      (if (not (get-class-spec class-name))
	  (if (null parent)
	      (add-class-spec class-name 
			      (append (list parent) 
				      (process-slots slot-values)))
	      (if (not (null (get-class-spec parent)))
		  (add-class-spec class-name
				  (append (list parent) 
					  (process-slots slot-values)))
		  (error "ERROR: The Parent Class ~S doesn't exist!" parent)))
	(error "ERROR: The Class ~S has been already defined!" class-name))
      (error "ERROR: Illegal input!")))

; CHECK-DEFINE
; Controlla che l'input per DEFINE-CLASS sia legale, restituisce NIL se anche
; solo uno dei controlli fallisce.
(defun check-define (class parent slot-values)
  (if (symbolp class)
      (if (symbolp parent)
	       (if (evenp (length slot-values))
		   (check-slot slot-values)
		   NIL)
	  NIL)
      NIL))

; CHECK-SLOT
; Controlla la legalità dell'input per DEFINE-CLASS, nello specifico degli 
; Slot-Values, restituisce NIL se non è nella forma (KEY . VALUE).
(defun check-slot (slot-values)
  (if (null slot-values)
      T
      (if (symbolp (first slot-values))
	  (check-slot (rest (rest slot-values)))
	  NIL)))

; PROCESS-SLOTS
; Verifica se negli SLOT sono stati definiti metodi, se così fosse li processa.
; Se la lista degli SLOT-VALUES è vuota la restituisce così com'è, altrimenti
; la scansiona per capire se contiene metodi. Se ne trova, li processa.
; Se trova attributi, copia semplicemente la chiave e il suo valore.
(defun process-slots (slot-values)
  (if (null slot-values)
      ()
      (if (and (not (atom (second slot-values)))
	       (equal (car (second slot-values)) 
		     'method))
	  (append (list (first slot-values))
		  (list (method-process (first slot-values) 
					(second slot-values)))
		  (process-slots (rest (rest slot-values))))
	  (append (list (first slot-values)
			(second slot-values))
		  (process-slots (rest (rest slot-values)))))))

; METHOD-PROCESS
; Ricevendo in input lo slot (KEY . VALUE), dove KEY è nome di un metodo e
; VALUE il suo corpo, crea una funzione COMMON LISP che abbia il nome del 
; metodo associandole una Lambda Expression che esegue il corpo vero e
; proprio presente in method-spec.
(defun method-process (method-name method-spec)
  (setf (fdefinition method-name)
	(lambda (this &rest args)
	  (apply (get-slot this 
			   method-name)
		 (append (list this)
			 args))))	
  (eval (rewrite-method-code method-spec)))

; REWRITE-METHOD-CODE
; Riscrive l'intera funzione sotto forma di lista aggiungendo
; alle specifiche del metodo le keywords 'lambda' e 'this'.
(defun rewrite-method-code (method-spec)
   (list 'lambda (append (list 'this)
		       (second method-spec))
	(cons 'progn (rest (rest method-spec)))))


; FUNZIONE PRIMITIVA (GET-SLOT <INSTANCE> <SLOT-NAME>)
; Restituisce il valore associato alla chiave <SLOT-NAME> mediante ricerca
; ricorsiva in <INSTANCE> (e in un'eventuale classe genitore). 
; Gestisce gli errori in caso di parametri non corretti.
(defun get-slot (instance slot-name)
  (if (and (not (null instance))
	   (symbolp slot-name))                              
      (if (not (null (find-slot (rest instance)
				slot-name)))
	  (cdr (find-slot (rest instance)
			  slot-name))
	  (let ((class-sp (get-class-spec (first instance))))
	    (if (not (null class-sp))
		(if (not (null (find-slot (rest class-sp) 
					  slot-name)))
		    (cdr (find-slot (rest class-sp)
				    slot-name))
		    (let ((slot-par (find-slot-ancestor (first class-sp) slot-name)))
		      (if (not (null slot-par))
			  (cdr slot-par)
			  (error "ERROR: The slot ~S has not been found!" slot-name))))
		(error "ERROR: The slot ~S has not been found" slot-name))))
      (error "ERROR: Illegal input!")))

; FIND-SLOT
; Cerca lo SLOT all'interno della lista degli slot dell'istanza che mi 
; interessa, lo restituisce se lo trova, altrimenti restituisce NIL.
(defun find-slot (slots slot-name)
  (if (not (null slots))
      (if (equal (first slots) 
		 slot-name)
	  (cons slot-name
		(second slots)) 
	  (find-slot (rest (rest slots)) slot-name))
      NIL))

; FIND-SLOT-ANCESTOR
; Cerca lo SLOT all'interno della lista degli slot delle classi antenate dell'istanza
; che mi interessa (se presenti), lo restituisce se lo trovo,
; altrimenti restituisce NIL.
(defun find-slot-ancestor (ancestor slot-name)
  (if (not (null ancestor))
      (if (not (null (get-class-spec ancestor)))
	(let ((slot (find-slot (rest (get-class-spec ancestor)) slot-name)))
	  (if (not (null slot))
	      slot
	      (find-slot-ancestor (first (get-class-spec ancestor))
			   slot-name)))
	NIL)
      NIL))
 

; FUNZIONE PRIMITIVA (NEW <CLASS-NAME> <SLOT-VALUE>*)
; Genera un'istanza della classe <CLASS-NAME> e ridefinisce eventuali attributi
; e/o metodi <SLOT-VALUE>* della classe sovrascritti dall'istanza, gestendo
; eventuali errori.
(defun new (class-name &rest slot-values)
  (if (symbolp class-name)
      (if (get-class-spec class-name)
	  (if (evenp (length slot-values))
	      (if (check-slot slot-values)
		  (append (list class-name)
			  (process-slots slot-values))
		  (error "ERROR: Illegal slot-values input!"))
	      (error "ERROR: Illegal slot-values input!"))
	  (error "ERROR: The class ~S doesn't exist!" class-name))
      (error "ERROR: Illegal class ~S input!" class-name)))

;================================== END =======================================