(cond ((string= "ryzennova" (system-name))
       (setq doom-font (font-spec :family "DejaVuSansM Nerd Font" :size 14)
             doom-variable-pitch-font (font-spec :family "Hack Nerd Font" :size 14)
             doom-big-font (font-spec :family "DejaVuSansM Nerd Font" :size 16)
             org-mode-font "DejaVuSansM Nerd Font"))
      ((string= "yoganova" (system-name))
       (setq doom-font (font-spec :family "DejaVuSansM Nerd Font" :size 16)
             doom-variable-pitch-font (font-spec :family "Hack Nerd Font" :size 16)
             doom-big-font (font-spec :family "DejaVuSansM Nerd Font" :size 24)
             org-mode-font "DejaVuSansM Nerd Font")))
