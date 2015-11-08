#lang racket

(require web-server/servlet)
(require web-server/servlet-env)
(require web-server/dispatch)
(require db)

(struct post (id body slug date_published title))
(struct blog (db))

(define my-blog (sqlite3-connect #:database "site-dev.db"))

(define (blog-posts a-blog) 
  (for/list ([(id body slug date_published title) 
              (in-query my-blog "SELECT * from posts ORDER BY date_published DESC")])
       (post id body slug date_published title)))

(define head-scripts '("jquery-2.1.1.min.js" "boostrap.min.js" "mousetrap.min.js"))

(define (page-head)
  '(head
    (meta [[http-equiv "Content-type"] [content "text/html; charset=utf-8"]])
    (meta [[name "viewport"] [content "width=device-width, initial-scale=1"]])
    (link [[type "text/css"] [rel "stylesheet"]] "style.css")
    (title "Antti Halla")))

(define (page-header)
  '(div [[id "header"]]
        (div [[class "container"]]
             (div [[class "row"]]
                  (div [[class "col-md-10"]]
                       (h2 (a [[href "/"] [class "site-title"]]
                              "Antti Halla —  Web & Data")))))))


(define (render-post-head post)
  `(div (a [[href "#"]] ,(post-title post))))

(define (list-posts req)
  `(ul
    ,@(map render-post-head (blog-posts my-blog))))

(define (start request)
  (response/xexpr
   `(html ,(page-head)
          (body 
           ,(page-header)
           ,(blog-dispatch request)))))

(define (render-post post)
  (post-title post))

(define (review-post req year month slug empty)
  (let ([post-data (query-maybe-row my-blog "SELECT * from posts WHERE slug = ?" slug)])
    (if post-data
        (render-post (apply post (vector->list post-data)))
        "Not found")))
  
(define-values (blog-dispatch blog-url)
    (dispatch-rules
     [("") list-posts]
     [("posts" (string-arg)) review-post]
     [((string-arg) (string-arg) (string-arg) (string-arg)) review-post]
     [else list-posts]))

(serve/servlet start
               #:servlet-regexp #rx""
               #:servlet-path "/")
