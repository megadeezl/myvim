" MIT License. Copyright (c) 2013-2014 Bailey Ling.
" vim: et ts=2 sts=2 sw=2

let s:prototype = {}

function! s:prototype.split(...)
  call add(self._sections, ['|', a:0 ? a:1 : '%='])
endfunction

function! s:prototype.add_section_spaced(group, contents)
  call self.add_section(a:group, (g:airline_symbols.space).a:contents.(g:airline_symbols.space))
endfunction

function! s:prototype.add_section(group, contents)
  call add(self._sections, [a:group, a:contents])
endfunction

function! s:prototype.add_raw(text)
  call add(self._sections, ['', a:text])
endfunction

function! s:prototype.build()
  let side = 1
  let prev_group = ''
  let line = ''
  let i = 0
  let length = len(self._sections)

  while i < length
    let section = self._sections[i]
    let group = section[0]
    let contents = section[1]

    if group == ''
      let line .= contents
    elseif group == '|'
      let side = 0
      let line .= contents
      let prev_group = ''
    else
      if i == 0
        let line .= '%#'.group.'#'
      endif

      if prev_group != '' && group != ''
        let line .= s:get_seperator(self, prev_group, group, side)
      endif

      let line .= s:get_accented_line(self, group, contents)
      let prev_group = group
    endif

    let i = i + 1
  endwhile

  if !self._context.active
    let line = substitute(line, '%#.\{-}\ze#', '\0_inactive', 'g')
  endif
  return line
endfunction

function! s:get_seperator(self, prev_group, group, side)
  let line = ''
  if airline#highlighter#is_same_bg(a:prev_group, a:group)
    let line .= a:side ? a:self._context.left_alt_sep : a:self._context.right_alt_sep
  else
    call airline#highlighter#add_separator(a:prev_group, a:group, a:side)
    let line .= '%#'.a:prev_group.'_to_'.a:group.'#'
    let line .= a:side ? a:self._context.left_sep : a:self._context.right_sep
    let line .= '%#'.a:group.'#'
  endif
  return line
endfunction

function! s:get_accented_line(self, group, contents)
  if a:self._context.active
    let contents = []
    let content_parts = split(a:contents, '__accent')
    for cpart in content_parts
      let accent = matchstr(cpart, '_\zs[^#]*\ze')
      call add(contents, cpart)
    endfor
    let line = join(contents, a:group)
    let line = substitute(line, '__restore__', a:group, 'g')
  else
    let line = substitute(a:contents, '%#__accent[^#]*#', '', 'g')
    let line = substitute(line, '%#__restore__#', '', 'g')
  endif
  return line
endfunction

function! airline#builder#new(context)
  let builder = copy(s:prototype)
  let builder._context = a:context
  let builder._sections = []

  call extend(builder._context, {
        \ 'left_sep': g:airline_left_sep,
        \ 'left_alt_sep': g:airline_left_alt_sep,
        \ 'right_sep': g:airline_right_sep,
        \ 'right_alt_sep': g:airline_right_alt_sep,
        \ }, 'keep')
  return builder
endfunction

