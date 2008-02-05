#lang scheme/base

(require scribble/struct
         scribble/manual-struct
         scribble/decode-struct
         scribble/base-render
         scribble/search
         (prefix-in html: scribble/html-render)
         scheme/class
         mzlib/serialize
         scheme/path
         setup/main-collects)

(provide load-xref
         xref?
         xref-render
         xref-index
         xref-binding->definition-tag
         xref-tag->path+anchor
         xref-tag->index-entry
         (struct-out entry))

(define-struct entry (words    ; list of strings: main term, sub-term, etc.
                      content  ; Scribble content to the index label
                      tag ; for generating a Scribble link
                      desc))   ; further info that depends on the kind of index entry

;; Private:
(define-struct xrefs (renderer ri))

(define (xref? x) (xrefs? x))

;; ----------------------------------------
;; Xref loading

(define-namespace-anchor here)

(define (load-xref sources #:render% [render% (html:render-mixin render%)])
  (let* ([renderer (new render%
                        [dest-dir (find-system-path 'temp-dir)])]
         [ci (send renderer collect null null)])
    (for-each (lambda (src)
                (parameterize ([current-namespace (namespace-anchor->empty-namespace here)])
                  (let ([v (src)])
                    (when v
                      (send renderer deserialize-info v ci)))))
              sources)
    (make-xrefs renderer (send renderer resolve null null ci))))

;; ----------------------------------------
;; Xref reading

(define (xref-index xrefs)
  (filter
   values
   (hash-table-map (collect-info-ext-ht (resolve-info-ci (xrefs-ri xrefs)))
                   (lambda (k v)
                     (and (pair? k)
                          (eq? (car k) 'index-entry)
                          (make-entry (car v) 
                                      (cadr v)
                                      (cadr k)
                                      (caddr v)))))))

(define (xref-render xrefs doc dest-file #:render% [render% (html:render-mixin render%)])
  (let* ([dest-file (if (string? dest-file)
                        (string->path dest-file)
                        dest-file)]
         [renderer (new render%
                        [dest-dir (path-only dest-file)])]
         [ci (send renderer collect (list doc) (list dest-file))])
    (send renderer transfer-info ci (resolve-info-ci (xrefs-ri xrefs)))
    (let ([ri (send renderer resolve (list doc) (list dest-file) ci)])
      (send renderer render (list doc) (list dest-file) ri)
      (void))))

;; Returns (values <tag-or-#f> <form?>)
(define xref-binding-tag
  (case-lambda
   [(xrefs id/binding mode)
    (let ([search
           (lambda (id/binding)
             (let ([tag (find-scheme-tag #f (xrefs-ri xrefs) id/binding mode)])
               (if tag
                   (values tag (eq? (car tag) 'form))
                   (values #f #f))))])
      (cond
        [(identifier? id/binding)
         (search id/binding)]
        [(and (list? id/binding)
              (= 6 (length id/binding)))
         (search id/binding)]
        [(and (list? id/binding)
              (= 2 (length id/binding)))
         (let loop ([src (car id/binding)])
           (cond
             [(path? src)
              (if (complete-path? src)
                (search (list src (cadr id/binding)))
                (loop (path->complete-path src)))]
             [(path-string? src)
              (loop (path->complete-path src))]
             [(resolved-module-path? src)
              (let ([n (resolved-module-path-name src)])
                (if (pair? n)
                  (loop n)
                  (search n)))]
             [(module-path-index? src)
              (loop (module-path-index-resolve src))]
             [(module-path? src)
              (loop (module-path-index-join src #f))]
             [else
              (raise-type-error 'xref-binding-definition->tag
                                "list starting with module path, resolved module path, module path index, path, or string"
                                src)]))]
        [else (raise-type-error 'xref-binding-definition->tag
                                "identifier, 2-element list, or 6-element list"
                                id/binding)]))]))

(define (xref-binding->definition-tag xrefs id/binding mode)
  (let-values ([(tag form?) (xref-binding-tag xrefs id/binding mode)])
    tag))

(define (xref-tag->path+anchor xrefs tag #:render% [render% (html:render-mixin render%)])
  (let ([renderer (new render%
                       [dest-dir (find-system-path 'temp-dir)])])
    (send renderer tag->path+anchor (xrefs-ri xrefs) tag)))

(define (xref-tag->index-entry xrefs tag)
  (let ([v (hash-table-get (collect-info-ext-ht (resolve-info-ci (xrefs-ri xrefs)))
                           `(index-entry ,tag)
                           #f)])
    (cond [v (make-entry (car v) (cadr v) (cadr tag) (caddr v))]
          [(and (pair? tag) (eq? 'form (car tag)))
           ;; Try again with 'def:
           (xref-tag->index-entry xrefs (cons 'def (cdr tag)))]
          [else #f])))
