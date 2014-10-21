require 'rails_helper'

describe "my/scrapbooks/show.html.erb" do
  let(:scrapbook) { Fabricate.build(:scrapbook, id: 123) }
  # let(:memory) { Fabricate.build(:photo_memory, id: 456) }

  before :each do
    # scrapbook.memories << memory
    assign(:scrapbook, scrapbook)
  end

  it "has an 'All my scrapbooks' link to the my_scrapbooks page" do
    render
    expect(rendered).to have_link('All my scrapbooks', href: my_scrapbooks_path)
  end

  context "when memory doesn't belong to the user" do
    before :each do
      allow(view).to receive(:belongs_to_user?).and_return(false)
      render
    end

    it "does not have an 'Add memories' link" do
      expect(rendered).not_to have_link('Add memories', href: memories_path)
    end

    it "does not have an edit link" do
      expect(rendered).not_to have_link('Edit', href: edit_my_scrapbook_path(scrapbook))
    end

    it "does not have a delete link" do
      expect(rendered).not_to have_link('Delete', href: my_scrapbook_path(scrapbook))
    end
  end

  context "when memory belongs to the user" do
    before :each do
      allow(view).to receive(:belongs_to_user?).and_return(true)
      render
    end

    it "has an 'Add memories' link" do
      expect(rendered).to have_link('Add memories', href: memories_path)
    end

    it "has an edit link" do
      expect(rendered).to have_link('Edit', href: edit_my_scrapbook_path(scrapbook))
    end

    it "has a delete link" do
      expect(rendered).to have_link('Delete', href: my_scrapbook_path(scrapbook))
    end
  end

  describe "scrapbook details" do
    before :each do
      render
    end

    it "has a title" do
      expect(rendered).to have_content(scrapbook.title)
    end

    it "has a description" do
      expect(rendered).to have_content(scrapbook.description)
    end
  end

  describe "memory thumbnails" do
    let(:memories)            { stub_memories(3).map.with_index{|m,i| double(id: i, scrapbook: scrapbook, memory: m)} }
    let(:scrapbook_memories)  { double('scrapbook_memories', by_ordering: memories) }

    before :each do
      allow(scrapbook).to receive(:scrapbook_memories).and_return(scrapbook_memories)
      render
    end

    it "displays one for each memory" do
      expect(rendered).to have_css('.memory', count: 3)
    end

    it "displays the memory's image" do
      expect(rendered).to match /1\.jpg/
      expect(rendered).to match /2\.jpg/
      expect(rendered).to match /3\.jpg/
    end

    it "displays the memory's title" do
      expect(rendered).to match /Test 1/
      expect(rendered).to match /Test 2/
      expect(rendered).to match /Test 3/
    end
  end
end

