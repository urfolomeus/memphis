require 'rails_helper'

describe My::MemoriesController do
  let(:stub_memories)   { double('memories', find: memory) }
  let(:memory)          { Fabricate.build(:photo_memory, id: 123, user: @user) }
  let(:base_path)       { my_memories_path }

  before :each do
    @user = Fabricate.build(:user)
    allow(Memory).to receive(:find).and_return(memory)
  end

  describe 'GET index' do
    describe 'ensure user is logged in' do
      before :each do
        get :index, format: format
      end

      it_behaves_like 'requires logged in user'
    end

    context 'when logged in' do
      let(:current_user)     { Fabricate.build(:approved_user) }
      let(:memories)         { double }
      let(:ordered_memories) { double }
      let(:paged_memories)   { double }
      let(:page)             { '1' }
      let(:scrapbooks_count) { 3 }

      before :each do
        allow(controller).to receive(:current_user).and_return(current_user)

        allow(current_user).to receive(:memories).and_return(memories)
        allow(memories).to receive(:by_last_created).and_return(ordered_memories)
        allow(ordered_memories).to receive(:page).and_return(paged_memories)

        allow(current_user.scrapbooks).to receive(:count).and_return(scrapbooks_count)

        login_user
        get :index, page: page
      end

      it 'sets the current memory index path if action is index' do
        expect(session[:current_memory_index_path]).to eql(my_memories_path(page: page))
      end

      it "fetches the current user's memories" do
        expect(current_user).to have_received(:memories)
      end

      it 'orders the memories by their last created date' do
        expect(memories).to have_received(:by_last_created)
      end

      it 'paginates the ordered memories' do
        expect(ordered_memories).to have_received(:page).with(page)
      end

      it 'assigns the paged memories' do
        expect(assigns[:memories]).to eq(paged_memories)
      end

      it 'assigns the scrapbook count' do
        expect(assigns[:scrapbooks_count]).to eql(scrapbooks_count)
      end

      it "renders the user index page" do
        expect(response).to render_template('my/memories/index')
      end
    end
  end

  describe 'GET show' do
    describe 'ensure user is logged in' do
      before :each do
        get :show, id: 123, format: format
      end

      it_behaves_like 'requires logged in user'
    end

    context "when logged in" do
      before :each do
        login_user
      end

      it 'does not set the current memory index path' do
        expect(session[:current_memory_index_path]).to be_nil
      end

      it "fetches the requested memory" do
        get :show, id: 123
        expect(Memory).to have_received(:find).with('123')
      end

      it "renders the not found page if memory wasn't found" do
        allow(Memory).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        get :show, id: 123
        expect(response).to render_template('exceptions/not_found')
      end

      context "when the current user can modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(true)
          get :show, id: 123, page: '2'
        end

        it "assigns fetched memory" do
          expect(assigns(:memory)).to eql(memory)
        end

        it "assigns the page number" do
          expect(assigns(:page)).to eql('2')
        end

        it "renders the show page" do
          expect(response).to render_template(:show)
        end
      end

      context "when the current_user cannot modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(false)
          get :show, id: 123
        end

        it "does not assign the page number" do
          expect(assigns(:page)).to be_nil
        end

        it "renders the not found page" do
          expect(response).to render_template('exceptions/not_found')
        end
      end
    end
  end

  describe 'GET new' do
    describe 'ensure user is logged in' do
      before :each do
        get :new, format: format
      end

      it_behaves_like 'requires logged in user'
    end

    context 'when logged in' do
      before :each do
        allow(@user).to receive(:memories).and_return(stub_memories)
        login_user
        get :new
      end

      it 'does not set the current memory index path if action is not index' do
        expect(session[:current_memory_index_path]).to be_nil
      end

      it "assigns a new Memory" do
        expect(assigns(:memory)).to be_a(Memory)
      end

      it "is successful" do
        expect(response).to be_success
        expect(response.status).to eql(200)
      end

      it "renders the new page" do
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'POST create' do
    let(:strong_params) {{ title: 'A title' }}
    let(:format)        { 'html' }
    let(:given_params)  {{
      memory: strong_params,
      controller: "my/memories",
      action: "create",
      format: format
    }}

    describe 'ensure user is logged in' do
      before :each do
        post :create, given_params
      end

      it_behaves_like 'requires logged in user'
    end

    context 'when logged in' do
      before :each do
        allow(@user).to receive(:memories).and_return(stub_memories)
        login_user
        allow(MemoryParamCleaner).to receive(:clean).and_return(strong_params)
        allow(Memory).to receive(:new).and_return(memory)
        allow(memory).to receive(:user=)
        allow(memory).to receive(:save).and_return(true)
        post :create, given_params
      end

      it 'does not set the current memory index path if action is not index' do
        expect(session[:current_memory_index_path]).to be_nil
      end

      it "cleans the given params" do
        expect(MemoryParamCleaner).to have_received(:clean).with(given_params)
      end

      it "builds a new Memory with the given params" do
        expect(Memory).to have_received(:new).with(strong_params)
      end

      it "assigns the memory" do
        expect(assigns(:memory)).to eql(memory)
      end

      it "assigns the current user" do
        expect(memory).to have_received('user=').with(@user)
      end

      it "saves the Memory" do
        expect(memory).to have_received(:save)
      end

      context "save is successful" do
        context "when save and add another" do
          it "redirects to the new page" do
            post :create, given_params.merge(commit: 'Save And Add Another')
            expect(response).to redirect_to(new_my_memory_url)
          end
        end

        context "when save" do
          it "redirects to the user's memories page" do
            post :create, given_params.merge(commit: 'Save')
            expect(response).to redirect_to(my_memories_url)
          end
        end
      end

      context "save is not successful" do
        it "re-renders the new form" do
          allow(memory).to receive(:save).and_return(false)
          post :create, given_params
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET edit' do
    describe 'ensure user is logged in' do
      before :each do
        get :edit, id: 123, format: format
      end

      it_behaves_like 'requires logged in user'
    end

    context "when logged in" do
      before :each do
        login_user
      end

      it 'does not set the current memory index path if action is not index' do
        expect(session[:current_memory_index_path]).to be_nil
      end

      it "fetches the requested memory" do
        get :edit, id: 123
        expect(Memory).to have_received(:find).with('123')
      end

      it "renders the not found page if memory wasn't found" do
        allow(Memory).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        get :edit, id: 123
        expect(response).to render_template('exceptions/not_found')
      end

      context "when the current user can modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(true)
          get :edit, id: 123
        end

        it "assigns fetched memory" do
          expect(assigns(:memory)).to eql(memory)
        end

        it "renders the edit page" do
          expect(response).to render_template(:edit)
        end
      end

      context "when the current_user cannot modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(false)
          get :edit, id: 123
        end

        it "renders the not found page" do
          expect(response).to render_template('exceptions/not_found')
        end
      end
    end
  end

  describe 'PUT upate' do
    let(:strong_params) {{ title: 'New title' }}
    let(:format)        { 'html' }
    let(:given_params)  {{
      memory: strong_params,
      id: '123',
      controller: "my/memories",
      action: "update",
      format: format
    }}

    describe 'ensure user is logged in' do
      before :each do
        put :update, given_params
      end

      it_behaves_like 'requires logged in user'
    end

    context 'when logged in' do
      before :each do
        login_user
        allow(MemoryParamCleaner).to receive(:clean).and_return(strong_params)
        allow(Memory).to receive(:find).and_return(memory)
        allow(memory).to receive(:update).and_return(true)
      end

      it 'does not set the current memory index path if action is not index' do
        expect(session[:current_memory_index_path]).to be_nil
      end

      it "finds the Memory with the given id" do
        put :update, given_params
        expect(Memory).to have_received(:find).with('123')
      end

      context "when the current user can modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(true)
          put :update, given_params
        end

        it "assigns fetched memory" do
          expect(assigns(:memory)).to eql(memory)
        end

        it "cleans the given params" do
          expect(MemoryParamCleaner).to have_received(:clean).with(given_params)
        end

        it "updates the given attributes" do
          expect(memory).to have_received('update').with(strong_params)
        end

        context "update is successful" do
          it "redirects to the memory page" do
            expect(response).to redirect_to(memory_path(memory.id))
          end
        end

        context "update is not successful" do
          it "re-renders the edit form" do
            allow(memory).to receive(:update).and_return(false)
            put :update, given_params
            expect(response).to render_template(:edit)
          end
        end
      end

      context "when the current_user cannot modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(false)
          put :update, given_params
        end

        it "renders the not found page" do
          expect(response).to render_template('exceptions/not_found')
        end
      end
    end
  end

  describe 'DELETE destroy' do
    describe 'ensure user is logged in' do
      before :each do
        delete :destroy, id: '123', format: format
      end

      it_behaves_like 'requires logged in user'
    end

    context 'when logged in' do
      before :each do
        login_user
        allow(Memory).to receive(:find).and_return(memory)
        allow(memory).to receive(:destroy).and_return(true)
      end

      it 'does not set the current memory index path if action is not index' do
        expect(session[:current_memory_index_path]).to be_nil
      end

      it "finds the Memory with the given id" do
        delete :destroy, id: '123'
        expect(Memory).to have_received(:find).with('123')
      end

      it "renders the not found page if memory wasn't found" do
        allow(Memory).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        delete :destroy, id: '123'
        expect(response).to render_template('exceptions/not_found')
      end

      context "when the current user can modify the memory" do
        let(:current_memory_index_path) { memories_url }

        before :each do
          allow(@user).to receive(:can_modify?).and_return(true)
          session[:current_memory_index_path] = current_memory_index_path
          delete :destroy, id: '123'
        end

        it "assigns fetched memory" do
          expect(assigns(:memory)).to eql(memory)
        end

        it "destroys the given attributes" do
          expect(memory).to have_received('destroy')
        end

        context "when current index path is memories" do
          it "redirects to the memories page" do
            expect(response).to redirect_to(memories_url)
          end
        end

        context "when current memory index path is my memories" do
          let(:current_memory_index_path) { my_memories_url }

          it "redirects to the my memories page" do
            expect(response).to redirect_to(my_memories_url)
          end
        end

        context "destroy is successful" do
          it "shows a success notice" do
            expect(flash[:notice]).to eql('Successfully deleted')
          end
        end

        context "destroy is not successful" do
          it "shows an alert" do
            allow(memory).to receive(:destroy).and_return(false)
            delete :destroy, id: '123'
            expect(flash[:alert]).to eql('Could not delete')
          end
        end
      end

      context "when the current_user cannot modify the memory" do
        before :each do
          allow(@user).to receive(:can_modify?).and_return(false)
          delete :destroy, id: '123'
        end

        it "renders the not found page" do
          expect(response).to render_template('exceptions/not_found')
        end
      end
    end
  end
end

