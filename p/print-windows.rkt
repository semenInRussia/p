#lang racket/base

(require racket/base
         racket/contract
         racket/port
         racket/string
         racket/system
         threading)

(provide/contract
 [printing-admin-script-shell-command-exec-to-string
  (->* (string?) ((listof string?)) string?)])

(define (printing-admin-script-shell-command-exec-to-string script-name
                                                            [switches '()])
  (~>
   script-name
   (printing-admin-script-shell-command switches)
   shell-command-string-result
   standartize-cscript-output))

(define/contract (printing-admin-script-shell-command script-name
                                                      [switches '()])
  (->* (string?) ((listof string?)) string?)
  (~>>
   script-name
   (string-append _ ".vbs")
   (build-path
    (getenv "windir")
    "System32"
    "Printing_Admin_Scripts"
    "en-US")
   (path->string)
   (string-append _ " " (string-join switches " "))
   (string-append "cscript ")))

(define/contract (shell-command-string-result shell-command)
  (-> string? string?)
  (with-output-to-string (lambda () (system shell-command))))

(define/contract (standartize-cscript-output output-string)
  (-> string? string?)
  (~>
   output-string
   (string-split "\n")
   (filter (lambda (l)
             (not (or
                   (string-prefix? l "Microsoft")
                   (string-prefix? l "Copyright")
                   (string-prefix? l "\r"))))
           _)
   (string-join "\n")))

(module+ main
  (display
   (printing-admin-script-shell-command-exec-to-string "prnmngr" '("-l"))))
