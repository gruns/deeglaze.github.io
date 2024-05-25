; ****************** BEGIN INITIALIZATION FOR ACL2s MODE ****************** ;
; (Nothing to see here!  Your actual file is after this initialization code);

#+acl2s-startup (er-progn (assign fmt-error-msg "Problem loading ACL2's lexicographic-ordering book.~%This indicates that either your ACL2 installation is missing the standard books are they are not properly certified.") (value :invisible))
(include-book "ordinals/lexicographic-ordering" :dir :system)

#+acl2s-startup (er-progn (assign fmt-error-msg "Problem loading the CCG book.~%Please choose \"Recertify ACL2s system books\" under the ACL2s menu and retry after successful recertification.") (value :invisible))
(include-book "ccg" :uncertified-okp nil :dir :acl2s-modes :ttags ((:ccg)) :load-compiled-file :comp)

#+acl2s-startup (er-progn (assign fmt-error-msg "Problem loading the TRACE* book.~%Please choose \"Recertify ACL2s system books\" under the ACL2s menu and retry after successful recertification.") (value :invisible))
; only load for interactive sessions: 
#+acl2s-startup (include-book "trace-star" :uncertified-okp nil :dir :acl2s-modes :ttags ((:acl2s-interaction)) :load-compiled-file :comp)
#+acl2s-startup (assign evalable-printing-abstractions nil)

#+acl2s-startup (er-progn (assign fmt-error-msg "Problem loading DataDef+RandomTesting book.~%Please choose \"Recertify ACL2s system books\" under the ACL2s menu and retry after successful recertification.") (value :invisible))
(include-book "acl2-datadef/acl2-check" :uncertified-okp nil :dir :acl2s-modes :load-compiled-file :comp)

#+acl2s-startup (er-progn (assign fmt-error-msg "Problem loading ACL2s customizations book.~%Please choose \"Recertify ACL2s system books\" under the ACL2s menu and retry after successful recertification.") (value :invisible))
(include-book "custom" :dir :acl2s-modes :uncertified-okp nil :load-compiled-file :comp)

#+acl2s-startup (er-progn (assign fmt-error-msg "Problem setting up ACL2s mode.") (value :invisible))

; Other events:
(set-well-founded-relation l<)
(make-event ; use ruler-extenders if available
 (if (member-eq 'ruler-extenders-lst
                (getprop 'put-induction-info 'formals nil
                         'current-acl2-world (w state)))
   (value '(set-ruler-extenders :all))
   (value '(value-triple :invisible))))

; Non-events:
(set-guard-checking :none)

;THIS IS THE ENABLER FOR RANDOM TESTING
(set-acl2s-random-testing-enabled t)
;verbosity settings for random-testing and defdata stuff
(set-acl2s-random-testing-verbose nil)
(set-acl2s-defdata-verbose nil)
;Settings for avoiding control stack errors for testing non-tail-recursive fns
(defdata-testing pos :test-enumerator nth-pos-testing)
(defdata-testing integer :test-enumerator nth-integer-testing)
(defdata-testing nat :test-enumerator nth-nat-testing)
(defdata-testing neg :test-enumerator nth-neg-testing)
(set-acl2s-random-testing-use-test-enumerator t)


;hopefully the following will not affect the checkpoint testing hints
(assign checkpoint-processors
  (set-difference-eq (@ checkpoint-processors)
                     '(ELIMINATE-DESTRUCTORS-CLAUSE)))

;added by harshrc on behalf of Pete
(set-termination-method :ccg)
(set-ccg-time-limit nil)
(set-ccg-print-proofs nil)
(set-ccg-inhibit-output-lst
 '(QUERY BASICS PERFORMANCE BUILD/REFINE SIZE-CHANGE))

; ******************* END INITIALIZATION FOR ACL2s MODE ******************* ;
;$ACL2s-SMode$;ACL2s
#|

Make sure that your session mode is "recursion and induction"
and that the line mode is "enforced" for this lab. You 
have to modify this file.

Before you start, make sure you are using the *latest* version of 
ACL2s. We updated it on Oct 22nd, so use eclipse to get the latest 
version.

We start with some familiar definitions.

|#


(defun tlp (x)
  (if (endp x)
    (equal x nil)
    (tlp (cdr x))))

(defun app (x y)
  (if (endp x) 
    y
    (cons (first x)
          (app (rest x) y))))

(defun rev (x)
  (if (endp x)
    nil
    (app (rev (cdr x))
         (list (car  x)))))

(defun dup (x)
  (if (endp x)
    nil
    (cons (* 2 (car x)) 
          (dup (cdr x)))))

#|

Part 1. Falsify or Validate.

For all conjectures in this section, determine if they are valid 
or if a counterexample exists. If they are valid put a "test?" 
around them (which should succeed). 

If they are falsifiable, put a let around them that binds all free 
variables and evaluates to nil. Recall that a falsifiable conjecture
may have a witness: a substitution that evaluates to t. If the 
conjecture has a witness, put a let around it that binds all free
variables and evaluates to t.

For example, consider the following conjecture:

(equal x y)

It is obviously falsifiable. (Notice that using test? will reveal 
a counterexample!) So, you should wrap it in a let that evaluates 
to nil, eg:

(let ((x 1)
      (y 2))
  (equal x y))

It also has a witness, so you should wrap it in a let that 
evaluates to t, eg:

(let ((x 1)
      (y 1))
  (equal x y))

If you were considering the conjecture:

(equal x x)

This is obviously true, so you should wrap it in a test? as follows:

(test? (equal x x))

This succeeds (because test? cannot find a counterexample).

|#

(implies (and (rationalp x)
              (integerp y)
              (<= x y))
         (= x (* x y)))

(implies (and (rationalp x)
              (integerp y))
         (not (integerp (+ x y))))

(implies (and (rationalp x)
              (integerp (+ x 1)))
         (integerp (+ 3 (* 2 x))))

(equal (rev (dup (rev x))) (dup x))

(tlp (dup x))

(equal (rev (dup x)) (dup (rev x)))

(implies (equal (dup x) (rev y))
         (equal (app (rev y) (dup y))
                (dup (app x y))))

(equal (dup (app x y))
       (app (dup x) (dup y)))

#|

Part 2. Proving theorems.

All conjectures in this section are theorems. You have to figure out
how to steer ACL2s so that it discovers a proof. 

You only have two things you can do to help ACL2s.

1. Give an induction hint.

For example, given the conjecture:

(equal (tlp (app x y))
       (tlp y))

You should wrap it in a "theorem", give it a name, and tell ACL2s
to induct on x. We use (tlp x) in the induction hint because the 
intended domain of x is tlp (true-listp).

(theorem app-tlp 
 (equal (tlp (app x y))
        (tlp y))
 :hints (("Goal" :induct (tlp x))))

Another thing you can do is to tell ACL2s that it should use a 
previously proven theorem. For example, given the conjecture

(tlp (rev x))

You can tell ACL2s to induct on x and to use the previous app-tlp
theorem as follows:

(theorem rev-tlp
  (tlp (rev x))
  :hints (("Goal"
           :induct (tlp x)
           :in-theory (enable app-tlp))))

Those are the only two hints you can give ACL2s (for now). 
Note that you can enable more than one previous theorem. For
example, to enable both th1 and th2, you would write:

  ... :in-theory (enable th1 th2) ...

However, you must use the *minimal* number of hints. If the proof 
goes through without an induction hint, but you include one anyway, 
you will not get full credit. If the proof goes through if you 
enable th1 only, but you enable th1, th2, and th3, you will not get
full credit.

|#

(tlp (dup x))

(tlp (rev x))

(equal (dup (app x y))
       (app (dup x) (dup y)))

(implies (equal (dup x) (rev y))
         (equal (app (rev y) (dup y))
                (dup (app x y))))



