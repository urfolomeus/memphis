require 'rails_helper'

describe SessionsController do
  describe 'GET new' do
    it 'renders the login page' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST create' do
    let(:token) { 't0k3n' }
    let(:login_params) {{
      username: 'bobby',
      password: 's3cr3t'
    }}

    before :each do
      allow(SessionWrapper).to receive(:create).and_return(token)
      post :create, login: login_params
    end

    it 'logs the user in' do
      expect(SessionWrapper).to have_received(:create).with(login_params)
    end

    context 'when successful' do
      let(:token) { 't0k3n' }

      it 'has a session token' do
        expect(session[:auth_token]).to eql(token)
      end

      it 'redirects to the root page' do
        expect(response).to redirect_to(:root)
      end

      it 'displays a success notice' do
        expect(flash[:notice]).to eql('Successfully signed in')
      end
    end

    context 'when unsuccessful' do
      let(:token) { '' }

      it 'does not have a session token' do
        expect(session[:auth_token]).to be_blank
      end

      it 'redirects to the login page' do
        expect(response).to redirect_to(:login)
      end

      it 'displays a failure alert' do
        expect(flash[:alert]).to eql('Could not sign in')
      end
    end
  end

  describe 'DELETE destroy' do
    let(:token) { 't0k3n' }

    before :each do
      session[:auth_token] = token
      allow(SessionWrapper).to receive(:delete)
      delete :destroy
    end

    it 'logs the user out' do
      expect(SessionWrapper).to have_received(:delete).with(token)
    end

    it 'removes the session token' do
      expect(session[:auth_token]).to be_nil
    end

    it 'redirects to the root page' do
      expect(response).to redirect_to(:root)
    end

    it 'displays a success notice' do
      expect(flash[:notice]).to eql('Signed out')
    end
  end
end
