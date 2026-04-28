require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when user is not signed in" do
      it "renders the home page" do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Welcome to Homeboard")
        expect(response.body).to include("Track your home bouldering problems")
      end
    end

    context "when user is signed in" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      context "with no problems" do
        it "renders the dashboard with empty state" do
          get root_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("You don't have any problems yet")
          expect(response.body).to include("Go to My Boards")
        end
      end

      context "with problems" do
        let!(:board) { create(:board) }
        let!(:user_board) { create(:user_board, user: user, board: board) }
        let!(:board_layout) { create(:board_layout, board: board) }
        let!(:problem1) { create(:problem, board_layout: board_layout, name: "Test Problem 1", grade: "V5") }
        let!(:problem2) { create(:problem, board_layout: board_layout, name: "Test Problem 2", grade: "V7") }

        it "renders the dashboard with problems list" do
          get root_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Test Problem 1")
          expect(response.body).to include("Test Problem 2")
          expect(response.body).to include("V5")
          expect(response.body).to include("V7")
          expect(response.body).to include(board.name)
          expect(response.body).to include(board_layout.name)
        end

        it "shows the first problem as selected by default" do
          get root_path
          expect(response.body).to include('data-holds-holds-value')
          expect(response.body).to include(problem2.name) # Most recent problem
        end
      end

      context "with soft-deleted problems" do
        let!(:board) { create(:board) }
        let!(:user_board) { create(:user_board, user: user, board: board) }
        let!(:board_layout) { create(:board_layout, board: board) }
        let!(:active_problem) { create(:problem, board_layout: board_layout, name: "Active Problem") }
        let!(:deleted_problem) { create(:problem, board_layout: board_layout, name: "Deleted Problem", discarded_at: Time.current) }

        it "only shows kept problems" do
          get root_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Active Problem")
          expect(response.body).not_to include("Deleted Problem")
        end
      end
    end
  end

  describe "GET /home/index" do
    it "works the same as root path" do
      get home_index_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /home/select_problem/:id" do
    let(:user) { create(:user) }
    let(:board) { create(:board) }
    let!(:user_board) { create(:user_board, user: user, board: board) }
    let(:board_layout) { create(:board_layout, board: board) }
    let(:problem) { create(:problem, board_layout: board_layout, name: "Selected Problem") }

    before do
      sign_in user
    end

    context "with valid problem id" do
      it "returns a turbo stream response" do
        post select_problem_path(problem), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream')
        expect(response.body).to include('problem_display')
        expect(response.body).to include(problem.name)
      end

      it "includes holds data in the response" do
        problem.update!(
          start_holds: [ { x: 0.5, y: 0.5 } ].to_json,
          finish_holds: [ { x: 0.8, y: 0.2 } ].to_json
        )

        post select_problem_path(problem), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('data-holds-holds-value')
      end
    end

    context "with invalid problem id" do
      it "raises RecordNotFound" do
        expect {
          post select_problem_path(999999), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when trying to access another user's problem" do
      let(:other_user) { create(:user) }
      let(:other_board) { create(:board) }
      let!(:other_user_board) { create(:user_board, user: other_user, board: other_board) }
      let(:other_layout) { create(:board_layout, board: other_board) }
      let(:other_problem) { create(:problem, board_layout: other_layout) }

      it "raises RecordNotFound" do
        expect {
          post select_problem_path(other_problem), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when not signed in" do
      before do
        sign_out user
      end

      it "redirects to sign in" do
        post select_problem_path(problem)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
