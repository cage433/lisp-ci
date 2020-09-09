(proclaim '(optimize (debug 3)))

(defpackage :cage433-ci
  (:use :common-lisp )
  (:export :load-and-compile-if-necessary
           :run-ci-function)
  )

(in-package :cage433-ci)

(defun load-and-compile-if-necessary (name)
  (labels ((file-name (ext) (concatenate 'string name ext))
           (file-date (ext)
              (and (probe-file (file-name ext))
                  (file-write-date (file-name ext))))
           (compile-source()
            (format *standard-output* "Compiling ~A~%" name)
            (multiple-value-bind (output-file warnings-p failure-p)
                                 (compile-file name :verbose nil :print nil)
              (let ((success (and (null warnings-p) (null failure-p))))
                (unless success
                  (delete-file output-file))
                success)))
           (fasl-out-of-date()
              (let ((src-time (file-date ".lisp"))
                        (fasl-time (file-date ".fasl")))
                    (or (null fasl-time)
                        (> src-time fasl-time))))
           (load-fasl()
             (load (file-name ".fasl") :verbose nil))
           )
    (if (fasl-out-of-date)
      (and (compile-source) (load-fasl))
      (progn (load-fasl) t))))

(defun ascii-color (color)
  (ecase color
    (:red 31)
    (:green 32)
    (:blue 34)))

(defun colored-text (text color &key bold)
  (format nil "~c[~a~:[~;;1~]m~a~c[0m"
          #\Esc
          (ascii-color color)
          bold
          text #\Esc))

(defun run-ci-function(ci-fun)
  (declare #+sbcl(sb-ext:muffle-conditions style-warning))
  (multiple-value-bind (success error-condition)
    (ignore-errors
      (funcall ci-fun)
      )
    (if success
      (progn
        (format t (colored-text "Tests passed~%" :green))
        (sb-ext:exit :code 0))
      (progn
        (if error-condition
          (format t (colored-text "~a~%" :red) error-condition)
          (format t (colored-text "Tests failed ~%" :red)))
        (sb-ext:exit :code 1)))))




