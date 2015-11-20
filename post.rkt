#lang racket

(require db)

(struct blog (db))

(struct post (id body slug date_published title))

(define my-blog (sqlite3-connect #:database "db/site-dev.db"))

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

(define (gen-post-link-rel post) 
  (match-define (list yyyy mm dd)
    (string-split (post-date_published post) "-"))
  (string-append  "/blog/" yyyy "/" mm "/" (post-slug post) "/"))

(define (gen-post-link-abs post)
  (string-append "http://anttihalla.fi/" (gen-post-link-rel post)))


(provide (all-defined-out))
(provide (struct-out post))