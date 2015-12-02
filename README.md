
lyx2docbook
===========

A very simple LyX to Docbook-XML converter. Will probably not fully convert
your document automatically, but it may serve as a start!

How to run
----------

```
chmod +x ./lyx2docbook
./lyx2docbook my_lyx_document.lyx
```

If all works, the last line of output will display:

```
my_lyx_document.xml written.
```

And yes, this will generate `my_lyx_document.xml`.

If the script finds any construct it does not recognize (or knowingly
ignore), it will abort. You can then tweak the document or the script
to make it progress. The script is a bit ugly but it's meant to be 
understandable.

Limitations
-----------

* Only supports the latest version of the LyX format
* Only supports a subset of the Layouts from the extarticle (default) class
* Outputs invalid "FIXME" tags when using cross-references
* Many others, I'm sure

I do not intend to write a complete converter myself; the current version is 
already functional enough for the documents I had to convert. But Pull Requests
fixing any of the tool's limitations are definitely welcome!

Contact
-------

* http://github.com/hishamhm/lyx2docbook
* http://hisham.hm/
* @hisham_hm

Enjoy!!
