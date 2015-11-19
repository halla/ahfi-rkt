#lang racket

(require web-server/servlet)
(require web-server/servlet-env)
(require web-server/dispatch)
(require web-server/configuration/responders)
(require web-server/templates)
(require xml)
(require (prefix-in s. srfi/19))
(require (only-in markdown
                  parse-markdown))

(require "post.rkt")
(require "view.rkt")
(require "local-config.rkt")




(define (prev-link post)
  `(a [[href ,(gen-post-link-rel post)] [class "prev-post"] [title "Previous post <Left Arrow>"]] "← " ,(post-title post)))

(define (next-link post)
  `(a [[href ,(gen-post-link-rel post)] [class "next-post"]  [title "Next post <Left Arrow>"]] ,(post-title post) " →"))



(define (render-disqus post)
  (let ([disqus_id (gen-post-link-abs post)]
        [disqus_url (gen-post-link-abs post)]
        [disqus_title (post-title post)])
    (make-cdata #f #f (include-template "templates/disqus.html"))))


(define (gen-post-link-rel post) 
  (match-define (list yyyy mm dd)
    (string-split (post-date_published post) "-"))
  (string-append  "/blog/" yyyy "/" mm "/" (post-slug post) "/"))

(define (gen-post-link-abs post)
  (string-append "http://anttihalla.fi/" (gen-post-link-rel post)))




(define (render-post-head post)
  `(li (a [[href ,(gen-post-link-rel post)]] ,(post-title post))))

(define (list-posts)
  (xexpr->string `(ul [[class "blog-list-simple list-unstyled"]]
                    ,@(map render-post-head (blog-posts)))))


(define (sqldate->rfc822 sqldate)
  (s.date->string (s.string->date sqldate "~Y-~m-~d") "~a, ~d ~b ~Y ~H:~M:~S ~z"))
 

(define (render-post-body post)
  (string-append 
   "<![CDATA["
   (xexpr->string `(div ,@(parse-markdown (string-replace (post-body post) "\r" ""))))
   "]]>"))

;; RSS
(define (render-rss-item post)
  `(item 
    (title ,(post-title post))
    (link ,(gen-post-link-abs post))
    (guid ,(gen-post-link-abs post))
    (pubDate ,(sqldate->rfc822 (post-date_published post)))
    (description ,(make-cdata #f #f (render-post-body post)))
    
    ))

(define (render-rss posts)
  `(rss [[version "2.0"]]
        (channel
         (title "Antti Halla — Web & Data")
         (link "http://anttihalla.fi")
         (description "Exploring Web & Data")
         ,@(map render-rss-item posts))))



;; Dispatcher
(define-values (dispatch site-url)
  (dispatch-rules
   [("static" (string-arg)) serve-static]
   [("static" (string-arg) (string-arg)) serve-static]
   [("static" (string-arg) (string-arg) (string-arg)) serve-static]
   [("blog" "feeds" "rss" (string-arg)) rss-feed]
   [else start]))

(define (serve-static req . files)
  (file-response 200 #"OK" (apply build-path here "static" files)))


(define (start request)
  (response/xexpr
   #:preamble #"<!DOCTYPE html>\n"
   `(html ,(page-head)
          (body 
           ,(render-gtm-tag)
           ,(page-header)
           ,(blog-dispatch request)
           ,(make-cdata #f #f (include-template "templates/footer.html"))))))

(define (render-post this-post)
  (let ([prev-post (get-prev-post (post-date_published this-post))]
        [next-post (get-next-post (post-date_published this-post))])
    (make-cdata #f #f (include-template "templates/post-view.html"))))

(define (review-post req year month slug empty)
  (let ([post-data (get-post slug)])
    (if post-data
        (let ([this-post (apply post (vector->list post-data))])
          (render-post this-post))
        "Not found")))
  
(define (index-page req) 
  (make-cdata #f #f (include-template "templates/index.html")))

(define (rss-feed req _)
  (response/xexpr 
   #:preamble #"<?xml version='1.0' encoding='UTF-8'?>"
   (render-rss (blog-posts))))

(define-values (blog-dispatch blog-url)
    (dispatch-rules
     [("") index-page]
     [("posts" (string-arg)) review-post]
     [("blog" (string-arg) (string-arg) (string-arg) (string-arg)) review-post]
     [else (λ (req) "Not found")]))

(require racket/runtime-path)
(define-runtime-path here ".")

(serve/servlet dispatch
               #:extra-files-paths (list (build-path here "static"))
               #:servlet-regexp #rx""
               #:servlet-path "/"
               )


(module+ test
         (require rackunit)

         (check-equal? 1 1)
         (check-equal? (sqldate->rfc822 "2015-01-01") "Thu, 01 Jan 2015 00:00:00 +0000"))

