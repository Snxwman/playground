#lang racket

;Find if a rectangle overlaps (intersection or containment) other rectangles in a grid.

;Checks if r1 contains r2
;r1, r2 - rectangles
(define contains
  (lambda (r1 r2)
    (if (and
        (and (< (first r1) (first r2)) (> (third r1) (third r2)))      ;r1 is wider than r2
        (and (> (second r1) (second r2)) (< (fourth r1) (fourth r2)))) ;r1 is taller than r2
      #t
      #f )))

;Checks if r1 intersects r2
;r1, r2 - rectangles
(define intersects
  (lambda (r1 r2)
    (if (and 
          (or  ;Horizontal alignment (a vertical side of r1 is between the vertical sides of r2)
            (and (> (first r1) (first r2))
                 (< (first r1) (third r2)))
            (and (> (third r1) (first r2))
                 (< (third r1) (third r2))))
          (or  ;Vertical alignment (a horizontal side of r1 is between the horizontal sides of r2)
            (and (< (second r1) (second r2))
                 (> (second r1) (fourth r2)))
            (and (< (fourth r1) (second r2))
                 (> (fourth r1) (fourth r2)))))
      #t
      #f )))

;Finds all rectangles in `grid` that overlap with `rect`
;Returns a list of rectangles that overlap
;rect - given rectangle
;grid - list of rectangles to check `rect` against
(define find-overlap
  (lambda (rect grid)
    (if (null? rect)
      "Error: No rectangle given"
      (if (null? grid)
        '()  ;Return an empty list if there are no rectangles in the grid
        (if (or (contains rect (car grid)) (contains (car grid) rect) (intersects rect (car grid)))  ;rect contains, is contained by, or intersects `(car grid)`
          (append (list (car grid)) (find-overlap rect (cdr grid)))  ;Keep `(car grid)` and recurse
          (find-overlap rect (cdr grid)))))))  ;Ignore `(car grid)` and recurse

"Test 1"
(define rect1 '(5 5 50 0))
(define grid1 '((0 10 5 0) (0 5 4 0) (0 10 10 0) (60 4 70 2) (4 6 6 4)))
(find-overlap rect1 grid1)
'((0 10 10 0) (4 6 6 4))  ;Expected output
(newline)

"Test 2"  ;Rect is a point
(define rect2 '(0 0 0 0))
(define grid2 '((0 10 5 0) (0 5 4 0) (0 10 10 0) (6 6 3 3) (4 6 6 4) (0 0 0 0) (1 1 1 1) (-1 1 1 -1)))
(find-overlap rect2 grid2)
'((-1 1 1 -1))  ;Expected output
(newline)

"Test 3"  ;Rect contains all rectangles in grid
(define rect3 '(0 10 10 0))
(define grid3 '((1 9 9 1) (3 3 3 3)))
(find-overlap rect3 grid3)
'((1 9 9 1) (3 3 3 3))  ;Expected output
(newline)

"Test 4"  ;No overlap
(define rect4 '(2 2 4 4))
(define grid4 '((6 6 8 8)))
(find-overlap rect4 grid4)
'()  ;Expected output
(newline)

"Test 5"  ;No rectangle given
(define rect5 '())
(define grid5 '((6 6 8 8)))
(find-overlap rect5 grid5)
"Error: No rectangle given"  ;Expected output
(newline)

"Test 6"  ;Rect is adjacent to all rectangles in grid
(define rect6 '(3 9 7 4))
(define grid6 '((5 4 6 1) (7 6 10 5) (1 14 14 9) (0 10 3 0)))
(find-overlap rect6 grid6)
'() ;Expected output
(newline)

"Test 7"  ;Rect has negative coordinates
(define rect7 '(-5 5 5 -5))
(define grid7 '((-1 -1 -1 -1) (0 0 0 0) (1 1 1 1) (2 8 9 1)  (-4 2 3 1) (-7 -7 1 -9) (-8 1 -1 -11) (-3 -1 -1 -3)  (5 5 8 2) (3 3 6 -6)))
(find-overlap rect7 grid7)
'((-1 -1 -1 -1) (0 0 0 0) (1 1 1 1) (2 8 9 1) (-4 2 3 1) (-8 1 -1 -11) (-3 -1 -1 -3) (3 3 6 -6))  ;Expected output
(newline)

"Test 8"  ;No rectangles in grid
(define rect8 '(2 9 16 4))
(define grid8 '())
(find-overlap rect8 grid8)
'()  ;Expected output
(newline)