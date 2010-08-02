;;; ensime-config.el
;;
;;;; License
;;
;;     Copyright (C) 2010 Aemon Cannon
;;
;;     This program is free software; you can redistribute it and/or
;;     modify it under the terms of the GNU General Public License as
;;     published by the Free Software Foundation; either version 2 of
;;     the License, or (at your option) any later version.
;;
;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;     GNU General Public License for more details.
;;
;;     You should have received a copy of the GNU General Public
;;     License along with this program; if not, write to the Free
;;     Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;;     MA 02111-1307, USA.



(defvar ensime-config-file-name ".ensime"
  "The default file name for ensime project configurations.")

(add-to-list 'auto-mode-alist '("\\.ensime$" . emacs-lisp-mode))

(defun ensime-config-gen ()
  "Interactively generate a new .ensime configuration file."
  (interactive)
  (catch 'done
    (let* ((root (ido-read-directory-name "Find project root: "))
	   (conf-file (concat root "/" ensime-config-file-name)))

      ;; Check if config already exists for this project...
      (if (file-exists-p conf-file)
	  (if (yes-or-no-p (format (concat "Found an existing "
					   "%s file for this project. " 
					   "Back up existing file and "
					   "continue?") ensime-config-file-name))
	      (rename-file conf-file (concat conf-file ".bak") t)
	    (throw 'done nil)))

      ;; Try to infer the project type...
      (let ((guessed-proj-type (ensime-config-guess-type root)))
	(if (yes-or-no-p 
	     (format (concat "Your project seems "
			     "to be of type '%s', "
			     "continue with this "
			     "assumption?") guessed-proj-type))
	    (ensime-config-build root guessed-proj-type)
	  (let ((proj-type (ido-completing-read 
			    "What type of project is this? " 
			    '("custom" "custom-with-ivy" "maven" "sbt"))))
	    (ensime-config-build root (make-symbol proj-type))))))))


(defun ensime-config-find-ensime-root (root)
  (ido-read-directory-name 
   "Where did you unpack the ENSIME distribution?: " root))

(defun ensime-config-read-proj-package ()
  (read-string 
   "What is the name of your projects main package? e.g. com.myproject: "
   ))


(defun ensime-config-read-source-dirs (root)
  `(,(ido-read-directory-name 
      "Where is the project's source located? " root)))


(defun ensime-config-read-dependency-jar-dirs (root)
  `(,(ido-read-directory-name 
      "Where are the project's dependency jars located? " root)))


(defun ensime-config-read-target-dir (root)
  (ido-read-directory-name 
   "Where are classes written by the compiler? " root))

(defmacro ensime-set-key (conf key val)
  `(setq ,conf (plist-put ,conf ,key ,val)))


(defun ensime-config-build-maven (root)
  (let ((conf '()))

    (ensime-set-key conf :server-root 
		    (ensime-config-find-ensime-root root))

    (ensime-set-key conf :project-package
		    (ensime-config-read-proj-package))

    (ensime-set-key conf :use-maven t)

    conf
    ))

(defun ensime-config-build-custom-with-ivy (root)
  (let ((conf '()))

    (ensime-set-key conf :server-root 
		    (ensime-config-find-ensime-root root))

    (ensime-set-key conf :project-package
		    (ensime-config-read-proj-package))

    (ensime-set-key conf :use-ivy t)

    (when (yes-or-no-p 
	   "Does your project use custom ivy configurations? ")
      (ensime-set-key conf :ivy-compile-conf
		      (read-string 
		       "What config should be used to compile? (space separated): " "compile"))
      (ensime-set-key conf :ivy-runtime-conf
		      (read-string 
		       "What config should be used at runtime? (space separated): " "runtime")))

    (ensime-set-key conf :sources
		    (ensime-config-read-source-dirs root))

    (ensime-set-key conf :dependency-jars
		    (ensime-config-read-dependency-jar-dirs root))

    (ensime-set-key conf :target
		    (ensime-config-read-target-dir root))

    conf
    ))

(defun ensime-config-build-sbt (root)
  (let ((conf '()))

    (ensime-set-key conf :server-root 
		    (ensime-config-find-ensime-root root))

    (ensime-set-key conf :project-package
		    (ensime-config-read-proj-package))

    (ensime-set-key conf :use-sbt t)

    (when (yes-or-no-p 
	   "Does your project use custom ivy configurations? ")
      (ensime-set-key conf :sbt-compile-conf
		      (read-string 
		       "What config should be used to compile? (space separated): " "compile"))
      (ensime-set-key conf :sbt-runtime-conf
		      (read-string 
		       "What config should be used at runtime? (space separated): " "runtime")))


    conf
    ))

(defun ensime-config-build-custom (root)
  (let ((conf '()))

    (ensime-set-key conf :server-root 
		    (ensime-config-find-ensime-root root))

    (ensime-set-key conf :project-package
		    (ensime-config-read-proj-package))

    (ensime-set-key conf :sources
		    (ensime-config-read-source-dirs root))

    (ensime-set-key conf :dependency-jars
		    (ensime-config-read-dependency-jar-dirs root))

    (ensime-set-key conf :target
		    (ensime-config-read-target-dir root))

    conf
    ))

(defun ensime-config-build (root proj-type)
  (let* ((builder-func (intern-soft 
			(concat 
			 "ensime-config-build-" 
			 (symbol-name proj-type))))
	 (conf (funcall builder-func root))
	 (conf-file (concat root "/" ensime-config-file-name)))
    (with-temp-file conf-file
      (insert (format "%S" conf)))
    (message (concat "Your project config "
		     "has been written to %s, "
		     "run M-x ensime in a source "
		     "buffer to launch ENSIME.") conf-file)
    ))

(defun ensime-config-guess-type (root)
  "Return a best guess of what type of project is located at root."
  (cond ((ensime-config-is-sbt-test root) 'sbt)
	((ensime-config-is-maven-test root) 'maven)
	((ensime-config-is-ivy-test root) 'custom-with-ivy)
	(t 'custom)))

(defun ensime-config-is-maven-test (root)
  (file-exists-p (concat root "/pom.xml")))

(defun ensime-config-is-ivy-test (root)
  (file-exists-p (concat root "/ivy.xml")))

(defun ensime-config-is-sbt-test (root)
  (and 
   (file-exists-p (concat root "/project/build.properties" ))
   (file-exists-p (concat root "/src/main/" ))))


(defun ensime-config-find-file (file-name)
  "Search up the directory tree starting at file-name 
   for a suitable config file to load, return it's path. Return nil if 
   no such file found."
  (let* ((dir (if file-name (file-name-directory file-name) default-directory))
	 (possible-path (concat dir ensime-config-file-name)))
    (if (file-directory-p dir)
	(if (file-exists-p possible-path)
	    possible-path
	  (if (not (equal dir (directory-file-name dir)))
	      (ensime-config-find-file (directory-file-name dir)))))))

(defun ensime-config-find-and-load ()
  "Query the user for the path to a config file, then load it."
  (let* ((default (ensime-config-find-file buffer-file-name))
	 (file (if ensime-prefer-noninteractive default
		 (read-file-name 
		  "ENSIME Project file: "
		  (if default (file-name-directory default))
		  default
		  nil
		  (if default (file-name-nondirectory default))
		  ))))
    (ensime-config-load file)))


(defun ensime-config-load (file-name)
  "Load and parse a project config file. Return the resulting plist.
   The :root-dir setting will be deduced from the location of the project file."
  (let ((dir (expand-file-name (file-name-directory file-name))))
    (save-excursion
      (let ((config
	     (let ((buf (find-file-read-only file-name ensime-config-file-name))
		   (src (buffer-substring-no-properties
			 (point-min) (point-max))))
	       (kill-buffer buf)
	       (condition-case error
		   (read src)
		 (error
		  (error "Error reading configuration file, %s: %s" src error)
		  ))
	       )))

	;; We use the project file's location as the project root.
	(ensime-set-key config :root-dir dir)
	config)
      )))




(provide 'ensime-config)