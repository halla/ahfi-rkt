#lang racket

(require web-server/servlet)
(require web-server/servlet-env)
(require web-server/dispatch)
(require web-server/configuration/responders)
(require web-server/templates)
(require xml)

(require db)

(struct post (id body slug date_published title))
(struct blog (db))

(define my-blog (sqlite3-connect #:database "site-dev.db"))

(define (blog-posts a-blog) 
  (for/list ([(id body slug date_published title) 
              (in-query my-blog "SELECT * from posts ORDER BY date_published DESC")])
       (post id body slug date_published title)))

(define (get-next-post date_published)
  (let ([post-data (query-maybe-row my-blog "SELECT * from posts WHERE date_published > ? ORDER BY date_published ASC LIMIT 1" date_published)])
    (if post-data
        (apply post (vector->list post-data))
        #f)))

(define (get-prev-post date_published)
  (let ([post-data (query-maybe-row my-blog "SELECT * FROM posts where date_published < ? ORDER BY date_published DESC LIMIT 1" date_published)])
    (if post-data
        (apply post (vector->list post-data))
        #f)))

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
    ,@(map (λ (x) `(link [[type "text/css"] [rel "stylesheet"] [href ,x]])) head-styles)
    ,@(map (λ (x) `(script [[type "text/javascript"] [src ,x]])) head-scripts)

    (title "Antti Halla")))

(define (page-header)
  '(div [[id "header"]]
        (div [[class "container"]]
             (div [[class "row"]]
                  (div [[class "col-md-10"]]
                       (h2 (a [[href "/"] [class "site-title"]]
                              "Antti Halla —  Web & Data")))))))


(define (render-post-head post)
  `(li (a [[href "#"]] ,(post-title post))))

(define (list-posts)
  (xexpr->string `(ul [[class "blog-list-simple list-unstyled"]]
                    ,@(map render-post-head (blog-posts my-blog)))))


;; Dispatcher
(define-values (dispatch site-url)
  (dispatch-rules
   [("static" (string-arg)) serve-static]
   [("static" (string-arg) (string-arg)) serve-static]
   [("static" (string-arg) (string-arg) (string-arg)) serve-static]
   [else start]))

(define (serve-static req . files)
  (file-response 200 #"OK" (apply build-path here "static" files)))


(define (start request)
  (response/xexpr
   `(html ,(page-head)
          (body 
           ,(page-header)
           ,(blog-dispatch request)
           ,(make-cdata #f #f (include-template "templates/footer.html"))))))

(define (render-post this-post)
  (let ([prev-post (get-prev-post (post-date_published this-post))]
        [next-post (get-next-post (post-date_published this-post))])
    (make-cdata #f #f (include-template "templates/post-view.html"))))

(define (review-post req year month slug empty)
  (let ([post-data (query-maybe-row my-blog "SELECT * from posts WHERE slug = ?" slug)])
    (if post-data
        (let ([this-post (apply post (vector->list post-data))])
          (render-post this-post))
        "Not found")))
  
(define (index-page req) 
  (make-cdata #f #f (include-template "templates/index.html")))

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


