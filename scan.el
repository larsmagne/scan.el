;;; scan.el --- Scanning Sleeves
;; Copyright (C) 2001, 2002, 2003, 2010, 2011 Lars Magne Ingebrigtsen

;; Author: Lars Magne Ingebrigtsen <larsi@gnus.org>
;; Keywords: music

;; This file is not part of GNU Emacs.

;; Scan is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; Scan is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Scan; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;;; Code:

(require 'cl)
(require 'gnus-util)

(defvar scan-filter "pnmnorm -bvalue 20 -wvalue 235"
  "Command to do post-processing on the image.")

(defun scan-sleeve (dir &optional complete start-number
			callback)
  (interactive "DDirectory: ")
  (let ((suffix (if start-number
		    (format "-%d" start-number)
		  ""))
	(part (or start-number 0))
	(continue t))
    (while continue
      (let ((spec (scan-type)))
	(if spec
	    (scan-sleeve-1 dir spec suffix (not complete))
	  (setq continue nil)))
      (when callback
	(funcall callback))
      (if complete
	  (setq suffix (format "-%d" (incf part)))
	(setq continue nil)))
    (when callback
      (funcall callback))))

(defun scan-sleeve-1 (dir spec suffix async)
  (message "Scanning sleeve %s" spec)
  (let ((default-directory dir)
	(device (scan-find-device)))
    (call-process "scan-sleeve" nil (and async 0) nil
		  (format "epson2:libusb:%s:%s" (car device) (cdr device))
		  dir
		  (number-to-string (nth 0 spec))
		  (number-to-string (nth 1 spec))
		  (number-to-string (or (nth 2 spec) 0))
		  (number-to-string (or (nth 3 spec) 0))
		  suffix)))

(defun scan-type (&optional return-choice)
  ;; The numbers are in millimeters, and are width/height, with
  ;; optional start-x/start-y parameters.
  (let* ((types '((?\r "cd" 117 117)
		  (?b "cd booklet spread" 234 117)
		  (?c "naked cd" 119 119)
		  (?B "cd backing board" 148 116)
		  (?n "cdsingle" 138 123)
		  (?C "cdsingle other way" 123 138)
		  (?q "square" 130 130)
		  (?W "smaller big square" 123 122)
		  (?F "Fabriclive" 130 122)
		  (?Q "bigger square" 134 134)
		  (?m "clam" 124 125)
		  (?M "mego" 140 165)
		  (?e "bookletish" 140 190)
		  (?r "smaller raster-noton" 125 175)
		  (?I "slim" 135 116)
		  (?h "high" 120 170)
		  (?9 "12 inch" 310 310)
		  (?H "high and slimmer" 120 170)
		  (?d "dvd" 132 182)
		  (?w "wolf eyes" 145 180)
		  (?D "deluxe high" 130 230)
		  (?t "tape with box" 72 108)
		  (?T "unboxed tape" 65 104)
		  (?y "tape sleeve" 99 104)
		  (?Y "long tape sleeve" 101 180)
		  (?U "normal tape sleeve" 101 160)
		  (?5 "A4 long tape sleeve" 101 290)
		  (?6 "Triple Cassette" 105 200)
		  (?R "raster-noton" 150 190)
		  (?3 "3 inch" 85 85)
		  (?l "lp" 310 310)
		  (?L "bigger lp" 320 320)
		  (?i "inner lp" 304 304)
		  (?K "smaller LP package" 304 280)
		  (?p "postcard portrait" 103 145)
		  (?p "postcard landscape" 145 103)
		  (?f "7 inch flexi" 150 148)
		  (?7 "7 inch" 180 180)
		  (?8 "7 inch label" 120 120 30 30)
		  (?w "Wide 7 inch" 185 180)
		  (?4 "9 inch" 230 230)
		  (?1 "10 inch" 258 258)
		  (?2 "10 inch label" 130 130 60 60)
		  (?a "label" 140 140 80 80)
		  (?A "a4" 210 297)
		  (?S "a3" 297 420)
		  (?o "book" 150 210)
		  (?O "book inner" 140 200)
		  (?z "end")))
	 (choice (gnus-multiple-choice "Sleeve type" types)))
    (if return-choice
	(assq choice types)
      (cddr (assq choice types)))))

(defvar scan-directory "/stage/scans")

(defun scan-find-device ()
  (let ((bits (split-string (file-truename "/dev/epson") "/")))
    (cons (car (last bits 2))
	  (car (last bits 1)))))

(defun scan-with-name (name)
  "Prompt for an item name (like CAD408), create the directory and scan."
  (interactive "sItem name: ")
  (let ((dir (expand-file-name name scan-directory))
	(device (scan-find-device)))
    (unless (file-exists-p dir)
      (make-directory dir))
    (let ((part 0)
	  (continue t))
      (while continue
	(let ((spec (scan-type t)))
	  (if (not (nth 2 spec))
	      (setq continue nil)
	    (shell-command
	     (format "scanimage --mode=color -d epson:libusb:%s:%s --resolution 300dpi -t %s -l %s -x %s -y %s | pnmflip -topbottom -leftright | pnmtotiff > %s/%s-%d-%c.tiff"
		     (car device)
		     (cdr device)
		     (or (nth 4 spec) 0)
		     (or (nth 5 spec) 0)
		     (nth 2 spec) (nth 3 spec)
		     dir name (incf part)
		     (if (= (nth 0 spec) 13)
			 ?C
		       (nth 0 spec))))))))))

(provide 'scan)

;;; scan.el ends here
