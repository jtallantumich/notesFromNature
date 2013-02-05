Spine   = require 'spine'

Archive = require 'models/Archive'
Classification = require 'models/Classification'
Subject = require 'models/Subject'

class SernacTranscriptionController extends Spine.Controller
  className: "SernacTranscriptionController"

  constructor: ->
    super 
    Spine.bind("finishedSernacTranscription", @saveClassification)

  render: =>
    @html require('views/transcription/sernac')
      subject: @currentSubject

  startWorkflow: (subject) =>
    @currentSubject = subject
    @render()
    @delay @go, 500

  go: =>
    archive = Archive.find(@currentSubject.archive_id)

    window.GOD = new nfn.ui.view.GOD({
      model: new nfn.ui.model.GOD()
    })

    transcriberModel = new nfn.ui.model.Herbarium()
    @transcriber = new nfn.ui.view.HerbariumTranscriber({
      model: transcriberModel
    })

    $(".btn.close").attr("href", "#/archives/#{archive.slug()}")
    
    @nextSubject()
    window.transcriber = @transcriber

  saveClassification: (data) =>
    classification = Classification.create({subject_id: @currentSubject.id, workflow_id: @currentSubject.workflow_ids[0] } )
    for annotation in data.toJSON()
      classification.annotate annotation.step, annotation.value

    classification.save()
    @currentSubject.retire()
    classification.send()
    @nextSubject()

  nextSubject: =>
    callback = => 
      $(".photos img").animate({ marginLeft: "0" }, 500)
      @transcriber.spinner.hide()
      @transcriber.startTranscribing()

    @currentSubject = Subject.random()

    @transcriber.loadPhoto(@currentSubject.location.standard, callback)
    @transcriber.loadLargePhoto(@currentSubject.location.large)



module.exports = SernacTranscriptionController
