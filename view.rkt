#lang racket

(require xml)
(require web-server/templates)

(require "local-config.rkt") ;; maybe inject the values some other way?

(define head-scripts '("/static/jquery-2.1.1.min.js" 
                       "/static/bootstrap-3.2.0-dist/js/bootstrap.min.js" 
                       "/static/mousetrap.min.js"))

(define head-styles '("http://fonts.googleapis.com/css?family=Raleway"
                      "http://fonts.googleapis.com/css?family=Lustria" 
                      "/static/bootstrap-3.2.0-dist/css/bootstrap.min.css"
                      "/static/style.css"))

(define (page-head)
  `(head
    (meta [[http-equiv "Content-type"] [content "text/html; charset=utf-8"]])
    (meta [[name "viewport"] [content "width=device-width, initial-scale=1"]])
    ,@(map (λ (x) `(link [[type "text/css"] [rel "stylesheet"] [href ,x] [media "all"]])) head-styles)
    ,@(map (λ (x) `(script [[type "text/javascript"] [src ,x]])) head-scripts)

    (title "Antti Halla")))

(define (page-header)
  '(div [[id "header"]]
        (div [[class "container"]]
             (div [[class "row"]]
                  (div [[class "col-md-10"]]
                       (h2 (a [[href "/"] [class "site-title"]]
                              "Antti Halla —  Web & Data")))))))

(define (render-gtm-tag) 
  (make-cdata #f #f (include-template "templates/gtm-tag.html")))



(provide (combine-out page-head page-header render-gtm-tag)) 