;;
;;  cl-project  -  Common Lisp source project utilities
;;
;;  Copyright 2015-2017 Thomas de Grivel <thoxdg@gmail.com>
;;
;;  Permission to use, copy, modify, and distribute this software for any
;;  purpose with or without fee is hereby granted, provided that the above
;;  copyright notice and this permission notice appear in all copies.
;;
;;  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;;  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;;  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;;  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;;  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;;  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;;  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
;;

(in-package :cl-project)

(defgeneric header (file))

(defun empty-p (line)
  (string= "" (string-trim (coerce '(#\Space #\Tab) 'string) line)))

(defmethod header ((stream stream))
  (with-output-to-string (out)
    (loop
       (let ((line (read-line stream)))
	 (when (empty-p line)
	   (return))
	 (write-string line out)
	 (write-char #\Newline out)))))

(defmethod header ((pathname pathname))
  (with-open-file (stream pathname
			  :element-type 'character
			  :external-format :utf-8)
    (header stream)))

(defmethod header ((pathname string))
  (header (pathname pathname)))

(defgeneric (setf header) (value file))

(defvar *buffer-size*
  65536)

(defun copy-stream (in out)
  (let ((seq (make-array `(,*buffer-size*)
			 :element-type 'character)))
    (loop
       (let ((r (read-sequence seq in)))
	 (when (= 0 r)
	   (return))
	 (write-sequence seq out :end r)))))

(defmethod (setf header) ((value string) (pathname pathname))
  (let ((out-path (pathname (concatenate 'string (namestring pathname)
					 ".cl-project.tmp"))))
    (with-open-file (in pathname
			:element-type 'character
			:external-format :utf-8)
      (loop
	 (let ((line (read-line in nil)))
	   (unless line
	     (file-position in 0)
	     (return))
	   (when (empty-p line)
	     (return))))
      (with-open-file (out out-path
			   :direction :output
			   :external-format :utf-8
			   :if-does-not-exist :create
			   :if-exists :supersede)
	(write-string value out)
	(write-char #\Newline out)
	(copy-stream in out)
	(delete-file in)
	(rename-file out pathname)
	value))))

(defmethod (setf header) ((value string) (pathname string))
  (setf (header (pathname pathname)) value))

(defun project-asd (dir)
  (directory (make-pathname :name :wild
			    :type "asd"
			    :directory (pathname-directory dir)
			    :defaults dir)))

(defun project-lisp (dir)
  (let* ((wild-dir `(,@(pathname-directory dir) :wild-inferiors))
	 (wild-pathname (make-pathname :name :wild
				       :type "lisp"
				       :directory wild-dir
				       :defaults dir)))
    (directory wild-pathname)))

(defun update-header (project-dir)
  (let* ((asd (first (project-asd project-dir)))
	 (hdr (header asd)))
    (format t "~&; ~A~%" (enough-namestring asd))
    (dolist (src (project-lisp project-dir))
      (format t "~&;  ~A~%" (enough-namestring src))
      (setf (header src) hdr))))
