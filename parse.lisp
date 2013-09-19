;;;;  json-streams
;;;;
;;;;  Copyright (C) 2013 Thomas Bakketun <thomas.bakketun@copyleft.no>
;;;;
;;;;  This library is free software: you can redistribute it and/or modify
;;;;  it under the terms of the GNU Lesser General Public License as published
;;;;  by the Free Software Foundation, either version 3 of the License, or
;;;;  (at your option) any later version.
;;;;
;;;;  This library is distributed in the hope that it will be useful,
;;;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;  GNU General Public License for more details.
;;;;
;;;;  You should have received a copy of the GNU General Public License
;;;;  along with this library.  If not, see <http://www.gnu.org/licenses/>.

(in-package #:json-streams)


(defun json-parse (source &rest options)
  (with-open-json-stream (jstream (apply #'make-json-input-stream source options))
    (values (parse-single jstream)
            (slot-value jstream 'position))))


(defun json-parse-multiple (source &rest options)
  (with-open-json-stream (jstream (apply #'make-json-input-stream source :multiple t options))
    (loop for value = (parse-single jstream)
          until (eql :eof value)
          collect value)))


(defun parse-single (jstream)
  (labels ((parse-array (jstream)
             (cons :array
                   (loop for value = (parse-value jstream)
                         until (eql :end-array value)
                         collect value)))
           (parse-object (jstream)
             (cons :object
                   (loop for key = (parse-value jstream)
                         until (eql :end-object key)
                         collect (cons key (parse-value jstream)))))
           (parse-value (jstream)
             (let ((token (json-read jstream)))
               (case token
                 (:true t)
                 (:false nil)
                 (:begin-array (parse-array jstream))
                 (:begin-object (parse-object jstream))
                 (otherwise token)))))
    (values (parse-value jstream)
            (json-stream-position jstream))))
