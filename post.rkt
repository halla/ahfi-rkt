#lang racket

(require db)

(struct blog (db))

(struct post (id body slug date_published title))

(define my-blog (sqlite3-connect #:database "site-dev.db"))

(define (blog-posts) 
  (for/list ([(id body slug date_published title) 
              (in-query my-blog "SELECT * from posts ORDER BY date_published DESC")])
       (post id body slug date_published title)))

(define (get-post slug)
 (query-maybe-row my-blog "SELECT * from posts WHERE slug = ?" slug))

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

(provide (all-defined-out))
(provide (struct-out post))