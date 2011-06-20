#lang scribble/doc
@(require scribble/manual "utils.rkt")

@title[#:tag "decode"]{Decoding Text}

@defmodule[scribble/decode]{The @racketmodname[scribble/decode]
library helps you write document content in a natural way---more like
plain text, except for @litchar["@"] escapes.  Roughly, it processes a
stream of strings to produces instances of the
@racketmodname[scribble/struct] datatypes (see @secref["struct"]).}

At the @tech{flow} level, decoding recognizes a blank line as a
@tech{paragraph} separator. Blocks and paragraphs without blank lines
in between are collected into a @tech{compound paragraph}.

At the @tech{content} level, decoding makes just a few
special text conversions:

@itemize[

 @item{@litchar{---}: converted to @racket['mdash]}

 @item{@litchar{--}: converted to @racket['ndash]}

 @item{@litchar{``}: converted to @racket['ldquo], which is fancy open quotes: ``}

 @item{@litchar{''}: converted to @racket['rdquo], which is fancy closing quotes: ''}

 @item{@litchar{'}: converted to @racket['rsquo], which is a fancy apostrophe: '}

]

Some functions @deftech{decode} a sequence of @racket[_pre-flow] or
@racket[_pre-content] arguments using @racket[decode-flow] or
@racket[decode-content], respectively. For example, the @racket[bold]
function accepts any number of @racket[_pre-content] arguments, so
that in

@verbatim[#:indent 2]|{@bold{``apple''}}|

the @litchar{``apple''} argument is decoded to use fancy quotes, and
then it is bolded.


@defproc[(pre-content? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @deftech{pre-content} value: a
string or other non-list @racket[content], or a @racket[splice]
containing a list of @tech{pre-content} values; otherwise returns
@racket[#f].

Pre-content is decoded into @tech{content} by functions like
@racket[decode-content] and @racket[decode-paragraph].}


@defproc[(pre-flow? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @deftech{pre-flow} value: a
string or other non-list @racket[content], a @racket[block],
@|void-const|, or a @racket[splice] containing a list of
@tech{pre-flow} values; otherwise returns @racket[#f].

Pre-flow is decoded into a @tech{flow} (i.e., a list of @tech{blocks})
by functions like @racket[decode-flow].}


@defproc[(pre-part? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @deftech{pre-part} value: a
string or other non-list @tech{content}, a @tech{block}, a
@racket[part], a @racket[title-decl], a @racket[part-start], a
@racket[part-index-decl], a @racket[part-collect-decl], a
@racket[part-tag-decl], @|void-const|, or a @racket[splice] containing
a list of @tech{pre-part} values; otherwise returns @racket[#f].

A pre-part sequence is decoded into a @racket[part] by functions like
@racket[decode] and @racket[decode-part].}


@defproc[(decode [lst (listof pre-part?)]) part?]{

Decodes a document, producing a part. In @racket[lst], instances of
@racket[splice] are inlined into the list. An instance of
@racket[title-decl] supplies the title for the part, plus tag, style
and version information. Instances of @racket[part-index-decl] (that
precede any sub-part) add index entries that point to the
section. Instances of @racket[part-collect-decl] add elements to the
part that are used only during the @techlink{collect pass}. Instances
of @racket[part-tag-decl] add hyperlink tags to the section
title. Instances of @racket[part-start] at level 0 trigger sub-part
parsing. Instances of @racket[section] trigger are used as-is as
subsections, and instances of @racket[paragraph] and other
flow-element datatypes are used as-is in the enclosing flow.}


@defproc[(decode-part [lst (listof pre-part?)]
                      [tags (listof string?)]
                      [title (or/c #f list?)]
                      [depth exact-nonnegative-integer?])
         part?]{

Like @racket[decode], but given a list of tag string for the part, a
title (if @racket[#f], then a @racket[title-decl] instance is used if
found), and a depth for @racket[part-start]s to trigger sub-part
parsing.

}

@defproc[(decode-flow [lst (listof pre-flow?)]) (listof block?)]{

Decodes a flow. A sequence of two or more newlines separated only by
whitespace counts is parsed as a paragraph separator. In @racket[lst],
instances of @racket[splice] are inlined into the list. Instances of
@racket[paragraph] and other flow-element datatypes are used as-is in
the enclosing flow.

}

@defproc[(decode-compound-paragraph [lst (listof pre-flow?)]) block?]{

Decodes a compound paragraph. If the compound paragraph contains a
single block, the block is returned without a
@racket[compound-paragraph] wrapper.

}

@defproc[(decode-paragraph [lst (listof pre-content?)]) paragraph?]{

Decodes a paragraph.

}

@defproc[(decode-content [lst (listof pre-content?)]) list?]{

Decodes @tech{content}.

}

@defproc[(decode-elements [lst (listof pre-content?)]) list?]{

An alias for @racket[decode-content].
}

@defproc[(decode-string [s string?]) (listof content?)]{

Decodes a single string to produce @tech{content}.

}


@defproc[(whitespace? [s string?]) boolean?]{

Returns @racket[#t] if @racket[s] contains only whitespace, @racket[#f]
otherwise.

}

@defstruct[title-decl ([tag-prefix (or/c #f string?)]
                       [tags (listof string?)]
                       [version (or/c string? #f)]
                       [style any/c]
                       [content content?])]{

See @racket[decode] and @racket[decode-part]. The @racket[_tag-prefix]
and @racket[_style] fields are propagated to the resulting
@racket[part].

}

@defstruct[part-start ([depth integer?]
                       [tag-prefix (or/c #f string?)]
                       [tags (listof string?)]
                       [style any/c]
                       [title content?])]{

Like @racket[title-decl], but for a sub-part.  See @racket[decode] and
@racket[decode-part].

}

@defstruct[part-index-decl ([plain-seq (listof string?)]
                            [entry-seq list?])]{

See @racket[decode]. The two fields are as for @racket[index-element].

}

@defstruct[part-collect-decl ([element element?])]{

See @racket[decode].

}

@defstruct[part-tag-decl ([tag tag?])]{

See @racket[decode].

}

@defstruct[splice ([run list?])]{

See @racket[decode], @racket[decode-part], and @racket[decode-flow].

}

@defproc[(clean-up-index-string [str string?]) string?]{

Trims leading and trailing whitespace, and converts non-empty
sequences of whitespace to a single space character.}

