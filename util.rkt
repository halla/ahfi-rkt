#lang racket

; INTERFACE

(provide
 sqldate->rfc822)


; IMPLEMENTATION

(require (prefix-in s. srfi/19))

(define (sqldate->rfc822 sqldate)
  (s.date->string (s.string->date sqldate "~Y-~m-~d") "~a, ~d ~b ~Y ~H:~M:~S ~z"))


