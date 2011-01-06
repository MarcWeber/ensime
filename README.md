# ENSIME
the ENhanced Scala Interaction Mode for Emacs


## Features

- Highlight errors and warnings in your code buffers.
- Inspect the type of any expression.
- Browse packages
- Completion-on-demand for variables, methods, constructors, etc.
- Jump to symbol definitions.
- Automated Refactorings (rename, organize imports, extract method...)
- Source Formatting
- Finds sbt,Maven,Ivy dependencies
- Scala REPL
- Scala Debugger
- Embedded sbt shell


Check out this (rather old)[video](http://www.youtube.com/watch?v=A2Lai8IjLoY) or this [one](http://www.youtube.com/watch?v=v7-G6vD42z8) showcasing debugger support


## System Requirements

- Emacs 22 or later.
- Unix-like OS or Windows. Note that you'll need to use bin/server.bat on windows.
- Java Runtime
- Scala 2.8 compatible source and libraries. ENSIME is built against the 2.8 nightly Scala releases. 


## Documentation
- [The ENSIME User Manual](http://aemon.com/file_dump/ensime_manual.html)


## Quick Start

__1) Install scala-mode__

ENSIME is designed to compliment scala-mode (or any other scala language mode). scala-mode can be found in the Scala distribution under ./misc/scala-tool-support/emacs/. The rest of the steps assume your scala-mode is installed and working correctly.

__2) Install ensime-mode__

Download the ENSIME distribution from the github [downloads page](http://github.com/aemoncannon/ensime/downloads). Unpack the ENSIME distribution into a directory of your choosing. 

Add the following lines to your .emacs file:

    ;; Load the ensime lisp code...
    (add-to-list 'load-path "ENSIME_ROOT/elisp/")
    (require 'ensime)

    ;; This step causes the ensime-mode to be started whenever
    ;; scala-mode is started for a buffer. You may have to customize this step
    ;; if you're not using the standard scala mode.
    (add-hook 'scala-mode-hook 'ensime-scala-mode-hook)

    ;; MINI HOWTO: 
    ;; Open .scala file. M-x ensime (once per project)


__3) Verify Permissions__

Verify that the startup script (usually bin/server.sh) has executable permissions.


__4) Create Project__

In Emacs, execute M-x ensime-config-gen. Follow directions in the mini-buffer to create a .ensime file for your project.. 


__5) Start ENSIME__

Execute M-x ensime
You only need to do this once per project.

## Vim Notes

  Not everything has been tested and implemented yet. However the most
  important features are working.
  Installation: See bottom

  maintainers of this Vim related code:
    casualjim (github) (started porting the .scala code)
    MarcWeber (github) (rest)

  this works:

    commands:
      :Ensime                - start the server
      :EnsimeConnectionInfo  - should print some info
      :EnsimeRepl            - read eval print loop (See documentation of vim-addon-async)
      :EnsimeReformatSources - reformat source file and reload it into Vim (vim 7.3 can undo reloading so no care has to be taken)
      :EnsimeDefinition       - goto definition (only if its found in source file for now)
      :EnsimeShowTypeAtCursor - show type under cursor in preview window
      :EnsimeTypecheckAll     - typecheck all (smart sorting: show the errors of the current buffer you're in first)
 
    completion:
      (scope, type (member), constructor) completion
    
    - typechecking the files on bufwrite (is this annoying?)


    TODO:
    - templates for .ensime files
    - ...

## Vim: Howto create the .enime project file?
  Either use Emacs :-( or open it and use the provided snipmate snippet in
  vim/snippets/dot_ensime_config.snippets (quick & dirty solution which worked for me)
  I also partially implemented a different parsing function which should enable
  you writing a json based configuration file (totally untested - so expect
  that you have write a small patch to make it work)

## Vim installation

  Vim plugin dependencies:

    vim-addon-async
    vim-addon-completion
    vim-addon-json-encoding

  I recommend using vim-addon-manager to install ensime and its dependencies.
  (Follow its documentation - or contact Marc Weber if you have any issues).

  You can find the source locations here if you want to install them manually:
  http://github.com/MarcWeber/vim-addon-manager-known-repositories/raw/master/plugin/vim-addon-manager-known-repositories.vim
  Many thanks to the main author Aemon Cannon who always assisted this process.

  Additionally you have to run sbt dist (in the ensime directory) and compile
  the .c app in C/ in vim-addon-async.

## VIM TODO
  the inspection view is poor. You can only follow types by :EnsimeInspectTypeById nr
  you can't debug yet (dito)
  ... Probably there is much more I've been missing

## VIM BRANCH status

Vim uses its own branch for now.
We both (Marc Weber, Aemon Cannon) want a merge. Its my lack of time preventing it at
the moment. It should be explored whether it was necessary / a good idea to
drop the toWF and the wireframe class. I don't use Scala that much - so it
looks to be the less time consuming choice to just update this branch
occasionally (?)
Ping me to make it more likely to work on the merge.
