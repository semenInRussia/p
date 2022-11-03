#lang racket/base

(require racket/contract
         "print-file.rkt")


(define mama-directory "c:/Users/hrams/MAMA")

(define cs-document-filename (build-path mama-directory "Obelisk.docx.pdf"))
(define cs-map-filename (build-path mama-directory "pushkin-maps.pdf"))

(define/contract (print-cs amount-of-docs amount-of-maps)
  (-> (and/c number? positive?) (and/c number? positive?) boolean?)
  (printf "Print main document, ~a times\n" amount-of-maps)
  (2side-print-file cs-document-filename amount-of-docs)
  (printf "Print maps, ~a times\n" amount-of-maps)
  (print-file cs-map-filename #:amount amount-of-maps))

(module+ main
  (require racket/cmdline)

  (command-line
   #:program "print-special-files"
   #:args (special-files-set . argv)
   (case special-files-set
     [("cs")
      (define docs (make-parameter 1))
      (define maps (make-parameter 1))
      (command-line
       #:program "print-cs"
       #:argv argv
       #:once-each
       [("-d" "--documents" "--docs") DOCS
                                      "Amount of the documents to print."
                                      (docs DOCS)]
       [("-m" "--maps") MAPS
                        "Amount of the maps to print."
                        (maps MAPS)])
      (print-cs (docs) (maps))]
     [else
      (displayln "This command excepts one argument: command")
      (displayln "Command can be one of the following things:")
      (displayln "cs --- Carskoe Selo")])))
