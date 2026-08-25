# theCrag no longer serves logbooks to anonymous visitors, so scraping needs a
# session lifted from a signed-in browser. One admin's cookie is used to fetch
# for everyone, so in practice only an admin row carries a value here.
class AddThecragSessionCookieToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :thecrag_session_cookie, :string
  end
end
