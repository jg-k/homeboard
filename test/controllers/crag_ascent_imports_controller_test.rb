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

  # The key identifies the climber on theCrag's side, so requiring a username
  # too would leave a key-only climber with nothing to type in.
  test "POST sync_thecrag accepts a key with no username" do
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "", thecrag_api_key: "secret-key" }

    assert_redirected_to settings_path
    assert_equal "secret-key", @user.reload.thecrag_api_key
  end

  test "POST sync_thecrag still needs a username when there is no key" do
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url, params: { thecrag_username: "" }

    assert_redirected_to settings_path
    assert_match(/username/, flash[:alert])
  end

  test "POST sync_thecrag forgets the watermark for a full re-sync" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 4242)
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "jegk", thecrag_api_key: "", full_thecrag_resync: "1" }

    assert_equal "secret-key", @user.reload.thecrag_api_key
    assert_nil @user.thecrag_since_epoch
  end

  test "POST sync_thecrag saves a pasted API key" do
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "jegk", thecrag_api_key: "secret-key" }

    assert_redirected_to settings_path
    assert_equal "secret-key", @user.reload.thecrag_api_key
    assert_equal "jegk", @user.thecrag_username
  end

  # A password field cannot be prefilled, so it submits blank on every sync.
  # Treating that as "clear the key" used to wipe it on the next sync.
  test "POST sync_thecrag keeps the saved key when the field is left blank" do
    @user.update!(thecrag_api_key: "secret-key")
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "jegk", thecrag_api_key: "" }

    assert_equal "secret-key", @user.reload.thecrag_api_key
  end

  test "POST sync_thecrag clears the key only when asked" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 4242)
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "jegk", thecrag_api_key: "", remove_thecrag_api_key: "1" }

    assert_nil @user.reload.thecrag_api_key
    assert_nil @user.thecrag_since_epoch
  end

  # A new key may belong to a different logbook, so the watermark that made the
  # last sync incremental cannot be carried over.
  test "POST sync_thecrag forgets the watermark when the key changes" do
    @user.update!(thecrag_api_key: "old-key", thecrag_since_epoch: 4242)
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "jegk", thecrag_api_key: "new-key" }

    assert_equal "new-key", @user.reload.thecrag_api_key
    assert_nil @user.thecrag_since_epoch
  end

  test "POST sync_thecrag keeps the watermark when the same key is pasted again" do
    @user.update!(thecrag_api_key: "secret-key", thecrag_since_epoch: 4242)
    sign_in @user

    post sync_thecrag_crag_ascent_imports_url,
      params: { thecrag_username: "jegk", thecrag_api_key: "secret-key" }

    assert_equal 4242, @user.reload.thecrag_since_epoch
  end
end
