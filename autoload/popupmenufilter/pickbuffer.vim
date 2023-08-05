vim9script

import autoload 'popupmenufilter.vim'

const path_separator = has('win64') ? '\' : '/'

def SortLastUsed(a: dict<any>, b: dict<any>): number
  return b.lastused - a.lastused
enddef

def FormatMenuItem(file_path: string, max_width: number): string
  var depth: number = len(split(file_path, path_separator))
  var top_folder: string = fnamemodify(file_path, repeat(':h', depth - 2))
  var bottom_folder: string = fnamemodify(file_path, ':h:t')
  var filename: string = fnamemodify(file_path, ':t')
  var formatted_path: string = $"{filename} {fnamemodify(file_path, ":p:.:h")}"

  # If everything fits, return formatted value
  if strlen(formatted_path) < max_width
    return formatted_path
  endif

  var i: number = depth
  var temp: string = ''

  # Loop bottom up
  while i >= 3
    var current_folder: string = fnamemodify(file_path, ':h' .. repeat(':h', depth - i) .. ':t')
    var test_path = $"{filename} {top_folder}{path_separator}{current_folder}{temp}"
    if strlen(test_path) <= max_width
      temp = $"{path_separator}{current_folder}{temp}"
    else
      return $"{filename} {top_folder}{path_separator}...{temp}"
    endif
    i -= 1
  endwhile

  return $"{filename} {temp}"
enddef

export def PickBuffer()
  var filter_cmd: string = 'v:val.name != ""'
  var buf_list: list<dict<any>> = filter(getbufinfo({ buflisted: true }), filter_cmd)
  sort(buf_list, 'SortLastUsed')
  var buffers = mapnew(buf_list, (_, v) => fnamemodify(v.name, ':p:.'))

  if len(buffers) <= 1
    return
  endif

  var options: dict<any> = {
    title: 'Buffers',
    wrap: 0,
    pos: 'center',
    maxwidth: &columns - 10,
    maxheight: &lines - 10,
    mapping: 1,
    fixed: 1,
    cb: (id: number, result: number) => {
      if result < 0
        return
      endif

      var buf = buffers[result - 1]
      var bnr = bufwinnr(buf)
      if bnr >= 0
        execute $":{bnr} wincmd w"
      else
        execute $"b {buf}"
      endif
      },
  }

  var formatted_buffers = mapnew(buffers, (_, v) => FormatMenuItem(v, &columns - 14))
  popupmenufilter.PopupMenuFilter(formatted_buffers, options)
enddef

