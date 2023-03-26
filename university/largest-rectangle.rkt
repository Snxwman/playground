#lang racket

(define area
  (lambda (coords)
    (* (- (third (flatten coords)) (first (flatten coords)))
    (- (second (flatten coords)) (fourth (flatten coords))))))

(define max
  (lambda (a)
    (if (= (length a) 1)
      (car a)
      (if (> (car a) (car (cdr a)))
        (car a)
        (max (cdr a))))))

(define largest-rectangle
  (lambda (rectangles)
    (if (= (length rectangles) 0)
      "No Rectangles Given"
      (if (= (length rectangles) 1)
        (car rectangles)
        (if (> (area (car rectangles)) (max (flatten (map area (cdr rectangles)))))
          (car rectangles)
          (largest-rectangle (cdr rectangles)))))))

(define rectangles '((3 12 9 5) (7 7 12 2) (8 11 12 9) (12 5 16 3)))
(largest-rectangle rectangles)
