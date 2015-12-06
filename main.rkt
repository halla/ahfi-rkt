#lang racket
(require reloadable)
(define main (reloadable-entry-point->procedure
              (make-reloadable-entry-point 'start-server "server.rkt")))
(reload!)
(main)
