# cl-project

## Source file headers

### header *file*

Get the header of a pathname string, pathname, or stream.
```Lisp
(header "myfile.lisp")
=> ""
```

The header is defined as contiguous non-empty lines at the beginning of a file.

The header of a pathname string, pathname, or stream is also setf-able.

```Lisp
(setf (header "myfile.lisp") *wtfpl*)
=> "[...]"
```

### update-header *directory*

Update a project's lisp file headers according to its asd file header. Lisp files are found recursively. The first asd file in alphabetical order is the source.

```Lisp
(update-header "~/common-lisp/my-project/")
```
