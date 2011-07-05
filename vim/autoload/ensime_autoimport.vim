" quick and dirty implementation
" reads .jar files to find package name
" TODO: also use project tags file

fun! ensime_autoimport#CodefellowScalaShell()
  let cp = ensime_autoimport#CP()
  let cps = cp.jars + cp.classpaths
  call async_porcelaine#ScalaBuffer({'cmd': 'scala -cp '.join(cps,':'),'move_last':1, 'prompt': 'scala> $'})
endf

fun! ensime_autoimport#CP() abort
  let bp = ensime_autoimport#SBTBuildProperties()
  return { 'jars' : ensime_autoimport#AllJars(),
       \   'classpaths' : [ 'target/'.bp['build.scala.versions'].'/classes' ] }
endfun

" TODO  drop codefellow stuff
fun! ensime_autoimport#AllJars() abort
  " yes, this is not 100% correct. Get 80% result with 20% of effort..
  " I should only return jars of .codefellow file associated with current
  " buffer.
  let jars = {}
  let scala_version = ""
  for dotcodefellowfile in split(glob("**/.codefellow"),"\n")
    for l in readfile(dotcodefellowfile)
      for maybejar in split(l,":")
        if maybejar =~ '\.jar$'
          let jars[maybejar] =1
        endif
      endfor
    endfor
  endfor

  " scala library:
  let p = ensime_autoimport#SBTBuildProperties()
  let v = get(p,'build.scala.versions','')
  if v != ''
    let jar = 'project/boot/scala-'.v.'/lib/scala-library.jar'
    if filereadable(jar)
      let jars[jar] = 1
    endif
  endif

  if !exists('g:codefellow_no_java_rt_as_class_source')
    let jars[fnamemodify(system('which java'),':h:h').'/jre/lib/rt.jar'] = 1
  endif
  return keys(jars)
endfun

fun! ensime_autoimport#SBTBuildProperties()
  let r = {}
  let prop = 'project/build.properties'
  if filereadable(prop)
    for l in readfile(prop,'b')
      let m = matchlist(l, '^\([^=]\+\)=\(.\+\)$')
      if len(m) > 2
        let r[m[1]] = m[2]
      endif
    endfor
  endif
  return r
endf

fun! ensime_autoimport#ClassesByRegex(regex) abort

  call scriptmanager#Activate(["vim-addon-mw-utils"])

  let classes = []

  " find in .jar files. Use caching for speed
  for jar in ensime_autoimport#AllJars()
    if complete_check() | return [] | endif
    let r = cached_file_contents#CachedFileContents( jar, s:scan_jar )
    for [k,v] in items(r)
      if k =~ a:regex
        call add(classes, {'class':k, 'packages': v})
      endif
      unlet k v
    endfor
    unlet r
  endfor

  return classes
endf

" returns packages containing class
" ["package|file.jar", ...]
fun! ensime_autoimport#Find_package_of_class(class) abort

  call scriptmanager#Activate(["vim-addon-mw-utils"])

  let packages = []

  " find in .jar files. Use caching for speed
  
  for jar in ensime_autoimport#AllJars()
    let r = cached_file_contents#CachedFileContents( jar, s:scan_jar )
    for x in get(r, a:class, [])
      call add(packages, x.'|'.jar)
    endfor
    unlet r
  endfor

  " TODO: use tags in order to find classes of current project
  return packages

endf

fun! ensime_autoimport#AddImport(class)
  let match = tlib#input#List("s","select package", ensime_autoimport#Find_package_of_class(a:class))
  if match == ''
    echoe a:class.' not found'
    return
  endif
  let match = substitute(match,'|.*','','').'.'.a:class

  " always top level imports..
  if search('^import','cwb') == 0
    " no import found, add above (first line)
    let a = "ggO"
  else
    " one import found, add below
    let a = "o"
  endif
  exec "normal ".a."import ".match.";\<esc>"
endf

fun! ensime_autoimport#AddImportFromQuickfix() abort

  let list = getqflist()

  let did_class = {}

  for item in list

    let class = matchstr(item.text,'not found: \%(type\|value\) \zs[^|]\+\ze')

    if class == "" || has_key(did_class, class)
      continue
    endif

    " open file
    exec 'b '.item.bufnr


    " add import
    call ensime_autoimport#AddImport(class)

    " back to quickfix, select next error
    wincmd p
    silent! cnext

    let did_class[class] = 1
  endfor

endf

let s:scan_jar = {'func': funcref#Function('ensime_autoimport#ClassesFromJar'), 'version' : 3, 'use_file_cache' : 1}
fun! ensime_autoimport#ClassesFromJar(filename) abort
  let result = {}
  " TODO escape
  for l in split(system('jar tf '.a:filename),"\n")
    let r = matchlist(l, '^\(.*\)[$/]\(.*\)\.class')
    if len(r) > 1 && r[2] != ""
      let class = r[2]
      if !has_key(result, class)
        let result[class] = []
      endif
      call add(result[class], substitute(r[1],'[\\/]','.','g'))
    endif
  endfor
  return result
endf
