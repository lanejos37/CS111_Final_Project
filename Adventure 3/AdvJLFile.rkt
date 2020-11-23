;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname AdvJLFile) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require "adventure-define-struct.rkt")
(require "macros.rkt")
(require "utilities.rkt")

(define-struct object
  (adjectives))
#:methods
(define(objectlist a)
  (type-name-string a))