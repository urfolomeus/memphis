describe "CreateScrapbookController", ->
  beforeEach ->
    loadFixtures('create_scrapbook.html')

    @successSpy = jasmine.createSpy('successSpy')

    @createScrapbookController = new CreateScrapbookController(@successSpy)

  afterEach ->
    $('body').removeClass('modal-open').find('.modal-backdrop').remove()


  describe "showing the Create Scrapbook modal", ->
    it "shows the Create Scrapbook modal", ->
      expect($('#create-scrapbook-modal')).toBeHidden()
      $('#create-scrapbook-button').trigger('click')
      expect($('#create-scrapbook-modal')).toBeVisible()

  describe "closing the Create Scrapbook modal", ->
    it "hides the Create Scrapbook modal", ->
      # show the Create Scrapbook modal
      $('#create-scrapbook-button').trigger('click')
      expect( $('.modal#create-scrapbook-modal') ).toBeVisible()
      $('#cancel-create-scrapbook').trigger('click')
      expect( $('.modal#create-scrapbook-modal') ).toBeHidden()

  describe "successful creation", ->
    beforeEach ->
      # show the Create Scrapbook modal
      $('#create-scrapbook-button').trigger('click')
      expect($('#create-scrapbook-modal')).toBeVisible()
      $('form#create-scrapbook').trigger('ajax:success')

    it "calls the given success callback", ->
      expect(@successSpy).toHaveBeenCalled()

    it "hides the Create Scrapbook modal", ->
      expect($('#create-scrapbook-modal')).toBeHidden()


  describe "error on create", ->
    beforeEach ->
      data = { responseJSON: {"title" : ["can't be blank", "foo is not bar"]} }
      @createScrapbookController.markErrors(data)
      @error_field = $('form#create-scrapbook #scrapbook_title')

    it "highlights any errors", ->
      $form_group = @error_field.closest('.form-group')
      expect($form_group).toHaveClass('has-error')

    it "shows the appropriate error messages", ->
      $error_message = @error_field.siblings('.help-block').first()
      expect($error_message.text()).toEqual("can't be blank, foo is not bar")


