(in-package :json-streams-tests)


(defun run-all-tests ()
  (quickcheck
    (random-test)
    (run-test-files)))

(define (a-json-array)
  (cons :array (generate (a-list a-json-value))))

(define (a-json-object)
  (cons :object
        (remove-duplicates
         (loop for (key value) in (generate (a-list (a-tuple #'a-string a-json-value)))
               collect (cons key value))
         :key #'car
         :test #'string=)))

(define (a-double-float)
  (coerce (generate a-real) 'double-float))

(define (a-number)
  (generate (a-member an-integer a-double-float)))

(define (a-json-text)
  (pick-weighted
    (1 (generate a-json-array))
    (1 (generate a-json-object))))

(define (a-json-value)
  (pick-weighted
    (10 :null)
    (10 (generate a-boolean))
    (10 (generate a-number))
    (10 (generate #'a-string))
    (1 (generate (a-member a-json-array a-json-object)))))

(defun random-test ()
  (for-all ((json a-json-text))
    (is= json (json-parse (princ (json-stringify json))))
    (terpri) (terpri)))


(defun run-test-files (&optional (dir (asdf:system-relative-pathname :json-streams "tests/")))
  (dolist (file (directory (merge-pathnames "*/*.json" dir)))
    (run-test-file file)))


(defun read-all-tokens (in options)
  (with-open-json-stream (jstream (apply #'make-json-input-stream in options))
    (loop for token = (handler-case (json-read jstream)
                        (json-parse-error () :error))
          collect token
          until (member token '(:eof :error)))))

(defmacro with-open-file* ((stream pathname &rest options) &body body)
  (let ((binary (gensym "BINARY-STREAM")))
    `(with-open-file (,binary ,pathname :element-type 'flex:octet ,@options)
       (with-open-stream (,stream (flex:make-flexi-stream ,binary :external-format '(:utf-8 :eol-style :lf)))
         ,@body))))


(defun run-test-file (file)
  (with-open-file* (in (make-pathname :type "lisp" :defaults file))
    (loop for options = (read in nil)
          for expected-tokens = (read in nil)
          while expected-tokens
          do
          (with-open-file* (in file)
            (loop for token-num from 0
                  for expected in expected-tokens
                  for got in (read-all-tokens in options)
                  do (named (format nil "~A ~S ~D" options (pathname-name file) token-num)
                       (is= expected got)))))))