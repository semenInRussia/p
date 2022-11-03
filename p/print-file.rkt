#lang racket/base

(require racket/contract
         racket/cmdline
         racket/system
         racket/string)

(provide print-file
         2side-print-file)

(define page/c (and/c number? (or/c positive? zero?)))
(define pages/c (or/c
                 string?
                 page/c
                 (listof page/c)
                 'all
                 'even
                 'odd
                 'reversed
                 'reversed-even
                 'reversed-odd))

(define/contract (print-file filename #:amount (amount 1) #:pages (pages 'all))
  (->* (path-string?) (#:amount number? #:pages pages/c) boolean?)
  (let ([pages (format-pages pages)])
    (and
     (positive? amount)
     (system
      (format "pdftoprinter ~a pages=~a copies=~a"
              filename
              pages
              amount)))))

(define/contract (format-pages pages)
  (-> pages/c string?)
  (cond
    [(list? pages)
     (string-join (map number->string pages) ",")]
    [(number? pages)
     (number->string pages)]
    [(symbol? pages)
     (case pages
       [(odd)
        "1-z:odd"]
       [(reversed-odd)
        "z-1:odd"]
       [(even)
        "1-z:even"]
       [(reversed-even)
        "z-1:even"]
       [(all)
        "1-"]
       [(reversed)
        "z-1"])]
    [else
     pages]))

(define/contract (2side-print-file filename (amount 1))
  (->* (path-string?) (number?) boolean?)
  (and
   (positive? amount)
   (begin
     (printf "Print odd pages of file: ~a\n" filename)
     (print-file filename
                 #:amount amount
                 #:pages 'reversed-odd)
     (display "Rotate odd pages of file and type enter (RET)")
     (read-line)
     (printf "Print even pages of file: ~a\n" filename)
     (print-file filename
                 #:amount amount
                 #:pages 'even))))

(module+ test
  (require rackunit)
  (check-equal? (format-pages "1") "1")
  (check-equal? (format-pages 'even) "1-z:even")
  (check-equal? (format-pages 'odd) "1-z:odd")
  (check-equal? (format-pages 'all) "1-")
  (check-equal? (format-pages 'reversed-even) "z-1:even")
  (check-equal? (format-pages 'reversed-odd) "z-1:odd")
  (check-equal? (format-pages 'reversed) "z-1")
  (check-equal? (format-pages '(1 2 3)) "1,2,3")
  (check-equal? (format-pages 1) "1"))

(module+ main
  (define pages (make-parameter "1-z"))
  (define 2side? (make-parameter #f))
  (define amount (make-parameter 1))

  (define filename
    (command-line
     #:program "print-anything"
     #:once-each
     [("--pages" "-p")
      PAGES
      ("Query string to special pages print."
       "Can be:"
       ""
       ":all --- print each of document's pages"
       ":even --- print only even pages of document"
       ":odd --- print only odd pages of document"
       ""
       "These keywords can be used with other query before."
       "For examples: 1-9:even print only even pages beetween"
       "first and ninth pages"
       ""
       "a-b --- Print each of page beetween a and b"
       "a,b --- Print pages which match with either a or b"
       "query, for example 5,2-3 print 5th, 2nd and 3rd pages"
       ""
       "Here a and b can either number of page or Z indicates"
       "the last page")
      (pages PAGES)]
     [("--even" "-e")
      "Print only even pages"
      (pages (string-append (pages) ":even"))]
     [("--odd" "-o")
      "Print only odd pages"
      (pages (string-append (pages) ":odd"))]
     [("--reversed" "-r")
      "Print pages reversely"
      (pages "z-1")]
     [("--amount" "-n" "-a")
      AMOUNT
      "Amount of document copies to print"
      (define AMOUNT-number (string->number AMOUNT))
      (if AMOUNT-number
          (amount AMOUNT)
          (error "--amount flag expected number, given ~a"
                 AMOUNT))]
     [("--2side")
      "Enable 2 the side printing"
      (2side? #t)]
     #:args (filename)
     filename))
  (cond
    [(2side?)
     (2side-print-file filename (amount))]
    [else
     (print-file filename
                 #:amount (amount)
                 #:pages (pages))]))
