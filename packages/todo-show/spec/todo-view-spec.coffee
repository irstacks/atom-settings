path = require 'path'

ShowTodoView = require '../lib/todo-view'
TodosCollection = require '../lib/todo-collection'

describe "Show Todo View", ->
  [showTodoView, collection] = []

  beforeEach ->
    atom.config.set 'todo-show.findTheseTodos', ['TODO']
    atom.config.set 'todo-show.findUsingRegex', '/\\b(${TODOS}):?\\d*($|\\s.*$)/g'

    atom.project.setPaths [path.join(__dirname, 'fixtures/sample1')]
    collection = new TodosCollection
    uri = 'atom://todo-show/todos'
    showTodoView = new ShowTodoView(collection, uri)
    waitsFor -> !showTodoView.loading

  describe "View properties", ->
    it "has a title, uri, etc.", ->
      expect(showTodoView.getIconName()).toEqual 'checklist'
      expect(showTodoView.getURI()).toEqual 'atom://todo-show/todos'
      expect(showTodoView.find('.btn-group')).toExist()

    it "updates view title", ->
      count = showTodoView.collection.getTodosCount()
      expect(showTodoView.getTitle()).toBe "Todo Show: #{count} results"
      showTodoView.collection.search()
      expect(showTodoView.getTitle()).toBe "Todo Show: ..."

      waitsFor ->
        !showTodoView.loading
      runs ->
        expect(showTodoView.getTitle()).toBe "Todo Show: #{count} results"
        showTodoView.collection.todos = ['a single todo']
        expect(showTodoView.getTitle()).toBe "Todo Show: 1 result"

  describe "Automatic update of todos", ->
    it "refreshes on save", ->
      waitsForPromise -> atom.workspace.open 'temp.txt'
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        expect(showTodoView.getTodos()).toHaveLength 3
        editor.setText("# TODO: Test")
        editor.save()

        waitsFor -> !showTodoView.loading
        runs ->
          expect(showTodoView.getTodos()).toHaveLength 4
          editor.setText("")
          editor.save()

          waitsFor -> !showTodoView.loading
          runs ->
            expect(showTodoView.getTodos()).toHaveLength 3

    it "updates on search scope change", ->
      expect(showTodoView.loading).toBe false
      expect(collection.getSearchScope()).toBe 'full'
      expect(collection.toggleSearchScope()).toBe 'open'
      expect(showTodoView.loading).toBe true

      waitsFor -> !showTodoView.loading
      runs ->
        expect(collection.toggleSearchScope()).toBe 'active'
        expect(showTodoView.loading).toBe true

        waitsFor -> !showTodoView.loading
        runs ->
          expect(collection.toggleSearchScope()).toBe 'full'
          expect(showTodoView.loading).toBe true

    it "handles search scope; full, open, active", ->
      waitsForPromise ->
        atom.workspace.open 'sample.c'
      runs ->
        pane = atom.workspace.getActivePane()
        expect(showTodoView.getTodos()).toHaveLength 3

        collection.setSearchScope 'open'
        waitsFor -> !showTodoView.loading
        runs ->
          expect(showTodoView.getTodos()).toHaveLength 1

          waitsForPromise ->
            atom.workspace.open 'temp.txt'
          runs ->
            collection.setSearchScope 'active'
            waitsFor -> !showTodoView.loading
            runs ->
              expect(showTodoView.getTodos()).toHaveLength 0

              pane.activateItemAtIndex 0
              waitsFor -> !showTodoView.loading
              runs ->
                expect(showTodoView.getTodos()).toHaveLength 1
