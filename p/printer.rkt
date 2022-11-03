#lang racket/base

(require racket/contract
         racket/function
         racket/string
         threading
         "print-windows.rkt")

(define printer? string?)

(provide/contract
 [printer?           (-> any/c boolean?)]
 [printers-list      (-> (listof printer?))]
 [view-printers-list (-> void?)])

(define (printers-list)
  (~>>
   (printing-admin-script-shell-command-exec-to-string "prnmngr" '("-l"))
   (string-split _ "\r\n")
   (filter (curryr string-prefix? "Printer name "))
   (map (curryr string-replace "Printer name " ""))))

(define (view-printers-list)
  (for-each displayln
            (printers-list)))

(module+ main
  (require racket/cmdline)

  (command-line
   #:program "printers"
   #:once-each ))
