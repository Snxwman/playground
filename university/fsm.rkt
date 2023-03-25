#lang racket

;Returns the number of the next state after applying the transition function for the given symbol
(define transition
  (lambda (current-state symbol transitions)
    ; Gets the first list that coresponds to the current-state then gets the sublist that coresponds to the current symbol.
    (second (assoc symbol (cdr (assoc current-state transitions))))))

;Determines if a string is valid for the defined finite state machine
(define valid-string?
  (lambda (alphabet current-state final-states transitions string)
    (if (null? string)
      (if (member current-state final-states)  ;The current state is a final (acceptance) state
        #t
        #f )
      (if (member (car string) alphabet)  ;The current symbol is in the alphabet
        (valid-string? alphabet (transition current-state (car string) transitions) final-states transitions (cdr string))
        #f ))))
 
;Finite State Machine definition
;This example FSM is the FSM given in homework 3, question 1.
(define alphabet '(a b))
(define start-state 0)
(define final-states '(0 3 6))
(define transitions '((0 (a 1) (b 4))  ;e.g. at q0-a->q1 or at q0-b->q4
                      (1 (a 7) (b 2))
                      (2 (a 3) (b 7))
                      (3 (a 1) (b 7))
                      (4 (a 5) (b 7))
                      (5 (a 7) (b 6))
                      (6 (a 7) (b 4))
                      (7 (a 7) (b 7))))

;String to test on the FSM
(define string '(b a b))

;Run the FSM
(if (or (null? alphabet) (null? start-state) (null? final-states) (null? transitions))
  (error "Finite State Machine not fully specified")
  (if (valid-string? alphabet start-state final-states transitions string)
    "ACCEPTED"
    "REJECTED"))