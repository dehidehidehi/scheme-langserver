(library (scheme-langserver analysis package-manager akku)
  (export generate-akku-acceptable-file-filter)
  (import 
    (chezscheme)
    (scheme-langserver util io)
    (scheme-langserver virtual-file-system file-node)
    (only (srfi :13 strings) string-prefix? string-contains string-index-right string-index string-take string-drop string-drop-right))
  
(define (generate-akku-acceptable-file-filter list-path)
  (let* ([root (string-drop-right list-path 10)]
      [akku-path (string-append root ".akku")]
      [akku-lib-path (string-append root ".akku/lib")]
      [path->library (make-hashtable string-hash equal?)])
    (map 
      (lambda (line) 
        (let* ([first-tab-index (string-index line #\tab)]
            [second-tab-index (string-index line #\tab (+ 1 first-tab-index))]
            [target-path (string-drop-right line (- (string-length line) first-tab-index))]
            [target-library (string-drop (string-drop-right line (- (string-length line) second-tab-index)) (+ 1 first-tab-index))])
          (hashtable-set! path->library (string-append root target-path) target-library))) 
      (read-lines list-path))
    (lambda (path)
      (cond 
        [(string-contains path "/.git/") #f]
        [(equal? path akku-path) #t]
        [(equal? path akku-lib-path) #t]
        [(and (string-prefix? akku-path path) (not (string-prefix? akku-lib-path path))) #f]
        [(and (string-prefix? akku-path path) (string-prefix? akku-lib-path path) (file-directory? path)) #t]
        [(and (string-prefix? akku-path path) (string-prefix? akku-lib-path path) (hashtable-ref path->library path #f)) 
          (not (equal? "-" (hashtable-ref path->library path #f)))]
        [(not (string-prefix? akku-path path)) (not (equal? #f (folder-or-scheme-file? path)))]
        [else #f]))))
)