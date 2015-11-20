#lang racket

(require web-server/servlet)
(require web-server/servlet-env)
(require web-server/dispatch)
(require web-server/configuration/responders)
(require web-server/templates)
(require xml)

(require (only-in markdown
                  parse-markdown))

(require "post.rkt")
(require "view.rkt")
(require "local-config.rkt")
(require (prefix-in rss. "rss-view.rkt"))



(define (prev-link post)
  `(a [[href ,(gen-post-link-rel post)] [class "prev-post"] [title "Previous post <Left Arrow>"]] "← " ,(post-title post)))

(define (next-link post)
  `(a [[href ,(gen-post-link-rel post)] [class "next-post"]  [title "Next post <Left Arrow>"]] ,(post-title post) " →"))



(define (render-disqus post)
  (let ([disqus_id (gen-post-link-abs post)]
        [disqus_url (gen-post-link-abs post)]
        [disqus_title (post-title post)])
    (make-cdata #f #f (include-template "templates/disqus.html"))))






(define (render-post-head post)
  `(li (a [[href ,(gen-post-link-rel post)]] ,(post-title post))))

(define (list-posts)
  (xexpr->string `(ul [[class "blog-list-simple list-unstyled"]]
                    ,@(map render-post-head (blog-posts)))))



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
   (rss.render-rss (blog-posts))))

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


