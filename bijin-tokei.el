;; (require 'posframe)
;; (require 'request)

(defconst custom/bijin-tokei-buffer " *custom/bijin-tokei-buffer*")
(defconst custom/bijin-tokei-holiday '(
	"aomori"
	"chiba"
	"fukushima"
	"kagawa"
	"kagoshima"
	"kanazawa"
	"nagoya"
	"nara"
	"okayama"
	"okinawa"
	"saitama"
	"sendai"
	"shizuoka"
))
(defconst custom/bijin-tokei-url "http://www.bijint.com/assets/pict/%s/pc/%s")
(defconst custom/bijin-tokei-weekday "jp")
(defvar custom/bijin-tokei-active nil)
(defvar custom/bijin-tokei-frame-active nil)
(defvar custom/bijin-tokei-frame-height (lambda () 450))
(defvar custom/bijin-tokei-frame-width (lambda () 590))
(defvar custom/bijin-tokei-poshandler 'posframe-poshandler-frame-bottom-right-corner)
(defvar custom/bijin-tokei-timer nil)
(defvar custom/bijin-tokei-timer-loop nil)
(defun custom/bijin-load ()
	(when (posframe-workable-p)
		(if custom/bijin-tokei-frame-active
			(posframe-refresh custom/bijin-tokei-buffer)
			(posframe-show custom/bijin-tokei-buffer
				:background-color "white"
				:keep-ratio t
				:poshandler custom/bijin-tokei-poshandler
			)
		)
	)
)
(defun custom/bijin-path ()
	(let*
		(
			(week (format-time-string "%w"))
			(infix (if (or (eq week "0") (eq week "6")) (nth (random (length custom/bijin-tokei-holiday)) custom/bijin-tokei-holiday) custom/bijin-tokei-weekday))
			(suffix (format-time-string "%H%M.jpg" (current-time)))
		)
		(format custom/bijin-tokei-url infix suffix)
	)
)
(defun custom/bijin-tokei-start ()
	(interactive)
	(get-buffer-create custom/bijin-tokei-buffer)
	(custom/bijin-tokei-update (custom/bijin-path))
	(setq custom/bijin-tokei-timer (run-at-time (format-time-string "%H:%M" (time-add (current-time) 60)) nil (lambda ()
		(setq custom/bijin-tokei-timer-loop (run-with-timer nil 60 (lambda ()
			(custom/bijin-tokei-update (custom/bijin-path))
		)))
	)))
	(setq custom/bijin-tokei-active t)
)
(defun custom/bijin-tokei-stop ()
	(interactive)
	(when custom/bijin-tokei-timer (cancel-timer custom/bijin-tokei-timer))
	(when custom/bijin-tokei-timer-loop (cancel-timer custom/bijin-tokei-timer-loop))
	(when (posframe-workable-p) (posframe-delete custom/bijin-tokei-buffer))
	(setq custom/bijin-tokei-frame-active nil)
	(setq custom/bijin-tokei-active nil)
)
(defun custom/bijin-tokei-toggle ()
	(interactive)
	(if custom/bijin-tokei-active
		(custom/bijin-tokei-stop)
		(custom/bijin-tokei-start)
	)
)
(defun custom/bijin-tokei-update (url)
	(request url
		:type
			"GET"
		:parser
			'buffer-string
		:success
			(cl-function (lambda (&key data &allow-other-keys) (when data
				(with-current-buffer (get-buffer custom/bijin-tokei-buffer)
					(erase-buffer)
					(insert-image (create-image
						(encode-coding-string data 'utf-8) 'jpeg t
						:height (funcall custom/bijin-tokei-frame-height)
						:pointer 'arrow
						:width (funcall custom/bijin-tokei-frame-width)
					))
				)
				(custom/bijin-load)
				(setq custom/bijin-tokei-frame-active t)
			)))
		:error
			(cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
				(message "Error: %S" error-thrown)
			))
	)
)
;;TODO: Resize event.
;; (add-to-list 'window-size-change-functions (lambda (frame)
;; 	(posframe-refresh custom/bijin-tokei-buffer)
;; ))

(provide 'bijin-tokei)
