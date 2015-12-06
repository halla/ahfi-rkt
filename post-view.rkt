#lang racket

; INTERFACE

(provide 
 ;(review-post req year month slug empty)
 ;post as cdata-xexpr html-string
 review-post 
 ;(list-posts)
 ; list meta of all posts
 list-posts)


; IMPLEMENTATION

(require "post.rkt")
(require xml)
(require web-server/templates)
(require "local-config.rkt")
(require (only-in markdown
                  parse-markdown))


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


