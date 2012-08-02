Spine = require('spine')
Subject= require('models/Subject')
Archive= require('models/Archive')
EOL = require('models/EOL')

SernacTranscriptionController = require('controllers/SernacTranscriptionController')
DoubleTranscriptionController = require('controllers/DoubleTranscriptionController')

class TranscriptionController extends Spine.Controller
  className: "TranscriptionController"

  transcriptionControllers: 
    'double' : new DoubleTranscriptionController()
    'sernac' : new SernacTranscriptionController()

  constructor:->
    super
    $("body").bind "doneClassification", (data)=>
      @saveAnnotation data.values

    $("body.transcribingScreen .wrapper .right .button").on 'click', =>
      alert("HERE")

    Spine.bind("nextSubject", @nextSubject)

  saveAnnotation:(values)=>
    @annotations||=[]
    @annotations.push values

  saveTranscription:(data)=>
    zooApi.saveClassification
      project : "notes_from_nature"
      subjects: [@currnetSubject.id]
      workflow: @currnetSubject.workflow_ids[0]
      annotations: @annotations
    ,(result)=>
      console.log "save result"

  render:=>
    if @currnetSubject
      transcriptionType = @currnetSubject.metadata.workflow_type
      @transcriptionControllers[transcriptionType].startWorkflow(@currnetSubject)
      @html @transcriptionControllers[transcriptionType].el
      $("body").addClass(transcriptionType)
      $("body").addClass("transcribingScreen")
    else 
      @html require('views/transcription/outOfSubjects')

  nextSubject:=>
    
    if @currnetSubject?
      console.log @currnetSubject      
      archive = Archive.find(@currnetSubject.archive_id)
      @archive.nextSubject (subject)=>
        $("div.transcribing.sernac img").attr("src", subject.location.standard)
          


  active:(params)=>
    super
    
    if Archive.count() ==0 
      Archive.bind 'refresh', =>
        @active params
    if params.id
      @currnetSubject = Subject.find(params.id)
      @render()
    else if params.archiveID
      @archive = Archive.findBySlug(params.archiveID)
      if @archive
        @archive.nextSubject (subject)=>
          @currnetSubject=subject
          @render()

    else if !@currnetSubject?
      @currnetSubject = Subject.random()
      @render()

  
    
module.exports = TranscriptionController