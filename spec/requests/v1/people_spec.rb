require 'rails_helper'

RSpec.describe "V1::People", type: :request do
  let!(:user) { create(:user) }
  let!(:planet) { create(:planet) }

  req_payload = {
    people: {
      name: Faker::Lorem.sentence(word_count: 2),
      birth_year: Faker::Lorem.sentence(word_count: 2),
      eye_color: Faker::Lorem.sentence(word_count: 2),
      gender: Faker::Lorem.sentence(word_count: 2),
      hair_color: Faker::Lorem.sentence(word_count: 2),
      height: Faker::Lorem.sentence(word_count: 2),
      mass: Faker::Lorem.sentence(word_count: 2),
      skin_color: Faker::Lorem.sentence(word_count: 2)
    }
  }

  describe 'GET /v1/people' do
    describe 'with auth' do
      before { sign_in user }

      it 'should return OK' do
        get '/v1/people'
        expect(response).to have_http_status(:ok)
      end

      describe 'with data in the DB' do
        let!(:people) { create_list(:people, 10, planet_id: planet.id) }
        it 'should return the people' do
          get '/v1/people'
          payload = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(payload['people'].size).to eq(people.size)
        end
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        get '/v1/people'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /v1/people/:id' do
    let!(:people) { create(:people, planet_id: planet.id) }

    describe 'with auth' do
      before { sign_in user }

      it 'should return OK' do
        get "/v1/people/#{people.id}"
        expect(response).to have_http_status(:ok)
      end

      it 'should return the correct people' do
        get "/v1/people/#{people.id}"
        payload = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(payload['people']['id']).to eq(people.id)
        expect(payload['people']['name']).to eq(people.name)
      end

      it 'should return an error when the record doesn\'t exist' do
        get '/v1/people/0'
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        get "/v1/people/#{people.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /v1/people' do
    describe 'with auth' do
      before { sign_in user }

      it 'should create the people' do
        req_payload[:people][:planet_id] = planet.id
        post '/v1/people', params: req_payload
        payload = JSON.parse(response.body)
        expect(payload).to_not be_empty
        expect(response).to have_http_status(:created)
        expect(payload['people']['id']).to_not be_nil
      end

      it 'should return an error if the payload is wrong' do
        wrong_payload = {
          people: {
            name: 'wrong people',
            diameter: nil
          }
        }

        post '/v1/people', params: wrong_payload
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        req_payload[:people][:planet_id] = planet.id
        post '/v1/people', params: req_payload
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /v1/people' do
    let!(:people) { create(:people, planet_id: planet.id) }

    describe 'with auth' do
      before { sign_in user }

      it 'should update the people' do
        req_payload[:people][:planet_id] = planet.id
        put "/v1/people/#{people.id}", params: req_payload
        payload = JSON.parse(response.body)
        expect(payload).to_not be_empty
        expect(response).to have_http_status(:ok)
        expect(payload['people']['name']).to eq(req_payload[:people][:name])
      end

      it 'should return an error if the payload is wrong' do
        wrong_payload = {
          people: { name: nil }
        }
        put "/v1/people/#{people.id}", params: wrong_payload
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        req_payload[:people][:planet_id] = planet.id
        put "/v1/people/#{people.id}", params: req_payload
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /v1/people/:id' do
    let!(:people) { create_list(:people, 10, planet_id: planet.id) }

    describe 'with auth' do
      before { sign_in user }

      it 'should delete the people' do
        delete "/v1/people/#{people[0].id}"
        # payload = JSON.parse(response.body)
        expect(response.body).to be_empty
        expect(response).to have_http_status(:no_content)
        expect(People.all.size).to eq(9)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        delete "/v1/people/#{people[0].id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /v1/people/:id/films' do
    let!(:planet1) { create(:planet) }
    let!(:people1) { create(:people, planet_id: planet1.id) }
    let!(:film1) { create(:film) }
    let!(:film2) { create(:film) }
    let!(:filmpeople1) { create(:film_people, people_id: people1.id, film_id: film1.id) }
    let!(:filmpeople2) { create(:film_people, people_id: people1.id, film_id: film2.id) }

    describe 'with auth' do
      before { sign_in user }

      it 'should list the films of the people' do
        get "/v1/people/#{people1.id}/films"
        payload = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(payload['films'].size).to eq(2)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        get "/v1/people/#{people1.id}/films"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /v1/people/:id/films' do
    let!(:planet) { create(:planet) }
    let!(:people) { create(:people, planet_id: planet.id) }
    let!(:film) { create(:film) }

    describe 'with auth' do
      before { sign_in user }

      it 'should create the films for the people' do
        post "/v1/people/#{people.id}/films", params: { film: { id: film.id } }
        payload = JSON.parse(response.body)
        expect(response).to have_http_status(:created)
        expect(payload['films'].size).to eq(1)
        expect(People.find(people.id).films.size).to eq(1)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        post "/v1/people/#{people.id}/films", params: { film: { id: film.id } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE  /v1/people/:people_id/films/:film_id' do
    let!(:planet1) { create(:planet) }
    let!(:people1) { create(:people, planet_id: planet1.id) }
    let!(:film1) { create(:film) }
    let!(:film2) { create(:film) }
    let!(:filmpeople1) { create(:film_people, people_id: people1.id, film_id: film1.id) }
    let!(:filmpeople2) { create(:film_people, people_id: people1.id, film_id: film2.id) }

    describe 'with auth' do
      before { sign_in user }

      it 'should delete the films for the people' do
        expect(People.find(people1.id).films.size).to eq(2)
        delete "/v1/people/#{people1.id}/films/#{film2.id}"
        # payload = JSON.parse(response.body)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        expect(People.find(people1.id).films.size).to eq(1)
      end
    end

    describe 'without auth' do
      it 'should return an error' do
        delete "/v1/people/#{people1.id}/films/#{film1.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
