Api = require 'zooniverse/lib/api'
User  = require 'zooniverse/lib/models/user'

InterfaceController = require 'controllers/InterfaceController'
Classification = require 'models/Classification'
Subject = require 'models/Subject'

data = require 'lib/ocr-data'

PROJECT_ID = '5008739e516bcbd236000001' # Cheating

class BirdsTranscriptionController extends InterfaceController
  canCreateBox: true
  className: 'birds-interface'
  elements:
    '.boxes': 'boxes'
    '#data-entry': 'widget'
    '#entry': 'entry'
    '#tool-actions': 'actions'
    '#tools-list': 'toolsList'
    '#selected-tool': 'selectedTool'
  events:
    'mousedown .box': 'onClickBox'
    'mousedown .boxes': 'onClickImage'
    'click #finish': 'onFinish'
    'click #done': 'onDoneBox'
    'click #autoMove': 'toggleAutoMove'
    'click #tools-list li': 'onSelectTool'
    'click #power': 'exit'
  dataTemplate: require 'views/transcription/interfaces/birds/data'
  template: require 'views/transcription/interfaces/birds/main'
  tools:
    'cursor': require 'lib/tools/Cursor'
    'multi-select': require 'lib/tools/MultiSelect'

  constructor: ->
    super
    # Load previous interface preferences
    if User.current? and User.current.preferences[PROJECT_ID]
      for key, value of User.current.preferences[PROJECT_ID]
        if value in ['true', 'false']
          @preferences[key] = (value is 'true')
        else
          @preferences[key] = value

    $(document).on 'keypress', @onKeyPress

  startWorkflow: (@archive) =>
    @render({archive: @archive, preferences: @preferences})
    # @widget.draggable()
    @selectTool 'cursor'
    @nextSubject()



  # Events
  onClickBox: (e) =>
    e.preventDefault()
    e.stopPropagation()
    @tool.clickBox $(e.currentTarget)

  onClickImage: (e) =>
    e.preventDefault()
    e.stopPropagation()
    @tool.clickImage e

  onDoneBox: (e) =>
    e.preventDefault()
    @currentBox.data 'value', @entry.find('#field').val()
    @tool.nextBox()

  onKeyPress: (e) =>
    if e.ctrlKey
      switch e.keyCode
        when 49
          @selectTool 'cursor'
        when 50
          @selectTool 'multi-select'

    if e.altKey then @tool.shortcut e.keyCode

  onFinish: (e) =>
    @finish()

  onSelectTool: (e) =>
    @selectTool $(e.currentTarget).attr 'id'


  # Settings
  toggleAutoMove: (e) =>
    @preferences.auto_move = e.target.checked
    obj =
      key: 'auto_move'
      value: @preferences.auto_move
    Api.put "/projects/notes_from_nature/users/preferences", obj


  # "API"
  finish: =>
    data = []
    $('.box').each (i) ->
      obj = {}
      obj =
        top: $(@).position().top
        left: $(@).position().left
        width: $(@).width()
        height: $(@).height()
        value: $(@).data('value')
      data.push obj

    console.log 'test data', data
    # classification = Classification.create({subject_id: testSubject.id, workflow_id: testSubject.workflow_ids[0] } )
    
    # testSubject.retire()
    # classification.send()
    # @nextSubject()
    
  nextSubject: =>
    @counter = 1
    lastMid = 0

    for datum, i in data
        box = datum.split(',')
        y = parseInt(box[1])
        x = parseInt(box[0])
        width = parseInt(box[2] - box[0])
        height = parseInt(box[3] - box[1])
        mid = y + (height / 2)

        style = "top: #{box[1]}px; left: #{box[0]}px; width: #{width}px; height: #{height}px"

        unless width > 600 or height > 100 or box[0] is "0" or box[1] < 50 or width < 3 or height < 3
          @boxes.append('<div data-id='+@counter+' class="box" style="' + style + '"></div>')
          @counter += 1
          lastMid = mid

    @$('.box').resizable({
      handles: 'all'
      disabled: true
    })

  selectTool: (tool) =>
    # Reset selected boxes for new tool. 
    $('.box').removeClass 'selected'

    # Cleanup old tool.
    if @tool then @tool.clean()
    @toolsList.find('li').removeClass 'selected'

    @toolsList.find("##{tool}").addClass 'selected'
    @selectedTool.html tool.charAt(0).toUpperCase() + tool.slice(1, tool.length)
    @tool = new @tools[tool]({interface: @})

  startDataEntry: (@currentBox) =>
    id = @currentBox.data('id')
    value = @currentBox.data('value') || ''

    @entry.children('div').removeClass('disabled')

    field = @entry.find('#field')
    field.prop('disabled', false)
    field.val(value).focus()


  # Generic UI
  exit: =>
    Spine.Route.navigate window.location.hash.split('/').slice(0,3).join('/')

module.exports = BirdsTranscriptionController