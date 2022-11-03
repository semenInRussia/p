#lang racket/base

(require racket/contract
         racket/format
         racket/port
         racket/string
         racket/system
         threading
         "print-windows.rkt")

(provide (contract-out
          [struct print-job
            ((id             (and/c number? positive?))
             (printer-name   string?)
             (document       path-string?)
             (elapsed-time   string?)
             (submitted-time string?)
             (pages-printed  (and/c number? (or/c positive? zero?)))
             (total-pages    (and/c number? positive?))
             (paper-size     string?)
             (status         string?))]
          [print-jobs (->* () ((or/c #f string?)) (listof print-job?))]
          [view-print-job (-> print-job? void?)]
          [view-print-jobs (-> void?)]
          [clear-print-queue (-> void?)]))

(define (clear-print-queue)
  (with-disabled-spooler-service
    (for-each delete-file
              (printer-active-queue-printers-files))))

(define-struct print-job (id
                          printer-name
                          document
                          elapsed-time
                          submitted-time
                          pages-printed
                          total-pages
                          paper-size
                          status))

(define (print-jobs [printer-name #f])
  (define switches (cons "-l" (if printer-name
                                  (string-append "-p " printer-name)
                                  null)))
  (~>
   "prnjobs"
   (printing-admin-script-shell-command-exec-to-string switches)
   (string->print-jobs)))

(define/contract (string->print-jobs s)
  (-> string? (listof print-job?))
  (define ids (map
               string->number
               (regexp-match* #rx"Job id (.+?)\r" s #:match-select cadr)))
  (define printer-names
    (regexp-match* #rx"Printer (.+?)\r" s #:match-select cadr))
  (define documents
    (regexp-match* #rx"Document (.+?)\r" s #:match-select cadr))
  (define elapsed-times
    (regexp-match* #rx"Elapsed time (.+?)\r" s #:match-select cadr))
  (define submitted-times
    (regexp-match* #rx"Time submitted (.+?)\r" s #:match-select cadr))
  (define numbers-of-printed-pages
    (map string->number
         (regexp-match* #rx"Pages printed (.+?)\r" s #:match-select cadr)))
  (define numbers-of-total-pages
    (map string->number
         (regexp-match* #rx"Total pages (.+?)\r\n" s #:match-select cadr)))
  (define papers-sizes
    (regexp-match* #rx"PaperSize (.+?) " s #:match-select cadr))
  (define statuses
    (regexp-match* #rx"Status (.*?)\r\n" s #:match-select cadr))
  (map make-print-job
       ids
       printer-names
       documents
       elapsed-times
       submitted-times
       numbers-of-printed-pages
       numbers-of-total-pages
       papers-sizes
       statuses))

(define (view-print-jobs)
  (for ([job (print-jobs)])
    (view-print-job job)
    (newline)))

(define (view-print-job job)
  (printf "~a. <~a>  ~a/~a        ~a~n    Status: ~a"
          (~r (print-job-id job) #:min-width 2)
          (print-job-submitted-time job)
          (~r (print-job-pages-printed job) #:min-width 3)
          (~a (print-job-total-pages job) #:min-width 3)
          (print-job-document job)
          (print-job-status job)))

(define/contract (printer-active-queue-printers-files)
  (-> (listof path?))
  (directory-list
   (build-path (getenv "systemroot")
               "System32"
               "spool"
               "printers")
   #:build? #t))

(define-syntax-rule (with-disabled-spooler-service body ...)
  (begin
    (net-stop-spooler)
    body ...
    (net-start-spooler)))

(define (net-stop-spooler)
  (without-output
    (system "net stop spooler")))

(define (net-start-spooler)
  (without-output
    (system "net start spooler")))

(define-syntax-rule (without-output body ...)
  (parameterize ([current-output-port (open-output-string)])
    body ...))

(module+ main
  (require racket/cmdline)

  (command-line
   #:program "print-job"
   #:args (command)
   (case command
     [("clear" "c")
      (clear-print-queue)]
     [("list" "l")
      (view-print-jobs)]
     [else
      (displayln "print-job: except one command, one of the following")
      (displayln "clear, c --- clear the print queue")
      (displayln "list, l --- view the print jobs list")])))
