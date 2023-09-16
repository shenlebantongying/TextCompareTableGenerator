#!/usr/bin/env racket
#lang racket

(define (throw-error str)
  (displayln str)
  (exit 1))

;;;;;;;;;;;;;;;;
;; tagging lines

;; TODO: bad code
(define (process-lines)
  (letrec ([aux (lambda (request-tag acc)
                  (let* ([cur-line (read-line)]
                         [cur-type (line-analyze cur-line)])
                    (match cur-type
                      ['eof acc]
                      ['line (if request-tag
                                 (aux false (list cur-line 'normal))
                                 (aux false (cons (string-trim cur-line #:left? #f) acc)))]
                      ['sec-start
                       (if request-tag
                           (aux false (list (obtain-title cur-line) 'section))
                           (cons (reverse acc) (aux false (list (obtain-title cur-line) 'section))))]
                      ['sec-end (cons (reverse acc) (aux true (list)))])))])
    (aux true (list))))

(define (line-analyze str)
  (cond
    [(equal? str eof) 'eof]
    [(< (string-length str) 3) 'line]
    [(equal? "```" str) 'sec-end]
    [(equal? "```" (substring str 0 3)) 'sec-start]
    [else 'line]))

(define (obtain-title title-line)
  (substring title-line 3))

;;;;;;;;;;
;; display

;; Calculate balanced half sec width
;; -hd1---------+-hd2----------
;;  <-- len --->| <-- len --->|
;; ============================

(define extra-space 1)

(define (calc-half-sec-width lst1 lst2)
  (letrec ([rec (lambda (lst1 lst2 len)
                  (if (or (empty? lst1) (empty? lst2))
                      len
                      (rec (cdr lst1) (cdr lst2) (max len (string-length (car lst1)) (string-length (car lst1))))))])
    (+ extra-space (rec lst1 lst2 0))))

(define (print-header hd1 hd2 len)
  (printf "-~a~a+-~a~a\n"
          hd1 (make-string (- len (string-length hd1)) #\-)
          hd2 (make-string (- len (string-length hd2)) #\-)))

(define (loop-body-lines lst1 lst2 len)
  (let ([c1 (empty? lst1)]
        [c2 (empty? lst2)])
    (cond
      [(and c1 (not c2))
       (print-body-lines "" (car lst2) len)
       (loop-body-lines (list) (cdr lst2))]
      [(and (not c2) c1)
       (print-body-lines (car lst1) "" len)
       (loop-body-lines (cdr lst1) (list))]
      [(and (not c1) (not c2))
       (print-body-lines (car lst1) (car lst2) len)
       (loop-body-lines (cdr lst1) (cdr lst2) len)]
      [else '()])))

(define (print-body-lines l1 l2 len)
  (let ([p-str (lambda (l)
                 (string-append " " l (make-string (- len (string-length l)) #\space)))])
    (printf "~a|~a\n" (p-str l1) (p-str l2))))

(define (print-sec-end len)
  (displayln (make-string (+ (* len 2) 3) #\=)))

;; finally display everything
(define (shutter data)
  (cond
    [(empty? data)
     (void)]
    [(eq? 'normal (caar data))
     (for ([line (cdar data)]) (displayln line)) (shutter (cdr data))]
    [(eq? 'section (caar data))
     (let* ([lst1 (car data)]
            [lst2 (cadr data)]
            [len (calc-half-sec-width (cdr lst1) (cdr lst2))])
       (print-header (cadr lst1) (cadr lst2) len)
       (loop-body-lines (cddr lst1) (cddr lst2) len)
       (print-sec-end len)
       (shutter (cddr data)))]))
;;;;;;;
;; Main

(define cmd (current-command-line-arguments))

(begin
  (when (< (vector-length cmd) 1)
    (throw-error "Need a input file"))
  (define tfile (vector-ref cmd 0)))

;; for debug
#;(define tfile (string->path "./test.md"))

(with-input-from-file tfile
  (lambda () (shutter (process-lines))))
