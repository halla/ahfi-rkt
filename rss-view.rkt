#lang racket

(require xml)
(require "post.rkt")
(require "util.rkt")
(require (only-in markdown
                  parse-markdown))


;; RSS
(define (render-rss-item post)
  `(item 
    (title ,(post-title post))
    (link ,(gen-post-link-abs post))
    (guid ,(gen-post-link-abs post))
    (pubDate ,(sqldate->rfc822 (post-date_published post)))
    (description ,(make-cdata #f #f (render-post-body post)))))

(define (render-rss posts)
  `(rss [[version "2.0"]]
        (channel
         (title "Antti Halla — Web & Data")
         (link "http://anttihalla.fi")
         (description "Exploring Web & Data")
         ,@(map render-rss-item posts))))


(define (render-post-body post)
  (string-append 
   "<![CDATA["
   (xexpr->string `(div ,@(parse-markdown (string-replace (post-body post) "\r" ""))))
   "]]>"))

(module+ test
         (require rackunit)

         (check-equal? 1 1)
         (check-equal? (sqldate->rfc822 "2015-01-01") "Thu, 01 Jan 2015 00:00:00 +0000"))


(provide render-rss)