Sugar.RichTextArea = (textArea, options) ->
  @textArea = textArea
  settings = jQuery.extend(
    className: "richTextToolbar"
  , options)

  @toolbar =
    settings: settings
    textArea: textArea
    listElement: false
    buttons: []
    addButton: (name, callback, options) ->
      settings = jQuery.extend(
        className: name.replace(/[\s]+/, "") + "Button"
      , options)
      li = document.createElement("li")
      a = document.createElement("a")
      a.title = name
      a.textArea = @textArea
      jQuery(a).click callback
      jQuery(a).addClass settings.className
      jQuery(li).append(a).appendTo @listElement
      @buttons.push li
      this

    create: ->
      unless @listElement
        @listElement = document.createElement("ul")
        jQuery(@listElement).addClass @settings.className
        jQuery(@listElement).insertBefore @textArea

  @textArea.selectedText = ->
    jQuery(this).getSelection().text

  @textArea.replaceSelection = (replacement) ->
    jQuery(this).replaceSelection replacement

  @textArea.wrapSelection = ->
    prepend = arguments[0]
    append = (if (arguments.length > 1) then arguments[1] else prepend)
    @replaceSelection prepend + @selectedText() + append

  @textArea.toolbar = @toolbar
  @toolbar.create()
  this


$(Sugar).bind 'ready modified', ->

  $('textarea.rich').each ->

    unless this.toolbar
      ta = new Sugar.RichTextArea(this)

      # Setup the buttons
      ta.toolbar

        # Bold
        .addButton "Bold", ->
          this.textArea.wrapSelection('<strong>', '</strong>')

        # Italic
        .addButton "Italics", ->
          this.textArea.wrapSelection('<em>', '</em>')

        # Link
        .addButton "Link", ->
          selection = this.textArea.selectedText()
          response = prompt('Enter link URL', '')
          this.textArea.replaceSelection(
            '<a href="' + (response || 'http://link_url/').replace(/^(?!(f|ht)tps?:\/\/)/, 'http://') + '">' +
            (selection || "Link text") + '</a>'
          )

        # Image tag
        .addButton "Image", ->
          selection = this.textArea.selectedText()
          if selection == ''
            response = prompt('Enter image URL', '')
            unless response
              return
            this.textArea.replaceSelection('<img src="' + response + '" alt="" />')
          else
            this.textArea.replaceSelection('<img src="' + selection + '" alt="" />')

        # MP3 Player
        .addButton "MP3", ->
          selection = this.textArea.selectedText()
          response = prompt('Enter MP3 URL', '')
          unless selection
            selection = prompt('Enter track title', '')
          this.textArea.replaceSelection(
            '<a href="' + (response || 'http://link_url/').replace(/^(?!(f|ht)tps?:\/\/)/, 'http://') + '" class="mp3player">' +
            (selection || "Link text") + '</a>')

        # Block Quote
        .addButton "Block Quote", ->
          this.textArea.wrapSelection('<blockquote>', '</blockquote>')

        # Escape HTML
        .addButton "Escape HTML", ->
          selection = this.textArea.selectedText()
          response = prompt('Enter language (leave blank for no syntax highlighting)', '')
          if response
            this.textArea.replaceSelection('<code language="' + response + '">' + selection + '</code>')
          else
            this.textArea.replaceSelection('<code>' + selection + '</code>')

        # Spoiler
        .addButton "Spoiler", ->
          this.textArea.wrapSelection('<div class="spoiler">', '</div>')
