require "test_helper"

class CragAscentImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "GET new requires authentication" do
    get new_crag_ascent_import_url
    assert_redirected_to new_user_session_path
  end

  test "GET new returns success" do
    sign_in @user
    get new_crag_ascent_import_url
    assert_response :success
  end

  test "POST create with valid CSV imports ascents" do
    sign_in @user

    csv = CSV.generate do |csv|
      csv << [ "Ascent ID", "Route Name", "Ascent Date", "Ascent Type",
               "Ascent Gear Style", "Route Gear Style", "Ascent Grade",
               "Route Grade", "Route Height", "Crag Name", "Crag Path",
               "Country", "With", "Comment", "Quality" ]
      csv << [ "10001", "Test Route", "2025-06-01T00:00:00Z", "Flash", "Sport",
               "Sport", "7a", "6c", "25",
               "Test Crag", "Europe > Spain", "Spain", "Partner", "Great", "***" ]
    end

    file = Rack::Test::UploadedFile.new(
      StringIO.new(csv), "text/csv", true, original_filename: "logbook.csv"
    )

    assert_difference [ "CragAscent.count", "ActivityLog.count" ], 1 do
      post crag_ascent_imports_url, params: { file: file }
    end

    assert_redirected_to activity_path
    assert_match(/Imported 1 ascent/, flash[:notice])
  end

  test "POST create with no file redirects with alert" do
    sign_in @user

    assert_no_difference "CragAscent.count" do
      post crag_ascent_imports_url
    end

    assert_redirected_to new_crag_ascent_import_path
    assert_match(/Please select a CSV file/, flash[:alert])
  end

  test "POST create requires authentication" do
    post crag_ascent_imports_url
    assert_redirected_to new_user_session_path
  end
end
